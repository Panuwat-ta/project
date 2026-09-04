import pytest
from app.utils.risk_calculator import calculate_risk_score

def test_hybrid_worst_case_and_multi_factor():
    # 1. เคสค่าศูนย์ทั้งหมด
    res = calculate_risk_score(text_score=0, visual_score=0, source_score=0)
    assert res["total_risk_score"] == 0
    assert res["grade"] == "low"
    assert res["primary_factor"] == "none"
    assert res["is_multi_risk"] is False

    # 2. เคส Visual เดี่ยวรุนแรง (ภาพ Romance Scam ไม่มีข้อความ) -> ไม่ถูกค่า 0 ฉุดรั้ง
    res = calculate_risk_score(text_score=0, visual_score=85, source_score=0)
    assert res["total_risk_score"] == 85
    assert res["grade"] == "high"
    assert res["primary_factor"] == "visual"
    assert res["is_multi_risk"] is False

    # 3. เคส Text เดี่ยวรุนแรง (สลิป/ข้อความหลอกลวง ภาพไม่ตัดต่อ)
    res = calculate_risk_score(text_score=90, visual_score=0, source_score=0)
    assert res["total_risk_score"] == 90
    assert res["grade"] == "high"
    assert res["primary_factor"] == "textual"
    assert res["is_multi_risk"] is False

    # 4. เคสพบความเสี่ยงหลายมิติพร้อมกัน (Multi-factor Compounding)
    # visual=80, text=50 (พบ 2 ปัจจัยที่มีความเสี่ยง >= 40) -> 80 + 5 = 85
    res = calculate_risk_score(text_score=50, visual_score=80, source_score=0)
    assert res["total_risk_score"] == 85
    assert res["grade"] == "high"
    assert res["primary_factor"] == "visual"
    assert res["is_multi_risk"] is True

    # 5. เคสพบทั้ง 3 มิติพร้อมกัน (visual=80, text=50, source=60) -> 80 + 10 = 90
    res = calculate_risk_score(text_score=50, visual_score=80, source_score=60)
    assert res["total_risk_score"] == 90
    assert res["grade"] == "high"
    assert res["is_multi_risk"] is True

    # 6. เคสระดับความเสี่ยงปานกลาง (Medium: 40-69)
    res = calculate_risk_score(text_score=20, visual_score=55, source_score=10)
    assert res["total_risk_score"] == 55
    assert res["grade"] == "medium"
    assert res["primary_factor"] == "visual"
    assert res["is_multi_risk"] is False

    # 7. เคสค่าสูงสุด 100
    res = calculate_risk_score(text_score=100, visual_score=100, source_score=100)
    assert res["total_risk_score"] == 100
    assert res["grade"] == "high"

    # 8. เคสโครงสร้าง breakdown ครบถ้วน
    assert "breakdown" in res
    assert res["breakdown"]["visual_score"] == 100
    assert res["breakdown"]["text_score"] == 100
    assert res["breakdown"]["source_score"] == 100
