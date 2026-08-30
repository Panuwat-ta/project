import pytest
from httpx import AsyncClient, ASGITransport
import io
from unittest.mock import AsyncMock, MagicMock
from app.main import app
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User

# Mocking database session
async def override_get_db():
    mock_session = MagicMock()

    async def mock_commit():
        pass

    async def mock_refresh(instance):
        import uuid
        from datetime import datetime, timezone
        instance.id = uuid.uuid4()
        instance.created_at = datetime.now(timezone.utc)

    async def mock_execute(statement):
        result = MagicMock()
        scalar = MagicMock()
        scalar.first.return_value = None
        scalar.all.return_value = []
        scalar.scalar_one_or_none.return_value = None
        result.scalars.return_value = scalar
        return result

    mock_session.commit = AsyncMock(side_effect=mock_commit)
    mock_session.refresh = AsyncMock(side_effect=mock_refresh)
    mock_session.execute = AsyncMock(side_effect=mock_execute)
    mock_session.flush = AsyncMock(side_effect=mock_commit)
    yield mock_session

# Mocking authenticated user
async def override_get_current_user():
    user = User(id=1, email="test@scamguard.com", role="user")
    return user


@pytest.fixture(autouse=True)
def apply_scan_overrides(monkeypatch):
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = override_get_current_user
    # Mock GPU inference (Surya + ONNX worker) เพื่อให้ test เร็วและไม่พึ่ง GPU
    from app.services import scan_service
    def fake_predict(image_bytes):
        return {
            "visual_risk_score": 50,
            "ai_gen_probability": 0.5,
            "heatmap_bytes": b"",
            "ocr_text": "",
        }
    monkeypatch.setattr(scan_service.inference_service, "predict", fake_predict)
    yield


def _make_image_bytes(fmt: str = "JPEG", size=(100, 100)) -> bytes:
    from PIL import Image
    image = Image.new("RGB", size)
    buf = io.BytesIO()
    image.save(buf, format=fmt)
    return buf.getvalue()


@pytest.mark.asyncio
async def test_scan_upload():
    files = {"file": ("test.jpg", _make_image_bytes("JPEG"), "image/jpeg")}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/scan/", files=files)

    assert response.status_code == 200
    data = response.json()
    assert "id" in data
    assert "visual_score" in data
    assert "total_risk_score" in data
    assert "risk_grade" in data


@pytest.mark.asyncio
async def test_scan_invalid_file_type():
    files = {"file": ("test.txt", b"dummy text", "text/plain")}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/scan/", files=files)

    assert response.status_code == 400
    assert "not a valid image" in response.json()["detail"]


@pytest.mark.asyncio
async def test_scan_webp():
    files = {"file": ("test.webp", _make_image_bytes("WEBP"), "image/webp")}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/scan/", files=files)

    assert response.status_code == 200, f"Failed with {response.text}"
    assert "id" in response.json()


@pytest.mark.asyncio
async def test_scan_bmp():
    files = {"file": ("test.bmp", _make_image_bytes("BMP"), "image/bmp")}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/scan/", files=files)

    assert response.status_code == 200, f"Failed with {response.text}"
    assert "id" in response.json()


@pytest.mark.asyncio
async def test_scan_heic():
    try:
        from pillow_heif import register_heif_opener
        register_heif_opener()
        from PIL import Image
        image = Image.new("RGB", (100, 100))
        buf = io.BytesIO()
        image.save(buf, format="HEIF")
        img_bytes = buf.getvalue()
    except Exception:
        pytest.skip("pillow-heif not available")

    files = {"file": ("test.heic", img_bytes, "image/heic")}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/scan/", files=files)

    assert response.status_code == 200, f"Failed with {response.text}"
    assert "id" in response.json()


@pytest.mark.asyncio
async def test_scan_oversize(monkeypatch):
    import app.services.scan_service as scan_service
    # ลด limit เหลือ 1KB เพื่อทดสอบโดยไม่ต้องสร้างไฟล์ใหญ่จริง
    monkeypatch.setattr(scan_service, "MAX_UPLOAD_BYTES", 1024)

    files = {"file": ("test.jpg", _make_image_bytes("JPEG", size=(512, 512)), "image/jpeg")}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/scan/", files=files)

    assert response.status_code == 413


@pytest.mark.asyncio
async def test_scan_real_image():
    image_path = "/home/panuwat/project/test.png"
    import os
    if not os.path.exists(image_path):
        pytest.skip(f"Test image not found at {image_path}")

    with open(image_path, "rb") as f:
        img_bytes = f.read()

    files = {"file": ("test.png", img_bytes, "image/png")}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/scan/", files=files)

    assert response.status_code == 200, f"Failed with {response.text}"
    data = response.json()
    assert "id" in data
    assert "visual_score" in data
    assert "total_risk_score" in data
    assert "risk_grade" in data
    assert "heatmap_image_url" in data
    assert data["heatmap_image_url"] is not None