"""Smoke tests: verify routes are reachable."""


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_docs_redirect(client):
    r = client.get("/", follow_redirects=False)
    assert r.status_code in (200, 307)


def test_agent_tools(client):
    r = client.get("/api/v1/agent/tools")
    assert r.status_code == 200
    data = r.json()
    assert "tools" in data
    assert len(data["tools"]) > 0
