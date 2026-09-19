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


class AlurChatState(TypedDict, total=False):
    raw_message: str
    user_id: str
    today_date: str
    daily_capacity_hours: float
    daily_capacity_minutes: int
    existing_load_minutes_by_date: Dict[str, int]
    recent_completion_rate: Optional[float]
    consecutive_misses: Optional[int]
    recent_insights: Optional[List[str]]
    conversation_context: List[Dict[str, str]]
    
    # Companion classification and tone
    message_type: str  # 'TASK_CAPTURE' | 'REFLECTION' | 'CHAT' | 'CAPACITY_QUERY'
    tone_used: str     # 'HONEST' | 'GENTLE'
    mood_detected: Optional[str]  # e.g., 'overload', 'burnout', or None
    
    # Task extraction & scheduling
    draft_tasks: List[DraftTask]
    scheduled_tasks: List[ScheduledTask]
    
    # Final AI response text
    ai_response: str
