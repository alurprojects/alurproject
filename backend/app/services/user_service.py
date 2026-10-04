"""Preferences user: kapasitas efektif = daily_capacity_hours - fixed_blocks."""

from typing import Any, Dict, Optional
from uuid import UUID
from fastapi import HTTPException, status
from supabase import Client

from app.schemas.user import PreferencesUpdate

_PREF_KEYS = {"theme", "language", "week_start", "todo_default_view", "notifications"}


class UserService:
    def __init__(self, supabase: Client):
        self.supabase = supabase

    def get_me(self, user_id: UUID) -> Dict[str, Any]:
        res = (
            self.supabase.table("users")
            .select("id,email,name,timezone,daily_capacity_hours,preferences")
            .eq("id", str(user_id))
            .execute()
        )
        if not res.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
        return res.data[0]

    def update_preferences(self, user_id: UUID, patch_in: PreferencesUpdate) -> Dict[str, Any]:
        me = self.get_me(user_id)
        prefs: Dict[str, Any] = dict(me.get("preferences") or {})
        updates: Dict[str, Any] = {}

        if patch_in.daily_capacity_hours is not None:
            updates["daily_capacity_hours"] = patch_in.daily_capacity_hours
        if patch_in.timezone is not None:
            updates["timezone"] = patch_in.timezone
        if patch_in.fixed_blocks is not None:
            prefs["fixed_blocks"] = [b.model_dump(exclude_none=True) for b in patch_in.fixed_blocks]
        if patch_in.todo_default_view is not None:
            prefs["todo_default_view"] = patch_in.todo_default_view
        if patch_in.onboarding_completed_at is not None:
            prefs["onboarding_completed_at"] = patch_in.onboarding_completed_at
        if patch_in.extra:
            for k, v in patch_in.extra.items():
                if k in _PREF_KEYS:
                    prefs[k] = v
        if prefs:
            updates["preferences"] = prefs

        if not updates:
            return self.get_me(user_id)
        res = (
            self.supabase.table("users")
            .update(updates)
            .eq("id", str(user_id))
            .execute()
        )
        if not res.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
        return self.get_me(user_id)
