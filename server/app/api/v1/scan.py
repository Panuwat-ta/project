from fastapi import Request, APIRouter, UploadFile, File, Form, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from uuid import UUID
from app.core.rate_limit import limiter, GUEST_LIMIT, USER_LIMIT, ADMIN_LIMIT, SCAN_CREATE_LIMIT
from app.core.database import get_db
from app.schemas.scan import ScanResponse
from app.services.scan_service import create_scan_task, process_image_background
from app.models.scan import Scan
from app.models.user import User
from app.api.deps import get_current_user
from app.utils.risk_calculator import calculate_risk_score

router = APIRouter()

@router.post("/", response_model=ScanResponse)
@limiter.limit(SCAN_CREATE_LIMIT)
async def create_scan(request: Request, 
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    title: str | None = Form(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    อัปโหลดรูปภาพเพื่อวิเคราะห์หา Scam Image แบบ Asynchronous
    """
    scan_record, file_bytes, image_hash = await create_scan_task(file, current_user.id, db, title)
    
    background_tasks.add_task(process_image_background, scan_record.id, file_bytes, image_hash)
    
    return scan_record

@router.get("/{scan_id}", response_model=ScanResponse)
@limiter.limit(USER_LIMIT)
async def get_scan(request: Request, 
    scan_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    ดึงข้อมูลการวิเคราะห์ย้อนหลัง หรือ Poll สถานะล่าสุด
    """
    result = await db.execute(select(Scan).where(Scan.id == scan_id))
    scan_record = result.scalars().first()
    
    if not scan_record:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    if scan_record.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to view this scan")
        
    risk_result = calculate_risk_score(scan_record.text_score, scan_record.visual_score, scan_record.source_score)
    scan_record.risk_grade = risk_result["grade"]
        
    return scan_record

