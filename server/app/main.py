from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.core.config import settings
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

app.include_router(api_router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    return {"status": "ok", "version": settings.APP_VERSION}
