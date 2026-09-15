from datetime import date, datetime, timedelta
from typing import Optional
from uuid import UUID, uuid4
from fastapi import HTTPException, status
from supabase import Client

from app.schemas.task import (
    DayTasks,
    TaskCreate,
    TaskResponse,
    TaskSuggestionResponse,
    TaskUpdate,
    WeekTasksResponse,
)

DAY_NAMES = [
    "MONDAY",
    "TUESDAY",
    "WEDNESDAY",
    "THURSDAY",
    "FRIDAY",
    "SATURDAY",
    "SUNDAY",
]


class TaskService:
    def __init__(self, supabase: Client):
        self.supabase = supabase

    def get_week_tasks(
        self, user_id: UUID, start_date: date, today: Optional[date] = None
    ) -> WeekTasksResponse:
        """Fetch tasks for a 7-day period starting from start_date (typically Monday)."""
        if today is None:
            today = date.today()

        end_date = start_date + timedelta(days=6)

        # 1. Fetch tasks
        response = (
            self.supabase.table("tasks")
            .select("*")
            .eq("user_id", str(user_id))
            .gte("assigned_date", start_date.isoformat())
            .lte("assigned_date", end_date.isoformat())
            .order("assigned_date", desc=False)
            .order("created_at", desc=False)
            .execute()
        )

        # 2. Fetch pending suggestions for these tasks
        sug_res = (
            self.supabase.table("task_suggestions")
            .select("*")
            .eq("user_id", str(user_id))
            .eq("status", "PENDING")
            .execute()
        )
        suggestions_by_task = {
            s["task_id"]: TaskSuggestionResponse.model_validate(s)
            for s in (sug_res.data or [])
        }

        all_tasks: list[TaskResponse] = []
        for item in response.data or []:
            t_resp = TaskResponse.model_validate(item)
            if str(t_resp.id) in suggestions_by_task:
                t_resp.suggestion = suggestions_by_task[str(t_resp.id)]
            all_tasks.append(t_resp)

        # Group tasks by date
        tasks_by_date: dict[date, list[TaskResponse]] = {}
        for current_day_idx in range(7):
            d = start_date + timedelta(days=current_day_idx)
            tasks_by_date[d] = []

        for task in all_tasks:
            if task.assigned_date in tasks_by_date:
                tasks_by_date[task.assigned_date].append(task)

        # Build day list
        days: list[DayTasks] = []
        for current_day_idx in range(7):
            d = start_date + timedelta(days=current_day_idx)
            days.append(
                DayTasks(
                    date=d,
                    day_name=DAY_NAMES[d.weekday()],
                    is_today=(d == today),
                    tasks=tasks_by_date[d],
                )
            )

        return WeekTasksResponse(
            week_start=start_date,
            week_end=end_date,
            days=days,
        )

    def create_task(self, user_id: UUID, task_in: TaskCreate) -> TaskResponse:
        """Create a manual task.

        Ensures recurrence_group_id equals the task's id if recurring.
        Flags ambiguity if estimated_minutes is null.
        """
        task_id = uuid4()
        recurrence_group_id = task_id if task_in.recurrence_rule else None
        is_ambiguous = task_in.estimated_minutes is None

        payload = {
            "id": str(task_id),
            "user_id": str(user_id),
            "title": task_in.title.strip(),
            "assigned_date": task_in.assigned_date.isoformat(),
            "estimated_minutes": task_in.estimated_minutes,
            "goal_id": str(task_in.goal_id) if task_in.goal_id else None,
            "recurrence_rule": task_in.recurrence_rule,
            "recurrence_group_id": str(recurrence_group_id) if recurrence_group_id else None,
            "status": "PENDING",
            "source": "MANUAL",
            "is_ambiguous": is_ambiguous,
            "ai_generated": False,
            "missed_follow_up": "NONE",
        }

        response = self.supabase.table("tasks").insert(payload).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create task",
            )

        return TaskResponse.model_validate(response.data[0])

    def update_task(
        self, user_id: UUID, task_id: UUID, task_in: TaskUpdate
    ) -> TaskResponse:
        """Update an existing task belonging to the user."""
        update_data = {}

        if task_in.title is not None:
            update_data["title"] = task_in.title.strip()
        if task_in.assigned_date is not None:
            update_data["assigned_date"] = task_in.assigned_date.isoformat()
        if task_in.status is not None:
            update_data["status"] = task_in.status
        if task_in.estimated_minutes is not None:
            update_data["estimated_minutes"] = task_in.estimated_minutes
            update_data["is_ambiguous"] = False

        if not update_data:
            res = (
                self.supabase.table("tasks")
                .select("*")
                .eq("id", str(task_id))
                .eq("user_id", str(user_id))
                .execute()
            )
            if not res.data:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND, detail="Task not found"
                )
            return TaskResponse.model_validate(res.data[0])

        res = (
            self.supabase.table("tasks")
            .update(update_data)
            .eq("id", str(task_id))
            .eq("user_id", str(user_id))
            .execute()
        )

        if not res.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found or access denied",
            )

        return TaskResponse.model_validate(res.data[0])

    def delete_task(self, user_id: UUID, task_id: UUID) -> None:
        """Delete a task belonging to user."""
        res = (
            self.supabase.table("tasks")
            .delete()
            .eq("id", str(task_id))
            .eq("user_id", str(user_id))
            .execute()
        )
        if not res.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found or access denied",
            )

    def clarify_task(
        self, user_id: UUID, task_id: UUID, estimated_minutes: int
    ) -> TaskResponse:
        """Clarify task duration from ambiguous (?) state."""
        res = (
            self.supabase.table("tasks")
            .update({
                "estimated_minutes": estimated_minutes,
                "is_ambiguous": False,
            })
            .eq("id", str(task_id))
            .eq("user_id", str(user_id))
            .execute()
        )
        if not res.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found or access denied",
            )
        return TaskResponse.model_validate(res.data[0])

    def handle_follow_up(
        self, user_id: UUID, task_id: UUID, action: str
    ) -> TaskResponse:
        """Process user decision on missed task follow-up chip.

        - FORGOT: task was done, mark DONE + missed_follow_up = FORGOT
        - SKIPPED: task was skipped, remain MISSED + missed_follow_up = SKIPPED
        - RESCHEDULED: move task to today + status = PENDING + missed_follow_up = RESCHEDULED
        """
        today = date.today()

        if action == "FORGOT":
            payload = {"status": "DONE", "missed_follow_up": "FORGOT"}
        elif action == "SKIPPED":
            payload = {"status": "MISSED", "missed_follow_up": "SKIPPED"}
        elif action == "RESCHEDULED":
            payload = {
                "assigned_date": today.isoformat(),
                "status": "PENDING",
                "missed_follow_up": "RESCHEDULED",
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid follow-up action: {action}",
            )

        res = (
            self.supabase.table("tasks")
            .update(payload)
            .eq("id", str(task_id))
            .eq("user_id", str(user_id))
            .execute()
        )

        if not res.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found or access denied",
            )

        return TaskResponse.model_validate(res.data[0])

    def handle_reschedule(
        self, user_id: UUID, task_id: UUID, suggestion_id: UUID, action: str
    ) -> TaskResponse:
        """Process user decision on reschedule suggestion line.

        - ACCEPT: updates task.assigned_date to suggested_date, marks suggestion ACCEPTED
        - REJECT: leaves task unchanged, marks suggestion REJECTED
        """
        sug_res = (
            self.supabase.table("task_suggestions")
            .select("*")
            .eq("id", str(suggestion_id))
            .eq("user_id", str(user_id))
            .execute()
        )
        if not sug_res.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reschedule suggestion not found",
            )

        sug = sug_res.data[0]
        now_iso = datetime.now().isoformat()

        if action == "ACCEPT":
            # Update task assigned date
            new_date = sug["suggested_date"]
            self.supabase.table("tasks").update({
                "assigned_date": new_date,
            }).eq("id", str(task_id)).eq("user_id", str(user_id)).execute()

            # Mark suggestion accepted
            self.supabase.table("task_suggestions").update({
                "status": "ACCEPTED",
                "responded_at": now_iso,
            }).eq("id", str(suggestion_id)).execute()

        elif action == "REJECT":
            # Mark suggestion rejected
            self.supabase.table("task_suggestions").update({
                "status": "REJECTED",
                "responded_at": now_iso,
            }).eq("id", str(suggestion_id)).execute()
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid action: {action}",
            )

        # Return updated task
        updated_res = (
            self.supabase.table("tasks")
            .select("*")
            .eq("id", str(task_id))
            .eq("user_id", str(user_id))
            .execute()
        )
        return TaskResponse.model_validate(updated_res.data[0])

    def create_reschedule_suggestion(
        self, user_id: UUID, task_id: UUID, suggested_date: date, reason: str
    ) -> TaskSuggestionResponse:
        """Create a reschedule suggestion for an overloaded task."""
        # Archive any existing pending suggestion for this task
        self.supabase.table("task_suggestions").update({
            "status": "REJECTED",
            "responded_at": datetime.now().isoformat(),
        }).eq("task_id", str(task_id)).eq("status", "PENDING").execute()

        sug_id = str(uuid4())
        payload = {
            "id": sug_id,
            "task_id": str(task_id),
            "user_id": str(user_id),
            "suggested_date": suggested_date.isoformat(),
            "reason": reason,
            "status": "PENDING",
        }
        res = self.supabase.table("task_suggestions").insert(payload).execute()
        return TaskSuggestionResponse.model_validate(res.data[0])
