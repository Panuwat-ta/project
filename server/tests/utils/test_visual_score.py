import pytest

from app.services.onnx_worker import visual_score_from_det


# S_visual = Normalize(Det Score) when a det head is present, else max-prob.
# See Document/model/configs.md §3 (revised 2026-09-30).

# ค่าที่วัดจริงจากภาพในชุด Test-Cases และภาพกล้องจริง (2026-09-30)
REAL_CAMERA = [
    # ภาพถ่ายจริง -> det ต่ำมาก แต่ max-prob สูงเกือบ 1.0 เสมอ
    (0.0029299799994583443, 0.9988136291503906, 0),
    (0.0166, 0.9955, 2),
    (0.0006, 0.9989, 0),
]
MANIPULATED = [
    # ภาพถูกดัดแปลงจริง -> det สูงเกือบ 1.0
    (0.9999, 1.0000, 100),      # splicing
    (0.9996, 0.5038, 100),      # inpainting
    (0.9906, 0.9995, 99),       # casia
]
BORDERLINE = [
    (0.4662, 0.9946, 47),       # แชท LINE
    (0.2123, 0.9970, 21),       # กล้องจริง
    (0.2257, 0.9991, 23),       # กล้องจริง
]


@pytest.mark.parametrize("det,prob_max,expected", REAL_CAMERA)
def test_real_camera_photo_is_not_a_false_positive(det, prob_max, expected):
    """บั๊กเดิม: ภาพกล้องจริง 12 MP เคยได้ visual_score=100 จาก prob_map.max()"""
    assert visual_score_from_det(det, prob_max) == expected


@pytest.mark.parametrize("det,prob_max,expected", MANIPULATED)
def test_manipulated_image_is_still_detected(det, prob_max, expected):
    """ภาพถูกดัดแปลงต้องยังถูกจับ ไม่ให้หลุดจากการแก้สูตร"""
    assert visual_score_from_det(det, prob_max) == expected


@pytest.mark.parametrize("det,prob_max,expected", BORDERLINE)
def test_borderline_scores_map_linearly(det, prob_max, expected):
    assert visual_score_from_det(det, prob_max) == expected


def test_det_score_overrides_noisy_pixel_maximum():
    """หัวใจของ regression: max-prob สูง แต่ det ต่ำ ต้องได้คะแนนต่ำ

    prob_map.max() ของภาพ 12 MP มีพิกเซลราว 12 ล้านจุด ค่าสูงสุดของ noise
    เล็กน้อยจึงเกือบ 1.0 เสมอ โดยไม่เกี่ยวกับการดัดแปลงจริง
    """
    assert visual_score_from_det(0.0029, 0.9988) == 0
    assert visual_score_from_det(0.0, 1.0) == 0


def test_low_max_prob_with_high_det_is_still_high():
    """inpainting มี max-prob แค่ 0.50 แต่เป็นภาพปลอมจริง ต้องได้คะแนนสูง"""
    assert visual_score_from_det(0.9996, 0.5038) == 100


def test_falls_back_to_max_prob_without_det_head():
    """โมเดล single-output (ไม่มี det head) ต้องยังทำงานได้ด้วย max-prob"""
    assert visual_score_from_det(None, 0.87) == 87
    assert visual_score_from_det(None, 0.0) == 0


def test_score_is_always_clamped_to_0_100():
    for det in (-1.0, -0.01, 0.0, 0.5, 1.0, 1.01, 2.0):
        score = visual_score_from_det(det, 0.99)
        assert 0 <= score <= 100
    assert visual_score_from_det(1.5, 0.99) == 100
    assert visual_score_from_det(-0.5, 0.99) == 0


def test_rounding_matches_normalize_spec():
    """Normalize(y) = min(100, round(y * 100)) ตาม configs.md"""
    assert visual_score_from_det(0.4652, 0.9) == 47   # round(46.52)
    assert visual_score_from_det(0.9906, 0.9) == 99   # round(99.06)
    assert visual_score_from_det(0.5, 0.9) == 50