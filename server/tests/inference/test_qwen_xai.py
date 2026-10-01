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
    manipulation_confidence = 0.90
    scam_keywords = ["ยอดเงิน", "โอนเงินสำเร็จ"]

    explanation = inference_service.generate_xai_explanation(
        region=region,
        visual_score=visual_score,
        manipulation_confidence=manipulation_confidence,
        scam_keywords=scam_keywords
    )

    assert isinstance(explanation, str)
    assert len(explanation) > 10
    # Ensure it did not fall back to the generic static fallback string
    assert "ไม่พบร่องรอยการตัดต่อที่ส่งผลต่อความเสี่ยงอย่างมีนัยสำคัญ" not in explanation

# คำต้องห้ามใน prompt และข้อความขาออก: โมเดลไม่มีความสามารถวัดการสังเคราะห์
# ด้วย AI (seg มีแค่ 2 คลาส, det head เป็น binary) ดังนั้นทั้ง few-shot example
# และข้อความที่ generate ต้องไม่มีคำกล่าวอ้างเรื่อง AI-generation หรือระดับพิกเซล
# (พบรั่วเมื่อ 2026-10-01: few-shot เก่าสอนว่า "โอกาสสังเคราะห์ด้วย AI"
# ทำให้ output จริงมีประโยค "ภาพถูกส่งเสริมโดย AI อยู่ในเกณฑ์ต่ำ")
FORBIDDEN_XAI_PHRASES = [
    "สังเคราะห์",
    "AI-Generated",
    "AI-generated",
    "พิกเซลมีความเป็นธรรมชาติ",
    "โครงสร้างพิกเซล",
    "โอกาส AI:",
]


def test_qwen_prompt_has_no_ai_generation_claims():
    """ตรวจ source ของ prompt ว่าไม่มีคำกล่าวอ้าง AI-generation หลงเหลือ"""
    import inspect
    from app.services import inference_service as mod

    src = inspect.getsource(mod.InferenceService.generate_xai_explanation)
    for phrase in FORBIDDEN_XAI_PHRASES:
        assert phrase not in src, f"prompt ยังมีคำต้องห้าม '{phrase}'"
