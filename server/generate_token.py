import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker
from app.core.database import engine
from app.models.admin import Admin
from app.core.security import create_access_token
from app.core.config import settings

async def generate():
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as db:
        admin = Admin(
            email="admin@scamguard.local",
            hashed_password="hashed_dummy",
            full_name="System Admin",
            is_active=True,
            is_superadmin=True
        )
        db.add(admin)
        await db.commit()
        await db.refresh(admin)

        encoded_jwt = create_access_token(data={"sub": str(admin.id), "role": "admin"})
        print("TEST_ADMIN_TOKEN=" + encoded_jwt)

if __name__ == "__main__":
    asyncio.run(generate())