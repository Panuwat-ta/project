"""Single authority for Overall Risk Score (Hybrid Worst-Case & Multi-Factor Breakdown).

Wiki source of truth: [[concepts/risk-scoring]].
Every caller (scan/history/admin) must grade through this module so the
threshold table, the Visual Override rule and the score input builders
keep locality in exactly one place.
"""

from typing import Optional


# --- Threshold table (Low 0-39 / Medium 40-69 / High 70-100) ---
LOW_MAX = 39
MEDIUM_MAX = 69
COMPOUND_THRESHOLD = 40
COMPOUND_BONUS = 5
VISUAL_OVERRIDE = 80

# --- Textual input builder (moved from scan_service; behavior unchanged) ---
SCAM_KEYWORDS = ["ด่วน", "โบนัส", "กู้เงิน", "รับเงิน", "ลงทุน", "อนุมัติไว", "ได้เงินจริง", "คลิก", "เครดิตฟรี", "แจกฟรี", "หลุด"]
KEYWORD_SCORE = 25


def grade_for(total: int, visual_score: int) -> str:
    """sole grade authority: total bands + Visual Override (S_visual >= 80 -> high)."""
    if total >= 70 or visual_score >= VISUAL_OVERRIDE:
        return "high"
    if total >= 40:
        return "medium"
    return "low"


def build_text_analysis(ocr_text: str) -> tuple[int, list[str]]:
    """keyword heuristic -> (text_score, found_keywords). No text -> (0, [])."""
    if not ocr_text:
        return 0, []
    found = [kw for kw in SCAM_KEYWORDS if kw in ocr_text]
    return min(len(found) * KEYWORD_SCORE, 100), found


def build_source_score() -> Optional[int]:
    """Return no score while Source Verification is unavailable in v1.

    A missing provider is not evidence and must not contribute a synthetic
    neutral value to Overall Risk. API responses pair this with
    ``source_status="unavailable"``.
    """
    return None


def calculate_risk_score(text_score: int, visual_score: int, source_score: Optional[int]) -> dict:
    """
    ระบบประเมินความเสี่ยงแบบ Hybrid Worst-Case & Multi-Factor Breakdown ตาม configs.md:
    1. ประเมินคะแนนแยกมิติอิสระเต็ม 100% (Visual, Textual, Source)
    2. ฐานคะแนนหลักอิงตามมิติที่พบความเสี่ยงสูงสุด (Worst-Case Dominance):
       S_base = max(visual_score, text_score, source_score)
    3. Multi-factor Compounding: หากพบความเสี่ยงระดับน่าสงสัยในมิติอื่น (>= 40)
       จะเพิ่มคะแนนความเสี่ยง +5 คะแนนต่อมิติ (สูงสุดไม่เกิน 100)

    Canonical contract keys: total_risk_score, grade, primary_factor,
    is_multi_risk, breakdown{visual_score, text_score, source_score}.
    """
    # ตรวจสอบขอบเขตค่าอินพุต (0 - 100)
    t = max(0, min(100, int(round(text_score))))
    v = max(0, min(100, int(round(visual_score))))
    s = None if source_score is None else max(0, min(100, int(round(source_score))))

    # 1. ฐานคะแนนสูงสุด (Worst-Case Base). Unavailable dimensions are omitted.
    scores = {"visual": v, "textual": t}
    if s is not None:
        scores["source"] = s
    primary_factor = max(scores, key=scores.get)
    max_score = scores[primary_factor]

    if max_score == 0:
        primary_factor = "none"

    # 2. คำนวณ Multi-Factor Compounding (หากมีมิติอื่นที่มีความเสี่ยง >= 40)
    secondary_risks = [k for k, val in scores.items() if k != primary_factor and val >= COMPOUND_THRESHOLD]
    is_multi_risk = len(secondary_risks) > 0 and max_score >= COMPOUND_THRESHOLD

    compounding_bonus = len(secondary_risks) * COMPOUND_BONUS if is_multi_risk else 0
    total = min(100, max_score + compounding_bonus)

    # 3. เกรดผ่าน authority เดียว (รวม Visual Override + clamp)
    grade = grade_for(total, v)
    if grade == "high":
        total = max(70, total)

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
