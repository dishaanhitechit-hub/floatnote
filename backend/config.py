import os
from dotenv import load_dotenv

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(BASE_DIR, '.env'))

class Config:
    # Use DATABASE_URL env var on Railway/Render, fallback to local SQLite
    _db_url = os.environ.get("DATABASE_URL", f"sqlite:///{os.path.join(BASE_DIR, 'floatnote.db')}")
    # Heroku/Railway uses postgres:// but SQLAlchemy needs postgresql://
    SQLALCHEMY_DATABASE_URI = _db_url.replace("postgres://", "postgresql://", 1)
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY     = os.environ.get("SECRET_KEY", "floatnote-dev-secret-2026")
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "floatnote-jwt-secret-2026")
    JWT_ACCESS_TOKEN_EXPIRES  = 60 * 60 * 24 * 7    # 7 days
    JWT_REFRESH_TOKEN_EXPIRES = 60 * 60 * 24 * 30   # 30 days
