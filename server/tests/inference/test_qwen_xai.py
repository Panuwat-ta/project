import pytest
from app.services.inference_service import inference_service

def test_qwen_xai_model_loaded():
    """Verify that Qwen2.5-1.5B XAI model is successfully loaded."""
    assert inference_service.xai_model is not None, "Qwen2.5-1.5B model should be loaded into inference_service"

def test_qwen_xai_explanation_generation():
    """Test generating explanation using Qwen2.5-1.5B model."""
    region = "บริเวณข้อความยอดเงินและตราประทับ"
    visual_score = 85
    ai_gen_probability = 0.90
    scam_keywords = ["ยอดเงิน", "โอนเงินสำเร็จ"]

    explanation = inference_service.generate_xai_explanation(
        region=region,
        visual_score=visual_score,
        ai_gen_probability=ai_gen_probability,
        scam_keywords=scam_keywords
    )

    assert isinstance(explanation, str)
    assert len(explanation) > 10
    # Ensure it did not fall back to the generic static fallback string
    assert "ไม่พบร่องรอยการตัดต่อที่ส่งผลต่อความเสี่ยงอย่างมีนัยสำคัญ" not in explanation
