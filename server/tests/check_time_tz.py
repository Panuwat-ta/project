import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.core.config import settings

async def main():
    engine = create_async_engine(
        settings.DATABASE_URL,
        connect_args={"server_settings": {"timezone": "Asia/Bangkok"}}
    )
    async with engine.connect() as conn:
        result = await conn.execute(text("SELECT CURRENT_TIMESTAMP, NOW();"))
        row = result.fetchone()
        print("DB Time with TZ:", row)

asyncio.run(main())
