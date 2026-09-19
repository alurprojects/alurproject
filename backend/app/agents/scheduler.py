from datetime import date, timedelta
from typing import Dict, List, Optional
from uuid import uuid4
from app.agents.state import AlurState, ScheduledTask

DAY_MAP = {
    "senin": 0,
    "monday": 0,
    "selasa": 1,
    "tuesday": 1,
    "rabu": 2,
    "wednesday": 2,
    "kamis": 3,
    "thursday": 3,
    "jumat": 4,
    "friday": 4,
    "sabtu": 5,
    "saturday": 5,
    "minggu": 6,
    "sunday": 6,
}


def _resolve_target_date(preferred_day: Optional[str], today: date) -> date:
    """Resolve natural language day hint to a specific calendar date."""
    if not preferred_day:
        return today

    norm = preferred_day.strip().lower()

    if norm in ("hari ini", "today"):
        return today
    if norm in ("besok", "tomorrow"):
        return today + timedelta(days=1)
    if norm in ("lusa", "day after tomorrow"):
        return today + timedelta(days=2)

    for day_key, target_weekday in DAY_MAP.items():
        if day_key in norm:
            diff = (target_weekday - today.weekday()) % 7
            if diff == 0 and "next" in norm:
                diff = 7
            return today + timedelta(days=diff)

    return today


def scheduler_agent(state: dict) -> dict:
    """Scheduler node: Assigns calendar date to each task based on preferences and daily capacity."""
    draft_tasks = state.get("draft_tasks", [])
    today_str = state.get("today_date") or date.today().isoformat()
    today = date.fromisoformat(today_str)

    daily_capacity_minutes = state.get("daily_capacity_minutes", 480)
    existing_loads: Dict[str, int] = dict(state.get("existing_load_minutes_by_date", {}))
    source = state.get("source", "BRAIN_DUMP")

    scheduled: List[ScheduledTask] = []

    for draft in draft_tasks:
        task_id = str(uuid4())
        preferred_day = draft.get("preferred_day")
        target_date = _resolve_target_date(preferred_day, today)

        duration = draft.get("estimated_minutes")
        recurrence_rule = draft.get("recurrence_rule")
        recurrence_group_id = task_id if recurrence_rule else None

        # Check capacity: if target date is overloaded, shift to next day in week with room
        final_date = target_date
        if duration and duration > 0:
            for shift in range(7):
                candidate_date = target_date + timedelta(days=shift)
                candidate_str = candidate_date.isoformat()
                current_load = existing_loads.get(candidate_str, 0)
                if current_load + duration <= daily_capacity_minutes:
                    final_date = candidate_date
                    existing_loads[candidate_str] = current_load + duration
                    break
            else:
                # If all days full, keep original target date
                date_str = target_date.isoformat()
                existing_loads[date_str] = existing_loads.get(date_str, 0) + duration

        scheduled.append(
            ScheduledTask(
                id=task_id,
                title=draft.get("title", "").strip(),
                estimated_minutes=duration,
                assigned_date=final_date.isoformat(),
                is_ambiguous=draft.get("is_ambiguous", duration is None),
                recurrence_rule=recurrence_rule,
                recurrence_group_id=recurrence_group_id,
                source=source,
                ai_generated=True,
                status="PENDING",
                missed_follow_up="NONE",
            )
        )

    return {"scheduled_tasks": scheduled}
