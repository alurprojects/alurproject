"""Unit and integration tests for Morning Brief service, API endpoint, and internal cron."""
from datetime import date, datetime, timedelta, timezone
from unittest.mock import MagicMock, patch
from uuid import UUID, uuid4
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.api.deps import get_current_user_id, get_morning_brief_service
from app.core.config import settings
from app.services.morning_brief_service import MorningBriefService
from app.services.cron_service import CronService

client = TestClient(app)
DEV_USER_ID = UUID("00000000-0000-0000-0000-000000000001")


# ---------------------------------------------------------------------------
# 1. MorningBriefService Unit Tests
# ---------------------------------------------------------------------------
def test_morning_brief_greeting_and_capacity_calc():
    """Verify capacity calculation, greeting generation, and task grouping."""
    mock_supabase = MagicMock()
    mock_rag = MagicMock()
    mock_rag.retrieve_hybrid.return_value = []

    today = date(2026, 9, 29)  # Selasa
    yesterday = today - timedelta(days=1)

    # Mock tasks query
    mock_tasks_table = MagicMock()
    mock_yesterday_table = MagicMock()
    mock_profile_table = MagicMock()
    mock_brief_table = MagicMock()

    # tasks today: 2 pending tasks (60 mins, 90 mins = 150 mins scheduled)
    mock_tasks_res = MagicMock()
    mock_tasks_res.data = [
        {"id": str(uuid4()), "title": "Design UI", "estimated_minutes": 60, "status": "PENDING"},
        {"id": str(uuid4()), "title": "Write API", "estimated_minutes": 90, "status": "IN_PROGRESS"},
        {"id": str(uuid4()), "title": "Old Done Task", "estimated_minutes": 45, "status": "COMPLETED"},
    ]

    # tasks yesterday: 1 missed task
    mock_yesterday_res = MagicMock()
    mock_yesterday_res.data = [
        {"id": str(uuid4()), "title": "Review PR", "estimated_minutes": 30, "status": "MISSED"},
    ]

    # user profile: daily_capacity_hours = 6.0
    mock_user_res = MagicMock()
    mock_user_res.data = {"daily_capacity_hours": 6.0, "ai_profile_summary": "Normal"}

    mock_upsert_res = MagicMock()
    mock_upsert_res.data = [{"id": str(uuid4())}]

    def table_router(name):
        tbl = MagicMock()
        if name == "tasks":
            sel = MagicMock()
            tbl.select.return_value = sel

            # Handle chain for today's tasks vs missed tasks
            def eq_side_effect(field, val):
                eq_mock = MagicMock()
                if field == "assigned_date":
                    eq_mock.execute.return_value = mock_tasks_res
                elif field == "status" and val == "MISSED":
                    # Chain .eq("missed_follow_up", ...).gte(...).execute()
                    mf_mock = MagicMock()
                    gte_mock = MagicMock()
                    gte_mock.execute.return_value = mock_yesterday_res
                    mf_mock.gte.return_value = gte_mock
                    eq_mock.eq.return_value = mf_mock
                return eq_mock

            sel.eq.return_value.eq.side_effect = eq_side_effect
            return tbl
        elif name == "users":
            sel = MagicMock()
            tbl.select.return_value = sel
            eq_mock = MagicMock()
            sel.eq.return_value = eq_mock
            single_mock = MagicMock()
            eq_mock.single.return_value = single_mock
            single_mock.execute.return_value = mock_user_res
            return tbl
        elif name == "morning_briefs":
            tbl.upsert.return_value.execute.return_value = mock_upsert_res
            return tbl
        return tbl

    mock_supabase.table.side_effect = table_router

    service = MorningBriefService(supabase=mock_supabase, rag=mock_rag)

    with patch.object(service, "_generate_ai_note", return_value="AI note: Fokus satu per satu."):
        brief = service.generate_brief_sync(user_id=DEV_USER_ID, brief_date=today)

    assert brief["date"] == "2026-09-29"
    assert "Selasa, 29 September 2026" in brief["greeting"]
    # Total capacity = 6 hours = 360 mins. Scheduled = 150 mins = 2.5 hours. Remaining = 3.5 hours.
    assert brief["capacity_summary"]["total_hours"] == 6.0
    assert brief["capacity_summary"]["scheduled_hours"] == 2.5
    assert brief["capacity_summary"]["remaining_hours"] == 3.5
    assert len(brief["tasks"]) == 2  # PENDING and IN_PROGRESS
    assert len(brief["missed_tasks"]) == 1
    assert brief["ai_note"] == "AI note: Fokus satu per satu."


