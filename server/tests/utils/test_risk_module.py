"""Regression + contract tests for the unified RiskScore module.

(a) equivalence: grade_for(stored_total, visual) agrees with
    calculate_risk_score(t, v, s)["grade"] on every grid point, so the
    admin/mobile read paths can never diverge from the scan path.
(b) contract: canonical keys total_risk_score / risk_grade / breakdown.
(c) builders: keyword heuristic and unavailable-source default.
"""
import itertools

from app.schemas.scan import ScanResponse
from app.utils.risk_calculator import (
    build_source_score,
    build_text_analysis,
    calculate_risk_score,
    grade_for,
)


def test_grade_for_matches_calculator_on_full_grid():
    for t, v, s in itertools.product(range(0, 101, 5), repeat=3):
        res = calculate_risk_score(t, v, s)
        assert grade_for(res["total_risk_score"], v) == res["grade"], (t, v, s, res)


def test_visual_override_equivalence_on_stored_totals():
    # stored totals are clamped to >= 70 when the override fires; the read
    # path must still report high without recomputing the formula.
    res = calculate_risk_score(text_score=0, visual_score=85, source_score=20)
    assert res["total_risk_score"] == 85
    assert grade_for(res["total_risk_score"], 85) == "high"
    res = calculate_risk_score(text_score=50, visual_score=80, source_score=0)
    assert grade_for(res["total_risk_score"], 80) == "high"


def test_canonical_contract_keys():
    res = calculate_risk_score(text_score=10, visual_score=20, source_score=30)
    assert set(res) == {"total_risk_score", "grade", "primary_factor", "is_multi_risk", "breakdown"}
    assert set(res["breakdown"]) == {"visual_score", "text_score", "source_score"}
    assert res["grade"] in ("low", "medium", "high")


def test_build_text_analysis_keyword_heuristic():
    score, found = build_text_analysis("ด่วน ลงทุน คลิกเลย")
    assert score == 75
    assert found == ["ด่วน", "ลงทุน", "คลิก"]
    score, found = build_text_analysis("สวัสดีครับ")
    assert (score, found) == (0, [])
    score, found = build_text_analysis("")
    assert (score, found) == (0, [])


def test_build_text_analysis_caps_at_100():
    score, found = build_text_analysis("ด่วน โบนัส กู้เงิน รับเงิน ลงทุน คลิก")
    assert score == 100
    assert len(found) == 6


def test_unavailable_source_has_no_score_and_does_not_affect_risk():
    assert build_source_score() is None
    res = calculate_risk_score(text_score=10, visual_score=20, source_score=None)
    assert res["total_risk_score"] == 20
    assert res["primary_factor"] == "visual"
    assert res["breakdown"]["source_score"] is None


def test_scan_response_hides_legacy_storage_placeholder_when_source_unavailable():
    from datetime import datetime, timezone
    from uuid import uuid4

    response = ScanResponse(
        id=uuid4(),
        image_hash="abc",
        raw_image_url="/uploads/a.png",
        text_score=10,
        visual_score=20,
        source_score=20,
        source_status="unavailable",
        total_risk_score=20,
        ai_gen_probability=0.0,
        status="completed",
        created_at=datetime.now(timezone.utc),
    )
    dumped = response.model_dump()
    assert dumped["source_status"] == "unavailable"
    assert dumped["source_score"] is None
