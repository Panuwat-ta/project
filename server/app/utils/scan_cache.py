"""Result-cache seam for scan inference (keyed by image_hash).

Plain functions taking the client as an argument so tests can pass a fake
without Redis. Behavior identical to the inline code in scan_service.
"""
import json
from typing import Any, Optional

from app.core.config import settings

CACHE_KEY_PREFIX = "scan_result"


def cache_key(image_hash: str) -> str:
    return f"{CACHE_KEY_PREFIX}:{image_hash}"


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
