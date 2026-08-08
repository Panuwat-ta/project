import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import asyncio
import sys
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.future import select
from app.core.database import engine
from app.models.admin import Admin
from app.core.security import hash_password

async def create_admin(email, password, full_name):
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as db:
        # Check if exists
        result = await db.execute(select(Admin).where(Admin.email == email))
        admin = result.scalars().first()
        
        if admin:
            print(f"Admin with email {email} already exists. Updating password...")
            admin.hashed_password = hash_password(password)
            admin.full_name = full_name
            await db.commit()
            print(f"Admin '{email}' updated successfully.")
            return

        new_admin = Admin(
            email=email,
            hashed_password=hash_password(password),
            full_name=full_name,
            is_active=True,
            is_superadmin=True
        )
        db.add(new_admin)
        await db.commit()
        print(f"Admin '{email}' created successfully.")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python create_admin.py <email> <password> <full_name>")
        sys.exit(1)
    
    asyncio.run(create_admin(sys.argv[1], sys.argv[2], sys.argv[3]))
