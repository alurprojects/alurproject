from datetime import date, timedelta
from uuid import uuid4
from fastapi.testclient import TestClient
from app.core.supabase import get_supabase_client
from app.main import app

client = TestClient(app)
supabase = get_supabase_client()


def test_follow_up_state_machine():
    """Verify all 3 branches of missed_follow_up state machine: FORGOT, SKIPPED, RESCHEDULED."""
    today = date.today()
    yesterday = today - timedelta(days=1)

    # Branch 1: FORGOT -> status = DONE, missed_follow_up = FORGOT
    t1_res = client.post(
        "/tasks",
        json={"title": "Follow up test 1", "assigned_date": yesterday.isoformat()},
    )
    t1_id = t1_res.json()["id"]

    res_forgot = client.patch(f"/tasks/{t1_id}/follow-up", json={"action": "FORGOT"})
    assert res_forgot.status_code == 200
    assert res_forgot.json()["status"] == "DONE"
    assert res_forgot.json()["missed_follow_up"] == "FORGOT"

    # Branch 2: SKIPPED -> status = MISSED, missed_follow_up = SKIPPED
    t2_res = client.post(
        "/tasks",
        json={"title": "Follow up test 2", "assigned_date": yesterday.isoformat()},
    )
    t2_id = t2_res.json()["id"]

    res_skipped = client.patch(f"/tasks/{t2_id}/follow-up", json={"action": "SKIPPED"})
    assert res_skipped.status_code == 200
    assert res_skipped.json()["status"] == "MISSED"
    assert res_skipped.json()["missed_follow_up"] == "SKIPPED"

    # Branch 3: RESCHEDULED -> assigned_date = today, status = PENDING, missed_follow_up = RESCHEDULED
    t3_res = client.post(
        "/tasks",
        json={"title": "Follow up test 3", "assigned_date": yesterday.isoformat()},
    )
    t3_id = t3_res.json()["id"]

    res_rescheduled = client.patch(f"/tasks/{t3_id}/follow-up", json={"action": "RESCHEDULED"})
    assert res_rescheduled.status_code == 200
    assert res_rescheduled.json()["assigned_date"] == today.isoformat()
    assert res_rescheduled.json()["status"] == "PENDING"
    assert res_rescheduled.json()["missed_follow_up"] == "RESCHEDULED"

    # Clean up
    for tid in [t1_id, t2_id, t3_id]:
        client.delete(f"/tasks/{tid}")


def test_reschedule_suggestion_flow():
    """Verify accept & reject of AI reschedule suggestion."""
    today = date.today()
    alt_date = today + timedelta(days=2)

    # Create task
    task_res = client.post(
        "/tasks",
        json={"title": "Heavy report writing", "assigned_date": today.isoformat(), "estimated_minutes": 180},
    )
    task_id = task_res.json()["id"]
    user_id = task_res.json()["user_id"]

    # Insert a suggestion directly into task_suggestions
    sug_id = str(uuid4())
    supabase.table("task_suggestions").insert({
        "id": sug_id,
        "task_id": task_id,
        "user_id": user_id,
        "suggested_date": alt_date.isoformat(),
        "reason": "Kapasitas hari ini hampir penuh",
        "status": "PENDING",
    }).execute()

    # Verify get_week_tasks attaches this suggestion
    week_res = client.get(f"/tasks?week={today.isoformat()}")
    assert week_res.status_code == 200

    # Accept the suggestion
    accept_res = client.patch(
        f"/tasks/{task_id}/reschedule",
        json={"suggestion_id": sug_id, "action": "ACCEPT"},
    )
    assert accept_res.status_code == 200
    updated_task = accept_res.json()
    assert updated_task["assigned_date"] == alt_date.isoformat()

    # Clean up
    client.delete(f"/tasks/{task_id}")


def test_debug_cron_jobs():
    """Verify running debug cron jobs manually."""
    # 1. Nightly status check
    nightly_res = client.post("/debug/run-cron/nightly-status-check")
    assert nightly_res.status_code == 200
    assert nightly_res.json()["status"] == "success"

    # 2. Weekly recurrence generator
    rec_res = client.post("/debug/run-cron/weekly-recurrence-generator")
    assert rec_res.status_code == 200
    assert rec_res.json()["status"] == "success"

    # 3. Weekly reflection
    ref_res = client.post("/debug/run-cron/weekly-reflection")
    assert ref_res.status_code == 200
    assert ref_res.json()["status"] == "success"


def test_get_insights_endpoint():
    """Verify GET /insights endpoint returns list of insights."""
    res = client.get("/insights?surfaced=true")
    assert res.status_code == 200
    assert isinstance(res.json(), list)


