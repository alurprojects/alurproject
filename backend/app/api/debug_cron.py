from typing import Any, Dict, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Header, HTTPException, status
from supabase import Client

from app.api.deps import DEV_USER_ID
from app.core.supabase import get_supabase_client
from app.services.cron_service import CronService

router = APIRouter(prefix="/debug", tags=["debug"])


@router.api_route("/run-cron/{job_name}", methods=["GET", "POST"], response_model=Dict[str, Any])
def trigger_cron_job(
    job_name: str,
    x_user_id: Optional[str] = Header(None),
    supabase: Client = Depends(get_supabase_client),
) -> Dict[str, Any]:
    """Manually or automatically trigger a background cron job via GET or POST.

    Supported jobs:
    - 'nightly-status-check'
    - 'weekly-recurrence-generator'
    - 'weekly-reflection'
    - 'all'
    """
    target_user_id = DEV_USER_ID
    if x_user_id:
        try:
            target_user_id = UUID(x_user_id)
        except ValueError:
            pass

    cron_service = CronService(supabase)

    if job_name == "nightly-status-check":
        return cron_service.run_nightly_status_check(user_id=target_user_id)
    elif job_name == "weekly-recurrence-generator":
        return cron_service.run_weekly_recurrence_generator(user_id=target_user_id)
    elif job_name == "weekly-reflection":
        return cron_service.run_weekly_reflection(user_id=target_user_id)
    elif job_name == "all":
        r1 = cron_service.run_nightly_status_check(user_id=target_user_id)
        r2 = cron_service.run_weekly_recurrence_generator(user_id=target_user_id)
        r3 = cron_service.run_weekly_reflection(user_id=target_user_id)
        return {"nightly": r1, "recurrence": r2, "reflection": r3}
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown job_name '{job_name}'. Valid jobs: 'nightly-status-check', 'weekly-recurrence-generator', 'weekly-reflection', 'all'",
        )
