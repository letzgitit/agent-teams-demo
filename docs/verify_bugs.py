"""버그 재현용. 기대 동작을 단언하므로 버그가 살아 있는 동안은 실패한다."""
import sqlite3

import pytest

from app import create_app


@pytest.fixture
def ctx(tmp_path):
    path = str(tmp_path / "t.db")
    app = create_app(path)
    app.config["TESTING"] = True
    return app.test_client(), path


def test_search_is_not_sql_injectable(ctx):
    client, _ = ctx
    client.post("/todos", json={"title": "secret"})
    client.post("/todos", json={"title": "other"})
    # 정상 입력이라면 아무것도 안 맞아야 하는 검색어 — 주입되면 전부 나온다
    res = client.get("/todos/search", query_string={"q": "zzz' OR 1=1 --"})
    assert res.get_json() == []


def test_list_todos_does_not_query_per_row(ctx):
    client, path = ctx
    for i in range(10):
        client.post("/todos", json={"title": f"t{i}"})
    count = {"n": 0}
    # 요청 한 번에 나가는 SELECT 수를 센다 (연결을 가로채기 위해 db.get_db 를 감싼다)
    import app.routes as routes
    original = routes.get_db

    def traced():
        conn = original()
        conn.set_trace_callback(lambda s: count.__setitem__("n", count["n"] + (1 if s.lstrip().upper().startswith("SELECT") else 0)))
        return conn

    routes.get_db = traced
    try:
        count["n"] = 0
        client.get("/todos")
    finally:
        routes.get_db = original
    assert count["n"] <= 2, f"SELECT {count['n']}번 — 할 일 10개에 쿼리가 비례한다(N+1)"


def test_create_rejects_empty_title(ctx):
    client, _ = ctx
    assert client.post("/todos", json={"title": ""}).status_code == 400
    assert client.post("/todos", json={}).status_code == 400


def test_delete_removes_tags(ctx):
    client, path = ctx
    todo_id = client.post("/todos", json={"title": "x"}).get_json()["id"]
    conn = sqlite3.connect(path)
    conn.execute("INSERT INTO tags (todo_id, name) VALUES (?, 'a')", (todo_id,))
    conn.commit()
    client.delete(f"/todos/{todo_id}")
    left = conn.execute("SELECT COUNT(*) FROM tags WHERE todo_id = ?", (todo_id,)).fetchone()[0]
    conn.close()
    assert left == 0, "삭제한 할 일의 태그가 남았다(고아 행)"
