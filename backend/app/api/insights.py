from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Query
from supabase import Client

from app.api.deps import get_current_user_id
from app.core.supabase import get_supabase_client
from app.schemas.insight import InsightResponse

router = APIRouter(prefix="/insights", tags=["insights"])


@router.get("", response_model=List[InsightResponse])
def get_insights(
    surfaced: Optional[bool] = Query(True, description="Filter by surfaced status"),
    user_id: UUID = Depends(get_current_user_id),
    supabase: Client = Depends(get_supabase_client),
) -> List[InsightResponse]:
    """Retrieve weekly reflection insights written by Reflection Agent."""
    query = (
        supabase.table("ai_insights")
        .select("*")
        .eq("user_id", str(user_id))
        .order("week_of", desc=True)
    )
    if surfaced is not None:
        query = query.eq("surfaced", surfaced)

    res = query.execute()
    return [InsightResponse.model_validate(item) for item in (res.data or [])]
