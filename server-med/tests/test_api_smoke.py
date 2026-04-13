"""Smoke + CRUD API — chạy: pytest tests/ -v (từ thư mục server-med, venv bật)."""

from __future__ import annotations

import uuid
from datetime import date, datetime, timezone

import pytest


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_ping(client):
    r = client.get("/api/v1/ping")
    assert r.status_code == 200
    assert r.json().get("pong") is True


def test_profile_snapshot(client, profile_id):
    r = client.get(f"/api/v1/profiles/{profile_id}/snapshot")
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["profile"]["profile_id"] == str(profile_id)
    assert "medication_cabinet" in body
    assert "medication_logs_recent" in body
    assert "memories" in body
    assert "adherence_summary" in body
    assert body["adherence_summary"]["profile_id"] == str(profile_id)


def test_profile_agent_context_refresh_and_get(client, profile_id):
    r0 = client.get(f"/api/v1/profiles/{profile_id}/agent-context")
    # device-setup đã auto-làm mới agent context
    assert r0.status_code == 200, r0.text
    assert "Ngữ cảnh agent" in r0.json()["content_markdown"]

    r1 = client.post(f"/api/v1/profiles/{profile_id}/agent-context/refresh")
    assert r1.status_code == 200, r1.text
    data = r1.json()
    assert data["profile_id"] == str(profile_id)
    assert "Ngữ cảnh agent" in data["content_markdown"]
    assert data["char_count"] > 20
    assert data["source"] == "snapshot_derived"

    r2 = client.get(f"/api/v1/profiles/{profile_id}/agent-context")
    assert r2.status_code == 200, r2.text
    assert r2.json()["char_count"] == data["char_count"]


def test_profile_get_patch(client, profile_id):
    r = client.get(f"/api/v1/profiles/{profile_id}")
    assert r.status_code == 200
    assert r.json()["full_name"] == "Pytest User"

    r2 = client.patch(
        f"/api/v1/profiles/{profile_id}",
        json={"phone_number": "0900000000"},
    )
    assert r2.status_code == 200
    assert r2.json()["phone_number"] == "0900000000"


def test_medical_categories_and_records(client, profile_id):
    r = client.get("/api/v1/medical-records/categories")
    assert r.status_code == 200
    cats = r.json()
    assert isinstance(cats, list)

    r = client.post(
        "/api/v1/medical-records",
        json={
            "profile_id": str(profile_id),
            "disease_name": "Tăng huyết áp",
            "treatment_start_date": "2025-01-15",
            "treatment_status": "active",
        },
    )
    assert r.status_code == 201, r.text
    rid = r.json()["record_id"]

    r = client.get(f"/api/v1/medical-records/{rid}")
    assert r.status_code == 200

    r = client.patch(
        f"/api/v1/medical-records/{rid}",
        json={"notes": "Theo dõi hàng tuần"},
    )
    assert r.status_code == 200
    assert r.json()["notes"] == "Theo dõi hàng tuần"

    r = client.get("/api/v1/medical-records", params={"profile_id": str(profile_id)})
    assert r.status_code == 200
    assert len(r.json()["items"]) >= 1

    r = client.delete(f"/api/v1/medical-records/{rid}")
    assert r.status_code == 204


def test_habits_crud(client, profile_id):
    r = client.post(
        "/api/v1/habits/categories",
        json={"category_name": "Vận động", "description": "Test"},
    )
    assert r.status_code == 201, r.text
    cat_id = r.json()["category_id"]

    r = client.post(
        "/api/v1/habits",
        json={
            "profile_id": str(profile_id),
            "habit_name": "Đi bộ",
            "category_id": cat_id,
            "status": "active",
            "reminders": [{"reminder_time": "07:00", "repeat_frequency": "daily"}],
        },
    )
    assert r.status_code == 201, r.text
    hid = r.json()["habit_id"]

    r = client.get(f"/api/v1/habits/{hid}")
    assert r.status_code == 200

    r = client.post(
        f"/api/v1/habits/{hid}/logs",
        json={
            "profile_id": str(profile_id),
            "scheduled_datetime": "2026-04-01T07:00:00+00:00",
            "status": "completed",
        },
    )
    assert r.status_code == 201, r.text

    r = client.get(f"/api/v1/habits/{hid}/logs")
    assert r.status_code == 200
    assert len(r.json()["items"]) >= 1

    r = client.delete(f"/api/v1/habits/{hid}")
    assert r.status_code == 204


