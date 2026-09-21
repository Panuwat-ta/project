from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from jose import JWTError

from app.core.database import get_db

from app.core.security import decode_access_token
from app.models.user import User
from app.models.admin import Admin
from app.services.admin_access_policy import (
    AdminAccountDisabled,
    InvalidAdminCredentials,
    resolve_admin_access,
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception
    user_id: str = payload.get("sub")
    if user_id is None:
        raise credentials_exception

    result = await db.execute(select(User).where(User.id == int(user_id)))
    user = result.scalars().first()
    if user is None:
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(status_code=403, detail="User account is disabled")
    return user


async def get_current_admin(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)) -> Admin:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate admin credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        admin, _session = await resolve_admin_access(token, db)
    except AdminAccountDisabled as exc:
        raise HTTPException(status_code=403, detail="Admin account is disabled") from exc
    except InvalidAdminCredentials as exc:
        raise credentials_exception from exc
    return admin


async def require_super_admin(admin: Admin = Depends(get_current_admin)) -> Admin:
    """ทุก /admin/* ต้องเป็น Super Admin เท่านั้น (บังคับ is_superadmin)"""
    if not admin.is_superadmin:
        raise HTTPException(status_code=403, detail="Super Admin access required")
    return admin