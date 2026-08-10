from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.core.config import settings
from app.core.rate_limit import limiter
from app.core.middleware import RequestIDMiddleware
from app.api.router import api_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: สร้างตาราง DB, โหลด Model, etc.
    print(f"[Startup] {settings.APP_NAME} v{settings.APP_VERSION}")
    yield
    # Shutdown: ปิด connections
    print("[Shutdown] Cleaning up...")

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Security Headers Middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    if settings.ENVIRONMENT == "production":
        response.headers["Content-Security-Policy"] = "default-src 'self'; img-src 'self' data: blob:;"
    return response

app.add_middleware(RequestIDMiddleware)

# CORS - อนุญาตให้ frontend เชื่อมต่อได้ (ปรับ origins สำหรับ production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in settings.ALLOWED_ORIGINS.split(",") if origin.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

# Serve uploaded media (raw images + heatmaps) so admin portal can preview them
uploads_dir = settings.LOCAL_UPLOAD_DIR
app.mount("/uploads", StaticFiles(directory=uploads_dir, check_dir=False), name="uploads")

from sqlalchemy import text
from app.core.database import async_session

@app.get("/health")
async def health_check():
    db_status = "ok"
    try:
        async with async_session() as session:
            await session.execute(text("SELECT 1"))
    except Exception:
        db_status = "error"
        
    return {
        "status": "ok" if db_status == "ok" else "degraded", 
        "version": settings.APP_VERSION,
        "database": db_status
    }
