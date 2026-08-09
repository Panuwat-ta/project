import os
from fastapi import APIRouter, Depends, Request, Response, Cookie
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.deps import require_super_admin
from app.models.admin import Admin as AdminModel
from app.models.admin_session import AdminSession
from app.schemas.admin import (
    DashboardResponse, AdminReportListResponse, AdminReportDetailResponse, 
    ReportDecisionRequest, UserAdminListResponse, UserAdminDetailResponse, 
    UserUpdateRequest, ModelVersionListResponse, AuditLogListResponse, ExportRequest,
    AdminProfileResponse, AdminProfileUpdateRequest, AdminSessionResponse, AdminSessionListResponse,
    HealthStatus, GlobalSearchResponse, ModelDeployRequest, ModelDryRunResponse, ExportJobResponse, ExportJobListResponse,
)
from app.services import admin_service

from fastapi import HTTPException, status
from fastapi.responses import FileResponse
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.background import BackgroundTasks
from sqlalchemy.future import select
from sqlalchemy import desc
from app.core.security import (
    verify_password, hash_password, create_access_token, create_refresh_token,
    decode_refresh_token,
)
from app.models.admin import Admin
from app.schemas.auth import TokenResponse, RefreshTokenRequest
from app.core.config import TH_TIMEZONE, settings
from app.core.rate_limit import limiter

router = APIRouter()


def _user_payload(admin: Admin) -> dict:
    return {
        "id": admin.id,
        "email": admin.email,
        "full_name": admin.full_name,
        "role": "admin",
        "is_superadmin": admin.is_superadmin,
    }


