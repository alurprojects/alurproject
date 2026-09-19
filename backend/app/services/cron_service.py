from datetime import date, datetime, timedelta, timezone
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

    def _process_user_reflection(self, u_id: str, week_monday: date, seven_days_ago: date, today: date) -> int:
        """Process combined data reflection for a single user."""
        # 1. Fetch missed tasks with a goal
        missed_res = (
            self.supabase.table("tasks")
            .select("id, user_id, goal_id, title, assigned_date")
            .eq("user_id", u_id)
            .eq("status", "MISSED")
            .not_.is_("goal_id", "null")
            .gte("assigned_date", seven_days_ago.isoformat())
            .lte("assigned_date", today.isoformat())
            .execute()
        )
        missed_tasks = missed_res.data or []

        # 2. Fetch recent conversation logs (last 7 days)
        conv_res = (
            self.supabase.table("conversation_logs")
            .select("content, message_type")
            .eq("user_id", u_id)
            .eq("role", "USER")
            .gte("created_at", seven_days_ago.isoformat())
            .order("created_at", desc=True)
            .limit(5)
            .execute()
        )
        chat_reflections = [c["content"] for c in (conv_res.data or []) if c.get("content")]

        # 3. Calculate weekly completion rate
        all_tasks_res = (
            self.supabase.table("tasks")
            .select("status")
            .eq("user_id", u_id)
            .gte("assigned_date", seven_days_ago.isoformat())
            .lte("assigned_date", today.isoformat())
            .execute()
        )
        total_tasks = len(all_tasks_res.data or [])
        completed_tasks = sum(1 for t in (all_tasks_res.data or []) if t.get("status") == "DONE")
        completion_rate = (completed_tasks / total_tasks) if total_tasks > 0 else None

        # Group missed tasks by goal_id
        grouped: Dict[str, List[str]] = {}
        for t in missed_tasks:
            g_id = t["goal_id"]
            grouped.setdefault(g_id, []).append(t["title"])

        insights_created = 0
        for g_id, titles in grouped.items():
            if len(titles) >= 2:
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
                    recent_chat_reflections=chat_reflections,
                    completion_rate=completion_rate,
                )

                self.supabase.table("ai_insights").insert({
                    "id": str(uuid4()),
                    "user_id": u_id,
                    "content": content,
                    "week_of": week_monday.isoformat(),
                    "surfaced": True,
                    "insight_type": "WEEKLY_REFLECTION",
                    "source_data": {
                        "goal_id": g_id,
                        "missed_count": len(titles),
                        "has_chat_context": bool(chat_reflections),
                    },
                }).execute()

                insights_created += 1

        return insights_created

    def run_weekly_reflection(
        self,
        user_id: Optional[UUID] = None,
        only_active: bool = False,
        batch_size: int = 5,
    ) -> Dict[str, Any]:
        """Weekly Reflection (Enhanced with Combined Data & Batching):

        - Processes tasks (missed status) + conversation_logs (reflections/mood).
        - Uses Gemini / Batch LLM for high reasoning quality.
        - Employs batching via cron_batch_state to prevent Vercel 10s timeout.
        """
        today = date.today()
        seven_days_ago = today - timedelta(days=7)
        week_monday = today - timedelta(days=today.weekday())

        # If targeted user_id provided (single user run)
        if user_id:
            created = self._process_user_reflection(str(user_id), week_monday, seven_days_ago, today)
            return {
                "status": "success",
                "job": "weekly-reflection",
                "processed_users": 1,
                "insights_generated": created,
                "completed": True,
                "continue": False,
            }

        # Multi-user batch run:
        active_user_ids: List[str] = []
        if only_active:
            try:
                rpc_res = self.supabase.rpc("users_active_this_week").execute()
                active_user_ids = [str(r["user_id"]) for r in (rpc_res.data or []) if r.get("user_id")]
            except Exception as e:
                logger.warning(f"Failed to call users_active_this_week RPC: {e}")

        # Fallback to all users if RPC empty or only_active=False
        if not active_user_ids:
            users_res = self.supabase.table("users").select("id").execute()
            active_user_ids = [str(r["id"]) for r in (users_res.data or []) if r.get("id")]

        active_user_ids = sorted(list(set(active_user_ids)))
        today_str = today.isoformat()

        # Check existing batch state
        batch_state = None
        try:
            state_res = (
                self.supabase.table("cron_batch_state")
                .select("last_user_id, run_date, completed")
                .eq("job_name", "weekly-reflection")
                .execute()
            )
            if state_res.data:
                batch_state = state_res.data[0]
        except Exception as e:
            logger.warning(f"Failed to read cron_batch_state: {e}")

        # If already completed for today
        if batch_state and batch_state.get("run_date") == today_str and batch_state.get("completed"):
            return {
                "status": "success",
                "job": "weekly-reflection",
                "message": "Batch already completed for today",
                "completed": True,
                "continue": False,
                "processed_users": 0,
                "insights_generated": 0,
            }

        start_idx = 0
        if batch_state and batch_state.get("run_date") == today_str and batch_state.get("last_user_id"):
            last_uid = str(batch_state["last_user_id"])
            if last_uid in active_user_ids:
                start_idx = active_user_ids.index(last_uid) + 1

        batch = active_user_ids[start_idx : start_idx + batch_size]
        insights_created = 0

        for u_id in batch:
            try:
                insights_created += self._process_user_reflection(u_id, week_monday, seven_days_ago, today)
            except Exception as e:
                logger.error(f"Error processing reflection for user {u_id}: {e}")

        is_completed = (start_idx + len(batch) >= len(active_user_ids))
        new_last_id = batch[-1] if batch else (active_user_ids[-1] if active_user_ids else None)

        # Upsert batch state
        try:
            self.supabase.table("cron_batch_state").upsert({
                "job_name": "weekly-reflection",
                "last_user_id": new_last_id,
                "run_date": today_str,
                "completed": is_completed,
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to update cron_batch_state: {e}")

        return {
            "status": "success",
            "job": "weekly-reflection",
            "continue": not is_completed,
            "completed": is_completed,
            "processed_users": len(batch),
            "total_users": len(active_user_ids),
            "insights_generated": insights_created,
        }

    def run_conversation_retention_notify(self) -> Dict[str, Any]:
        """Mark conversation logs older than 83 days as pending deletion (H-7 alert)."""
        cutoff = (datetime.now(timezone.utc) - timedelta(days=83)).isoformat()

        res = (
            self.supabase.table("conversation_logs")
            .select("id")
            .lt("created_at", cutoff)
            .is_("pending_deletion_notified_at", "null")
            .eq("retention_override", False)
            .execute()
        )
        logs_to_notify = res.data or []
        notified_count = 0

        if logs_to_notify:
            now_iso = datetime.now(timezone.utc).isoformat()
            for item in logs_to_notify:
                self.supabase.table("conversation_logs").update({
                    "pending_deletion_notified_at": now_iso,
                }).eq("id", item["id"]).execute()
                notified_count += 1

        return {
            "status": "success",
            "job": "conversation-log-notify-pending",
            "notified_count": notified_count,
        }

    def run_conversation_hard_delete(self) -> Dict[str, Any]:
        """Hard delete conversation logs notified >= 7 days ago with retention_override = FALSE."""
        cutoff = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()

        res = (
            self.supabase.table("conversation_logs")
            .select("id")
            .lt("pending_deletion_notified_at", cutoff)
            .eq("retention_override", False)
            .execute()
        )
        logs_to_delete = res.data or []
        deleted_count = 0

        if logs_to_delete:
            for item in logs_to_delete:
                self.supabase.table("conversation_logs").delete().eq("id", item["id"]).execute()
                deleted_count += 1

        return {
            "status": "success",
            "job": "conversation-log-hard-delete",
            "deleted_count": deleted_count,
        }

