"""Cấu hình test: SQLite tạm, tắt log HTTP, seed profile mặc định qua lifespan."""

from __future__ import annotations

import os
import tempfile
import uuid

import pytest
from starlette.testclient import TestClient

# Phải set trước khi import app (settings + engine đọc env lúc import)
_db_fd, _DB_PATH = tempfile.mkstemp(suffix=".sqlite")
os.close(_db_fd)
os.environ["DATABASE_URL"] = f"sqlite:///{_DB_PATH}"
os.environ["CREATE_TABLES_ON_STARTUP"] = "true"
os.environ["HTTP_ACCESS_LOG"] = "false"
os.environ["HTTP_LOG_BODIES"] = "false"
os.environ["DEFAULT_PRESCRIPTION_USER_ID"] = "00000000-0000-0000-0000-000000000099"

from main import app  # noqa: E402


@pytest.fixture(scope="module")
def client() -> TestClient:
    with TestClient(app) as c:
        yield c


@pytest.fixture(scope="module")
def profile_id(client: TestClient) -> uuid.UUID:
    """Profile mới qua device-setup (tránh phụ thuộc seed demo)."""
    r = client.post("/api/v1/auth/device-setup", json={"full_name": "Pytest User"})
    assert r.status_code == 200, r.text
    return uuid.UUID(r.json()["user"]["id"])


def pytest_sessionfinish(session, exitstatus):  # noqa: ARG001
    try:
        os.unlink(_DB_PATH)
    except OSError:
        pass