@router.post("/login", response_model=TokenResponse)
@limiter.limit("5/minute")
async def admin_login(
    request: Request,
    response: Response,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Admin).where(Admin.email == form_data.username))
    admin = result.scalars().first()

    # Generic error เพื่อลด account enumeration
    if not admin or not verify_password(form_data.password, admin.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not admin.is_active:
        raise HTTPException(status_code=403, detail="Admin account is disabled")

    claims = {"sub": str(admin.id), "role": "admin"}
    import uuid
    sid = uuid.uuid4().hex
    refresh_raw = create_refresh_token(data=claims, sid=sid)
    await admin_service.create_admin_session(
        db, admin, refresh_raw,
        ip=request.client.host if request else None,
        user_agent=request.headers.get("user-agent") if request else None,
        sid=sid
    )
    access_token = create_access_token(data=claims, sid=sid)
    
    response.set_cookie(
        key="admin_refresh_token",
        value=refresh_raw,
        httponly=True,
        secure=settings.SECURE_COOKIES,
        samesite="lax",
        max_age=settings.JWT_REFRESH_TOKEN_EXPIRE_MINUTES * 60,
        path="/api/v1/admin/"
    )
    
    return TokenResponse(
        access_token=access_token,
        user=_user_payload(admin)
    )


@router.post("/refresh", response_model=TokenResponse)
@limiter.limit("5/minute")
async def admin_refresh_token(
    request: Request,
    response: Response,
    admin_refresh_token: str = Cookie(None),
    db: AsyncSession = Depends(get_db),
):
    if not admin_refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token is missing",
            headers={"WWW-Authenticate": "Bearer"},
        )
    payload = decode_refresh_token(admin_refresh_token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    admin_id = payload.get("sub")
    old_sid = payload.get("sid")
    if admin_id is None or old_sid is None:
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
    access_token, refresh_raw, _ = await admin_service.rotate_admin_session(
        db, old_sid, claims,
        ip=request.client.host if request else None,
        user_agent=request.headers.get("user-agent") if request else None,
    )
    
    response.set_cookie(
        key="admin_refresh_token",
        value=refresh_raw,
        httponly=True,
        secure=settings.SECURE_COOKIES,
        samesite="lax",
        max_age=settings.JWT_REFRESH_TOKEN_EXPIRE_MINUTES * 60,
        path="/api/v1/admin/"
    )
    
    return TokenResponse(
        access_token=access_token,
        user=_user_payload(admin)
    )


@router.post("/logout")
async def admin_logout(
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """เพิกถอน session ปัจจุบัน — refresh ต่อไม่ได้ และ access token เก่าถูกปฏิเสธทันที"""
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    from app.core.security import decode_access_token
    payload = decode_access_token(token)
    sid = payload.get("sid") if payload else None
    if sid:
        await admin_service.revoke_admin_session(db, current_admin.id, sid)
    
    response.delete_cookie("admin_refresh_token", path="/api/v1/admin/")
    return {"message": "ออกจากระบบแล้ว"}


@router.get("/me", response_model=AdminProfileResponse)
async def get_me(
    current_admin: AdminModel = Depends(require_super_admin),
):
    return _user_payload(current_admin)


@router.patch("/me", response_model=AdminProfileResponse)
async def update_me(
    body: AdminProfileUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """แก้ไขโปรไฟล์/รหัสผ่าน — เปลี่ยนรหัสต้องยืนยันรหัสเดิม"""
    if body.full_name is not None:
        current_admin.full_name = body.full_name
    if body.new_password is not None:
        if not body.current_password or not verify_password(body.current_password, current_admin.hashed_password):
            raise HTTPException(status_code=400, detail="รหัสผ่านเดิมไม่ถูกต้อง")
        if len(body.new_password) < 8:
            raise HTTPException(status_code=400, detail="รหัสผ่านใหม่ต้องยาวอย่างน้อย 8 ตัวอักษร")
        current_admin.hashed_password = hash_password(body.new_password)
    await db.commit()
    await db.refresh(current_admin)
    return _user_payload(current_admin)


@router.get("/sessions", response_model=AdminSessionListResponse)
async def get_sessions(
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """รายการ sessions ทั้งหมดของ admin (สำหรับหน้า Profile/ความปลอดภัย)"""
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    from app.core.security import decode_access_token
    current_sid = decode_access_token(token).get("sid") if token else None

    result = await db.execute(
        select(AdminSession)
        .where(AdminSession.admin_id == current_admin.id)
        .order_by(desc(AdminSession.created_at))
    )
    sessions = result.scalars().all()
    return {
        "items": [
            {
                "id": s.id,
                "is_current": s.id == current_sid,
                "user_agent": s.user_agent,
                "ip_address": s.ip_address,
                "created_at": s.created_at,
                "last_used_at": s.last_used_at,
                "expires_at": s.expires_at,
                "revoked_at": s.revoked_at,
            }
            for s in sessions
        ],
        "total": len(sessions),
    }


@router.post("/sessions/{session_id}/revoke")
async def revoke_session(
    session_id: str,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """เพิกถอน session อื่นทันที (ยกเลิก token ได้จริง)"""
    session = await admin_service.revoke_admin_session(db, current_admin.id, session_id)
    return {
        "id": session.id,
        "revoked_at": session.revoked_at,
        "message": "เพิกถอน session เรียบร้อยแล้ว",
    }


@router.get("/dashboard", response_model=DashboardResponse)
async def get_dashboard(
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/dashboard"""
    return await admin_service.get_dashboard_stats(db)

@router.get("/health", response_model=HealthStatus)
async def get_health(
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/health"""
    return await admin_service.get_health_status(db)

@router.get("/search", response_model=GlobalSearchResponse)
async def search_global(
    q: str,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/search"""
    return await admin_service.global_search(db, q)


@router.get("/reports", response_model=AdminReportListResponse)
async def get_reports(
    page: int = 1,
    limit: int = 20,
    status: str = None,
    category: str = None,
    search: str = None,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/reports"""
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1 or limit > 100:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 100")
    items, total = await admin_service.get_reports(db, page, limit, status, category, search)
    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": max(1, (total + limit - 1) // limit),
    }


from app.services import export_service

@router.post("/dataset/export-jobs", response_model=ExportJobResponse)
async def create_export_job(
    req: ExportRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """POST /api/v1/admin/dataset/export-jobs"""
    job = await export_service.create_export_job(db, current_admin.id, req.model_dump())
    background_tasks.add_task(export_service.process_export_job, str(job.id))
    return job

@router.get("/dataset/export-jobs", response_model=ExportJobListResponse)
async def list_export_jobs(
    page: int = 1,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/dataset/export-jobs"""
    from sqlalchemy import select, func, desc
    from app.models import ExportJob
    
    stmt = select(ExportJob).order_by(desc(ExportJob.created_at))
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = await db.scalar(count_stmt)
    
    stmt = stmt.offset((page - 1) * limit).limit(limit)
    result = await db.execute(stmt)
    items = result.scalars().all()
    
    return {"items": items, "total": total, "page": page, "limit": limit}

@router.get("/dataset/export-jobs/{job_id}", response_model=ExportJobResponse)
async def get_export_job(
    job_id: str,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/dataset/export-jobs/{job_id}"""
    from sqlalchemy import select
    from app.models import ExportJob
    stmt = select(ExportJob).where(ExportJob.id == job_id)
    job = (await db.execute(stmt)).scalar_one_or_none()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return job

@router.post("/dataset/export-jobs/{job_id}/cancel")
async def cancel_export_job(
    job_id: str,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """POST /api/v1/admin/dataset/export-jobs/{job_id}/cancel"""
    from sqlalchemy import select
    from app.models import ExportJob
    stmt = select(ExportJob).where(ExportJob.id == job_id)
    job = (await db.execute(stmt)).scalar_one_or_none()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
        
    if job.status in ["queued", "running"]:
        job.status = "canceled"
        await db.commit()
    
    return {"message": "Job canceled"}

@router.get("/dataset/export-jobs/{job_id}/download")
async def download_export_job(
    job_id: str,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/dataset/export-jobs/{job_id}/download"""
    from sqlalchemy import select
    from app.models import ExportJob
    from fastapi.responses import FileResponse
    import os
    
    stmt = select(ExportJob).where(ExportJob.id == job_id)
    job = (await db.execute(stmt)).scalar_one_or_none()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
        
    if job.status != "succeeded" or not job.file_path or not os.path.exists(job.file_path):
        raise HTTPException(status_code=404, detail="Export file not ready or expired")
        
    return FileResponse(
        path=job.file_path, 
        filename=os.path.basename(job.file_path),
        media_type="application/zip"
    )

@router.get("/reports/{report_id}", response_model=AdminReportDetailResponse)
async def get_report_detail(
    report_id: int,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/reports/{report_id}"""
    return await admin_service.get_report_detail(db, report_id)


@router.post("/reports/{report_id}/review")
async def start_review(
    report_id: int,
    request: Request,
    body: dict,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """POST /api/v1/admin/reports/{report_id}/review"""
    version = body.get("version")
    if version is None:
        raise HTTPException(status_code=400, detail="version is required")
    report = await admin_service.start_review_report(
        db, report_id, current_admin.id, version,
        ip=request.client.host if request else None,
        user_agent=request.headers.get("user-agent") if request else None,
    )
    return {
        "id": report.id,
        "status": report.status,
        "version": report.version,
        "message": "เริ่มตรวจสอบรายงาน"
    }


@router.patch("/reports/{report_id}")
async def review_report(
    report_id: int,
    decision: ReportDecisionRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """PATCH /api/v1/admin/reports/{report_id}"""
    report = await admin_service.review_report(
        db, report_id, current_admin.id, decision,
        ip=request.client.host if request else None,
        user_agent=request.headers.get("user-agent") if request else None,
    )
    return {
        "id": report.id,
        "status": report.status,
        "version": report.version,
        "admin_note": report.admin_note,
        "moderated_by": report.moderated_by,
        "moderated_at": report.moderated_at,
        "message": "อัปเดตสถานะรายงานเรียบร้อยแล้ว"
    }


@router.get("/users", response_model=UserAdminListResponse)
async def get_users(
    page: int = 1,
    limit: int = 20,
    search: str = None,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/users"""
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1 or limit > 100:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 100")
        
    items, total = await admin_service.get_users(db, page, limit, search)
    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": max(1, (total + limit - 1) // limit),
    }
    
@router.get("/users/{user_id}", response_model=UserAdminDetailResponse)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/users/{user_id}"""
    return await admin_service.get_user_detail(db, user_id)


@router.patch("/users/{user_id}")
async def update_user(
    user_id: int,
    update_req: UserUpdateRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """PATCH /api/v1/admin/users/{user_id}"""
    user = await admin_service.update_user(
        db, user_id, current_admin.id, update_req,
        ip=request.client.host if request else None,
        user_agent=request.headers.get("user-agent") if request else None,
    )
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
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/models"""
    items, total = await admin_service.get_model_versions(db)
    return {"items": items, "total": total}


@router.post("/models/{model_id}/deploy")
async def deploy_model(
    model_id: int,
    req: ModelDeployRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """POST /api/v1/admin/models/{model_id}/deploy"""
    model = await admin_service.deploy_model(db, model_id, current_admin.id, req.reason)
    return {
        "id": model.id,
        "version_tag": model.version_tag,
        "is_active": model.is_active,
        "deployed_at": model.deployed_at,
        "status": model.status,
        "message": f"Deploy โมเดลเวอร์ชัน {model.version_tag} สำเร็จ"
    }

@router.post("/models/{model_id}/dry-run", response_model=ModelDryRunResponse)
async def dry_run_model(
    model_id: int,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """POST /api/v1/admin/models/{model_id}/dry-run"""
    return await admin_service.dry_run_model(db, model_id)


@router.get("/audit-logs", response_model=AuditLogListResponse)
async def get_audit_logs(
    page: int = 1,
    limit: int = 50,
    search: str = None,
    action: str = None,
    entity_type: str = None,
    db: AsyncSession = Depends(get_db),
    current_admin: AdminModel = Depends(require_super_admin),
):
    """GET /api/v1/admin/audit-logs"""
    if page < 1:
        raise HTTPException(status_code=400, detail="page must be >= 1")
    if limit < 1 or limit > 100:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 100")
        
    items, total = await admin_service.get_audit_logs(db, page, limit, search, action, entity_type)
    return {"items": items, "total": total, "page": page, "limit": limit}


