from typing import List
from uuid import UUID
from fastapi import APIRouter, Depends, status
from supabase import Client

from app.agents.graph import run_brain_dump
from app.api.deps import get_current_user_id
from app.core.supabase import get_supabase_client
from app.schemas.brain_dump import BrainDumpRequest
from app.schemas.task import TaskResponse

router = APIRouter(prefix="/brain-dump", tags=["brain-dump"])


@router.post("", response_model=List[TaskResponse], status_code=status.HTTP_201_CREATED)
def process_brain_dump(
    request: BrainDumpRequest,
    user_id: UUID = Depends(get_current_user_id),
    supabase: Client = Depends(get_supabase_client),
) -> List[TaskResponse]:
    """Ingest free-form messy brain-dump text, parse with LangGraph agents,

    assign dates according to user capacity, and insert tasks into Supabase.
    """
    return run_brain_dump(
        text=request.text,
        user_id=user_id,
        supabase=supabase,
    )
