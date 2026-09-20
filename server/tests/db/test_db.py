import asyncpg
import pytest

from app.core.config import settings


def _asyncpg_dsn() -> str:
    return settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")


@pytest.mark.asyncio
async def test_database_accepts_select_one():
    conn = await asyncpg.connect(_asyncpg_dsn(), timeout=3)
    try:
        assert await conn.fetchval("SELECT 1") == 1
    finally:
        await conn.close()
