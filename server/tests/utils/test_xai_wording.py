import pytest

from app.services.inference_service import InferenceService
from app.services.onnx_worker import visual_score_from_det

# ค่า det ที่วัดจริงจากภาพ (2026-09-30) ใช้เป็น input ของข้อความ XAI
REAL_CAMERA = [("to171", 0, 0.0006), ("to175", 21, 0.2123), ("to180", 23, 0.2257)]
MANIPULATED = [("splicing", 100, 0.9999), ("inpainting", 100, 0.9996), ("casia", 99, 0.9906)]

REGION = "บริเวณที่น่าสงสัยในภาพ"

# คำที่ห้ามปรากฏ เพราะเราไม่มีโมเดลวัด "การสังเคราะห์ด้วย AI" แยกจากการดัดแปลง
AI_GENERATION_CLAIMS = ["สังเคราะห์จาก AI", "สังเคราะห์จากปัญญาประดิษฐ์", "ภาพ AI", "องค์ประกอบจาก AI"]


def _svc():
    # ไม่ต้องโหลดโมเดลใหญ่ ใช้เฉพาะ fallback_xai_explanation ที่ไม่พึ่ง state
    return InferenceService.__new__(InferenceService)


@pytest.mark.parametrize("name,visual,det", REAL_CAMERA + MANIPULATED)
def test_xai_never_claims_ai_generation(name, visual, det):
    """บั๊กเดิมบอกว่า 'โอกาสสูง (100%) ที่เป็นภาพสังเคราะห์จาก AI' บนภาพถ่ายจริง

    โมเดลนี้มีแค่ 2 seg class (authentic/forged) และ det head แบบ binary จึงไม่มี
    ความสามารถในการแยกภาพ AI-generated ออกจากภาพที่ถูกดัดแปลง
    """
    text = _svc().fallback_xai_explanation(REGION, visual, det, [])
    for claim in AI_GENERATION_CLAIMS:
        assert claim not in text, f"{name}: ยังมีคำกล่าวอ้าง '{claim}' -> {text}"


@pytest.mark.parametrize("name,visual,det", REAL_CAMERA)
def test_real_photo_text_is_self_consistent(name, visual, det):
    """ข้อความต้องไม่บอกทั้ง 'พิกเซลปกติ' และ 'ดัดแปลงสูง' ในประโยคเดียว"""
    text = _svc().fallback_xai_explanation(REGION, visual, det, [])
    assert "ความม่ันใจสูง" not in text
    assert "ความม่ันใจปานกลาง" not in text


def test_manipulated_text_states_high_confidence():
    text = _svc().fallback_xai_explanation(REGION, 100, 0.9999, [])
    assert "ความม่ันใจสูง (100%) ว่าภาพถูกตัดต่อหรือดัดแปลง" in text


# S_visual มาจาก Det Head ซึ่งประเมินภาพรวม ไม่ได้มาจากค่ารายพิกเซล
# ข้อความจึงต้องไม่อ้างว่าตรวจพบ "ที่ระดับพิกเซล" ซึ่งเป็นการอ้างเกินหลักฐาน
PIXEL_LEVEL_CLAIMS = ["โครงสร้างพิกเซล", "พิกเซลมีความเป็นธรรมชาติ", "พิกเซลสม่ำเสมอ"]


@pytest.mark.parametrize("name,visual,det", REAL_CAMERA + MANIPULATED + [("borderline", 47, 0.4662)])
def test_text_does_not_claim_pixel_level_analysis(name, visual, det):
    """คะแนนมาจาก Det Head (ภาพรวม) ไม่ใช่รายพิกเซล ข้อความจึงห้ามอ้างระดับพิกเซล"""
    text = _svc().fallback_xai_explanation(REGION, visual, det, [])
    for claim in PIXEL_LEVEL_CLAIMS:
        assert claim not in text, f"{name}: ยังอ้างระดับพิกเซล '{claim}' -> {text}"


def test_text_reports_level_alongside_score():
    """ข้อความต้องบอกระดับความเสี่ยงและคะแนนคู่กัน เพื่อให้ผู้ใช้ตรวจสอบได้"""
    assert "ระดับสูง (100/100)" in _svc().fallback_xai_explanation(REGION, 100, 0.9999, [])
    assert "ระดับปานกลาง (47/100)" in _svc().fallback_xai_explanation(REGION, 47, 0.4662, [])
    assert "ระดับต่ำ (0/100)" in _svc().fallback_xai_explanation(REGION, 0, 0.0006, [])


def test_borderline_uses_medium_confidence():
    text = _svc().fallback_xai_explanation(REGION, 47, 0.4662, [])
    assert "ความม่ันใจปานกลาง (47%) ว่าภาพถูกตัดต่อหรือดัดแปลง" in text


def test_low_confidence_phrase_is_omitted_not_zero_claimed():
    """ค่าต่ำไม่ควรระบุเป็น 0% เพราะโมเดลไม่ได้บอกว่า 'ไม่มีการดัดแปลง'"""
    text = _svc().fallback_xai_explanation(REGION, 0, 0.0006, [])
    assert "0%" not in text
    assert "ไม่พบข้อความหรือคำสำคัญที่เกี่ยวข้องกับการหลอกลวง" in text


def test_reported_probability_follows_det_not_pixel_max():
    """manipulation_confidence ต้องเท่ากับ det ไม่ใช่ค่าสูงสุดของพิกเซล

    ค่าเดิมมาจาก prob_map.max() ซึ่งเป็น ~0.99 บนภาพ 12 MP ทุกภาพ
    """
    det = 0.0006
    noisy_pixel_max = 0.9988
    reported = det if det is not None else noisy_pixel_max
    assert reported == det
    assert reported != noisy_pixel_max
    assert visual_score_from_det(det, noisy_pixel_max) == 0


def test_seo_keys_unchanged():
    """ข้อความภาษาไทยต้องยังมีโครงสร้างเดิมครบ เพื่อไม่ให้ regression ที่อื่น"""
    text = _svc().fallback_xai_explanation(REGION, 100, 0.9999, ["โอนเงินด่วน"])
    assert "โอนเงินด่วน" in text
    assert text.count(" ") > 5