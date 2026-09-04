"""Async API client — รองรับทั้ง ASGI in-process และ HTTP จริง"""
import httpx
from httpx import AsyncClient, ASGITransport
from config.settings import BASE_URL, API_PREFIX, TIMEOUT, USE_ASGI

def get_client():
    """คืน AsyncClient ที่พร้อมใช้ — caller ต้อง async with"""
    if USE_ASGI:
        # in-process: ไม่ต้อง start server
        from app.main import app
        transport = ASGITransport(app=app)
        return AsyncClient(transport=transport, base_url="http://test", timeout=TIMEOUT)
    else:
        return AsyncClient(base_url=BASE_URL, timeout=TIMEOUT)

def api_url(path: str) -> str:
    """เติม prefix ให้ path — ใช้ได้ทั้งสองโหมด"""
    if not path.startswith("/"):
        path = "/" + path
    if path.startswith(API_PREFIX):
        return path
    # /health อยู่นอก prefix
    if path == "/health" or path.startswith("/uploads"):
        return path
    return f"{API_PREFIX}{path}"
