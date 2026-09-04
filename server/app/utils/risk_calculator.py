def calculate_risk_score(text_score: int, visual_score: int, source_score: int) -> dict:
    """
    ระบบประเมินความเสี่ยงแบบ Hybrid Worst-Case & Multi-Factor Breakdown ตาม configs.md:
    1. ประเมินคะแนนแยกมิติอิสระเต็ม 100% (Visual, Textual, Source)
    2. ฐานคะแนนหลักอิงตามมิติที่พบความเสี่ยงสูงสุด (Worst-Case Dominance):
       S_base = max(visual_score, text_score, source_score)
    3. Multi-factor Compounding: หากพบความเสี่ยงระดับน่าสงสัยในมิติอื่น (>= 40)
       จะเพิ่มคะแนนความเสี่ยง +5 คะแนนต่อมิติ (สูงสุดไม่เกิน 100)
    """
    # ตรวจสอบขอบเขตค่าอินพุต (0 - 100)
    t = max(0, min(100, int(round(text_score))))
    v = max(0, min(100, int(round(visual_score))))
    s = max(0, min(100, int(round(source_score))))

    # 1. ฐานคะแนนสูงสุด (Worst-Case Base)
    scores = {"visual": v, "textual": t, "source": s}
    primary_factor = max(scores, key=scores.get)
    max_score = scores[primary_factor]

    if max_score == 0:
        primary_factor = "none"

    # 2. คำนวณ Multi-Factor Compounding (หากมีมิติอื่นที่มีความเสี่ยง >= 40)
    secondary_risks = [k for k, val in scores.items() if k != primary_factor and val >= 40]
    is_multi_risk = len(secondary_risks) > 0 and max_score >= 40

    compounding_bonus = len(secondary_risks) * 5 if is_multi_risk else 0
    total = min(100, max_score + compounding_bonus)

    # 3. คำนวณ Grade ตามเกณฑ์ 3 ระดับ (Low: 0-39, Medium: 40-69, High: 70-100)
    if total >= 70 or v >= 80:
        grade = "high"
        total = max(70, total)
    elif total >= 40:
        grade = "medium"
    else:
        grade = "low"

    return {
        "total_risk_score": total,
        "grade": grade,
        "primary_factor": primary_factor,
        "is_multi_risk": is_multi_risk,
        "breakdown": {
            "visual_score": v,
            "text_score": t,
            "source_score": s,
        },
    }
