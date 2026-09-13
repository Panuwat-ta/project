import pytest
from app.main import app
from app.core.rate_limit import limiter


@pytest.fixture(autouse=True)
def mock_redis_client():
    """TestClient ไม่รัน lifespan -> redis_client เป็น None -> /health degraded.

    mock ping() ให้ตอบ ok ทุกเทส (เทสสโคป DB/schema ไม่เกี่ยวกับ redis ตัวจริง).
    """
    from unittest.mock import AsyncMock
    import app.core.redis as redis_core
    fake = AsyncMock()
    fake.ping = AsyncMock(return_value=True)
    prev, redis_core.redis_client = redis_core.redis_client, fake
    yield
    redis_core.redis_client = prev


@pytest.fixture(autouse=True)
def clear_dependency_overrides():
    app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def reset_rate_limit_storage():
    """ล้าง quota ของ slowapi (in-memory) ทุกเทส กันเทสก่อนหน้าใช้โควต้าหมด (DOC-07)."""
    storage = limiter._storage
    try:
        storage.reset()
    except Exception:
        from limits.storage import MemoryStorage
        limiter._storage = MemoryStorage()
    yield