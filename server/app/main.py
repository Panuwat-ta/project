from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.core.config import settings
from app.api.router import api_router

limiter = Limiter(key_func=get_remote_address, default_limits=[f"{settings.RATE_LIMIT_PER_HOUR}/hour"])

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

# CORS - อนุญาตให้ frontend เชื่อมต่อได้ (ปรับ origins สำหรับ production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    return {"status": "ok", "version": settings.APP_VERSION}
