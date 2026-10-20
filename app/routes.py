from flask import Blueprint, jsonify, request

from app.db import get_db

bp = Blueprint("todos", __name__)


@bp.get("/todos")
def list_todos():
    db = get_db()
    todos = [dict(r) for r in db.execute("SELECT id, title, done FROM todos").fetchall()]
    for t in todos:
        t["tags"] = [r["name"] for r in db.execute(
            "SELECT name FROM tags WHERE todo_id = ?", (t["id"],)).fetchall()]
    return jsonify(todos)


@bp.get("/todos/search")
def search():
    q = request.args.get("q", "")
    rows = get_db().execute(
        f"SELECT id, title, done FROM todos WHERE title LIKE '%{q}%'").fetchall()
    return jsonify([dict(r) for r in rows])


@bp.post("/todos")
def create():
    title = request.get_json().get("title")
    db = get_db()
    cur = db.execute("INSERT INTO todos (title, done) VALUES (?, 0)", (title,))
    db.commit()
    return jsonify({"id": cur.lastrowid, "title": title}), 201


@bp.delete("/todos/<int:todo_id>")
def delete(todo_id):
    db = get_db()
    db.execute("DELETE FROM todos WHERE id = ?", (todo_id,))
    db.commit()
    return "", 204
