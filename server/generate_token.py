import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker
from app.core.database import engine
from app.models.admin import Admin
from jose import jwt
from app.core.config import settings
from datetime import datetime, timedelta

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
        
        expire = datetime.utcnow() + timedelta(days=365)
        to_encode = {"exp": expire, "sub": str(admin.id)}
        encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
        print("TEST_ADMIN_TOKEN=" + encoded_jwt)

if __name__ == "__main__":
    asyncio.run(generate())
