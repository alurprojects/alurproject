from typing import Any, Dict
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client

from app.api.deps import get_current_user_id
from app.core.supabase import get_supabase_client
from app.services.cron_service import CronService

router = APIRouter(prefix="/debug", tags=["debug"])


@router.post("/run-cron/{job_name}", response_model=Dict[str, Any])
def trigger_cron_job(
    job_name: str,
    user_id: UUID = Depends(get_current_user_id),
    supabase: Client = Depends(get_supabase_client),
) -> Dict[str, Any]:
    """Manually trigger a background cron job for controlled testing and verification.

    Supported jobs:
    - 'nightly-status-check'
    - 'weekly-recurrence-generator'
    - 'weekly-reflection'
    """
    cron_service = CronService(supabase)

    if job_name == "nightly-status-check":
        return cron_service.run_nightly_status_check(user_id=user_id)
    elif job_name == "weekly-recurrence-generator":
        return cron_service.run_weekly_recurrence_generator(user_id=user_id)
    elif job_name == "weekly-reflection":
        return cron_service.run_weekly_reflection(user_id=user_id)
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown job_name '{job_name}'. Valid jobs: 'nightly-status-check', 'weekly-recurrence-generator', 'weekly-reflection'",
        )
