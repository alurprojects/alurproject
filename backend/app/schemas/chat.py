from datetime import date, datetime
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, Field
from app.schemas.task import TaskResponse


class ChatMessageRequest(BaseModel):
    message: str = Field(..., min_length=1, description="Raw user message text")


class ChatMessageResponse(BaseModel):
    reply: str
    message_type: str
    tone_used: str
    mood_detected: Optional[str] = None
    extracted_tasks: List[TaskResponse] = []


class ChatHistoryItem(BaseModel):
    id: UUID
    role: str
    content: str
    message_type: str
    extracted_task_ids: Optional[List[UUID]] = Field(default_factory=list)
    tone_used: Optional[str] = None
    mood_detected: Optional[str] = None
    session_date: date
    created_at: datetime


class ChatPendingDeletionItem(BaseModel):
    id: UUID
    content: str
    session_date: date
    pending_deletion_notified_at: Optional[datetime] = None


class ChatExportResponse(BaseModel):
    exported_at: datetime
    user_id: UUID
    total_messages: int
    logs: List[ChatHistoryItem]


class RetentionOverrideRequest(BaseModel):
    log_ids: Optional[List[UUID]] = None
    retention_override: bool = True


class ChatActionResponse(BaseModel):
    success: bool
    count: int
    message: str
