import asyncio
import pytest
import requests
import time
from pathlib import Path
from sqlalchemy import select
from app.core.database import async_session
from app.core.config import settings
from app.core.security import create_access_token
from app.models.user import User

async def _get_active_user_id():
    async with async_session() as db:
        return await db.scalar(select(User.id).where(User.is_active.is_(True)).order_by(User.id).limit(1))


def test_live_scan_and_xai_pipeline():
    """Test the live scan pipeline through XAI output (model or safe fallback)."""
    # Check if server is up
    try:
        r = requests.get("http://localhost:8000/health", timeout=3)
        if r.status_code != 200:
            pytest.skip("Live server is not running on port 8000")
    except Exception:
        pytest.skip("Live server is not running on port 8000")

    user_id = asyncio.run(_get_active_user_id())
    assert user_id is not None, "Live scan test requires at least one active user"
    token = create_access_token(data={"sub": str(user_id)})
    headers = {"Authorization": f"Bearer {token}"}

    test_img = Path(__file__).resolve().parents[1] / "test1.png"
    assert test_img.is_file(), f"Test image missing at {test_img}"

    with test_img.open("rb") as f:
        files = {"file": ("test.png", f, "image/png")}
        data = {"title": "Live GPU Verification Test"}
        res = requests.post("http://localhost:8000/api/v1/scan/", headers=headers, files=files, data=data)

    assert res.status_code == 200, f"Scan request failed: {res.text}"
    scan_id = res.json().get("id")
    assert scan_id is not None

    # Poll using the real pipeline timeout budget instead of an arbitrary 30s.
    # ONNX, OCR and XAI are sequential phases and each has its own configured timeout.
    pipeline_budget = (
        settings.ONNX_WORKER_TIMEOUT
        + settings.OCR_TIMEOUT
        + settings.XAI_TIMEOUT
        + 30
    )
    deadline = time.monotonic() + pipeline_budget
    completed = False
    final_data = {}
    while time.monotonic() < deadline:
        time.sleep(2)
        try:
            r = requests.get(
                f"http://localhost:8000/api/v1/scan/{scan_id}",
                headers=headers,
                timeout=5,
            )
        except requests.RequestException:
            # Heavy local inference can briefly starve the HTTP worker; keep
            # polling until the overall pipeline deadline instead of failing early.
            continue
        if r.status_code != 200:
            continue
        final_data = r.json()
        status = final_data.get("status")
        if status == "completed":
            completed = True
            break
        if status == "failed":
            break

    assert completed, (
        f"Scan did not complete within {pipeline_budget}s. "
        f"Last status={final_data.get('status')}, progress={final_data.get('progress')}"
    )
    assert final_data.get("visual_score") is not None
    assert final_data.get("ai_gen_probability") is not None
    assert final_data.get("xai_explanation") is not None
    assert len(final_data.get("xai_explanation")) > 10
