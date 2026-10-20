import pytest

from app import create_app


@pytest.fixture
def client(tmp_path):
    app = create_app(str(tmp_path / "test.db"))
    app.config["TESTING"] = True
    return app.test_client()


def test_list_empty(client):
    res = client.get("/todos")
    assert res.status_code == 200
    assert res.get_json() == []


def test_create_then_list(client):
    res = client.post("/todos", json={"title": "buy milk"})
    assert res.status_code == 201
    assert res.get_json()["title"] == "buy milk"

    todos = client.get("/todos").get_json()
    assert [t["title"] for t in todos] == ["buy milk"]
    assert todos[0]["done"] == 0
    assert todos[0]["tags"] == []


def test_search_finds_match(client):
    client.post("/todos", json={"title": "buy milk"})
    client.post("/todos", json={"title": "walk dog"})
    res = client.get("/todos/search?q=milk")
    assert [t["title"] for t in res.get_json()] == ["buy milk"]
