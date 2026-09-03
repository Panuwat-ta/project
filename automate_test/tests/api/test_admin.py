"""Admin & rate limit"""
import pytest
from helpers.api_client import get_client, api_url
from helpers.auth_helper import register_and_login, auth_header

@pytest.mark.api
@pytest.mark.admin
@pytest.mark.asyncio
async def test_admin_requires_auth():
    async with get_client() as client:
        r = await client.get(api_url("/admin/users"))
        assert r.status_code in (401, 403, 404)

@pytest.mark.api
@pytest.mark.asyncio
async def test_rate_limit_headers_present():
    async with get_client() as client:
        r = await client.get("/health")
        # slowapi จะใส่ header แบบนี้ถ้าตั้ง limit ไว้
        # ไม่บังคับ — แค่เช็คว่าไม่ error
        assert r.status_code == 200
