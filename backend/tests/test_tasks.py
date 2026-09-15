from datetime import date
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_check():
    """Verify health endpoint returns status healthy."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "alur-backend"


def test_root_endpoint():
    """Verify root endpoint returns API overview."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["app"] == "ALUR"


def test_tasks_crud_flow():
    """Test full task lifecycle: create -> get weekly -> update status -> delete."""
    today = date.today().isoformat()

    # 1. Create a task
    create_payload = {
        "title": "Review PRD & test weekly accordion",
        "assigned_date": today,
        "estimated_minutes": 45,
    }
    create_res = client.post("/tasks", json=create_payload)
    assert create_res.status_code == 201, create_res.text
    task_data = create_res.json()

    task_id = task_data["id"]
    assert task_data["title"] == "Review PRD & test weekly accordion"
    assert task_data["status"] == "PENDING"
    assert task_data["is_ambiguous"] is False
    assert task_data["estimated_minutes"] == 45

    # 2. Fetch weekly tasks
    get_res = client.get(f"/tasks?week={today}")
    assert get_res.status_code == 200
    week_data = get_res.json()
    assert len(week_data["days"]) == 7

    # Find the day containing our newly created task
    found = False
    for day in week_data["days"]:
        if day["date"] == today:
            assert any(t["id"] == task_id for t in day["tasks"])
            found = True
            break
    assert found, "Created task should appear on its assigned_date"

    # 3. Toggle task status to DONE
    patch_res = client.patch(f"/tasks/{task_id}", json={"status": "DONE"})
    assert patch_res.status_code == 200
    updated_task = patch_res.json()
    assert updated_task["status"] == "DONE"

    # 4. Clean up - delete task
    del_res = client.delete(f"/tasks/{task_id}")
    assert del_res.status_code == 204
