import asyncio
import getpass
import sys
import os

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.core.database import SessionLocal
from app.models.admin import Admin
from app.core.security import hash_password
from sqlalchemy.future import select

async def main():
    print("=== ScamGuard SuperAdmin Bootstrap ===")
    email = input("Enter email for SuperAdmin: ").strip()
    if not email:
        print("Error: Email cannot be empty.")
        return

    full_name = input("Enter full name (e.g. Super Administrator): ").strip()
    if not full_name:
        full_name = "Super Administrator"

    password = getpass.getpass("Enter password: ")
    if len(password) < 8:
        print("Error: Password must be at least 8 characters.")
        return
        
    password_confirm = getpass.getpass("Confirm password: ")
    if password != password_confirm:
        print("Error: Passwords do not match.")
        return

    async with SessionLocal() as db:
        result = await db.execute(select(Admin).where(Admin.email == email))
        existing_admin = result.scalars().first()
        if existing_admin:
            print(f"\nAdmin with email '{email}' already exists.")
            update = input("Do you want to reset their password and ensure superadmin status? (y/N): ")
            if update.lower() == 'y':
                existing_admin.hashed_password = hash_password(password)
                existing_admin.is_superadmin = True
                existing_admin.is_active = True
                await db.commit()
                print("SuperAdmin updated successfully.")
            else:
                print("Operation cancelled.")
            return

        new_admin = Admin(
            email=email,
            full_name=full_name,
            hashed_password=hash_password(password),
            is_superadmin=True,
            is_active=True
        )
        db.add(new_admin)
        await db.commit()
        print(f"\nSuperAdmin '{email}' created successfully.")

if __name__ == "__main__":
    asyncio.run(main())
