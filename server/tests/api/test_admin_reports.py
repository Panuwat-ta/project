import uuid
from datetime import datetime, timezone
from unittest.mock import MagicMock, AsyncMock

import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.core.database import get_db
from app.api.deps import require_super_admin
from app.models.admin import Admin
from app.models.user import User
from app.models.scan import Scan
from app.models.report import ScamReport


def _make_report(report_id=7):
    return ScamReport(
        id=report_id,
        user_id=1,
        scan_id=uuid.uuid4(),
        category="fake_slip",
        reason="ได้รับสลิปปลอมในการโอนเงิน",
        platform="Facebook",
        reference_url="https://example.com/post/1",
        allow_research_use=True,
        status="pending",
        version=1,
        created_at=datetime.now(timezone.utc),
    )


def _make_scan():
    return Scan(
        id=uuid.uuid4(),
        total_risk_score=85,
        text_score=75,
        visual_score=90,
        source_score=20,
        ai_gen_probability=0.12,
        ocr_text="ยินดีด้วยคุณได้รับรางวัล",
        scam_keywords_found=["โบนัส"],
        exif_data={"Software": "Adobe Photoshop"},
        status="completed",
    )


def _make_user():
    return User(id=1, email="reporter@example.com", full_name="ผู้รายงาน", role="user", is_active=True)


async def _build_db_override(report_obj):
    async def override_get_db():
        session = MagicMock()

        async def mock_execute(stmt):
            text = str(stmt)
            result = MagicMock()
            if report_obj is None and "scam_reports" in text:
                result.scalar_one_or_none.return_value = None
                return result
            if "scam_reports" in text:
                result.scalar_one_or_none.return_value = report_obj
                return result
            if "FROM users" in text:
                result.scalars.return_value.first.return_value = _make_user()
                return result
            if "FROM scans" in text:
                result.scalars.return_value.first.return_value = _make_scan()
                return result
            result.scalars.return_value = MagicMock()
            return result

        session.execute = AsyncMock(side_effect=mock_execute)
        session.scalar = AsyncMock(return_value=12)  # total_reports_submitted
        session.commit = AsyncMock()
        yield session

    return override_get_db


async def override_require_super_admin():
    return Admin(id=1, email="admin@scamguard.com", full_name="Admin", is_active=True, is_superadmin=True)


@pytest.fixture(autouse=True)
def apply_admin_overrides():
    app.dependency_overrides[require_super_admin] = override_require_super_admin
    yield
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_get_report_detail():
    report = _make_report()
    app.dependency_overrides[get_db] = await _build_db_override(report)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get(f"/api/v1/admin/reports/{report.id}")

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == report.id
    assert data["category"] == "fake_slip"
    assert data["status"] == "pending"
    assert data["scan"]["total_risk_score"] == 85
    assert data["user"]["total_reports_submitted"] == 12


@pytest.mark.asyncio
async def test_get_report_detail_not_found():
    app.dependency_overrides[get_db] = await _build_db_override(None)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/api/v1/admin/reports/999")

    assert response.status_code == 404
    assert response.json()["detail"] == "Report not found"