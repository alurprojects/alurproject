"""Tests for Phase 3: Embedding Hooks, Dynamic Persona Router, Hierarchical Memory, and Background Memory Condenser."""
from datetime import date
from unittest.mock import MagicMock, patch
from uuid import UUID, uuid4
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.agents.companion import select_active_persona, _format_hierarchical_memory, PERSONA_PROMPTS
from app.api.deps import get_current_user_id, get_embedding_service, get_supabase_client
from app.schemas.task import TaskCreate, TaskResponse, TaskUpdate
from app.services.cron_service import CronService

client = TestClient(app)
DEV_USER_ID = UUID("00000000-0000-0000-0000-000000000001")


# --- 1. Dynamic Persona Router Tests ---
def test_dynamic_persona_router_burnout():
    """Burnout context routes to GENTLE persona."""
    persona, prompt = select_active_persona("capek banget kerjaan banyak", is_burnout_context=True)
    assert persona == "GENTLE"
    assert "Active Persona: GENTLE" in prompt


def test_dynamic_persona_router_minimalist():
    """Short message or explicit brevity request routes to MINIMALIST persona."""
    persona1, _ = select_active_persona("ok siap", is_burnout_context=False)
    assert persona1 == "MINIMALIST"

    persona2, prompt2 = select_active_persona("tolong jawab singkat ya", is_burnout_context=False)
    assert persona2 == "MINIMALIST"
    assert "Active Persona: MINIMALIST" in prompt2


def test_dynamic_persona_router_strategist():
    """High task load or strategy request routes to STRATEGIST persona."""
    persona1, prompt1 = select_active_persona("bagaimana strategi susun prioritas hari ini?", is_burnout_context=False)
    assert persona1 == "STRATEGIST"
    assert "Active Persona: STRATEGIST" in prompt1

    persona2, _ = select_active_persona("cek jadwal", is_burnout_context=False, task_count=5)
    assert persona2 == "STRATEGIST"


def test_dynamic_persona_router_default_honest():
    """Standard message routes to HONEST default persona."""
    persona, prompt = select_active_persona("besok ada tugas apa aja ya yang perlu dikerjakan?", is_burnout_context=False)
    assert persona == "HONEST"
    assert "Active Persona: HONEST (Default)" in prompt


# --- 2. 3-Layer Hierarchical Memory Tests ---
def test_hierarchical_memory_formatting():
    """Ensure formatting includes Level 1 (Core), Level 2 (Short-term), and Level 3 (Archival RAG)."""
    core_profile = {"work_style": "Deep work morning", "current_stress": "normal"}
    short_term = [
        {"role": "USER", "content": "Halo ALUR"},
        {"role": "AI", "content": "Halo! Siap atur fokus hari ini?"},
    ]
    rag_context = "[TASK | 2026-09-27] Review PR backend"

    formatted = _format_hierarchical_memory(core_profile, short_term, rag_context)

    assert "### Level 1: Core User Profile" in formatted
    assert "Deep work morning" in formatted
    assert "### Level 2: Short-term Context" in formatted
    assert "User: Halo ALUR" in formatted
    assert "### Level 3: Archival Memory" in formatted
    assert "Review PR backend" in formatted


# --- 3. Hook Tests: Tasks (create & update) ---
def test_task_hooks_trigger_embedding():
    """Verify create_task and update_task trigger upsert_embedding_sync."""
    mock_supabase = MagicMock()
    mock_embedding_service = MagicMock()

    app.dependency_overrides[get_supabase_client] = lambda: mock_supabase
    app.dependency_overrides[get_embedding_service] = lambda: mock_embedding_service
    app.dependency_overrides[get_current_user_id] = lambda: DEV_USER_ID

    fake_task = {
        "id": str(uuid4()),
        "user_id": str(DEV_USER_ID),
        "title": "Beli kopi Arabica",
        "estimated_minutes": 15,
        "assigned_date": date.today().isoformat(),
        "status": "PENDING",
        "source": "MANUAL",
        "is_ambiguous": False,
        "ai_generated": False,
        "missed_follow_up": "NONE",
        "created_at": "2026-09-28T10:00:00Z",
        "updated_at": "2026-09-28T10:00:00Z",
    }

    # Mock TaskService.create_task and update_task
    with patch("app.services.task_service.TaskService.create_task") as mock_create, \
         patch("app.services.task_service.TaskService.update_task") as mock_update:

        mock_create.return_value = TaskResponse.model_validate(fake_task)
        mock_update.return_value = TaskResponse.model_validate(fake_task)

        # 1. Test POST /tasks
        resp_post = client.post(
            "/tasks",
            json={
                "title": "Beli kopi Arabica",
                "estimated_minutes": 15,
                "assigned_date": date.today().isoformat(),
            },
        )
        assert resp_post.status_code == 201
        assert mock_embedding_service.upsert_embedding_sync.called
        call_args = mock_embedding_service.upsert_embedding_sync.call_args[1]
        assert call_args["source_type"] == "TASK"
        assert "Beli kopi Arabica" in call_args["content_text"]

        # 2. Test PATCH /tasks/{id}
        mock_embedding_service.reset_mock()
        resp_patch = client.patch(f"/tasks/{fake_task['id']}", json={"status": "DONE"})
        assert resp_patch.status_code == 200
        assert mock_embedding_service.upsert_embedding_sync.called

    app.dependency_overrides.clear()


