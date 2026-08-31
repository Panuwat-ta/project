import secrets
from pydantic_settings import BaseSettings, SettingsConfigDict
from datetime import timezone, timedelta

TH_TIMEZONE = timezone(timedelta(hours=7), name="Asia/Bangkok")
class Settings(BaseSettings):
    # App
    APP_NAME: str = "ScamGuard API"
    APP_VERSION: str = "0.1.0"
    ENVIRONMENT: str = "development"
    # DEBUG: SQL echo = DEBUG (dev). รองการ echo SQL ใน production
    DEBUG: bool = False
    SQL_ECHO: bool = False
    
    # Security
    SECURE_COOKIES: bool = False
    ALLOWED_ORIGINS: str = "http://localhost:5173,http://127.0.0.1:5173,http://localhost:59913,*"

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
    MAX_UPLOAD_SIZE_MB: int = 20
    # Decompression-bomb guard: สูงสุดที่อนุญาต decode (พิกเซล)
    MAX_IMAGE_PIXELS: int = 100_000_000  # 100 MP

    # Risk scoring (ค่าเริ่มต้นของ source score)
    DEFAULT_SOURCE_SCORE: int = 20

    # AI Inference
    ONNX_MODEL_PATH: str = "/home/panuwat/project/model/segformer/work_dirs/v1.0.0/segformer_v1_dynamic.onnx"
    ONNX_TILE_SIZE: int = 512
    ONNX_TILE_OVERLAP: int = 64

    # Rate Limit
    RATE_LIMIT_PER_HOUR: int = 60

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
