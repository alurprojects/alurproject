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
