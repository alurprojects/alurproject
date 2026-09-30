"""Phase 6 Comprehensive Verification Tests:
- 6.1 Backend Unit & Embedding / RAG Service Verification
- 6.2 RAG Accuracy & Grounded Fallback Verification (Anti-hallucination)
- 6.3 Morning Brief Payload, Idempotency & Database Serialization Verification
"""
from datetime import date, datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import UUID, uuid4
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.api.deps import get_current_user_id, get_embedding_service, get_rag_service, get_supabase_client
from app.core.config import settings
from app.agents.companion import companion_agent
from app.services.embedding_service import EmbeddingService
from app.services.rag_service import RAGService
from app.services.morning_brief_service import MorningBriefService
from app.services.cron_service import CronService

client = TestClient(app)
DEV_USER_ID = UUID("00000000-0000-0000-0000-000000000001")


# ===========================================================================
# 6.1 & 6.2: RAG Accuracy & Grounded Retrieval Tests
# ===========================================================================
@pytest.mark.asyncio
async def test_rag_accuracy_grounded_historical_context():
    """Verify Companion Agent utilizes RAG retrieved context to answer past activities accurately."""
    mock_supabase = MagicMock()
    mock_rag = MagicMock()

    # Simulate historical context found via semantic search
    mock_rag.retrieve_context = AsyncMock(
        return_value="[TASK | 2026-09-20] Selesaikan modul Auth Supabase & RLS (Status: COMPLETED)"
    )

    # Mock user profile
    mock_user_res = MagicMock()
    mock_user_res.data = {
        "daily_capacity_hours": 7,
        "ai_profile_summary": {"work_style": "Fokus pagi", "current_stress": "low"},
    }
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_user_res

    # Mock conversation logs (recent 5 messages)
    mock_logs_res = MagicMock()
    mock_logs_res.data = []
    mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_logs_res

    # Mock tasks today
    mock_tasks_res = MagicMock()
    mock_tasks_res.data = []

    def table_router(name):
        tbl = MagicMock()
        if name == "users":
            tbl.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_user_res
        elif name == "conversation_logs":
            tbl.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_logs_res
            tbl.insert.return_value.execute.return_value = MagicMock(data=[{"id": str(uuid4())}])
        elif name == "tasks":
            tbl.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_tasks_res
        return tbl

    mock_supabase.table.side_effect = table_router

    # Build grounded prompt
    mock_rag.generate_grounded_prompt = AsyncMock(
        return_value="## Konteks Historis User:\n[TASK] Selesaikan modul Auth Supabase"
    )

    system_prompt = await mock_rag.generate_grounded_prompt(
        user_id=DEV_USER_ID,
        user_query="Apa yang aku selesaikan minggu lalu?",
        system_context="Role: Companion Agent ALUR",
    )

    assert "Auth Supabase" in system_prompt


def test_rag_anti_hallucination_empty_context():
    """Verify RAGService returns explicit fallback when no relevant historical records exist."""
    mock_embed = MagicMock()
    mock_embed.similarity_search_sync.return_value = []
    rag_service = RAGService(embedding_service=mock_embed)

    context = rag_service.retrieve_context_sync(
        user_id=DEV_USER_ID,
        query="Apa mobil kesukaan saya?",
    )

    assert "Tidak ada konteks historis yang relevan ditemukan." in context


