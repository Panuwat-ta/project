"""Auth flow — register / login / me / refresh"""
import uuid
import pytest
from helpers.api_client import get_client, api_url
from helpers.auth_helper import register_and_login, auth_header

@pytest.mark.api
@pytest.mark.asyncio
async def test_register_login_me_flow():
    email = f"auto_{uuid.uuid4().hex[:8]}@example.com"
    pwd = "Test1234!@#"

    async with get_client() as client:
        # register — ต้องส่ง full_name + consents
        r = await client.post(api_url("/auth/register"), json={
            "email": email, "password": pwd, "full_name": "Auto",
            "system_consent": True, "research_consent": False,
        })
        assert r.status_code in (200, 201), r.text

        # login — form-encoded username/password
        r = await client.post(api_url("/auth/login"),
            data={"username": email, "password": pwd},
            headers={"Content-Type": "application/x-www-form-urlencoded"})
        assert r.status_code == 200, r.text
        data = r.json()
        token = data.get("access_token") or data.get("token")
        assert token, data

        # me
        r = await client.get(api_url("/auth/me"), headers=auth_header(token))
        assert r.status_code == 200, r.text
        assert r.json().get("email") == email or "id" in r.json()

@pytest.mark.api
@pytest.mark.asyncio
async def test_login_wrong_password():
    user = await register_and_login()
    async with get_client() as client:
        r = await client.post(api_url("/auth/login"),
            data={"username": user["email"], "password": "WrongPass999!"},
            headers={"Content-Type": "application/x-www-form-urlencoded"})
        assert r.status_code in (400, 401, 422)

@pytest.mark.api
@pytest.mark.asyncio
async def test_register_duplicate():
    user = await register_and_login()
    async with get_client() as client:
        r = await client.post(api_url("/auth/register"), json={
            "email": user["email"], "password": user["password"],
            "full_name": "Dup", "system_consent": True, "research_consent": False,
        })
        assert r.status_code in (400, 409, 422)

@pytest.mark.api
@pytest.mark.asyncio
async def test_unauthorized_access():
    async with get_client() as client:
        r = await client.get(api_url("/auth/me"))
        assert r.status_code in (401, 403, 404)
