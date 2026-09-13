from fastapi import Request, APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.rate_limit import limiter, USER_LIMIT
from app.core.database import get_db
from app.schemas.auth import DeleteAccountRequest, DeleteAccountResponse
from app.models.user import User
from app.api.deps import get_current_user
from app.services.user_service import delete_account

router = APIRouter()


@router.delete("/me", response_model=DeleteAccountResponse)
@limiter.limit(USER_LIMIT)
async def delete_me(
    request: Request,
    body: DeleteAccountRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """DELETE /api/v1/users/me - ลบบัญชีตัวเอง (soft-delete, ต้องยืนยันรหัสผ่าน)."""
    await delete_account(db, current_user, body.password)
    return DeleteAccountResponse()
