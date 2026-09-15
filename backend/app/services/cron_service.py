from datetime import date, timedelta
from typing import Any, Dict, List, Optional
from uuid import UUID, uuid4
import logging
from supabase import Client

from app.agents.reflection import generate_reflection_insight

logger = logging.getLogger(__name__)


def _get_next_monday(d: date) -> date:
    """Get the Monday of next week."""
    days_ahead = 7 - d.weekday()
    return d + timedelta(days=days_ahead)


class CronService:
    def __init__(self, supabase: Client):
        self.supabase = supabase

    def run_nightly_status_check(self, user_id: Optional[UUID] = None) -> Dict[str, Any]:
        """Nightly Status Check & Reflection Light:

        1. Mark past PENDING tasks as MISSED.
        2. Reflection Light: If task has goal_id OR recurrence_rule, set missed_follow_up = 'PENDING'.
        """
        today = date.today()

        query = (
            self.supabase.table("tasks")
            .select("id, user_id, goal_id, recurrence_rule, assigned_date")
            .eq("status", "PENDING")
            .lt("assigned_date", today.isoformat())
        )
        if user_id:
            query = query.eq("user_id", str(user_id))

        res = query.execute()
        overdue_tasks = res.data or []

        missed_count = 0
        follow_up_pending_count = 0

        for task in overdue_tasks:
            t_id = task["id"]
            has_goal = task.get("goal_id") is not None
            has_recurrence = bool(task.get("recurrence_rule"))

            # Reflection light rule: goal-linked or recurring tasks get follow-up chip
            if has_goal or has_recurrence:
                missed_follow_up = "PENDING"
                follow_up_pending_count += 1
            else:
                missed_follow_up = "NONE"

            self.supabase.table("tasks").update({
                "status": "MISSED",
                "missed_follow_up": missed_follow_up,
            }).eq("id", t_id).execute()

            missed_count += 1

        return {
            "status": "success",
            "job": "nightly-status-check",
            "overdue_tasks_processed": missed_count,
            "follow_up_chips_created": follow_up_pending_count,
        }

    def run_weekly_recurrence_generator(self, user_id: Optional[UUID] = None) -> Dict[str, Any]:
        """Weekly Recurrence Generator:

        Finds all active recurrence groups and generates next week's task instances.
        """
        today = date.today()
        next_monday = _get_next_monday(today)

        # Query all recurring tasks
        query = (
            self.supabase.table("tasks")
            .select("id, user_id, title, estimated_minutes, goal_id, recurrence_rule, recurrence_group_id, assigned_date")
            .not_.is_("recurrence_rule", "null")
            .order("assigned_date", desc=True)
        )
        if user_id:
            query = query.eq("user_id", str(user_id))

        res = query.execute()
        all_recurring = res.data or []

        # Find latest instance per recurrence_group_id
        latest_by_group: Dict[str, Dict[str, Any]] = {}
        for t in all_recurring:
            grp_id = t.get("recurrence_group_id") or t["id"]
            if grp_id not in latest_by_group:
                latest_by_group[grp_id] = t

        generated_tasks: List[Dict[str, Any]] = []

        for grp_id, t in latest_by_group.items():
            rule = (t.get("recurrence_rule") or "").strip().lower()
            u_id = t["user_id"]
            target_dates: List[date] = []

            if rule == "daily":
                target_dates = [next_monday + timedelta(days=i) for i in range(7)]
            elif rule == "weekdays":
                target_dates = [next_monday + timedelta(days=i) for i in range(5)]
            elif rule == "weekends":
                target_dates = [next_monday + timedelta(days=5), next_monday + timedelta(days=6)]
            elif rule == "2x/week":
                target_dates = [next_monday, next_monday + timedelta(days=3)]
            elif rule == "3x/week":
                target_dates = [next_monday, next_monday + timedelta(days=2), next_monday + timedelta(days=4)]
            else:  # 'weekly' or default
                # Keep same weekday as origin
                orig_date = date.fromisoformat(t["assigned_date"])
                target_dates = [next_monday + timedelta(days=orig_date.weekday())]

            for d in target_dates:
                # Check for existing duplicate on that date for this group
                existing = (
                    self.supabase.table("tasks")
                    .select("id")
                    .eq("recurrence_group_id", grp_id)
                    .eq("assigned_date", d.isoformat())
                    .execute()
                )
                if not existing.data:
                    new_task_id = str(uuid4())
                    generated_tasks.append({
                        "id": new_task_id,
                        "user_id": u_id,
                        "title": t["title"],
                        "estimated_minutes": t.get("estimated_minutes"),
                        "goal_id": t.get("goal_id"),
                        "recurrence_rule": t.get("recurrence_rule"),
                        "recurrence_group_id": grp_id,
                        "assigned_date": d.isoformat(),
                        "status": "PENDING",
                        "source": "MANUAL",
                        "is_ambiguous": t.get("estimated_minutes") is None,
                        "ai_generated": False,
                        "missed_follow_up": "NONE",
                    })

        if generated_tasks:
            self.supabase.table("tasks").insert(generated_tasks).execute()

        return {
            "status": "success",
            "job": "weekly-recurrence-generator",
            "active_groups": len(latest_by_group),
            "generated_count": len(generated_tasks),
        }

    def run_weekly_reflection(self, user_id: Optional[UUID] = None) -> Dict[str, Any]:
        """Weekly Reflection (Reflection Full):

        Aggregates MISSED tasks per goal in the past 7 days.
        If >= 2 MISSED tasks on a goal, generates a calm insight and inserts into ai_insights.
        """
        today = date.today()
        seven_days_ago = today - timedelta(days=7)
        week_monday = today - timedelta(days=today.weekday())

        query = (
            self.supabase.table("tasks")
            .select("id, user_id, goal_id, title, assigned_date")
            .eq("status", "MISSED")
            .not_.is_("goal_id", "null")
            .gte("assigned_date", seven_days_ago.isoformat())
            .lte("assigned_date", today.isoformat())
        )
        if user_id:
            query = query.eq("user_id", str(user_id))

        res = query.execute()
        missed_tasks = res.data or []

        # Group by (user_id, goal_id)
        grouped: Dict[tuple[str, str], List[str]] = {}
        for t in missed_tasks:
            key = (t["user_id"], t["goal_id"])
            grouped.setdefault(key, []).append(t["title"])

        insights_created = 0

        for (u_id, g_id), titles in grouped.items():
            if len(titles) >= 2:
                # Fetch goal title
                goal_res = (
                    self.supabase.table("goals")
                    .select("title")
                    .eq("id", g_id)
                    .execute()
                )
                goal_title = goal_res.data[0]["title"] if goal_res.data else "Target"

                content = generate_reflection_insight(
                    goal_title=goal_title,
                    missed_count=len(titles),
                    missed_examples=titles,
                )

                self.supabase.table("ai_insights").insert({
                    "id": str(uuid4()),
                    "user_id": u_id,
                    "content": content,
                    "week_of": week_monday.isoformat(),
                    "surfaced": True,
                }).execute()

                insights_created += 1

        return {
            "status": "success",
            "job": "weekly-reflection",
            "goals_evaluated": len(grouped),
            "insights_generated": insights_created,
        }
