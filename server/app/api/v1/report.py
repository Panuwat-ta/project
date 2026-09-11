from fastapi import Request, APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.rate_limit import limiter, GUEST_LIMIT, USER_LIMIT, ADMIN_LIMIT, SCAN_CREATE_LIMIT
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.report import ReportCreateRequest, ReportSubmitResponse, CategoryListResponse, ReportListResponse
from app.services import report_service

router = APIRouter()

@router.post("", response_model=ReportSubmitResponse, status_code=201)
@limiter.limit(USER_LIMIT)
async def create_report(
    request: Request,
    body: ReportCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """POST /api/v1/reports - ผู้ใช้รายงานภาพหลอกลวง"""
    report = await report_service.create_report(db, current_user.id, body)
    return {
        "id": report.id,
        "scan_id": report.scan_id,
        "category": report.category,
        "status": report.status,
        "message": "รายงานถูกส่งเรียบร้อยแล้ว ทีมงานจะตรวจสอบโดยเร็วที่สุด",
        "created_at": report.created_at
    }

@router.get("/categories", response_model=CategoryListResponse)
@limiter.limit(GUEST_LIMIT)
async def get_categories(request: Request, ):
    """GET /api/v1/reports/categories - ดึงรายการประเภทรายงาน"""
    categories = report_service.get_report_categories()
    return {"categories": categories}

@router.get("/my", response_model=ReportListResponse)
@limiter.limit(USER_LIMIT)
async def get_my_reports(request: Request, 
    page: int = 1,
    limit: int = 20,
    status: str = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """GET /api/v1/reports/my - ดูรายงานที่ตนเองเคยส่ง"""
    reports, total = await report_service.get_my_reports(db, current_user.id, page, limit, status)
    return {
        "items": reports,
        "total": total,
        "page": page,
        "limit": limit
    }
