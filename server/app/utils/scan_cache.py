"""Result-cache seam for scan inference (keyed by model namespace + image_hash).

Plain functions taking the client as an argument so tests can pass a fake
without Redis. Behavior identical to the inline code in scan_service.
"""
import hashlib
import json
from typing import Any, Optional

from app.core.config import settings

CACHE_KEY_PREFIX = "scan_result"


def model_cache_namespace() -> str:
    """Stable namespace for the configured ONNX model path.

    Model artifacts use versioned paths. Hashing the configured path keeps old
    Redis entries available for rollback while preventing a new deployment
    from reusing inference produced by the previous model.
    """
    model_path = str(settings.ONNX_MODEL_PATH)
    return hashlib.sha1(model_path.encode("utf-8")).hexdigest()[:12]


def cache_key(image_hash: str) -> str:
    return f"{CACHE_KEY_PREFIX}:{model_cache_namespace()}:{image_hash}"


async def get_cached_scan(client: Any, image_hash: str) -> Optional[dict]:
    """Return cached inference dict, or None on miss/error. Never raises."""
    if client is None:
        return None
    try:
        cached_str = await client.get(cache_key(image_hash))
        if cached_str:
            data = json.loads(cached_str)
            return data if isinstance(data, dict) else None
    except Exception as e:
        print(f"Redis cache read error: {e}")
    return None


async def store_cached_scan(client: Any, image_hash: str, result: dict) -> None:
    """Persist inference dict (must be JSON-serializable). Never raises."""
    if client is None:
        return
    try:
        await client.setex(cache_key(image_hash), settings.SCAN_CACHE_TTL_SECONDS, json.dumps(result))
    except Exception as e:
        print(f"Redis cache write error: {e}")
