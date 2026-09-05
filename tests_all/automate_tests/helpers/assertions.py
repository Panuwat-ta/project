"""Common assertions"""

def assert_ok_response(data: dict, required_fields=None):
    assert isinstance(data, dict), f"expected dict got {type(data)}"
    if required_fields:
        for f in required_fields:
            assert f in data, f"missing field '{f}' in {data}"

def assert_paginated(data: dict):
    assert "items" in data or "data" in data or "results" in data, f"not paginated: {data}"

def assert_scan_result(data: dict):
    # รองรับหลาย schema ของ scan result
    for key in ["risk_score", "risk_level", "scan_id", "status"]:
        if key in data:
            return
    # ถ้าไม่มี key เหล่านี้ ให้ตรวจว่ามี nested result
    assert "result" in data or "analysis" in data, f"unexpected scan result shape: {list(data.keys())}"
