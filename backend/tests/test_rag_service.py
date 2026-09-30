"""Tests for RAGService."""
import pytest
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

from app.services.rag_service import RAGService


@pytest.fixture
def mock_embedding_service():
    mock = MagicMock()
    # Mock sync similarity search
    mock.similarity_search_sync.return_value = [
        {
            "id": str(uuid4()),
            "source_type": "TASK",
            "source_id": str(uuid4()),
            "content_text": "Meeting dengan stakeholder (est: 60 menit)",
            "metadata": {"date": "2026-09-27"},
            "similarity": 0.88,
        },
        {
            "id": str(uuid4()),
            "source_type": "CONVERSATION",
            "source_id": str(uuid4()),
            "content_text": "Kemarin berhasil selesaikan 4 task tepat waktu",
            "metadata": {"date": "2026-09-27"},
            "similarity": 0.79,
        },
    ]

    # Mock async similarity search
    mock.similarity_search = AsyncMock(return_value=mock.similarity_search_sync.return_value)
    return mock


@pytest.fixture
def rag_service(mock_embedding_service):
    return RAGService(mock_embedding_service)


@pytest.mark.asyncio
async def test_retrieve_context_with_results(rag_service):
    """Test retrieving and formatting context when results exist."""
    user_id = uuid4()
    context = await rag_service.retrieve_context(user_id=user_id, query="meeting kemarin")

    assert "[TASK | 2026-09-27] Meeting dengan stakeholder" in context
    assert "[CONVERSATION | 2026-09-27] Kemarin berhasil selesaikan 4 task" in context
    assert "---" in context


@pytest.mark.asyncio
async def test_retrieve_context_empty(rag_service, mock_embedding_service):
    """Test retrieving context when no results are found."""
    mock_embedding_service.similarity_search.return_value = []
    user_id = uuid4()
    context = await rag_service.retrieve_context(user_id=user_id, query="topik baru")

    assert context == "Tidak ada konteks historis yang relevan ditemukan."


@pytest.mark.asyncio
async def test_generate_grounded_prompt(rag_service):
    """Test constructing a grounded prompt."""
    user_id = uuid4()
    prompt = await rag_service.generate_grounded_prompt(
        user_id=user_id,
        user_query="Berapa task yang kuselesaikan kemarin?",
        system_context="Kamu adalah Companion Agent.",
    )

    assert "## Konteks Historis User (dari database, FAKTA — jangan hallucinate di luar ini):" in prompt
    assert "## Instruksi Sistem:\nKamu adalah Companion Agent." in prompt
    assert "## Pesan User:\nBerapa task yang kuselesaikan kemarin?" in prompt
    assert "## ATURAN KETAT:" in prompt
    assert "[TASK | 2026-09-27]" in prompt


def test_sync_methods(rag_service):
    """Test sync counterparts of retrieve_context and generate_grounded_prompt."""
    user_id = uuid4()
    ctx = rag_service.retrieve_context_sync(user_id=user_id, query="meeting")
    assert "[TASK | 2026-09-27]" in ctx

    prompt = rag_service.generate_grounded_prompt_sync(
        user_id=user_id,
        user_query="Halo",
        system_context="System",
    )
    assert "## Konteks Historis User" in prompt
