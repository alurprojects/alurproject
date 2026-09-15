from typing import Any, Dict, List, Optional, TypedDict


class DraftTask(TypedDict, total=False):
    title: str
    estimated_minutes: Optional[int]
    goal_id: Optional[str]
    recurrence_rule: Optional[str]
    preferred_day: Optional[str]
    is_ambiguous: bool


class ScheduledTask(TypedDict, total=False):
    id: str
    title: str
    estimated_minutes: Optional[int]
    assigned_date: str
    is_ambiguous: bool
    recurrence_rule: Optional[str]
    recurrence_group_id: Optional[str]
    source: str
    ai_generated: bool
    status: str
    missed_follow_up: str


class AlurState(TypedDict, total=False):
    raw_text: str
    user_id: str
    today_date: str
    daily_capacity_minutes: int
    existing_load_minutes_by_date: Dict[str, int]
    draft_tasks: List[DraftTask]
    scheduled_tasks: List[ScheduledTask]
