"""RAG service: retrieval-augmented generation for grounded AI responses."""
from typing import Optional
from uuid import UUID

from app.services.embedding_service import EmbeddingService, EmbeddingSource


class RAGService:
    def __init__(self, embedding_service: EmbeddingService):
        self.embeddings = embedding_service

    def retrieve_context_sync(
        self,
        user_id: UUID,
        query: str,
        top_k: int = 10,
        source_filter: Optional[EmbeddingSource] = None,
    ) -> str:
        """Retrieve relevant context for AI generation (sync)."""
        results = self.embeddings.similarity_search_sync(
            user_id=user_id,
            query=query,
            top_k=top_k,
            source_filter=source_filter,
        )

        if not results:
            return "Tidak ada konteks historis yang relevan ditemukan."

        context_parts = []
        for r in results:
            source = r.get("source_type", "UNKNOWN")
            text = r.get("content_text", "")
            meta = r.get("metadata", {}) or {}
            date = meta.get("date", "unknown")
            context_parts.append(f"[{source} | {date}] {text}")

        return "\n---\n".join(context_parts)

    async def retrieve_context(
        self,
        user_id: UUID,
        query: str,
        top_k: int = 10,
        source_filter: Optional[EmbeddingSource] = None,
    ) -> str:
        """Retrieve relevant context for AI generation (async)."""
        results = await self.embeddings.similarity_search(
            user_id=user_id,
            query=query,
            top_k=top_k,
            source_filter=source_filter,
        )

        if not results:
            return "Tidak ada konteks historis yang relevan ditemukan."

        context_parts = []
        for r in results:
            source = r.get("source_type", "UNKNOWN")
            text = r.get("content_text", "")
            meta = r.get("metadata", {}) or {}
            date = meta.get("date", "unknown")
            context_parts.append(f"[{source} | {date}] {text}")

        return "\n---\n".join(context_parts)

    def generate_grounded_prompt_sync(
        self,
        user_id: UUID,
        user_query: str,
        system_context: str = "",
        top_k: int = 10,
        source_filter: Optional[EmbeddingSource] = None,
    ) -> str:
        """Build a RAG-augmented prompt with retrieved context (sync)."""
        retrieved = self.retrieve_context_sync(
            user_id=user_id,
            query=user_query,
            top_k=top_k,
            source_filter=source_filter,
        )

        return f"""## Konteks Historis User (dari database, FAKTA — jangan hallucinate di luar ini):
{retrieved}

## Instruksi Sistem:
{system_context}

## Pesan User:
{user_query}

## ATURAN KETAT:
- HANYA gunakan informasi dari Konteks Historis di atas.
- Jika informasi tidak ada di konteks, katakan "Saya tidak punya data tentang itu" — JANGAN mengarang.
- Sebutkan sumber data jika memungkinkan (misal: "Berdasarkan task kamu tanggal X...").
"""

    async def generate_grounded_prompt(
        self,
        user_id: UUID,
        user_query: str,
        system_context: str = "",
        top_k: int = 10,
        source_filter: Optional[EmbeddingSource] = None,
    ) -> str:
        """Build a RAG-augmented prompt with retrieved context (async)."""
        retrieved = await self.retrieve_context(
            user_id=user_id,
            query=user_query,
            top_k=top_k,
            source_filter=source_filter,
        )

        return f"""## Konteks Historis User (dari database, FAKTA — jangan hallucinate di luar ini):
{retrieved}

## Instruksi Sistem:
{system_context}

## Pesan User:
{user_query}

## ATURAN KETAT:
- HANYA gunakan informasi dari Konteks Historis di atas.
- Jika informasi tidak ada di konteks, katakan "Saya tidak punya data tentang itu" — JANGAN mengarang.
- Sebutkan sumber data jika memungkinkan (misal: "Berdasarkan task kamu tanggal X...").
"""
