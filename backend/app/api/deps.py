from typing import Optional
from uuid import UUID
from fastapi import Depends, Header, HTTPException, status
from supabase import Client

from app.core.config import settings
from app.core.supabase import get_supabase_client
from app.services.task_service import TaskService

DEV_USER_ID = UUID("00000000-0000-0000-0000-000000000001")


async def get_current_user_id(
    authorization: Optional[str] = Header(None),
    x_user_id: Optional[str] = Header(None),
    supabase: Client = Depends(get_supabase_client),
) -> UUID:
    """Extract and validate the current user's ID from Supabase Auth JWT.

    If a valid Bearer token is provided, extracts the authenticated user's ID.
    Otherwise, supports X-User-Id or falls back to the seeded default user ID
    (00000000-0000-0000-0000-000000000001) so the planner is immediately usable.
    """
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "").strip()
        try:
            res = supabase.auth.get_user(token)
            if res and res.user:
                return UUID(res.user.id)
        except Exception:
            pass

    if x_user_id:
        try:
            return UUID(x_user_id)
        except ValueError:
            pass

    return DEV_USER_ID


def get_task_service(
    supabase: Client = Depends(get_supabase_client),
) -> TaskService:
    """Dependency provider for TaskService."""
    return TaskService(supabase)
