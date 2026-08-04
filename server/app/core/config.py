from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # App
    APP_NAME: str = "ScamGuard API"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://scamguard:password@localhost:5432/scamguard_db"

    # JWT
    JWT_SECRET_KEY: str = "change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Storage
    STORAGE_BACKEND: str = "local"  # "local" สำหรับ dev, "gcs" สำหรับ production
    LOCAL_UPLOAD_DIR: str = "./uploads"

    # AI Inference
    ONNX_MODEL_PATH: str = "/home/panuwat/project/model/segformer/work_dirs/v1.0.0/segformer_v1.onnx"

    # Rate Limit
    RATE_LIMIT_PER_HOUR: int = 60

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

settings = Settings()
