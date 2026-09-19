from typing import Any, Dict, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from supabase import Client

from app.core.config import settings
from app.core.supabase import get_supabase_client
from app.services.cron_service import CronService

router = APIRouter(prefix="/internal/cron", tags=["internal-cron"])


@router.post("/{job_name}", response_model=Dict[str, Any])
def trigger_internal_cron_job(
    job_name: str,
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
    only_active: bool = Query(False),
    batch_size: int = Query(5, ge=1, le=50),
    user_id: Optional[str] = Query(None),
    supabase: Client = Depends(get_supabase_client),
) -> Dict[str, Any]:
    """Execute internal background cron jobs triggered by external cron services or pg_cron.

    Protected strictly by X-Cron-Secret header matching settings.CRON_SECRET.
    Returns HTTP 401 Unauthorized if missing or incorrect.
    """
    expected_secret = settings.CRON_SECRET
    if not expected_secret or not x_cron_secret or x_cron_secret != expected_secret:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing X-Cron-Secret header",
        )

    target_user_id: Optional[UUID] = None
    if user_id:
        try:
            target_user_id = UUID(user_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid user_id UUID format: '{user_id}'",
            )

    cron_service = CronService(supabase)
    normalized_job = job_name.lower().strip()

    if normalized_job == "nightly-status-check":
        return cron_service.run_nightly_status_check(user_id=target_user_id)

    elif normalized_job in ("weekly-recurrence-generator", "weekly-recurrence", "recurrence"):
        return cron_service.run_weekly_recurrence_generator(user_id=target_user_id)

    elif normalized_job in ("weekly-reflection", "reflection"):
        return cron_service.run_weekly_reflection(
            user_id=target_user_id,
            only_active=only_active,
            batch_size=batch_size,
        )

    elif normalized_job == "conversation-log-notify-pending":
        return cron_service.run_conversation_retention_notify()

    elif normalized_job == "conversation-log-hard-delete":
        return cron_service.run_conversation_hard_delete()

    elif normalized_job == "all":
        r_nightly = cron_service.run_nightly_status_check(user_id=target_user_id)
        r_rec = cron_service.run_weekly_recurrence_generator(user_id=target_user_id)
        r_ref = cron_service.run_weekly_reflection(
            user_id=target_user_id,
            only_active=only_active,
            batch_size=batch_size,
        )
        r_notify = cron_service.run_conversation_retention_notify()
        r_delete = cron_service.run_conversation_hard_delete()
        return {
            "status": "success",
            "job": "all",
            "results": {
                "nightly": r_nightly,
                "recurrence": r_rec,
                "reflection": r_ref,
                "retention_notify": r_notify,
                "retention_hard_delete": r_delete,
            },
        }

    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Unknown job_name '{job_name}'. Valid jobs: 'nightly-status-check', "
                "'weekly-recurrence' ('weekly-recurrence-generator'), 'weekly-reflection' ('reflection'), "
                "'conversation-log-notify-pending', 'conversation-log-hard-delete', 'all'"
            ),
        )
