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
    supabase: Client = Depends(get_supabase_client),
) -> UUID:
    """Extract and validate the current user's ID from Supabase Auth JWT.

    Requires a valid `Authorization: Bearer <supabase_jwt>` header.
    shortcut: dev fallback to seeded user when BACKEND_ENV != production,
    remove once local/mobile always send real JWTs.
    """
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "").strip()
        try:
            res = supabase.auth.get_user(token)
            if res and res.user:
                return UUID(res.user.id)
        except Exception:
            pass

    if settings.BACKEND_ENV != "production":
        return DEV_USER_ID

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Missing or invalid Authorization Bearer token",
    )

def get_task_service(
    supabase: Client = Depends(get_supabase_client),
) -> TaskService:
    """Dependency provider for TaskService."""
    return TaskService(supabase)

def get_embedding_service(
    supabase: Client = Depends(get_supabase_client),
) -> Optional["EmbeddingService"]:
    """Dependency provider for EmbeddingService.

    Kembalikan None (bukan 500) bila GEMINI_API_KEY tidak dikonfigurasi,
    agar CRUD tetap jalan di env tanpa embedding.
    """
    if not settings.GEMINI_API_KEY:
        return None
    from app.services.embedding_service import EmbeddingService
    return EmbeddingService(supabase)

def get_rag_service(
    embedding_service: Optional["EmbeddingService"] = Depends(get_embedding_service),
) -> Optional["RAGService"]:
    """Dependency provider for RAGService (None bila embedding mati)."""
    if embedding_service is None:
        return None
    from app.services.rag_service import RAGService
    return RAGService(embedding_service)

def get_morning_brief_service(
    supabase: Client = Depends(get_supabase_client),
    rag_service: Optional["RAGService"] = Depends(get_rag_service),
) -> "MorningBriefService":
    """Dependency provider for MorningBriefService."""
    from app.services.morning_brief_service import MorningBriefService
    return MorningBriefService(supabase, rag_service)
