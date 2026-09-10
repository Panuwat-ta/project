import asyncio
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine
from app.core.config import settings

async def test():
    engine = create_async_engine(settings.DATABASE_URL)
    async with engine.connect() as conn:
        res = await conn.execute(text('SELECT email, full_name FROM users LIMIT 5;'))
        print(res.fetchall())

asyncio.run(test())
