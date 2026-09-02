import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def main():
    engine = create_async_engine(
        "postgresql+asyncpg://scamguard:password@localhost/scamguard_db",
        connect_args={"server_settings": {"timezone": "Asia/Bangkok"}}
    )
    async with engine.connect() as conn:
        result = await conn.execute(text("SELECT CURRENT_TIMESTAMP, NOW();"))
        row = result.fetchone()
        print("DB Time with TZ:", row)

asyncio.run(main())
