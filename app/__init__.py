from flask import Flask

from app import db
from app.routes import bp


def create_app(db_path="todos.db"):
    app = Flask(__name__)
    app.config["DB_PATH"] = db_path
    app.teardown_appcontext(db.close_db)
    app.register_blueprint(bp)
    with app.app_context():
        db.init_db()
    return app
