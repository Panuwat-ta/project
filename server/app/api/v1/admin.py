from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.deps import get_current_admin
from app.models.admin import Admin as AdminModel
from app.schemas.admin import (
    DashboardResponse, AdminReportListResponse, AdminReportDetailResponse, 
    ReportDecisionRequest, UserAdminListResponse, UserAdminDetailResponse, 
    UserUpdateRequest, ModelVersionListResponse, AuditLogListResponse
)
from app.services import admin_service

from fastapi import HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.future import select
from app.core.security import verify_password, create_access_token, create_refresh_token
from app.models.admin import Admin
from app.schemas.auth import TokenResponse, RefreshTokenRequest

router = APIRouter()

@router.post("/login", response_model=TokenResponse)
async def admin_login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Admin).where(Admin.email == form_data.username))
    admin = result.scalars().first()
    
    if not admin or not verify_password(form_data.password, admin.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not admin.is_active:
        raise HTTPException(status_code=403, detail="Admin account is disabled")

    claims = {"sub": str(admin.id), "role": "admin"}
    return TokenResponse(
        access_token=create_access_token(data=claims),
        refresh_token=create_refresh_token(data=claims),
        user={"id": admin.id, "email": admin.email, "full_name": admin.full_name, "role": "admin"}
    )

@router.post("/refresh", response_model=TokenResponse)
async def admin_refresh_token(body: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    from app.core.security import decode_refresh_token
    payload = decode_refresh_token(body.refresh_token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    admin_id = payload.get("sub")
    if admin_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    result = await db.execute(select(Admin).where(Admin.id == int(admin_id)))
    admin = result.scalars().first()
    if admin is None:
        raise HTTPException(status_code=403, detail="Admin not found")
    if not admin.is_active:
        raise HTTPException(status_code=403, detail="Admin account is disabled")

    claims = {"sub": str(admin.id), "role": "admin"}
    return TokenResponse(
        access_token=create_access_token(data=claims),
        refresh_token=create_refresh_token(data=claims),
        user={"id": admin.id, "email": admin.email, "full_name": admin.full_name, "role": "admin"}
    )

@router.get("/dashboard", response_model=DashboardResponse)
async def get_dashboard(
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(get_current_admin)
):
    """GET /api/v1/admin/dashboard"""
    return await admin_service.get_dashboard_stats(db)

@router.get("/reports", response_model=AdminReportListResponse)
async def get_reports(
    page: int = 1,
    limit: int = 20,
    status: str = None,
    category: str = None,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(get_current_admin)
):
    """GET /api/v1/admin/reports"""
    items, total = await admin_service.get_reports(db, page, limit, status, category)
    return {"items": items, "total": total, "page": page, "limit": limit}

@router.patch("/reports/{report_id}")
async def review_report(
    report_id: int,
    decision: ReportDecisionRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(get_current_admin)
):
    """PATCH /api/v1/admin/reports/{report_id}"""
    report = await admin_service.review_report(db, report_id, current_admin.id, decision)
    return {
        "id": report.id,
        "status": report.status,
        "admin_note": report.admin_note,
        "moderated_by": report.moderated_by,
        "moderated_at": report.moderated_at,
        "message": "อัปเดตสถานะรายงานเรียบร้อยแล้ว"
    }

@router.get("/users", response_model=UserAdminListResponse)
async def get_users(
    page: int = 1,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(get_current_admin)
):
    """GET /api/v1/admin/users"""
    items, total = await admin_service.get_users(db, page, limit)
    return {"items": items, "total": total, "page": page, "limit": limit}

@router.patch("/users/{user_id}")
async def update_user(
    user_id: int,
    update_req: UserUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(get_current_admin)
):
    """PATCH /api/v1/admin/users/{user_id}"""
    user = await admin_service.update_user(db, user_id, current_admin.id, update_req)
    return {
        "id": user.id,
        "email": user.email,
        "role": user.role,
        "is_active": user.is_active,
        "message": "อัปเดตข้อมูลผู้ใช้เรียบร้อยแล้ว"
    }

@router.get("/models", response_model=ModelVersionListResponse)
async def get_models(
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(get_current_admin)
):
    """GET /api/v1/admin/models"""
    items, total = await admin_service.get_model_versions(db)
    return {"items": items, "total": total}

@router.post("/models/{model_id}/deploy")
async def deploy_model(
    model_id: int,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(get_current_admin)
):
    """POST /api/v1/admin/models/{model_id}/deploy"""
    model = await admin_service.deploy_model(db, model_id, current_admin.id)
    return {
        "id": model.id,
        "version_tag": model.version_tag,
        "is_active": model.is_active,
        "deployed_at": model.deployed_at,
        "message": f"Deploy โมเดลเวอร์ชัน {model.version_tag} สำเร็จ"
    }

@router.get("/audit-logs", response_model=AuditLogListResponse)
async def get_audit_logs(
    page: int = 1,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(get_current_admin)
):
    """GET /api/v1/admin/audit-logs"""
    items, total = await admin_service.get_audit_logs(db, page, limit)
    return {"items": items, "total": total, "page": page, "limit": limit}
