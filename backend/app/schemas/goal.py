from datetime import date, datetime
from typing import Any, Dict, List, Literal, Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

GoalStatus = Literal["ACTIVE", "DONE", "ARCHIVED"]
PlanStatus = Literal["NONE", "GENERATING", "DRAFT", "ACCEPTED"]


class GoalBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=300)
    description: Optional[str] = None
    deadline: Optional[date] = None
    target_hours_per_week: Optional[float] = Field(None, gt=0, le=168)
    definition_of_done: Optional[str] = None


class GoalCreate(GoalBase):
    pass


class GoalUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=300)
    description: Optional[str] = None
    deadline: Optional[date] = None
    status: Optional[GoalStatus] = None
    target_hours_per_week: Optional[float] = Field(None, gt=0, le=168)
    definition_of_done: Optional[str] = None


class GoalResponse(GoalBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    status: GoalStatus = "ACTIVE"
    plan: Dict[str, Any] = {}
    plan_draft: Dict[str, Any] = {}
    plan_status: PlanStatus = "NONE"
    last_replanned_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime


class GoalPlanResponse(BaseModel):
    goal_id: UUID
    plan_status: PlanStatus
    plan: Dict[str, Any] = {}
    plan_draft: Dict[str, Any] = {}
    last_replanned_at: Optional[datetime] = None


class GoalPlanAcceptRequest(BaseModel):
    plan_draft: Optional[Dict[str, Any]] = Field(
        None,
        description="Draft yang sudah diedit user. Jika kosong, pakai draft tersimpan.",
    )
    only_milestones: bool = Field(
        False, description="True = terima milestone saja, tugas dibuat nanti."
    )