# --- 4. Hook Tests: Chat Message Logs ---
def test_chat_hook_triggers_embedding():
    """Verify send_chat_message triggers upsert_embedding_sync for conversation logs."""
    mock_supabase = MagicMock()
    mock_embedding_service = MagicMock()

    app.dependency_overrides[get_supabase_client] = lambda: mock_supabase
    app.dependency_overrides[get_embedding_service] = lambda: mock_embedding_service
    app.dependency_overrides[get_current_user_id] = lambda: DEV_USER_ID

    fake_log_id = str(uuid4())
    mock_graph_result = {
        "reply": "Dicatat. Tetap jaga ritme fokus.",
        "message_type": "CHAT",
        "tone_used": "HONEST",
        "active_persona": "HONEST",
        "mood_detected": None,
        "extracted_tasks": [],
        "conversation_logs": [
            {
                "id": fake_log_id,
                "role": "USER",
                "content": "Besok mau evaluasi progress.",
                "session_date": "2026-09-28",
                "message_type": "CHAT",
            }
        ],
    }

    with patch("app.api.chat.run_chat_message", return_value=mock_graph_result):
        resp = client.post("/chat/message", json={"message": "Besok mau evaluasi progress."})
        assert resp.status_code == 200
        assert mock_embedding_service.upsert_embedding_sync.called
        call_args = mock_embedding_service.upsert_embedding_sync.call_args[1]
        assert call_args["source_type"] == "CONVERSATION"
        assert call_args["content_text"] == "Besok mau evaluasi progress."

    app.dependency_overrides.clear()


# --- 5. Background Memory Condenser Tests ---
def test_background_memory_condenser():
    """Test background memory condenser cron service and internal cron endpoint."""
    mock_supabase = MagicMock()
    cron_service = CronService(mock_supabase)

    # Mock user query
    mock_users_res = MagicMock(data=[{"id": str(DEV_USER_ID), "ai_profile_summary": {}}])
    mock_supabase.table().select().execute.return_value = mock_users_res

    # Mock conversation logs query
    mock_logs_res = MagicMock(data=[
        {"role": "USER", "content": "capek banget hari ini, pengen istirahat", "session_date": "2026-09-28"},
        {"role": "AI", "content": "Wajar jika merasa lelah. Istirahatlah.", "session_date": "2026-09-28"},
    ])
    mock_supabase.table().select().eq().gte().order().limit().execute.return_value = mock_logs_res

    res = cron_service.run_background_memory_condenser(user_id=DEV_USER_ID)
    assert res["status"] == "success"
    assert res["job"] == "background-memory-condenser"
    assert res["users_processed"] >= 1

    # Verify endpoint routing
    app.dependency_overrides[get_supabase_client] = lambda: mock_supabase
    with patch.object(CronService, "run_background_memory_condenser") as mock_condenser:
        mock_condenser.return_value = {"status": "success", "job": "background-memory-condenser"}
        resp = client.post(
            "/internal/cron/background-memory-condenser",
            headers={"X-Cron-Secret": "alur-dev-cron-secret-2026"},
        )
        assert resp.status_code == 200
        assert resp.json()["job"] == "background-memory-condenser"

    app.dependency_overrides.clear()
