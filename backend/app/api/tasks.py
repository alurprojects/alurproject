import logging
from datetime import date, timedelta
from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Query, status

from app.api.deps import get_current_user_id, get_embedding_service, get_task_service
from typing import Optional
from app.schemas.task import (
    TaskClarifyRequest,
    TaskCreate,
    TaskFollowUpRequest,
    TaskRescheduleRequest,
    TaskResponse,
    TaskUpdate,
    WeekTasksResponse,
)
from app.services.embedding_service import EmbeddingService
from app.services.task_service import TaskService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/tasks", tags=["tasks"])


def _sync_task_embedding(embedding_service: EmbeddingService | None, user_id: UUID, task: TaskResponse) -> None:
    """Helper to synchronously upsert vector embedding for a task.

    Embedding tidak boleh menggagalkan request utama (Vercel 10s + tanpa
    GEMINI_API_KEY di env tertentu). Semua error ditelan jadi warning.
    """
    if embedding_service is None:
        return
    try:
        embedding_service.upsert_embedding_sync(
            user_id=user_id,
            source_type="TASK",
            source_id=task.id,
            content_text=f"{task.title} (assigned: {task.assigned_date}, status: {task.status})",
            metadata={
                "date": str(task.assigned_date),
                "status": task.status,
                "source": task.source,
                "goal_id": str(task.goal_id) if task.goal_id else None,
            },
        )
    except Exception as e:
        logger.warning(f"Failed to upsert task embedding for {task.id}: {e}")


def _get_monday(d: date) -> date:
    """Return the Monday of the week containing date d."""
    return d - timedelta(days=d.weekday())


@router.get("", response_model=WeekTasksResponse)
def get_week_tasks(
    week: Optional[date] = Query(
        None,
        description="Any date within the target week, or Monday of target week (YYYY-MM-DD). Defaults to current week.",
    ),
    user_id: UUID = Depends(get_current_user_id),
    task_service: TaskService = Depends(get_task_service),
) -> WeekTasksResponse:
    """Fetch 7 days of tasks (Monday to Sunday) for the specified week."""
    target_date = week or date.today()
    monday = _get_monday(target_date)
    return task_service.get_week_tasks(user_id=user_id, start_date=monday)


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(
    task_in: TaskCreate,
    user_id: UUID = Depends(get_current_user_id),
    task_service: TaskService = Depends(get_task_service),
    embedding_service: Optional[EmbeddingService] = Depends(get_embedding_service),
) -> TaskResponse:
    """Create a new task manually."""
    task = task_service.create_task(user_id=user_id, task_in=task_in)
    _sync_task_embedding(embedding_service, user_id, task)
    return task


@router.patch("/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: UUID,
    task_in: TaskUpdate,
    user_id: UUID = Depends(get_current_user_id),
    task_service: TaskService = Depends(get_task_service),
    embedding_service: Optional[EmbeddingService] = Depends(get_embedding_service),
) -> TaskResponse:
    """Update a task (e.g. toggle status PENDING/DONE, edit title, or reschedule)."""
    task = task_service.update_task(user_id=user_id, task_id=task_id, task_in=task_in)
    _sync_task_embedding(embedding_service, user_id, task)
    return task



@router.patch("/{task_id}/clarify", response_model=TaskResponse)
def clarify_task(
    task_id: UUID,
    clarify_in: TaskClarifyRequest,
    user_id: UUID = Depends(get_current_user_id),
    task_service: TaskService = Depends(get_task_service),
) -> TaskResponse:
    """Clarify an ambiguous (?) task by setting its estimated duration."""
    return task_service.clarify_task(
        user_id=user_id,
        task_id=task_id,
        estimated_minutes=clarify_in.estimated_minutes,
    )


@router.patch("/{task_id}/follow-up", response_model=TaskResponse)
def follow_up_task(
    task_id: UUID,
    follow_up_in: TaskFollowUpRequest,
    user_id: UUID = Depends(get_current_user_id),
    task_service: TaskService = Depends(get_task_service),
) -> TaskResponse:
    """Respond to a missed task follow-up chip (FORGOT, SKIPPED, or RESCHEDULED)."""
    return task_service.handle_follow_up(
        user_id=user_id,
        task_id=task_id,
        action=follow_up_in.action,
    )


@router.patch("/{task_id}/reschedule", response_model=TaskResponse)
def reschedule_task(
    task_id: UUID,
    reschedule_in: TaskRescheduleRequest,
    user_id: UUID = Depends(get_current_user_id),
    task_service: TaskService = Depends(get_task_service),
) -> TaskResponse:
    """Accept or reject an AI reschedule suggestion for an overloaded task."""
    return task_service.handle_reschedule(
        user_id=user_id,
        task_id=task_id,
        suggestion_id=reschedule_in.suggestion_id,
        action=reschedule_in.action,
    )



@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    task_service: TaskService = Depends(get_task_service),
) -> None:
    """Delete a task by ID."""
    task_service.delete_task(user_id=user_id, task_id=task_id)
