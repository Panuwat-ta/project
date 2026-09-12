import pytest
from app.main import app
from app.core.rate_limit import limiter


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