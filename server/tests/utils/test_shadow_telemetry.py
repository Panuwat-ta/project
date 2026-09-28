import json

from app.utils.shadow_telemetry import append_shadow_event


def test_shadow_event_contains_only_expected_metadata(tmp_path, monkeypatch):
    path = tmp_path / "shadow.jsonl"
    monkeypatch.setenv("SHADOW_TELEMETRY_PATH", str(path))
    inference = {
        "onnx_model_id": "det2b.onnx",
        "det_score": 0.91,
        "ai_gen_probability": 0.72,
        "onnx_latency_ms": 1234,
        "onnx_worker_timed_out": False,
        "onnx_execution_providers": ["CUDAExecutionProvider"],
        "ocr_text": "must not be logged",
    }
    assert append_shadow_event(
        scan_id="scan-1", image_hash="a" * 64, cache_hit=False,
        inference_result=inference, text_score=25,
        visual_score=72, total_risk_score=77,
    ) is True
    data = json.loads(path.read_text().strip())
    assert data["scan_id"] == "scan-1"
    assert data["image_hash_prefix"] == "a" * 16
    assert data["det_score"] == 0.91
    assert data["visual_score"] == 72
    assert data["onnx_execution_providers"] == ["CUDAExecutionProvider"]
    assert "ocr_text" not in data
    assert "user_id" not in data
