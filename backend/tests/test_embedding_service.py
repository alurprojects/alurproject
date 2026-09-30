"""Tests for EmbeddingService."""
import pytest
from unittest.mock import MagicMock, patch
from uuid import UUID, uuid4

from app.services.embedding_service import (
    EmbeddingService,
    EMBEDDING_DIMENSION,
)


@pytest.fixture
def mock_supabase():
    mock = MagicMock()
    # Mock table('embeddings').upsert(...).execute()
    mock_table = MagicMock()
    mock_upsert = MagicMock()
    mock_execute = MagicMock()
    mock_execute.execute.return_value = MagicMock(data=[{"id": str(uuid4())}])
    mock_upsert.return_value = mock_execute
    mock_table.upsert = mock_upsert
    mock.table.return_value = mock_table

    # Mock rpc('match_embeddings', ...).execute()
    mock_rpc = MagicMock()
    mock_rpc.execute.return_value = MagicMock(
        data=[
            {
                "id": str(uuid4()),
                "source_type": "TASK",
                "source_id": str(uuid4()),
                "content_text": "Review PR",
                "metadata": {"status": "PENDING"},
                "similarity": 0.85,
            }
        ]
    )
    mock.rpc.return_value = mock_rpc
    return mock


@pytest.fixture
def embedding_service(mock_supabase):
    return EmbeddingService(mock_supabase)


def test_embed_text_sync_mock(embedding_service):
    """Test embed_text_sync with mocked Gemini."""
    with patch("google.generativeai.embed_content") as mock_embed:
        mock_embed.return_value = {"embedding": [0.1] * EMBEDDING_DIMENSION}
        vector = embedding_service.embed_text_sync("Task 1")
        assert len(vector) == EMBEDDING_DIMENSION
        assert vector[0] == 0.1


@pytest.mark.asyncio
async def test_embed_text_async_mock(embedding_service):
    """Test async embed_text."""
    with patch("google.generativeai.embed_content") as mock_embed:
        mock_embed.return_value = {"embedding": [0.2] * EMBEDDING_DIMENSION}
        vector = await embedding_service.embed_text("Async Task")
        assert len(vector) == EMBEDDING_DIMENSION
        assert vector[0] == 0.2


def test_upsert_embedding_sync(embedding_service, mock_supabase):
    """Test upserting an embedding row synchronously."""
    with patch("google.generativeai.embed_content") as mock_embed:
        mock_embed.return_value = {"embedding": [0.05] * EMBEDDING_DIMENSION}
        user_id = uuid4()
        source_id = uuid4()

        result = embedding_service.upsert_embedding_sync(
            user_id=user_id,
            source_type="TASK",
            source_id=source_id,
            content_text="Selesaikan laporan",
            metadata={"date": "2026-09-28"},
        )

        assert result is not None
        mock_supabase.table.assert_called_with("embeddings")


@pytest.mark.asyncio
async def test_upsert_embedding_async(embedding_service, mock_supabase):
    """Test upserting an embedding row asynchronously."""
    with patch("google.generativeai.embed_content") as mock_embed:
        mock_embed.return_value = {"embedding": [0.05] * EMBEDDING_DIMENSION}
        user_id = uuid4()
        source_id = uuid4()

        result = await embedding_service.upsert_embedding(
            user_id=user_id,
            source_type="CONVERSATION",
            source_id=source_id,
            content_text="Aku agak lelah hari ini",
            metadata={"role": "USER"},
        )

        assert result is not None
        mock_supabase.table.assert_called_with("embeddings")


def test_similarity_search_sync(embedding_service, mock_supabase):
    """Test similarity search RPC calling."""
    with patch("google.generativeai.embed_content") as mock_embed:
        mock_embed.return_value = {"embedding": [0.1] * EMBEDDING_DIMENSION}
        user_id = uuid4()

        results = embedding_service.similarity_search_sync(
            user_id=user_id,
            query="laporan",
            top_k=5,
            source_filter="TASK",
        )

        assert len(results) == 1
        assert results[0]["content_text"] == "Review PR"
        mock_supabase.rpc.assert_called_once()
        args, kwargs = mock_supabase.rpc.call_args
        assert args[0] == "match_embeddings"
        assert args[1]["match_user_id"] == str(user_id)
        assert args[1]["match_count"] == 5
        assert args[1]["filter_source"] == "TASK"
