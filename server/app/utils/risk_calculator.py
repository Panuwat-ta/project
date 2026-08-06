def calculate_risk_score(text_score: int, visual_score: int, source_score: int) -> dict:
    """
    สูตร: Risk Score = (S_text * 0.25) + (S_visual * 0.45) + (S_source * 0.30)

    Risk Grades:
      0-39  = low    (สีเขียว)
      40-69 = medium (สีเหลือง)
      70-100 = high  (สีแดง)
    """
    total = round((text_score * 0.25) + (visual_score * 0.45) + (source_score * 0.30))
    total = max(0, min(100, total))

    if visual_score >= 80:
        grade = "high"
    elif total >= 70:
        grade = "high"
    elif total >= 40:
        grade = "medium"
    else:
        grade = "low"

    return {
        "total_risk_score": total,
        "grade": grade,
    }
