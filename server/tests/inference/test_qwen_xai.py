import pytest
from app.services.inference_service import inference_service

def test_qwen_xai_model_loaded():
    """Verify that Qwen2.5-1.5B XAI model is successfully configured and accessible."""
    import os
    from app.core.config import settings
    xai_path = getattr(settings, "XAI_MODEL_PATH", "/home/panuwat/project/model/Qwen2.5-1.5B/qwen2.5-1.5b-instruct-q4_k_m.gguf")
    assert os.path.exists(xai_path), f"Qwen2.5-1.5B model file must exist at {xai_path}"
    if inference_service.xai_model is not None:
        assert hasattr(inference_service.xai_model, "model_path")

def test_qwen_xai_explanation_generation():
    """Test generating explanation using Qwen2.5-1.5B model or intelligent fallback."""
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