def test_morning_brief_ai_note_fallback():
    """Verify fallback text generation when LLM is unavailable."""
    mock_supabase = MagicMock()
    mock_rag = MagicMock()
    service = MorningBriefService(supabase=mock_supabase, rag=mock_rag)

    # Empty tasks fallback
    empty_note = service._generate_ai_note(
        tasks_today=[],
        missed_tasks=[],
        capacity_remaining=5.0,
        rag_context="",
    )
    assert "belum ada tugas terjadwal" in empty_note.lower()

    # Missed tasks fallback
    missed_note = service._generate_ai_note(
        tasks_today=[{"title": "Task A"}],
        missed_tasks=[{"title": "Laporan Keuangan"}],
        capacity_remaining=3.0,
        rag_context="",
    )
    assert "Laporan Keuangan" in missed_note
    assert "terlewat" in missed_note

    # Normal tasks fallback
    normal_note = service._generate_ai_note(
        tasks_today=[{"title": "Task A"}, {"title": "Task B"}],
        missed_tasks=[],
        capacity_remaining=4.0,
        rag_context="",
    )
    assert "2 tugas" in normal_note
    assert "4.0 jam" in normal_note


def test_get_or_generate_brief_cached():
    """Verify get_or_generate_brief_sync returns cached brief and updates opened_at."""
    mock_supabase = MagicMock()
    mock_rag = MagicMock()

    existing_content = {
        "greeting": "Selamat pagi!",
        "capacity": {"total_hours": 6.0, "scheduled_hours": 2.0, "remaining_hours": 4.0},
        "tasks_today": [],
        "missed_tasks": [],
        "ai_note": "Semangat pagi.",
    }

    mock_briefs_res = MagicMock()
    mock_briefs_res.data = [{
        "id": str(uuid4()),
        "content": existing_content,
        "opened_at": None,
    }]

    mock_table = MagicMock()
    mock_supabase.table.return_value = mock_table
    mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_briefs_res
    mock_table.update.return_value.eq.return_value.execute.return_value = MagicMock()

    service = MorningBriefService(supabase=mock_supabase, rag=mock_rag)
    content, is_new = service.get_or_generate_brief_sync(DEV_USER_ID, date(2026, 9, 29))

    assert is_new is False
    assert content["greeting"] == "Selamat pagi!"
    mock_table.update.assert_called_once()


# ---------------------------------------------------------------------------
# 2. GET /morning-brief API Route Tests
# ---------------------------------------------------------------------------
def test_get_morning_brief_endpoint():
    """Verify GET /morning-brief returns 200 with structured response."""
    mock_service = MagicMock()
    sample_content = {
        "greeting": "Selamat pagi! Hari Selasa, 29 September 2026.",
        "capacity": {"total_hours": 6.0, "scheduled_hours": 2.0, "remaining_hours": 4.0},
        "tasks_today": [],
        "missed_tasks": [],
        "ai_note": "Semangat hari ini.",
    }
    mock_service.get_or_generate_brief_sync.return_value = (sample_content, True)

    app.dependency_overrides[get_current_user_id] = lambda: DEV_USER_ID
    app.dependency_overrides[get_morning_brief_service] = lambda: mock_service

    try:
        response = client.get("/morning-brief?date=2026-09-29")
        assert response.status_code == 200
        payload = response.json()
        assert payload["status"] == "success"
        assert payload["generated"] is True
        assert payload["data"]["greeting"] == sample_content["greeting"]
    finally:
        app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# 3. POST /internal/cron/morning-brief Route Tests
# ---------------------------------------------------------------------------
def test_internal_cron_morning_brief_unauthorized():
    """Verify cron endpoint rejects requests without valid X-Cron-Secret."""
    response = client.post("/internal/cron/morning-brief", headers={"X-Cron-Secret": "invalid-secret"})
    assert response.status_code == 401


def test_internal_cron_morning_brief_authorized():
    """Verify cron endpoint triggers run_morning_brief_cron when authorized."""
    secret = settings.CRON_SECRET or "alur-test-cron-secret-2026"
    with patch.object(settings, "CRON_SECRET", secret):
        with patch.object(CronService, "run_morning_brief_cron") as mock_cron:
            mock_cron.return_value = {
                "status": "success",
                "job": "morning-brief",
                "users_processed": 1,
                "briefs_generated": 1,
                "errors": [],
            }

            response = client.post(
                "/internal/cron/morning-brief",
                headers={"X-Cron-Secret": secret},
            )
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert data["briefs_generated"] == 1
            mock_cron.assert_called_once()
