from datetime import date, timedelta
from typing import List
from uuid import UUID
from langgraph.graph import StateGraph
from supabase import Client

from app.agents.extractor import extractor_agent
from app.agents.scheduler import scheduler_agent
from app.agents.state import AlurState
from app.agents.validate_ambiguity import validate_ambiguity_fn
from app.schemas.task import TaskResponse

# Build LangGraph state machine
_workflow = StateGraph(AlurState)
_workflow.add_node("extractor", extractor_agent)
_workflow.add_node("validate_ambiguity", validate_ambiguity_fn)
_workflow.add_node("scheduler", scheduler_agent)

_workflow.add_edge("extractor", "validate_ambiguity")
_workflow.add_edge("validate_ambiguity", "scheduler")

_workflow.set_entry_point("extractor")
_workflow.set_finish_point("scheduler")

brain_dump_graph = _workflow.compile()


def run_brain_dump(text: str, user_id: UUID, supabase: Client) -> List[TaskResponse]:
    """Execute the end-to-end brain-dump orchestration pipeline and persist tasks in Supabase."""
    today = date.today()

    # 1. Fetch user daily capacity
    user_res = (
        supabase.table("users")
        .select("daily_capacity_hours, timezone")
        .eq("id", str(user_id))
        .execute()
    )

    daily_capacity_hours = 8.0
    if user_res.data:
        daily_capacity_hours = float(user_res.data[0].get("daily_capacity_hours") or 8.0)

    daily_capacity_minutes = int(daily_capacity_hours * 60)

    # 2. Fetch existing load for this week (from today to next 7 days)
    week_end = today + timedelta(days=7)
    existing_tasks_res = (
        supabase.table("tasks")
        .select("assigned_date, estimated_minutes")
        .eq("user_id", str(user_id))
        .gte("assigned_date", today.isoformat())
        .lte("assigned_date", week_end.isoformat())
        .neq("status", "DONE")
        .execute()
    )

    load_by_date: dict[str, int] = {}
    if existing_tasks_res.data:
        for t in existing_tasks_res.data:
            d_str = t["assigned_date"]
            mins = t.get("estimated_minutes") or 0
            load_by_date[d_str] = load_by_date.get(d_str, 0) + mins

    # 3. Invoke LangGraph
    initial_state: AlurState = {
        "raw_text": text,
        "user_id": str(user_id),
        "today_date": today.isoformat(),
        "daily_capacity_minutes": daily_capacity_minutes,
        "existing_load_minutes_by_date": load_by_date,
        "draft_tasks": [],
        "scheduled_tasks": [],
    }

    result = brain_dump_graph.invoke(initial_state)
    scheduled_tasks = result.get("scheduled_tasks", [])

    if not scheduled_tasks:
        return []

    # 4. Batch insert into Supabase tasks table
    insert_payload = []
    for st in scheduled_tasks:
        insert_payload.append({
            "id": st["id"],
            "user_id": str(user_id),
            "title": st["title"],
            "estimated_minutes": st.get("estimated_minutes"),
            "assigned_date": st["assigned_date"],
            "is_ambiguous": st.get("is_ambiguous", False),
            "recurrence_rule": st.get("recurrence_rule"),
            "recurrence_group_id": st.get("recurrence_group_id"),
            "source": "BRAIN_DUMP",
            "ai_generated": True,
            "status": "PENDING",
            "missed_follow_up": "NONE",
        })

    insert_res = supabase.table("tasks").insert(insert_payload).execute()
    if not insert_res.data:
        return []

    return [TaskResponse.model_validate(item) for item in insert_res.data]
