from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.core.database import get_db
from app.api.deps import require_super_admin
from app.models.admin import Admin
from app.core.security import create_refresh_token
import app.api.v1.admin as admin_router


async def _superadmin():
    return Admin(
        id=1,
        email="admin@scamguard.com",
        full_name="Admin",
        is_active=True,
        is_superadmin=True,
    )


async def _db_override():
    session = MagicMock()
    session.execute = AsyncMock()
    session.scalar = AsyncMock()
    session.commit = AsyncMock()
    session.refresh = AsyncMock()
    yield session
@pytest.fixture(autouse=True)
def admin_overrides():
    app.dependency_overrides[require_super_admin] = _superadmin
    app.dependency_overrides[get_db] = _db_override
    yield
    app.dependency_overrides.clear()


@pytest.mark.parametrize(
    ("path", "detail"),
    [
        ("/api/v1/admin/reports?page=0", "page must be >= 1"),
        ("/api/v1/admin/reports?limit=101", "limit must be between 1 and 100"),
        ("/api/v1/admin/users?page=0", "page must be >= 1"),
        ("/api/v1/admin/users?limit=0", "limit must be between 1 and 100"),
        ("/api/v1/admin/audit-logs?page=-1", "page must be >= 1"),
        ("/api/v1/admin/audit-logs?limit=101", "limit must be between 1 and 100"),
    ],
)
@pytest.mark.asyncio
async def test_admin_list_routes_reject_invalid_pagination(path, detail):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(path)
    assert response.status_code == 400
    assert response.json()["detail"] == detail
@pytest.mark.asyncio
async def test_start_review_requires_version_before_service_call(monkeypatch):
    called = AsyncMock()
    monkeypatch.setattr(admin_router.admin_service, "start_review_report", called)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/admin/reports/7/review", json={})

    assert response.status_code == 400
    assert response.json()["detail"] == "version is required"
    called.assert_not_awaited()


@pytest.mark.asyncio
async def test_refresh_rejects_non_integer_subject_claim_instead_of_500():
    app.dependency_overrides.pop(require_super_admin, None)
    malformed = create_refresh_token(
        data={"sub": "not-an-int", "role": "admin"},
        sid="malformed-subject",
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        client.cookies.set("admin_refresh_token", malformed)
        response = await client.post("/api/v1/admin/refresh")

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid refresh token"
