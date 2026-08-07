import secrets
from pydantic_settings import BaseSettings, SettingsConfigDict
from datetime import timezone, timedelta

TH_TIMEZONE = timezone(timedelta(hours=7), name="Asia/Bangkok")
class Settings(BaseSettings):
    # App
    APP_NAME: str = "ScamGuard API"
    APP_VERSION: str = "0.1.0"
    # DEBUG: SQL echo = DEBUG (dev). รองการ echo SQL ใน production
    DEBUG: bool = False
    SQL_ECHO: bool = False

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://scamguard:password@localhost:5432/scamguard_db"

    # JWT
    JWT_SECRET_KEY: str = secrets.token_urlsafe(64)
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Storage
    STORAGE_BACKEND: str = "local"  # "local" สำหรับ dev, "gcs" สำหรับ production
    LOCAL_UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE_MB: int = 10

    # Risk scoring (ค่าเริ่มต้นของ source score)
    DEFAULT_SOURCE_SCORE: int = 20

    # AI Inference
    ONNX_MODEL_PATH: str = "/home/panuwat/project/model/segformer/work_dirs/v1.0.0/segformer_v1.onnx"

    # Rate Limit
    RATE_LIMIT_PER_HOUR: int = 60

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

settings = Settings()
