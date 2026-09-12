import os

BASE_DIR = os.path.abspath(os.path.dirname(__file__))

class Config:
    # Use DATABASE_URL env var on Railway/Render, fallback to local SQLite
    _db_url = os.environ.get("DATABASE_URL", f"sqlite:///{os.path.join(BASE_DIR, 'floatnote.db')}")
    # Heroku/Railway uses postgres:// but SQLAlchemy needs postgresql://
    SQLALCHEMY_DATABASE_URI = _db_url.replace("postgres://", "postgresql://", 1)
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.environ.get("SECRET_KEY", "floatnote-dev-secret-2026")
