import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import AsyncMock, MagicMock
from app.main import app
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User

import app.services.user_service as user_service

user_service.verify_password = lambda pw, hsh: pw == "password123" and hsh == "mocked_hash"


def _user(active=True):
    return User(id=7, email="bastest@test.local", hashed_password="mocked_hash",
                role="user", full_name="bastest", is_active=active)


def _session():
    mock = MagicMock()
    mock.commit = AsyncMock()
    mock.execute = AsyncMock(return_value=MagicMock())
    return mock


@pytest.fixture()
def overrides():
    session = _session()
    user = _user()

    async def override_db():
        yield session

    async def override_user():
        return user

    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = override_user
    yield session, user


@pytest.mark.asyncio
async def test_delete_me_ok(overrides):
    session, user = overrides
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        r = await ac.request("DELETE", "/api/v1/users/me", json={"password": "password123"})
    assert r.status_code == 200, r.text
    assert user.is_active is False
    assert session.commit.called


@pytest.mark.asyncio
async def test_delete_me_wrong_password(overrides):
    session, user = overrides
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        r = await ac.request("DELETE", "/api/v1/users/me", json={"password": "wrong"})
    assert r.status_code == 401
    assert user.is_active is True


@pytest.mark.asyncio
async def test_delete_me_no_token():
    async def dummy_db():
        yield MagicMock()

    app.dependency_overrides.clear()
    app.dependency_overrides[get_db] = dummy_db
    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            r = await ac.request("DELETE", "/api/v1/users/me", json={"password": "x"})
        assert r.status_code == 401, r.status_code
    finally:
        app.dependency_overrides.clear()
