"""Embedding service: generate & store vector embeddings for RAG."""
import asyncio
import logging
from typing import Any, Dict, List, Literal, Optional
from uuid import UUID

import google.generativeai as genai
from supabase import Client

from app.core.config import settings

logger = logging.getLogger(__name__)

EmbeddingSource = Literal["TASK", "CONVERSATION", "INSIGHT"]

PRIMARY_EMBEDDING_MODEL = "models/text-embedding-004"
FALLBACK_EMBEDDING_MODEL = "models/gemini-embedding-001"
EMBEDDING_DIMENSION = 768


class EmbeddingService:
    def __init__(self, supabase: Client):
        self.supabase = supabase
        self._model = PRIMARY_EMBEDDING_MODEL

    def embed_text_sync(
        self,
        text: str,
        task_type: str = "retrieval_document",
    ) -> List[float]:
        """Generate embedding vector synchronously using Gemini."""
        if not settings.GEMINI_API_KEY:
            raise RuntimeError("GEMINI_API_KEY is not configured.")

        genai.configure(api_key=settings.GEMINI_API_KEY)
        try:
            res = genai.embed_content(
                model=self._model,
                content=text,
                task_type=task_type,
                output_dimensionality=EMBEDDING_DIMENSION,
            )
            return res["embedding"]
        except Exception as e:
            if self._model != FALLBACK_EMBEDDING_MODEL:
                logger.warning(
                    f"Model {self._model} failed ({e}), falling back to {FALLBACK_EMBEDDING_MODEL}"
                )
                self._model = FALLBACK_EMBEDDING_MODEL
                res = genai.embed_content(
                    model=FALLBACK_EMBEDDING_MODEL,
                    content=text,
                    task_type=task_type,
                    output_dimensionality=EMBEDDING_DIMENSION,
                )
                return res["embedding"]
            raise e

    async def embed_text(
        self,
        text: str,
        task_type: str = "retrieval_document",
    ) -> List[float]:
        """Generate embedding vector asynchronously using Gemini."""
        return await asyncio.to_thread(self.embed_text_sync, text, task_type)

    def upsert_embedding_sync(
        self,
        user_id: UUID,
        source_type: EmbeddingSource,
        source_id: UUID,
        content_text: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Generate and store embedding for a piece of content (sync)."""
        vector = self.embed_text_sync(content_text, task_type="retrieval_document")
        payload = {
            "user_id": str(user_id),
            "source_type": source_type,
            "source_id": str(source_id),
            "content_text": content_text,
            "embedding": vector,
            "metadata": metadata or {},
        }
        res = self.supabase.table("embeddings").upsert(
            payload,
            on_conflict="source_type,source_id",
        ).execute()
        return res.data[0] if res.data else payload

    async def upsert_embedding(
        self,
        user_id: UUID,
        source_type: EmbeddingSource,
        source_id: UUID,
        content_text: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Generate and store embedding for a piece of content (async)."""
        return await asyncio.to_thread(
            self.upsert_embedding_sync,
            user_id,
            source_type,
            source_id,
            content_text,
            metadata,
        )

    def similarity_search_sync(
        self,
        user_id: UUID,
        query: str,
        top_k: int = 10,
        source_filter: Optional[EmbeddingSource] = None,
    ) -> List[Dict[str, Any]]:
        """Find most similar content to query using cosine similarity (sync)."""
        query_vector = self.embed_text_sync(query, task_type="retrieval_query")
        params: Dict[str, Any] = {
            "query_embedding": query_vector,
            "match_user_id": str(user_id),
            "match_count": top_k,
        }
        if source_filter:
            params["filter_source"] = source_filter

        result = self.supabase.rpc("match_embeddings", params).execute()
        return result.data or []

    async def similarity_search(
        self,
        user_id: UUID,
        query: str,
        top_k: int = 10,
        source_filter: Optional[EmbeddingSource] = None,
    ) -> List[Dict[str, Any]]:
        """Find most similar content to query using cosine similarity (async)."""
        return await asyncio.to_thread(
            self.similarity_search_sync,
            user_id,
            query,
            top_k,
            source_filter,
        )
