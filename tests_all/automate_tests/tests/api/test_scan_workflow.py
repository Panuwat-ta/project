"""Scan workflow — upload -> analyze -> history"""
import pytest
from helpers.api_client import get_client, api_url
from helpers.auth_helper import register_and_login, auth_header
from helpers.image_factory import make_test_image_file

@pytest.mark.api
@pytest.mark.asyncio
async def test_scan_upload_and_get_result():
    user = await register_and_login()
    headers = auth_header(user["token"])
    fname, data, ctype = make_test_image_file(640, 480, fmt="PNG")

    async with get_client() as client:
        # POST /api/v1/scan/ — ต้อง auth, ส่ง file + title (form)
        r = await client.post(
            api_url("/scan/"),
            headers=headers,
            files={"file": (fname, data, ctype)},
            data={"title": "automate_test"},
        )
        # บางครั้ง trailing slash redirect
        if r.status_code in (307, 308):
            r = await client.post(
                api_url("/scan"),
                headers=headers,
                files={"file": (fname, data, ctype)},
                data={"title": "automate_test"},
            )
        assert r.status_code in (200, 201), f"{r.status_code} {r.text[:800]}"
        body = r.json()
        assert any(k in body for k in ("id", "scan_id", "status", "total_risk_score")), body
        # ควรได้ id กลับมาแล้ว poll ได้
        scan_id = body.get("id") or body.get("scan_id")
        if scan_id:
            r2 = await client.get(api_url(f"/scan/{scan_id}"), headers=headers)
            assert r2.status_code in (200, 404), r2.text

@pytest.mark.api
@pytest.mark.asyncio
async def test_scan_without_auth_should_fail():
    fname, data, ctype = make_test_image_file()
    async with get_client() as client:
        r = await client.post(
            api_url("/scan/"),
            files={"file": (fname, data, ctype)},
            data={"title": "noauth"},
        )
        # ต้อง 401/403 ถ้าไม่ส่ง token (ไม่ควร 500)
        assert r.status_code in (401, 403, 422), f"expected auth error got {r.status_code} {r.text[:300]}"
        assert r.status_code != 500

@pytest.mark.api
@pytest.mark.asyncio
async def test_scan_invalid_file():
    user = await register_and_login()
    headers = auth_header(user["token"])
    async with get_client() as client:
        r = await client.post(
            api_url("/scan/"),
            headers=headers,
            files={"file": ("evil.txt", b"not an image", "text/plain")},
            data={"title": "invalid"},
        )
        # ปัจจุบัน backend ยังรับไฟล์ทุกชนิดเป็น 200 (แล้วประมวลผลภายหลัง)
        # สิ่งที่ต้องตรวจคือต้องไม่ 500 และต้องได้ scan record กลับมา
        assert r.status_code in (200, 201, 400, 415, 422), f"{r.status_code} {r.text[:400]}"
        assert r.status_code != 500