def test_care_links_and_groups(client, profile_id):
    r = client.post("/api/v1/auth/device-setup", json={"full_name": "Caregiver"})
    assert r.status_code == 200
    cg_id = uuid.UUID(r.json()["user"]["id"])

    r = client.post(
        "/api/v1/care/links",
        json={
            "patient_id": str(profile_id),
            "caregiver_id": str(cg_id),
            "relationship": "con",
            "permission_level": "view",
        },
    )
    assert r.status_code == 201, r.text
    link_id = r.json()["link_id"]

    r = client.get("/api/v1/care/links", params={"profile_id": str(profile_id)})
    assert r.status_code == 200
    assert any(x["link_id"] == link_id for x in r.json())

    r = client.delete(f"/api/v1/care/links/{link_id}")
    assert r.status_code == 204

    r = client.post(
        "/api/v1/care/groups",
        json={
            "group_name": "Gia đình A",
            "description": "Test",
            "created_by_profile_id": str(profile_id),
        },
    )
    assert r.status_code == 201, r.text
    gid = r.json()["group_id"]

    r = client.post(
        f"/api/v1/care/groups/{gid}/members",
        json={"profile_id": str(cg_id), "role": "member"},
    )
    assert r.status_code == 201, r.text

    r = client.delete(f"/api/v1/care/groups/{gid}")
    assert r.status_code == 204


def test_notifications(client, profile_id):
    r = client.post(
        "/api/v1/notifications",
        json={
            "profile_id": str(profile_id),
            "notification_type": "test",
            "title": "Hello",
            "message": "Body",
        },
    )
    assert r.status_code == 201, r.text
    nid = r.json()["notification_id"]

    r = client.get("/api/v1/notifications", params={"profile_id": str(profile_id)})
    assert r.status_code == 200
    assert r.json()["unread_count"] >= 1

    r = client.patch(f"/api/v1/notifications/{nid}/read")
    assert r.status_code == 200

    r = client.delete(f"/api/v1/notifications/{nid}")
    assert r.status_code == 204


def test_memory_upsert(client, profile_id):
    key = "allergy"
    r = client.put(
        f"/api/v1/memory/{key}",
        params={"profile_id": str(profile_id)},
        json={"key": key, "value": {"items": ["penicillin"]}, "source": "test"},
    )
    assert r.status_code == 200, r.text

    r = client.get(f"/api/v1/memory/{key}", params={"profile_id": str(profile_id)})
    assert r.status_code == 200
    assert r.json()["value"]["items"] == ["penicillin"]

    r = client.delete(f"/api/v1/memory/{key}", params={"profile_id": str(profile_id)})
    assert r.status_code == 204


def test_reports_list_and_generate(client, profile_id):
    r = client.get("/api/v1/reports", params={"profile_id": str(profile_id)})
    assert r.status_code == 200
    assert "items" in r.json()

    r = client.post(
        "/api/v1/reports/generate",
        json={
            "profile_id": str(profile_id),
            "report_type": "weekly",
            "period_start": "2026-03-01",
            "period_end": "2026-03-31",
        },
    )
    assert r.status_code == 201, r.text
    rep_id = r.json()["report_id"]

    r = client.delete(f"/api/v1/reports/{rep_id}")
    assert r.status_code == 204


def test_agent_tools_list(client):
    r = client.get("/api/v1/agent/tools")
    assert r.status_code == 200
    body = r.json()
    assert "tools" in body
    assert len(body["tools"]) >= 1


def test_chat_welcome_hints(client, profile_id):
    r = client.get(
        "/api/v1/chat/welcome-hints",
        params={"profile_id": str(profile_id)},
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert isinstance(data.get("hints"), list)
    assert len(data["hints"]) >= 1
    assert data.get("source") in ("llm", "template")


def test_chat_suggested_questions(client, profile_id):
    r = client.get(
        "/api/v1/chat/suggested-questions",
        params={"profile_id": str(profile_id)},
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert isinstance(data.get("questions"), list)
    assert len(data["questions"]) >= 1
    assert data.get("source") in ("llm", "template")
