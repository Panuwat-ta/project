import base64
import json

import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import MagicMock, AsyncMock

from app.main import app
from app.core.database import get_db
from app.api.deps import get_current_admin
from app.models.admin import Admin
from app.core.security import create_access_token, create_refresh_token

import app.api.v1.admin as admin_router


@pytest.fixture(autouse=True)
def reset_overrides():
    app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()


async def _override_db(admin: Admin):
    async def override_get_db():
        session = MagicMock()
        result = MagicMock()
        result.scalars.return_value.first.return_value = admin
        session.execute = AsyncMock(return_value=result)
        session.commit = AsyncMock()
        session.refresh = AsyncMock()
        yield session
    return override_get_db


async def _superadmin():
    return Admin(id=1, email="admin@scamguard.com", full_name="Admin", is_active=True, is_superadmin=True)


async def _normal_admin():
    return Admin(id=1, email="admin@scamguard.com", full_name="Admin", is_active=True, is_superadmin=False)


def _decode_access(access_token: str) -> dict:
    payload = access_token.split(".")[1]
    payload += "=" * (-len(payload) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))


@pytest.mark.asyncio
async def test_login_creates_session_with_sid(monkeypatch):
    admin = Admin(id=1, email="admin@scamguard.com", is_active=True, is_superadmin=True)

    store = {}
    async def fake_create_admin_session(db, admin, refresh_raw, ip=None, user_agent=None, sid=None):
        store["sid"] = sid or "session-1"
        store["refresh_raw"] = refresh_raw
        return store["sid"]

    monkeypatch.setattr(admin_router, "verify_password", lambda pw, hsh: True)
    monkeypatch.setattr(admin_router.admin_service, "create_admin_session", fake_create_admin_session)
    app.dependency_overrides[get_db] = await _override_db(admin)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/admin/login", data={"username": "admin@scamguard.com", "password": "x"})

    assert response.status_code == 200
    data = response.json()
    assert data["access_token"]
    
    # Check cookies
    cookies = response.cookies
    assert "admin_refresh_token" in cookies
    
    assert store["sid"]
    payload = _decode_access(data["access_token"])
    assert payload["sid"] == store["sid"]
    assert payload["role"] == "admin"


@pytest.mark.asyncio
async def test_require_super_admin_rejects_normal_admin():
    # override เฉพาะ get_current_admin (ตัว inner) ให้ require_super_admin ทำงานจริง ๆ
    app.dependency_overrides[get_current_admin] = _normal_admin

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/api/v1/admin/me")

    assert response.status_code == 403
    assert response.json()["detail"] == "Super Admin access required"


@pytest.mark.asyncio
async def test_super_admin_allowed():
    app.dependency_overrides[get_current_admin] = _superadmin

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/api/v1/admin/me")

    assert response.status_code == 200
    assert response.json()["is_superadmin"] is True


@pytest.mark.asyncio
async def test_refresh_rotates_and_old_token_fails(monkeypatch):
    admin = Admin(id=1, email="admin@scamguard.com", is_active=True, is_superadmin=True)
    app.dependency_overrides[get_db] = await _override_db(admin)

    old_sid = "session-old"
    refresh_raw = create_refresh_token(data={"sub": "1", "role": "admin"}, sid=old_sid)

    store = {"sessions": {old_sid: {"revoked": False}}, "next": 2}

    async def fake_rotate(db, old_sid_arg, claims, ip=None, user_agent=None):
        session = store["sessions"][old_sid_arg]
        if session["revoked"]:
            from fastapi import HTTPException
            raise HTTPException(status_code=401, detail="Invalid refresh token")
        session["revoked"] = True
        new_sid = f"session-{store['next']}"
        store["next"] += 1
        store["sessions"][new_sid] = {"revoked": False}
        return "new-access", "new-refresh", new_sid

    monkeypatch.setattr(admin_router.admin_service, "rotate_admin_session", fake_rotate)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        ac.cookies.set("admin_refresh_token", refresh_raw)
        r1 = await ac.post("/api/v1/admin/refresh")
        r2 = await ac.post("/api/v1/admin/refresh")

    assert r1.status_code == 200
    assert store["sessions"][old_sid]["revoked"] is True
    assert r2.status_code == 401  # refresh token ที่ถูก rotation แล้วใช้ต่อไม่ได้


@pytest.mark.asyncio
async def test_logout_revokes_current_session(monkeypatch):
    app.dependency_overrides[get_current_admin] = _superadmin

    revoked = {}
    async def fake_revoke(db, admin_id, sid):
        revoked["admin_id"] = admin_id
        revoked["sid"] = sid
        return MagicMock()

    monkeypatch.setattr(admin_router.admin_service, "revoke_admin_session", fake_revoke)

    access = create_access_token(data={"sub": "1", "role": "admin"}, sid="session-abc")

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/admin/logout", headers={"Authorization": f"Bearer {access}"})

    assert response.status_code == 200
    assert revoked["admin_id"] == 1
    assert revoked["sid"] == "session-abc"


@pytest.mark.asyncio
async def test_change_password_without_current_password_rejected():
    admin = Admin(id=1, email="admin@scamguard.com", hashed_password="old-hash", is_active=True, is_superadmin=True)

    async def fake_require_super_admin():
        return admin
    app.dependency_overrides[get_current_admin] = fake_require_super_admin

    sample_db = MagicMock()
    sample_db.commit = AsyncMock()
    sample_db.refresh = AsyncMock()
    async def db_gen():
        yield sample_db
    app.dependency_overrides[get_db] = db_gen

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.patch("/api/v1/admin/me", json={"new_password": "newpassword123"})

    # ไม่มี current_password → ต้องปฏิเสธ 400
    assert response.status_code == 400