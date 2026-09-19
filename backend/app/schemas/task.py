from datetime import date, datetime
from typing import List, Literal, Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

TaskStatus = Literal["PENDING", "DONE", "MISSED"]
TaskSource = Literal["MANUAL", "BRAIN_DUMP", "CHAT_ROOM"]
MissedFollowUp = Literal["NONE", "PENDING", "FORGOT", "SKIPPED", "RESCHEDULED"]
SuggestionStatus = Literal["PENDING", "ACCEPTED", "REJECTED"]


class TaskBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=500, description="Task title/description")
    assigned_date: date = Field(..., description="Scheduled date for task execution")
    estimated_minutes: Optional[int] = Field(None, gt=0, description="Estimated duration in minutes, null for ambiguous")
    goal_id: Optional[UUID] = Field(None, description="Optional linked goal ID")
    recurrence_rule: Optional[str] = Field(None, description="Recurrence pattern: 'daily', 'weekdays', '2x/week', etc.")


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=500)
    assigned_date: Optional[date] = None
    status: Optional[TaskStatus] = None
    estimated_minutes: Optional[int] = Field(None, gt=0)


class TaskClarifyRequest(BaseModel):
    estimated_minutes: int = Field(..., gt=0, description="Duration in minutes (e.g. 15, 30, 45, 60)")


class TaskFollowUpRequest(BaseModel):
    action: Literal["FORGOT", "SKIPPED", "RESCHEDULED"] = Field(
        ...,
        description="FORGOT (done), SKIPPED (stay missed), RESCHEDULED (move to today and mark pending)",
    )


class TaskRescheduleRequest(BaseModel):
    suggestion_id: UUID = Field(..., description="ID of the task suggestion")
    action: Literal["ACCEPT", "REJECT"] = Field(..., description="ACCEPT or REJECT the reschedule suggestion")


class TaskSuggestionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    task_id: UUID
    user_id: UUID
    suggested_date: date
    reason: Optional[str] = None
    status: SuggestionStatus = "PENDING"
    responded_at: Optional[datetime] = None
    created_at: datetime


class TaskResponse(TaskBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    recurrence_group_id: Optional[UUID] = None
    status: TaskStatus = "PENDING"
    source: TaskSource = "MANUAL"
    is_ambiguous: bool = False
    ai_generated: bool = False
    missed_follow_up: MissedFollowUp = "NONE"
    suggestion: Optional[TaskSuggestionResponse] = None
    created_at: datetime
    updated_at: datetime


class DayTasks(BaseModel):
    date: date
    day_name: str
    is_today: bool = False
    tasks: List[TaskResponse] = []


class WeekTasksResponse(BaseModel):
    week_start: date
    week_end: date
    days: List[DayTasks]
