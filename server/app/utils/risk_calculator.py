def calculate_risk_score(text_score: int, visual_score: int, source_score: int) -> dict:
    """
    ระบบประเมินความเสี่ยงตาม configs.md:
    S_total = (S_textual * 0.25) + (S_visual * 0.45) + (S_source * 0.30)
    """
    # 1. คำนวณแบบถ่วงน้ำหนัก
    weighted_total = (text_score * 0.25) + (visual_score * 0.45) + (source_score * 0.30)
    total = min(100, max(0, int(round(weighted_total))))
    
    # 2. คำนวณ Grade ตามเกณฑ์
    if total >= 70 or visual_score >= 80:
        grade = "high"
        # กรณี visual >= 80 บังคับเป็น High ทันที ให้ดันคะแนนรวมให้ถึงเกณฑ์ขั้นต่ำของ High เพื่อไม่ให้ UI สับสน
        total = max(70, total)
    elif total >= 40:
        grade = "medium"
    elif total >= 20:
        grade = "low"
    else:
        grade = "safe"

    return {
        "total_risk_score": total,
        "grade": grade,
    }
