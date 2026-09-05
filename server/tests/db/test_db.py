import sys
import asyncio
import asyncpg
from pathlib import Path

# Add server directory to path if needed
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from app.core.config import settings

async def main():
    db_dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    try:
        conn = await asyncpg.connect(db_dsn)
        print("Success:", db_dsn)
        await conn.close()
    except Exception as e:
        print("Failed connection:", e)
asyncio.run(main())
