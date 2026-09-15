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

    In development mode, falls back to X-User-Id header or the seeded dev user ID.
    """
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "").strip()
        try:
            res = supabase.auth.get_user(token)
            if res and res.user:
                return UUID(res.user.id)
        except Exception:
            if settings.BACKEND_ENV != "development":
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired authentication token",
                )

    if settings.BACKEND_ENV == "development":
        if x_user_id:
            try:
                return UUID(x_user_id)
            except ValueError:
                pass
        return DEV_USER_ID

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Missing or invalid Authorization header",
    )


def get_task_service(
    supabase: Client = Depends(get_supabase_client),
) -> TaskService:
    """Dependency provider for TaskService."""
    return TaskService(supabase)
