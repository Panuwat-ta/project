"""OWASP Top 10 2021 — automated security tests (mapped per case).

A01: IDOR / missing auth | A03: injection | A04: abuse-case validation
A07: authentication (weak password policy enforced by RegisterRequest min_length=8)
"""
import io
import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4
from app.main import app
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.scan import Scan


def _mock_session(execute_side_effect):
    mock = MagicMock()
    mock.commit = AsyncMock()
    mock.refresh = AsyncMock()
    mock.flush = AsyncMock()
    mock.execute = AsyncMock(side_effect=execute_side_effect)
    return mock


def _empty_result():
    result = MagicMock()
    scalars = MagicMock()
    scalars.first.return_value = None
    scalars.all.return_value = []
    result.scalars.return_value = scalars
    return result


def _user(uid=1):
    return User(id=uid, email="sec@test.local", hashed_password="mocked_hash",
                role="user", full_name="sec", is_active=True)


@pytest.fixture()
def ctx():
    state = {}
    session = _mock_session(lambda stmt: state["handler"](stmt))

    async def override_db():
        yield session

    async def override_user():
        return _user(state.get("uid", 1))

    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_current_user] = override_user
    yield state
    app.dependency_overrides.clear()


def _scan_owned_by(uid):
    return Scan(id=uuid4(), user_id=uid, image_hash="h", raw_image_url="",
                text_score=0, visual_score=0, source_score=0,
                total_risk_score=0, status="completed", progress=100)


# ---------- A01: Broken Access Control ----------

@pytest.mark.asyncio
async def test_a01_idor_other_user_scan_forbidden(ctx):
    """เปิด scan ของคนอื่นต้อง 403 (ownership check ใน GET /scan/{id})."""
    result = MagicMock()
    scalars = MagicMock()
    scalars.first.return_value = _scan_owned_by(2)  # ของ user 2
    result.scalars.return_value = scalars
    ctx["handler"] = lambda stmt: result

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        r = await ac.get(f"/api/v1/scan/{uuid4()}")
    assert r.status_code == 403, r.text


@pytest.mark.asyncio
async def test_a01_scan_requires_auth():
    """ไม่มี token ต้อง 401."""
    app.dependency_overrides.clear()
    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            r = await ac.get(f"/api/v1/scan/{uuid4()}")
        assert r.status_code == 401, r.status_code
    finally:
        app.dependency_overrides.clear()


# ---------- A03: Injection ----------

@pytest.mark.asyncio
async def test_a03_login_sqli_returns_401_not_500(ctx):
    """`' OR '1'='1` ต้องได้ 401 (parameterized) ไม่ใช่ 500/error."""
    import app.api.v1.auth as auth_router
    auth_router.verify_password = lambda pw, hsh: False
    ctx["handler"] = lambda stmt: _empty_result()
    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            r = await ac.post("/api/v1/auth/login",
                              data={"username": "' OR '1'='1", "password": "x"})
        assert r.status_code == 401, (r.status_code, r.text)
    finally:
        auth_router.verify_password = lambda pw, hsh: pw == "password123" and hsh == "mocked_hash"


# ---------- A07: Authentication ----------

@pytest.mark.asyncio
async def test_a07_weak_password_rejected():
    """รหัสสั้นกว่า 8 ตัวต้อง 422 (password policy)."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        r = await ac.post("/api/v1/auth/register", json={
            "email": "w@test.local", "password": "1234", "full_name": "w"})
    assert r.status_code == 422, (r.status_code, r.text)


# ---------- A04: abuse-case (อ้างอิงเคสเดิมใน test_scan.py) ----------
# test_scan_invalid_file_type (400) + test_scan_oversize (413) ครอบคลุมแล้ว
# เคสนี้กัน regression ระดับ service: validate ก่อนสร้าง record เสมอ

@pytest.mark.asyncio
async def test_a04_empty_file_rejected(ctx):
    """ไฟล์ว่างต้อง 400 ไม่สร้าง record."""
    ctx["handler"] = lambda stmt: _empty_result()
    files = {"file": ("empty.jpg", b"", "image/jpeg")}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        r = await ac.post("/api/v1/scan/", files=files)
    assert r.status_code == 400, (r.status_code, r.text)
