from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_migrate import Migrate

from config import Config
from extensions import db, scheduler
from routes import auth_bp, tasks_bp, events_bp, db_manager_bp, stopwatch_bp


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    CORS(app, resources={r"/api/*": {"origins": "*"}})
    db.init_app(app)
    JWTManager(app)
    Migrate(app, db)

    app.register_blueprint(auth_bp)
    app.register_blueprint(tasks_bp)
    app.register_blueprint(events_bp)
    app.register_blueprint(db_manager_bp)
    app.register_blueprint(stopwatch_bp)

    with app.app_context():
        db.create_all()

    @app.get("/")
    def health():
        return jsonify({"status": "FloatNote API running"})

    return app


app = create_app()

if __name__ == "__main__":
    scheduler.start()
    try:
        app.run(host="0.0.0.0", port=5050, debug=True, use_reloader=False)
    finally:
        scheduler.shutdown()
