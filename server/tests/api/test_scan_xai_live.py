import pytest
import requests
import time
import os
from app.core.security import create_access_token

def test_live_scan_and_xai_pipeline():
    """Test full image scanning pipeline with XAI explanation running on GPU."""
    # Check if server is up
    try:
        r = requests.get("http://localhost:8000/health", timeout=3)
        if r.status_code != 200:
            pytest.skip("Live server is not running on port 8000")
    except Exception:
        pytest.skip("Live server is not running on port 8000")

    token = create_access_token(data={"sub": "6"})
    headers = {"Authorization": f"Bearer {token}"}

    test_img = "/home/panuwat/project/server/tests/test.png"
    assert os.path.exists(test_img), f"Test image missing at {test_img}"

    with open(test_img, "rb") as f:
        files = {"file": ("test.png", f, "image/png")}
        data = {"title": "Live GPU Verification Test"}
        res = requests.post("http://localhost:8000/api/v1/scan/", headers=headers, files=files, data=data)

    assert res.status_code == 200, f"Scan request failed: {res.text}"
    scan_id = res.json().get("id")
    assert scan_id is not None

    # Poll for completion
    completed = False
    final_data = {}
    for _ in range(30):
        time.sleep(1)
        r = requests.get(f"http://localhost:8000/api/v1/scan/{scan_id}", headers=headers)
        if r.status_code == 200:
            d = r.json()
            if d.get("status") == "completed":
                completed = True
                final_data = d
                break
            elif d.get("status") == "failed":
                break

    assert completed, f"Scan did not complete in time. Last status: {final_data.get('status')}"
    assert final_data.get("visual_score") is not None
    assert final_data.get("ai_gen_probability") is not None
    assert final_data.get("xai_explanation") is not None
    assert len(final_data.get("xai_explanation")) > 10
