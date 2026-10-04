"""Goal manual (M14-manual) untuk Fase 1 web-first.

Cakupan Fase 1: CRUD goals + plan async MANUAL (tanpa AI).
Breakdown AI (M14-AI) masuk Fase 2 R2b sebagai service terpisah.
"""

from datetime import date, datetime
from typing import Any, Dict, Optional
from uuid import UUID, uuid4
from fastapi import HTTPException, status
from supabase import Client

from app.schemas.goal import GoalCreate, GoalPlanResponse, GoalResponse, GoalUpdate

_ALLOWED_PLAN_KEYS = {"milestones", "week_tasks", "notes"}


def _clean_plan(raw: Any) -> Dict[str, Any]:
    if not isinstance(raw, dict):
        return {}
    return {k: v for k, v in raw.items() if k in _ALLOWED_PLAN_KEYS}


class GoalService:
    def __init__(self, supabase: Client):
        self.supabase = supabase

    # --- CRUD ---
    def list_goals(self, user_id: UUID, include_done: bool = False) -> list[GoalResponse]:
        q = self.supabase.table("goals").select("*").eq("user_id", str(user_id))
        if not include_done:
            q = q.eq("status", "ACTIVE")
        res = q.order("created_at", desc=False).execute()
        return [GoalResponse.model_validate(g) for g in (res.data or [])]

    def get_goal(self, user_id: UUID, goal_id: UUID) -> GoalResponse:
        res = (
            self.supabase.table("goals")
            .select("*")
            .eq("id", str(goal_id))
            .eq("user_id", str(user_id))
            .execute()
        )
        if not res.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Goal not found")
        return GoalResponse.model_validate(res.data[0])

    def create_goal(self, user_id: UUID, goal_in: GoalCreate) -> GoalResponse:
        payload = {
            "id": str(uuid4()),
            "user_id": str(user_id),
            "title": goal_in.title.strip(),
            "description": goal_in.description,
            "deadline": goal_in.deadline.isoformat() if goal_in.deadline else None,
            "target_hours_per_week": goal_in.target_hours_per_week,
            "definition_of_done": goal_in.definition_of_done,
            "status": "ACTIVE",
            "plan": {},
            "plan_draft": {},
            "plan_status": "NONE",
        }
        res = self.supabase.table("goals").insert(payload).execute()
        if not res.data:
            raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Failed to create goal")
        return GoalResponse.model_validate(res.data[0])

    def update_goal(self, user_id: UUID, goal_id: UUID, goal_in: GoalUpdate) -> GoalResponse:
        patch: Dict[str, Any] = {}
        if goal_in.title is not None:
            patch["title"] = goal_in.title.strip()
        if goal_in.description is not None:
            patch["description"] = goal_in.description
        if goal_in.deadline is not None:
            patch["deadline"] = goal_in.deadline.isoformat()
        if goal_in.status is not None:
            patch["status"] = goal_in.status
        if goal_in.target_hours_per_week is not None:
            patch["target_hours_per_week"] = goal_in.target_hours_per_week
        if goal_in.definition_of_done is not None:
            patch["definition_of_done"] = goal_in.definition_of_done
        if not patch:
            return self.get_goal(user_id, goal_id)
        res = (
            self.supabase.table("goals")
            .update(patch)
            .eq("id", str(goal_id))
            .eq("user_id", str(user_id))
            .execute()
        )
        if not res.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Goal not found")
        return GoalResponse.model_validate(res.data[0])

    def delete_goal(self, user_id: UUID, goal_id: UUID) -> None:
        res = (
            self.supabase.table("goals")
            .delete()
            .eq("id", str(goal_id))
            .eq("user_id", str(user_id))
            .execute()
        )
        if not res.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Goal not found")

    # --- Plan manual Fase 1 ---
    def request_plan(self, user_id: UUID, goal_id: UUID) -> GoalPlanResponse:
        """Fase 1: tandai GENERATING agar kontrak async siap, tanpa AI.

        Fase 2 akan mengisi plan_draft via goal_planner. Frontend boleh
        langsung kirim draft manual lewat accept_plan.
        """
        goal = self.get_goal(user_id, goal_id)
        if goal.plan_status == "GENERATING":
            return GoalPlanResponse(
                goal_id=goal.id,
                plan_status=goal.plan_status,
                plan=goal.plan,
                plan_draft=goal.plan_draft,
                last_replanned_at=goal.last_replanned_at,
            )
        res = (
            self.supabase.table("goals")
            .update({"plan_status": "GENERATING"})
            .eq("id", str(goal_id))
            .eq("user_id", str(user_id))
            .execute()
        )
        updated = GoalResponse.model_validate(res.data[0])
        return GoalPlanResponse(
            goal_id=updated.id,
            plan_status=updated.plan_status,
            plan=updated.plan,
            plan_draft=updated.plan_draft,
            last_replanned_at=updated.last_replanned_at,
        )

    def get_plan(self, user_id: UUID, goal_id: UUID) -> GoalPlanResponse:
        goal = self.get_goal(user_id, goal_id)
        return GoalPlanResponse(
            goal_id=goal.id,
            plan_status=goal.plan_status,
            plan=goal.plan,
            plan_draft=goal.plan_draft,
            last_replanned_at=goal.last_replanned_at,
        )

    def accept_plan(
        self,
        user_id: UUID,
        goal_id: UUID,
        plan_draft: Optional[Dict[str, Any]],
        only_milestones: bool,
        materialize_week: bool = True,
    ) -> GoalPlanResponse:
        """Terima draft manual. week_tasks dimaterialisasi max 7 hari ke depan.

        Aturan Fase 1: tidak menimpa tugas user. Hanya membuat task baru
        GOAL_PLAN ai_generated untuk tanggal yang belum ada tugas goal ini.
        """
        goal = self.get_goal(user_id, goal_id)
        draft = _clean_plan(plan_draft) if plan_draft is not None else goal.plan_draft
        if not draft and not only_milestones:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "plan_draft kosong")

        plan = {"milestones": draft.get("milestones", [])}
        if not only_milestones and materialize_week and isinstance(draft.get("week_tasks"), list):
            created = self._materialize_week_tasks(user_id, goal_id, draft["week_tasks"])
            plan["week_tasks"] = created

        res = (
            self.supabase.table("goals")
            .update({
                "plan": plan,
                "plan_draft": {},
                "plan_status": "ACCEPTED",
                "last_replanned_at": datetime.now().isoformat(),
            })
            .eq("id", str(goal_id))
            .eq("user_id", str(user_id))
            .execute()
        )
        updated = GoalResponse.model_validate(res.data[0])
        return GoalPlanResponse(
            goal_id=updated.id,
            plan_status=updated.plan_status,
            plan=updated.plan,
            plan_draft=updated.plan_draft,
            last_replanned_at=updated.last_replanned_at,
        )

    def _materialize_week_tasks(
        self, user_id: UUID, goal_id: UUID, week_tasks: list
    ) -> list[Dict[str, Any]]:
        today = date.today()
        created: list[Dict[str, Any]] = []
        for item in week_tasks[:21]:
            if not isinstance(item, dict) or not item.get("title"):
                continue
            try:
                day_offset = int(item.get("day_offset", 0))
            except (TypeError, ValueError):
                continue
            if day_offset < 0 or day_offset > 6:
                continue
            assigned = (today.toordinal() + day_offset)
            assigned_date = date.fromordinal(assigned).isoformat()
            # Jangan duplikat: lewati jika goal ini sudah punya tugas di tanggal itu.
            exists = (
                self.supabase.table("tasks")
                .select("id")
                .eq("user_id", str(user_id))
                .eq("goal_id", str(goal_id))
                .eq("assigned_date", assigned_date)
                .limit(5)
                .execute()
            )
            if exists.data:
                continue
            minutes = item.get("estimated_minutes")
            payload = {
                "id": str(uuid4()),
                "user_id": str(user_id),
                "goal_id": str(goal_id),
                "title": str(item["title"]).strip()[:500],
                "assigned_date": assigned_date,
                "estimated_minutes": minutes if isinstance(minutes, int) and minutes > 0 else None,
                "status": "PENDING",
                "source": "GOAL_PLAN",
                "is_ambiguous": not isinstance(minutes, int) or minutes <= 0,
                "ai_generated": True,
                "missed_follow_up": "NONE",
                "user_modified": False,
            }
            ins = self.supabase.table("tasks").insert(payload).execute()
            if ins.data:
                created.append({"title": payload["title"], "assigned_date": assigned_date})
        return created
