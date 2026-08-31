from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from uuid import UUID
from app.core.database import get_db
from app.schemas.scan import ScanResponse
from app.services.scan_service import analyze_image
from app.models.scan import Scan
from app.models.user import User
from app.api.deps import get_current_user
from app.utils.risk_calculator import calculate_risk_score

router = APIRouter()

@router.post("/", response_model=ScanResponse)
async def create_scan(
    file: UploadFile = File(...),
    title: str | None = Form(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    อัปโหลดรูปภาพเพื่อวิเคราะห์หา Scam Image
    """
    scan_result = await analyze_image(file, current_user.id, db, title)
    return scan_result

@router.get("/{scan_id}", response_model=ScanResponse)
async def get_scan(
    scan_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    ดึงข้อมูลการวิเคราะห์ย้อนหลัง
    """
    result = await db.execute(select(Scan).where(Scan.id == scan_id))
    scan_record = result.scalars().first()
    
    if not scan_record:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    # User can only view their own scans, or if they are admin (mock admin check for now)
    if scan_record.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to view this scan")
        
    # Re-calculate risk grade for schema
    risk_result = calculate_risk_score(scan_record.text_score, scan_record.visual_score, scan_record.source_score)
    scan_record.risk_grade = risk_result["grade"]
        
    return scan_record