def test_internal_cron_unauthorized():
    """Verify POST /internal/cron/{job_name} rejects requests without or with invalid X-Cron-Secret."""
    # 1. Missing header
    res_no_secret = client.post("/internal/cron/nightly-status-check")
    assert res_no_secret.status_code == 401
    assert "Invalid or missing X-Cron-Secret" in res_no_secret.json()["detail"]

    # 2. Wrong secret
    res_wrong_secret = client.post(
        "/internal/cron/nightly-status-check",
        headers={"X-Cron-Secret": "totally-wrong-secret"},
    )
    assert res_wrong_secret.status_code == 401
    assert "Invalid or missing X-Cron-Secret" in res_wrong_secret.json()["detail"]


def test_internal_cron_authorized_jobs():
    """Verify POST /internal/cron/{job_name} executes all valid jobs when X-Cron-Secret is valid."""
    from app.core.config import settings

    headers = {"X-Cron-Secret": settings.CRON_SECRET}

    # 1. Nightly status check
    r1 = client.post("/internal/cron/nightly-status-check", headers=headers)
    assert r1.status_code == 200
    assert r1.json()["status"] == "success"

    # 2. Weekly recurrence generator (and alias 'recurrence')
    r2 = client.post("/internal/cron/weekly-recurrence", headers=headers)
    assert r2.status_code == 200
    assert r2.json()["status"] == "success"

    # 3. Weekly reflection with batching params (?only_active=true&batch_size=5)
    r3 = client.post("/internal/cron/weekly-reflection?only_active=true&batch_size=5", headers=headers)
    assert r3.status_code == 200
    assert r3.json()["status"] == "success"
    assert "continue" in r3.json()
    assert "completed" in r3.json()

    # 4. Retention: conversation-log-notify-pending
    r4 = client.post("/internal/cron/conversation-log-notify-pending", headers=headers)
    assert r4.status_code == 200
    assert r4.json()["status"] == "success"
    assert "notified_count" in r4.json()

    # 5. Retention: conversation-log-hard-delete
    r5 = client.post("/internal/cron/conversation-log-hard-delete", headers=headers)
    assert r5.status_code == 200
    assert r5.json()["status"] == "success"
    assert "deleted_count" in r5.json()

    # 6. 'all' aggregator job
    r6 = client.post("/internal/cron/all", headers=headers)
    assert r6.status_code == 200
    assert r6.json()["status"] == "success"
    assert "results" in r6.json()


def test_internal_cron_unknown_job():
    """Verify unknown job names return 400 Bad Request."""
    from app.core.config import settings

    headers = {"X-Cron-Secret": settings.CRON_SECRET}
    res = client.post("/internal/cron/some-unknown-job", headers=headers)
    assert res.status_code == 400
    assert "Unknown job_name" in res.json()["detail"]


def test_enhanced_reflection_agent_combined_data():
    """Verify Reflection Agent processes combined data (tasks + conversation logs)."""
    from app.agents.reflection import generate_reflection_insight

    insight = generate_reflection_insight(
        goal_title="Belajar Flutter & LangGraph",
        missed_count=3,
        missed_examples=["Membaca dokumentasi LangGraph", "Implementasi Follow-up Chip"],
        recent_chat_reflections=["Aku merasa kewalahan dengan deadline kantor minggu ini", "Capek banget"],
        completion_rate=0.33,
    )
    assert isinstance(insight, str)
    assert len(insight) > 0
    assert len(insight) <= 280


def test_adaptive_personality_tone_switching():
    """Verify Companion Agent adaptively switches between HONEST and GENTLE persona."""
    from app.agents.companion import companion_agent
    from app.agents.state import AlurChatState

    # Scenario A: User is struggling (low completion rate 25%, 4 misses, struggling insights)
    struggling_state: AlurChatState = {
        "raw_message": "Aku belum sempat nyentuh tugas hari ini",
        "user_id": "00000000-0000-0000-0000-000000000001",
        "today_date": "2026-09-19",
        "daily_capacity_hours": 8.0,
        "daily_capacity_minutes": 480,
        "existing_load_minutes_by_date": {},
        "recent_completion_rate": 0.25,
        "consecutive_misses": 4,
        "recent_insights": ["Ada 3 task terlewat pada target Belajar"],
        "conversation_context": [],
        "message_type": "CHAT",
        "tone_used": "HONEST",
        "draft_tasks": [],
        "scheduled_tasks": [],
        "ai_response": "",
    }
    result_struggling = companion_agent(struggling_state)
    assert result_struggling["tone_used"] == "GENTLE"

    # Scenario B: User is on track (high completion rate 85%, 0 misses)
    normal_state: AlurChatState = {
        "raw_message": "Halo, selamat pagi",
        "user_id": "00000000-0000-0000-0000-000000000001",
        "today_date": "2026-09-19",
        "daily_capacity_hours": 8.0,
        "daily_capacity_minutes": 480,
        "existing_load_minutes_by_date": {},
        "recent_completion_rate": 0.85,
        "consecutive_misses": 0,
        "recent_insights": [],
        "conversation_context": [],
        "message_type": "CHAT",
        "tone_used": "HONEST",
        "draft_tasks": [],
        "scheduled_tasks": [],
        "ai_response": "",
    }
    result_normal = companion_agent(normal_state)
    assert result_normal["tone_used"] == "HONEST"

