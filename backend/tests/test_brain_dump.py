from datetime import date
from fastapi.testclient import TestClient

from app.agents.scheduler import scheduler_agent
from app.agents.state import AlurState, DraftTask
from app.agents.validate_ambiguity import validate_ambiguity_fn
from app.main import app

client = TestClient(app)


def test_validate_ambiguity_rule():
    """Verify validate_ambiguity node marks tasks correctly without LLM call."""
    state: AlurState = {
        "draft_tasks": [
            DraftTask(title="Task with duration", estimated_minutes=45),
            DraftTask(title="Ambiguous task", estimated_minutes=None),
        ]
    }
    result = validate_ambiguity_fn(state)
    drafts = result["draft_tasks"]
    assert len(drafts) == 2
    assert drafts[0]["is_ambiguous"] is False
    assert drafts[1]["is_ambiguous"] is True


def test_scheduler_node_date_resolution():
    """Verify scheduler node resolves dates and respects daily capacity."""
    today = date(2026, 9, 15)  # Tuesday
    state: AlurState = {
        "today_date": today.isoformat(),
        "daily_capacity_minutes": 60,
        "existing_load_minutes_by_date": {
            "2026-09-15": 50,  # Only 10 mins remaining
        },
        "draft_tasks": [
            # 30 mins will exceed today's remaining 10 mins -> should shift to tomorrow (2026-09-16)
            DraftTask(title="Heavy task", estimated_minutes=30, preferred_day="today", is_ambiguous=False),
            # Tomorrow preferred
            DraftTask(title="Tomorrow task", estimated_minutes=15, preferred_day="tomorrow", is_ambiguous=False),
        ],
    }
    result = scheduler_agent(state)
    scheduled = result["scheduled_tasks"]
    assert len(scheduled) == 2
    assert scheduled[0]["assigned_date"] == "2026-09-16"
    assert scheduled[0]["source"] == "BRAIN_DUMP"
    assert scheduled[0]["ai_generated"] is True


def test_clarify_task_flow():
    """Verify task clarify endpoint updates duration and removes ambiguous flag."""
    today = date.today().isoformat()

    # 1. Create an ambiguous task
    create_res = client.post(
        "/tasks",
        json={
            "title": "Unclarified research task",
            "assigned_date": today,
            "estimated_minutes": None,
        },
    )
    assert create_res.status_code == 201
    task_id = create_res.json()["id"]
    assert create_res.json()["is_ambiguous"] is True
    assert create_res.json()["estimated_minutes"] is None

    # 2. Clarify with 30 minutes
    clarify_res = client.patch(
        f"/tasks/{task_id}/clarify",
        json={"estimated_minutes": 30},
    )
    assert clarify_res.status_code == 200
    clarified = clarify_res.json()
    assert clarified["is_ambiguous"] is False
    assert clarified["estimated_minutes"] == 30

    # 3. Clean up
    client.delete(f"/tasks/{task_id}")


def test_brain_dump_endpoint():
    """Verify POST /brain-dump processes input text and creates tasks."""
    res = client.post(
        "/brain-dump",
        json={"text": "Lari pagi 30 menit, terus beli kopi, sama riset desain to-do app"},
    )
    assert res.status_code == 201, res.text
    tasks = res.json()
    assert isinstance(tasks, list)
    assert len(tasks) >= 1

    # Cleanup created tasks
    for t in tasks:
        assert t["source"] == "BRAIN_DUMP"
        assert t["ai_generated"] is True
        client.delete(f"/tasks/{t['id']}")
