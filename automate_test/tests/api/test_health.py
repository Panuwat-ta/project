"""Health & infra — รันได้แม้ DB/Redis ล่ม (assert degraded ได้)"""
import pytest
from helpers.api_client import get_client

@pytest.mark.api
@pytest.mark.asyncio
async def test_health_status():
    async with get_client() as client:
        r = await client.get("/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] in ("ok", "degraded")
    assert "version" in data
    assert "database" in data
    assert "redis" in data

@pytest.mark.api
@pytest.mark.asyncio
async def test_health_security_headers():
    async with get_client() as client:
        r = await client.get("/health")
    # ต้องมี security headers จาก middleware
    assert r.headers.get("x-content-type-options") == "nosniff"
    assert r.headers.get("x-frame-options") == "DENY"

@pytest.mark.api
@pytest.mark.asyncio
async def test_api_v1_not_found():
    async with get_client() as client:
        r = await client.get("/api/v1/nonexistent_route_xyz")
    assert r.status_code in (404, 405)
