from datetime import date, datetime, timezone
from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from supabase import Client

from app.agents.graph import run_chat_message
from app.api.deps import get_current_user_id
from app.core.supabase import get_supabase_client
from app.schemas.chat import (
    ChatActionResponse,
    ChatExportResponse,
    ChatHistoryItem,
    ChatMessageRequest,
    ChatMessageResponse,
    ChatPendingDeletionItem,
    RetentionOverrideRequest,
)

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/message", response_model=ChatMessageResponse, status_code=status.HTTP_200_OK)
def send_chat_message(
    request: ChatMessageRequest,
    user_id: UUID = Depends(get_current_user_id),
    supabase: Client = Depends(get_supabase_client),
) -> ChatMessageResponse:
    """Send user message to Chat Room.

    Orchestrates Companion Agent, Extractor Agent, and Scheduler Agent via LangGraph.
    Returns AI reply, tone used, and any extracted tasks.
    """
    result = run_chat_message(
        message=request.message,
        user_id=user_id,
        supabase=supabase,
    )

    return ChatMessageResponse(
        reply=result["reply"],
        message_type=result["message_type"],
        tone_used=result["tone_used"],
        mood_detected=result.get("mood_detected"),
        extracted_tasks=result.get("extracted_tasks", []),
    )


@router.get("/history", response_model=List[ChatHistoryItem], status_code=status.HTTP_200_OK)
def get_chat_history(
    target_date: Optional[str] = Query(None, alias="date", description="Filter by session_date YYYY-MM-DD"),
    limit: int = Query(50, ge=1, le=200),
    user_id: UUID = Depends(get_current_user_id),
    supabase: Client = Depends(get_supabase_client),
) -> List[ChatHistoryItem]:
    """Fetch conversation history for the current user."""
    query = (
        supabase.table("conversation_logs")
        .select("*")
        .eq("user_id", str(user_id))
    )

    if target_date:
        query = query.eq("session_date", target_date)

    res = query.order("created_at", desc=False).limit(limit).execute()
    if not res.data:
        return []

    return [ChatHistoryItem.model_validate(item) for item in res.data]


@router.get(
    "/history/pending-deletion",
    response_model=List[ChatPendingDeletionItem],
    status_code=status.HTTP_200_OK,
)
def get_pending_deletion_chats(
    user_id: UUID = Depends(get_current_user_id),
    supabase: Client = Depends(get_supabase_client),
) -> List[ChatPendingDeletionItem]:
    """Retrieve chat logs approaching the automatic retention deletion limit (83+ days)."""
    res = (
        supabase.table("conversation_logs")
        .select("id, content, session_date, pending_deletion_notified_at")
        .eq("user_id", str(user_id))
        .not_.is_("pending_deletion_notified_at", "null")
        .eq("retention_override", False)
        .order("session_date", desc=True)
        .execute()
    )

    if not res.data:
        return []

    return [ChatPendingDeletionItem.model_validate(item) for item in res.data]


@router.post(
    "/history/export",
    response_model=ChatExportResponse,
    status_code=status.HTTP_200_OK,
)
def export_chat_history(
    user_id: UUID = Depends(get_current_user_id),
    supabase: Client = Depends(get_supabase_client),
) -> ChatExportResponse:
    """Export all conversation history for the user as a downloadable JSON backup."""
    res = (
        supabase.table("conversation_logs")
        .select("*")
        .eq("user_id", str(user_id))
        .order("created_at", desc=False)
        .execute()
    )

    logs = [ChatHistoryItem.model_validate(item) for item in (res.data or [])]

    return ChatExportResponse(
        exported_at=datetime.now(timezone.utc),
        user_id=user_id,
        total_messages=len(logs),
        logs=logs,
    )


@router.patch(
    "/history/retention-override",
    response_model=ChatActionResponse,
    status_code=status.HTTP_200_OK,
)
def override_chat_retention(
    request: RetentionOverrideRequest,
    user_id: UUID = Depends(get_current_user_id),
    supabase: Client = Depends(get_supabase_client),
) -> ChatActionResponse:
    """Mark chat logs with retention_override = True so they are never automatically purged."""
    query = (
        supabase.table("conversation_logs")
        .update({"retention_override": request.retention_override})
        .eq("user_id", str(user_id))
    )

    if request.log_ids:
        ids_str = [str(i) for i in request.log_ids]
        query = query.in_("id", ids_str)

    res = query.execute()
    updated_count = len(res.data) if res.data else 0

    return ChatActionResponse(
        success=True,
        count=updated_count,
        message=f"{updated_count} log chat berhasil diatur dengan Simpan Selamanya.",
    )


@router.delete(
    "/history",
    response_model=ChatActionResponse,
    status_code=status.HTTP_200_OK,
)
def delete_all_chat_history(
    user_id: UUID = Depends(get_current_user_id),
    supabase: Client = Depends(get_supabase_client),
) -> ChatActionResponse:
    """Permanently delete all chat history for the authenticated user.

    Destructive and cannot be undone.
    """
    res = (
        supabase.table("conversation_logs")
        .delete()
        .eq("user_id", str(user_id))
        .execute()
    )

    deleted_count = len(res.data) if res.data else 0

    return ChatActionResponse(
        success=True,
        count=deleted_count,
        message=f"Seluruh riwayat chat ({deleted_count} pesan) berhasil dihapus permanen.",
    )
