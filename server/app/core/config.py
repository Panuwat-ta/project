from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict
from datetime import timezone, timedelta

PROJECT_ROOT = Path(__file__).resolve().parents[3]
SERVER_DIR = Path(__file__).resolve().parents[2]
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
    ALLOWED_ORIGINS: str

    # Database 
    DATABASE_URL: str

    # JWT Authentication 
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days

    # Redis Cache 
    REDIS_URL: str

    # Storage
    STORAGE_BACKEND: str = "local"  # "local" สำหรับ dev, "gcs" สำหรับ production
    LOCAL_UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE_MB: int = 20
    # Decompression-bomb guard: สูงสุดที่อนุญาต decode (พิกเซล)
    MAX_IMAGE_PIXELS: int = 100_000_000  # 100 MP

    # Risk scoring (ค่าเริ่มต้นของ source score)
    DEFAULT_SOURCE_SCORE: int = 20

    # AI Inference 
    ONNX_MODEL_PATH: str
    ONNX_TILE_SIZE: int = 512
    ONNX_TILE_OVERLAP: int = 64

    # Explainable AI (XAI) - Qwen2.5-1.5B (GGUF) 
    XAI_MODEL_PATH: str
    XAI_GPU_LAYERS: int = -1  # -1 = offload all layers to GPU
    XAI_CONTEXT_SIZE: int = 1024

    # Rate Limit
    RATE_LIMIT_PER_HOUR: int = 60

    model_config = SettingsConfigDict(
        env_file=(
            str(SERVER_DIR / ".env"),
            str(SERVER_DIR / ".env.local"),
            ".env",
            ".env.local",
        ),
        env_file_encoding="utf-8",
        extra="ignore",
    )

settings = Settings()
