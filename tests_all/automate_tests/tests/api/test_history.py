"""History & report"""
import pytest
from helpers.api_client import get_client, api_url
from helpers.auth_helper import register_and_login, auth_header
from helpers.image_factory import make_test_image_file

@pytest.mark.api
@pytest.mark.asyncio
async def test_history_list():
    user = await register_and_login()
    headers = auth_header(user["token"])
    async with get_client() as client:
        r = await client.get(api_url("/history"), headers=headers)
        if r.status_code == 404:
            r = await client.get(api_url("/history/list"), headers=headers)
        # อาจยังไม่มี history ก็ต้อง 200 + list ว่าง
        if r.status_code == 404:
            pytest.skip("no history endpoint")
        assert r.status_code == 200, r.text
        data = r.json()
        assert isinstance(data, (list, dict))

@pytest.mark.api
@pytest.mark.asyncio
async def test_report_create():
    user = await register_and_login()
    headers = auth_header(user["token"])
    async with get_client() as client:
        # ต้องสร้าง scan ก่อนเพื่อเอา scan_id ที่ถูกต้อง
        fname, data, ctype = make_test_image_file(512, 512)
        r_scan = await client.post(api_url("/scan/"), headers=headers,
            files={"file": (fname, data, ctype)}, data={"title": "for_report"})
        if r_scan.status_code in (307, 308):
            r_scan = await client.post(api_url("/scan"), headers=headers,
                files={"file": (fname, data, ctype)}, data={"title": "for_report"})
        assert r_scan.status_code in (200, 201), r_scan.text
        scan_id = r_scan.json().get("id") or r_scan.json().get("scan_id")
        assert scan_id, r_scan.text

        r = await client.post(api_url("/reports"), headers=headers, json={
            "scan_id": str(scan_id),
            "category": "fake_image",
            "description": "test report from automate suite - scam image detected",
            "allow_research_use": False,
        })
        assert r.status_code in (200, 201), r.text
        body = r.json()
        assert body.get("scan_id") or body.get("id")

        # ตรวจ /reports/my ด้วย
        r2 = await client.get(api_url("/reports/my"), headers=headers)
        assert r2.status_code == 200, r2.text

@pytest.mark.api
@pytest.mark.asyncio
async def test_report_categories():
    async with get_client() as client:
        # ไม่ต้อง auth ก็ควรได้ categories (หรือ 401 แล้ว skip)
        r = await client.get(api_url("/reports/categories"))
        if r.status_code in (401, 403):
            pytest.skip("categories requires auth")
        assert r.status_code == 200, r.text
        assert "categories" in r.json()
