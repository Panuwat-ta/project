def calculate_risk_score(text_score: int, visual_score: int, source_score: int) -> dict:
    """
    ระบบประเมินความเสี่ยงใหม่ (Strict Logic):
    1. ถ้าระบบใดระบบหนึ่งตรวจพบความเสี่ยง (Score >= 30) ให้ถือว่ามีความเสี่ยงทันที
    2. ถ้าตรวจพบร่องรอยการตัดต่อ (Visual Score >= 30) ให้ถือเป็นความเสี่ยงสูง (High Risk) ทันที
    """
    max_score = max(text_score, visual_score, source_score)
    
    # 1. ตรวจพบร่องรอยการตัดต่อภาพ (AI ตัดสินว่าตัดต่อ)
    if visual_score >= 30:
        # ปรับคะแนนรวมให้อย่างน้อย 80 (High Risk)
        total = max(80, max_score)
        grade = "high"
        
    # 2. ตรวจพบความเสี่ยงจากข้อความ (OCR/Scam Keywords) หรือ แหล่งที่มา (Source)
    elif text_score >= 30 or source_score >= 30:
        # ปรับคะแนนรวมให้อย่างน้อย 60 (Medium Risk)
        total = max(60, max_score)
    else:
        total = max_score

    # จำกัดค่าคะแนนให้อยู่ในช่วง 0-100
    total = min(100, int(total))
    
    # คำนวณ Grade ใหม่ตามเกณฑ์ 4 ระดับ (0-40, 40-60, 60-80, 80-100)
    if total >= 80:
        grade = "high"
    elif total >= 60:
        grade = "medium"
    elif total >= 40:
        grade = "low"
    else:
        grade = "safe"

    return {
        "total_risk_score": total,
        "grade": grade,
    }
