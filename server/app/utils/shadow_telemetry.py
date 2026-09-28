"""Persistent internal telemetry for Det Head shadow rollout.

Stores only scan/model/scoring metadata. It never stores image bytes, OCR text,
titles, or user identifiers, and failures must never fail the scan pipeline.
"""
from __future__ import annotations

import json
import os
import threading
from pathlib import Path
from typing import Any

from app.core.config import SERVER_DIR, TH_TIMEZONE
from datetime import datetime

_LOCK = threading.Lock()
_DEFAULT_PATH = SERVER_DIR / "logs" / "shadow" / "det_head.jsonl"


def shadow_log_path() -> Path:
    configured = os.environ.get("SHADOW_TELEMETRY_PATH")
    return Path(configured).expanduser() if configured else _DEFAULT_PATH


def append_shadow_event(*, scan_id: Any, image_hash: str, cache_hit: bool,
                        inference_result: dict, text_score: int,
                        visual_score: int, total_risk_score: int) -> bool:
    """Append one JSONL event. Returns False instead of raising on I/O errors."""
    try:
        event = {
            "timestamp": datetime.now(TH_TIMEZONE).isoformat(),
            "scan_id": str(scan_id),
            "image_hash_prefix": str(image_hash)[:16],
            "cache_hit": bool(cache_hit),
            "model_id": inference_result.get("onnx_model_id"),
            "det_score": inference_result.get("det_score"),
            "visual_score": int(visual_score),
            "ai_gen_probability": inference_result.get("ai_gen_probability"),
            "text_score": int(text_score),
            "total_risk_score": int(total_risk_score),
            "onnx_latency_ms": inference_result.get("onnx_latency_ms"),
            "onnx_worker_timed_out": bool(inference_result.get("onnx_worker_timed_out", False)),
            "onnx_execution_providers": inference_result.get("onnx_execution_providers", []),
        }
        path = shadow_log_path()
        path.parent.mkdir(parents=True, exist_ok=True)
        line = json.dumps(event, ensure_ascii=False, separators=(",", ":"))
        with _LOCK:
            with path.open("a", encoding="utf-8") as handle:
                handle.write(line + "\n")
        return True
    except Exception as exc:
        print(f"Shadow telemetry write error: {exc}")
        return False
