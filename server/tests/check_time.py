import asyncio
from app.core.database import async_session
from sqlalchemy import text

async def main():
    async with async_session() as session:
        result = await session.execute(text("SELECT CURRENT_TIMESTAMP, NOW();"))
        row = result.fetchone()
        print("DB Time:", row)

asyncio.run(main())
