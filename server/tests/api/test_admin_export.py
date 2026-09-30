from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import require_super_admin
from app.core.database import get_db
from app.main import app
from app.models.admin import Admin


async def override_require_super_admin():
    return Admin(
        id=1,
        email="admin@example.invalid",
        full_name="Admin",
        is_active=True,
        is_superadmin=True,
    )


async def override_get_db():
    session = MagicMock()
    session.scalar = AsyncMock(return_value=0)
    result = MagicMock()
    result.scalars.return_value.all.return_value = []
    session.execute = AsyncMock(return_value=result)
    yield session


@pytest.fixture(autouse=True)
def admin_dependencies():
    app.dependency_overrides[require_super_admin] = override_require_super_admin
    app.dependency_overrides[get_db] = override_get_db
    yield
    app.dependency_overrides.clear()


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("query", "expected_detail"),
    [
        ("page=0", "page must be >= 1"),
        ("page=-1", "page must be >= 1"),
        ("limit=0", "limit must be between 1 and 100"),
        ("limit=101", "limit must be between 1 and 100"),
    ],
)
async def test_export_jobs_rejects_invalid_pagination(query, expected_detail):
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(f"/api/v1/admin/dataset/export-jobs?{query}")

    assert response.status_code == 400
    assert response.json()["detail"] == expected_detail
