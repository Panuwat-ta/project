"""Tests for the scan pipeline seams: result cache + image store.

Both run without Redis, DB, GPU, or model files.
"""
import json
import os

import pytest

from app.core.config import settings
from app.utils.scan_cache import cache_key, get_cached_scan, store_cached_scan
from app.utils import image_utils


class FakeCache:
    def __init__(self):
        self.store = {}
        self.ttls = {}

    async def get(self, key):
        return self.store.get(key)

    async def setex(self, key, ttl, value):
        self.store[key] = value
        self.ttls[key] = ttl


@pytest.mark.asyncio
async def test_cache_miss_returns_none():
    assert await get_cached_scan(FakeCache(), "abc") is None
    assert await get_cached_scan(None, "abc") is None


@pytest.mark.asyncio
async def test_cache_roundtrip_and_ttl():
    client = FakeCache()
    result = {"visual_risk_score": 10, "ocr_text": "x"}
    await store_cached_scan(client, "abc", result)
    assert await get_cached_scan(client, "abc") == result
    assert client.ttls[cache_key("abc")] == settings.SCAN_CACHE_TTL_SECONDS
    assert json.loads(client.store[cache_key("abc")]) == result


@pytest.mark.asyncio
async def test_cache_never_raises():
    class Boom:
        async def get(self, key):
            raise RuntimeError("down")

        async def setex(self, *a):
            raise RuntimeError("down")

    assert await get_cached_scan(Boom(), "abc") is None
    await store_cached_scan(Boom(), "abc", {})
    await store_cached_scan(None, "abc", {})


def test_image_store_roundtrip(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "LOCAL_UPLOAD_DIR", str(tmp_path))
    png_path = image_utils.save_evidence_png(b"PNGDATA", "h1")
    assert png_path == os.path.join(str(tmp_path), "h1.png")
    assert open(png_path, "rb").read() == b"PNGDATA"

    hm_path = image_utils.save_heatmap_file(b"JPGDATA", "h1")
    assert hm_path == os.path.join(str(tmp_path), "heatmaps", "h1_heatmap.jpg")
    assert open(hm_path, "rb").read() == b"JPGDATA"
    assert image_utils.heatmap_path("h1") == hm_path
