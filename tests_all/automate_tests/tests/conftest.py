"""Global conftest — เตรียม sys.path ให้ import app จาก server ได้"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SERVER = ROOT / "server"
if str(SERVER) not in sys.path:
    sys.path.insert(0, str(SERVER))

# ล้าง dependency_overrides ก่อน/หลังทุก test
import pytest

@pytest.fixture(autouse=True)
def clear_overrides():
    try:
        from app.main import app
        app.dependency_overrides.clear()
        yield
        app.dependency_overrides.clear()
    except Exception:
        yield

@pytest.fixture(autouse=True)
async def dispose_engine_after_test():
    yield
    try:
        from app.core.database import engine
        await engine.dispose()
    except Exception:
        pass

