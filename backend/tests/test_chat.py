from datetime import date, datetime, timezone
from unittest.mock import MagicMock, patch
from uuid import UUID, uuid4
import pytest
from fastapi.testclient import TestClient

from app.agents.companion import companion_agent
from app.agents.state import AlurChatState
from app.main import app

client = TestClient(app)

TEST_USER_ID = UUID("00000000-0000-0000-0000-000000000001")


def test_companion_agent_tone_and_classification():
    """Verify Companion Agent's 2-Tone Persona (HONEST vs GENTLE) and classification."""
    # 1. Normal task capture message should classify as TASK_CAPTURE and HONEST tone
    state_task: AlurChatState = {
        "raw_message": "besok aku harus kirim invoice jam 10 pagi",
        "user_id": str(TEST_USER_ID),
        "today_date": "2026-09-18",
        "daily_capacity_hours": 8.0,
        "consecutive_misses": 0,
        "recent_completion_rate": 0.8,
        "conversation_context": [],
    }
    res_task = companion_agent(state_task)
    assert res_task["message_type"] == "TASK_CAPTURE"
    assert res_task["tone_used"] == "HONEST"

    # 2. Burnout / overload message should classify as REFLECTION and GENTLE tone
    state_burnout: AlurChatState = {
        "raw_message": "aku capek banget hari ini pusing overwhelmed sama kerjaan",
        "user_id": str(TEST_USER_ID),
        "today_date": "2026-09-18",
        "daily_capacity_hours": 8.0,
        "consecutive_misses": 3,
        "recent_completion_rate": 0.2,
        "conversation_context": [],
    }
    res_burnout = companion_agent(state_burnout)
    assert res_burnout["message_type"] == "REFLECTION"
    assert res_burnout["tone_used"] == "GENTLE"
    assert res_burnout.get("mood_detected") == "overload"
    assert "kapasitas harianmu" in res_burnout["ai_response"].lower()

    # 3. Capacity query
    state_capacity: AlurChatState = {
        "raw_message": "cek sisa kapasitas hari ini",
        "user_id": str(TEST_USER_ID),
        "today_date": "2026-09-18",
        "daily_capacity_hours": 6.0,
        "existing_load_minutes_by_date": {"2026-09-18": 120},
        "consecutive_misses": 0,
        "conversation_context": [],
    }
    res_capacity = companion_agent(state_capacity)
    assert res_capacity["message_type"] == "CAPACITY_QUERY"
    assert "kapasitas" in res_capacity["ai_response"].lower()


@patch("app.agents.graph.chat_graph.invoke")
def test_send_chat_message_endpoint(mock_invoke):
    """Test POST /chat/message with mock LangGraph result."""
    task_id = str(uuid4())
    mock_invoke.return_value = {
        "message_type": "TASK_CAPTURE",
        "tone_used": "HONEST",
        "mood_detected": None,
        "ai_response": "Saya telah mencatat dan menjadwalkan tugasmu.",
        "scheduled_tasks": [
            {
                "id": task_id,
                "title": "Beli domain baru",
                "estimated_minutes": 30,
                "assigned_date": "2026-09-19",
                "is_ambiguous": False,
                "source": "CHAT_ROOM",
                "ai_generated": True,
                "status": "PENDING",
                "missed_follow_up": "NONE",
            }
        ],
    }

    payload = {"message": "besok beli domain baru 30 menit"}
    headers = {"X-User-Id": str(TEST_USER_ID)}

    with patch("app.core.supabase.get_supabase_client") as mock_get_client:
        mock_supabase = MagicMock()
        # Mock users query
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"daily_capacity_hours": 8.0, "timezone": "Asia/Jakarta"}
        ]
        # Mock tasks insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [
            {
                "id": task_id,
                "user_id": str(TEST_USER_ID),
                "title": "Beli domain baru",
                "estimated_minutes": 30,
                "assigned_date": "2026-09-19",
                "is_ambiguous": False,
                "source": "CHAT_ROOM",
                "ai_generated": True,
                "status": "PENDING",
                "missed_follow_up": "NONE",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }
        ]
        mock_get_client.return_value = mock_supabase

        response = client.post("/chat/message", json=payload, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["message_type"] == "TASK_CAPTURE"
        assert data["tone_used"] == "HONEST"
        assert "tugasmu" in data["reply"]


from app.core.supabase import get_supabase_client


def test_get_chat_history_endpoint():
    """Test GET /chat/history returns conversation logs."""
    headers = {"X-User-Id": str(TEST_USER_ID)}
    mock_logs = [
        {
            "id": str(uuid4()),
            "user_id": str(TEST_USER_ID),
            "role": "USER",
            "content": "Halo apa kabar",
            "message_type": "CHAT",
            "extracted_task_ids": [],
            "tone_used": None,
            "mood_detected": None,
            "session_date": "2026-09-18",
            "created_at": datetime.now(timezone.utc).isoformat(),
        },
        {
            "id": str(uuid4()),
            "user_id": str(TEST_USER_ID),
            "role": "AI",
            "content": "Halo! Ada yang bisa dibantu?",
            "message_type": "CHAT",
            "extracted_task_ids": [],
            "tone_used": "HONEST",
            "mood_detected": None,
            "session_date": "2026-09-18",
            "created_at": datetime.now(timezone.utc).isoformat(),
        },
    ]

    mock_supabase = MagicMock()
    mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = mock_logs
    app.dependency_overrides[get_supabase_client] = lambda: mock_supabase

    try:
        response = client.get("/chat/history", headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["role"] == "USER"
        assert data[1]["role"] == "AI"
    finally:
        app.dependency_overrides.clear()


def test_retention_endpoints():
    """Test Data Retention: export, retention-override, and delete."""
    headers = {"X-User-Id": str(TEST_USER_ID)}
    log_id = str(uuid4())

    mock_supabase = MagicMock()

    # 1. Export
    mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [
        {
            "id": log_id,
            "user_id": str(TEST_USER_ID),
            "role": "USER",
            "content": "Pesan penting",
            "message_type": "CHAT",
            "extracted_task_ids": [],
            "session_date": "2026-09-18",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
    ]
    app.dependency_overrides[get_supabase_client] = lambda: mock_supabase

    try:
        export_res = client.post("/chat/history/export", headers=headers)
        assert export_res.status_code == 200
        export_data = export_res.json()
        assert export_data["total_messages"] == 1
        assert export_data["logs"][0]["content"] == "Pesan penting"

        # 2. Retention Override
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [
            {"id": log_id, "retention_override": True}
        ]
        override_res = client.patch(
            "/chat/history/retention-override",
            json={"retention_override": True},
            headers=headers,
        )
        assert override_res.status_code == 200
        assert override_res.json()["success"] is True

        # 3. Delete All History
        mock_supabase.table.return_value.delete.return_value.eq.return_value.execute.return_value.data = [
            {"id": log_id}
        ]
        delete_res = client.delete("/chat/history", headers=headers)
        assert delete_res.status_code == 200
        assert delete_res.json()["success"] is True
        assert delete_res.json()["count"] == 1
    finally:
        app.dependency_overrides.clear()
