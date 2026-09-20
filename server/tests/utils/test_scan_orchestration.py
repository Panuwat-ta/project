import json
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest

import app.core.database as database_core
from app.services import scan_service
from app.utils.scan_cache import cache_key, store_cached_scan


class FakeCache:
    def __init__(self):
        self.store = {}

    async def get(self, key):
        return self.store.get(key)

    async def setex(self, key, _ttl, value):
        self.store[key] = value


class FakeResult:
    def __init__(self, scan):
        self.scan = scan

    def scalars(self):
        return self

    def first(self):
        return self.scan


class FakeDb:
    def __init__(self, scan):
        self.scan = scan
        self.commits = 0

    async def execute(self, _stmt):
        return FakeResult(self.scan)

    async def commit(self):
        self.commits += 1


class FakeSessionContext:
    def __init__(self, db):
        self.db = db

    async def __aenter__(self):
        return self.db

    async def __aexit__(self, exc_type, exc, tb):
        return False


def _scan():
    return SimpleNamespace(
        status="uploading",
        progress=0,
        raw_image_url="",
        heatmap_image_url=None,
        exif_data=None,
        text_score=0,
        visual_score=0,
        source_score=0,
        total_risk_score=0,
        ocr_text=None,
        scam_keywords_found=None,
        ai_gen_probability=0.0,
        xai_explanation=None,
        completed_at=None,
    )


def _wire_pipeline(monkeypatch, tmp_path, scan):
    db = FakeDb(scan)
    monkeypatch.setattr(database_core, "async_session", lambda: FakeSessionContext(db))
    monkeypatch.setattr(scan_service, "load_image_verified", lambda _b: (object(), {"Camera": "test"}))
    monkeypatch.setattr(scan_service, "encode_lossless_png", lambda _img: b"PNG")

    evidence = tmp_path / "evidence.png"
    heatmap = tmp_path / "heatmap.jpg"

    def save_evidence(data, _hash):
        evidence.write_bytes(data)
        return str(evidence)

    def save_heatmap(data, _hash):
        heatmap.write_bytes(data)
        return str(heatmap)

    monkeypatch.setattr(scan_service, "save_evidence_png", save_evidence)
    monkeypatch.setattr(scan_service, "save_heatmap_file", save_heatmap)
    monkeypatch.setattr(scan_service, "heatmap_path", lambda _hash: str(heatmap))
    monkeypatch.setattr(
        scan_service.inference_service,
        "generate_xai_explanation",
        lambda **_kwargs: "คำอธิบาย XAI",
    )
    monkeypatch.setattr(scan_service.manager, "broadcast", AsyncMock())
    return db, evidence, heatmap


@pytest.mark.asyncio
async def test_process_image_background_cache_miss_runs_model_and_caches(monkeypatch, tmp_path):
    scan = _scan()
    db, evidence, heatmap = _wire_pipeline(monkeypatch, tmp_path, scan)
    cache = FakeCache()
    calls = {"predict": 0}

    def predict(_png):
        calls["predict"] += 1
        return {
            "visual_risk_score": 65,
            "ai_gen_probability": 0.65,
            "anomaly_region": "บริเวณกลางภาพ",
            "ocr_text": "ด่วน",
            "heatmap_bytes": b"HEATMAP",
        }

    await scan_service.process_image_background(
        "scan-1", b"RAW", "hash-1", predict_fn=predict, cache_client=cache
    )

    assert calls["predict"] == 1
    assert evidence.read_bytes() == b"PNG"
    assert heatmap.read_bytes() == b"HEATMAP"
    cached = json.loads(cache.store[cache_key("hash-1")])
    assert "heatmap_bytes" not in cached
    assert cached["has_heatmap"] is True
    assert scan.status == "completed"
    assert scan.progress == 100
    assert scan.visual_score == 65
    assert scan.text_score == 25
    assert scan.xai_explanation == "คำอธิบาย XAI"
    assert db.commits >= 6


@pytest.mark.asyncio
async def test_process_image_background_cache_hit_skips_model(monkeypatch, tmp_path):
    scan = _scan()
    _db, _evidence, heatmap = _wire_pipeline(monkeypatch, tmp_path, scan)
    heatmap.write_bytes(b"CACHED-HEATMAP")
    cache = FakeCache()
    await store_cached_scan(
        cache,
        "hash-2",
        {
            "visual_risk_score": 42,
            "ai_gen_probability": 0.42,
            "anomaly_region": "บริเวณด้านซ้ายของภาพ",
            "ocr_text": "",
            "has_heatmap": True,
        },
    )

    def should_not_run(_png):
        raise AssertionError("predict_fn must not run on cache hit")

    await scan_service.process_image_background(
        "scan-2", b"RAW", "hash-2", predict_fn=should_not_run, cache_client=cache
    )

    assert scan.status == "completed"
    assert scan.progress == 100
    assert scan.visual_score == 42
    assert scan.heatmap_image_url == str(heatmap)
