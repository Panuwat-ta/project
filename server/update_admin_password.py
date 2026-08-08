import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker
from app.core.database import engine
from app.models.admin import Admin
from sqlalchemy.future import select
from app.core.security import hash_password

async def update_pw():
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as db:
        result = await db.execute(select(Admin).where(Admin.email == 'admin@scamguard.local'))
        admin = result.scalars().first()
        if admin:
            admin.hashed_password = hash_password('admin123')
            await db.commit()
            print("Password updated to admin123")
        else:
            print("Admin not found")

if __name__ == "__main__":
    asyncio.run(update_pw())