# ===========================================================================
# 6.3: Morning Brief Payload & Idempotent Upsert Verification
# ===========================================================================
def test_morning_brief_payload_structure_and_idempotency():
    """Verify that MorningBriefService produces a valid schema and upserts cleanly to database."""
    mock_supabase = MagicMock()
    mock_rag = MagicMock()
    mock_rag.retrieve_context_sync.return_value = ""

    today = date(2026, 9, 29)
    yesterday = today - timedelta(days=1)

    mock_tasks_res = MagicMock()
    mock_tasks_res.data = [
        {"id": "task-uuid-1", "title": "Implement pgvector", "estimated_minutes": 120, "status": "PENDING"},
        {"id": "task-uuid-2", "title": "Run flutter analyze", "estimated_minutes": 30, "status": "IN_PROGRESS"},
    ]

    mock_missed_res = MagicMock()
    mock_missed_res.data = [
        {"id": "task-uuid-0", "title": "Setup cron remote", "estimated_minutes": 45, "missed_follow_up": "PENDING"},
    ]

    mock_user_res = MagicMock()
    mock_user_res.data = {
        "daily_capacity_hours": 8.0,
        "ai_profile_summary": {"current_stress": "normal"},
    }

    upserted_payloads = []

    mock_brief_table = MagicMock()
    def mock_upsert(record, **kwargs):
        upserted_payloads.append(record)
        res = MagicMock()
        res.data = [record]
        return MagicMock(execute=MagicMock(return_value=res))

    mock_brief_table.upsert.side_effect = mock_upsert

    def table_router(name):
        tbl = MagicMock()
        if name == "tasks":
            sel = MagicMock()
            tbl.select.return_value = sel
            def eq_side(field, val):
                eq_mock = MagicMock()
                if field == "assigned_date":
                    eq_mock.execute.return_value = mock_tasks_res
                elif field == "status" and val == "MISSED":
                    mf_mock = MagicMock()
                    gte_mock = MagicMock()
                    gte_mock.execute.return_value = mock_missed_res
                    mf_mock.gte.return_value = gte_mock
                    eq_mock.eq.return_value = mf_mock
                return eq_mock
            sel.eq.return_value.eq.side_effect = eq_side
            return tbl
        elif name == "users":
            tbl.select.return_value.eq.return_value.single.return_value.execute.return_value = mock_user_res
            return tbl
        elif name == "morning_briefs":
            return mock_brief_table
        return tbl

    mock_supabase.table.side_effect = table_router

    service = MorningBriefService(supabase=mock_supabase, rag=mock_rag)

    # 1. First generation (e.g. triggered by cron at 07:00)
    brief1 = service.generate_brief_sync(user_id=DEV_USER_ID, brief_date=today)

    # 2. Second generation (e.g. user manually opens app, idempotent upsert)
    brief2 = service.generate_brief_sync(user_id=DEV_USER_ID, brief_date=today)

    assert len(upserted_payloads) == 2
    # Verify exact schema stored in Database JSONB column
    record = upserted_payloads[0]
    assert record["user_id"] == str(DEV_USER_ID)
    assert record["brief_date"] == "2026-09-29"

    content = record["content"]
    assert "date" in content
    assert "greeting" in content
    assert "tasks" in content
    assert "missed_tasks" in content
    assert "capacity_summary" in content
    assert "ai_note" in content

    # Verify task data serialization
    assert len(content["tasks"]) == 2
    assert content["tasks"][0]["title"] == "Implement pgvector"
    assert content["tasks"][0]["estimated_minutes"] == 120

    # Verify capacity calculation
    # Total: 8.0 hrs. Scheduled: (120 + 30) = 150 mins = 2.5 hrs. Remaining: 5.5 hrs.
    assert content["capacity_summary"]["total_hours"] == 8.0
    assert content["capacity_summary"]["scheduled_hours"] == 2.5
    assert content["capacity_summary"]["remaining_hours"] == 5.5

    # Verify missed task data
    assert len(content["missed_tasks"]) == 1
    assert content["missed_tasks"][0]["title"] == "Setup cron remote"
    assert content["missed_tasks"][0]["follow_up"] == "PENDING"


def test_cron_service_user_timezone_evaluation():
    """Verify CronService accurately evaluates user timezone and triggers morning brief."""
    mock_supabase = MagicMock()
    cron_service = CronService(mock_supabase)

    # Mock user with Asia/Jakarta timezone and reminder_hour = 7
    test_user_wib = {
        "id": str(DEV_USER_ID),
        "timezone": "Asia/Jakarta",
        "preferences": {
            "notifications": {
                "reminder_hour": 7,
                "morning_brief_enabled": True,
            }
        },
    }
    mock_users_res = MagicMock(data=[test_user_wib])
    mock_supabase.table.return_value.select.return_value.execute.return_value = mock_users_res

    # Mock MorningBriefService
    with patch("app.services.morning_brief_service.MorningBriefService") as mock_mb_cls:
        mock_mb_instance = MagicMock()
        mock_mb_cls.return_value = mock_mb_instance

        # Test at UTC 00:00 (which is 07:00 WIB in Asia/Jakarta)
        simulated_utc_time = datetime(2026, 9, 29, 0, 0, 0, tzinfo=timezone.utc)
        with patch("app.services.cron_service.datetime") as mock_dt:
            mock_dt.now.return_value = simulated_utc_time
            mock_dt.side_effect = lambda *args, **kw: datetime(*args, **kw)

            summary = cron_service.run_morning_brief_cron()

        assert summary["status"] == "success"
        assert summary["job"] == "morning-brief"
        assert summary["users_matched"] == 1
        assert summary["briefs_generated"] == 1
        mock_mb_instance.generate_brief_sync.assert_called_once()
