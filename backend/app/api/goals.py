from uuid import UUID
from fastapi import APIRouter, Depends, Query, status
from supabase import Client

from app.api.deps import get_current_user_id
from app.core.supabase import get_supabase_client
from app.schemas.goal import (
    GoalCreate,
    GoalPlanAcceptRequest,
    GoalPlanResponse,
    GoalResponse,
    GoalUpdate,
)
from app.services.goal_service import GoalService

router = APIRouter(prefix="/goals", tags=["goals"])


def _service(supabase: Client = Depends(get_supabase_client)) -> GoalService:
    return GoalService(supabase)


@router.get("", response_model=list[GoalResponse])
def list_goals(
    include_done: bool = Query(False),
    user_id: UUID = Depends(get_current_user_id),
    service: GoalService = Depends(_service),
) -> list[GoalResponse]:
    return service.list_goals(user_id=user_id, include_done=include_done)


@router.post("", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
def create_goal(
    goal_in: GoalCreate,
    user_id: UUID = Depends(get_current_user_id),
    service: GoalService = Depends(_service),
) -> GoalResponse:
    return service.create_goal(user_id=user_id, goal_in=goal_in)


@router.get("/{goal_id}", response_model=GoalResponse)
def get_goal(
    goal_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    service: GoalService = Depends(_service),
) -> GoalResponse:
    return service.get_goal(user_id=user_id, goal_id=goal_id)


@router.patch("/{goal_id}", response_model=GoalResponse)
def update_goal(
    goal_id: UUID,
    goal_in: GoalUpdate,
    user_id: UUID = Depends(get_current_user_id),
    service: GoalService = Depends(_service),
) -> GoalResponse:
    return service.update_goal(user_id=user_id, goal_id=goal_id, goal_in=goal_in)


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_goal(
    goal_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    service: GoalService = Depends(_service),
) -> None:
    service.delete_goal(user_id=user_id, goal_id=goal_id)


@router.post("/{goal_id}/plan", response_model=GoalPlanResponse, status_code=status.HTTP_202_ACCEPTED)
def request_plan(
    goal_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    service: GoalService = Depends(_service),
) -> GoalPlanResponse:
    """Fase 1: tandai GENERATING. Fase 2 mengisi draft via goal_planner AI."""
    return service.request_plan(user_id=user_id, goal_id=goal_id)


@router.get("/{goal_id}/plan", response_model=GoalPlanResponse)
def get_plan(
    goal_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    service: GoalService = Depends(_service),
) -> GoalPlanResponse:
    return service.get_plan(user_id=user_id, goal_id=goal_id)


@router.post("/{goal_id}/plan/accept", response_model=GoalPlanResponse)
def accept_plan(
    goal_id: UUID,
    body: GoalPlanAcceptRequest,
    user_id: UUID = Depends(get_current_user_id),
    service: GoalService = Depends(_service),
) -> GoalPlanResponse:
    return service.accept_plan(
        user_id=user_id,
        goal_id=goal_id,
        plan_draft=body.plan_draft,
        only_milestones=body.only_milestones,
    )
