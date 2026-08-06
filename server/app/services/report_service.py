from typing import List, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc, func
from fastapi import HTTPException
from app.models.report import ScamReport
from app.models.scan import Scan
from app.schemas.report import ReportCreateRequest

async def create_report(db: AsyncSession, user_id: int, request: ReportCreateRequest) -> ScamReport:
    # Check if scan exists and belongs to user
    stmt = select(Scan).where(Scan.id == request.scan_id, Scan.user_id == user_id)
    result = await db.execute(stmt)
    scan = result.scalar_one_or_none()
    
    if not scan:
        raise HTTPException(status_code=403, detail="Scan not found or you don't have permission")

    # Check if already reported
    stmt = select(ScamReport).where(ScamReport.scan_id == request.scan_id)
    result = await db.execute(stmt)
    existing_report = result.scalar_one_or_none()
    
    if existing_report:
        raise HTTPException(status_code=409, detail="This scan has already been reported")

    report = ScamReport(
        user_id=user_id,
        scan_id=request.scan_id,
        category=request.category,
        reason=request.description,
        platform=request.platform,
        reference_url=request.reference_url,
        allow_research_use=request.allow_research_use,
        status="pending"
    )
    
    db.add(report)
    await db.commit()
    await db.refresh(report)
    
    # We set a description attribute so Pydantic schema can read it
    report.description = report.reason
    
    return report

async def get_my_reports(db: AsyncSession, user_id: int, page: int = 1, limit: int = 20, status: str = None) -> Tuple[List[ScamReport], int]:
    stmt = select(ScamReport).where(ScamReport.user_id == user_id)
    if status:
        stmt = stmt.where(ScamReport.status == status)
        
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = await db.scalar(count_stmt)
    
    stmt = stmt.order_by(desc(ScamReport.created_at)).offset((page - 1) * limit).limit(limit)
    result = await db.execute(stmt)
    reports = result.scalars().all()
    
    for report in reports:
        report.description = report.reason
        
    return reports, total

def get_report_categories():
    return [
        {"key": "romance_scam", "label_th": "หลอกลวงความรัก", "label_en": "Romance Scam"},
        {"key": "online_shopping", "label_th": "ซื้อขายออนไลน์", "label_en": "Online Shopping Fraud"},
        {"key": "fake_slip", "label_th": "สลิปปลอม", "label_en": "Fake Transfer Slip"},
        {"key": "investment", "label_th": "ลงทุนหรือผลตอบแทนสูง", "label_en": "Investment / Ponzi Scheme"},
        {"key": "identity_theft", "label_th": "ปลอมแปลงตัวตน", "label_en": "Identity Theft"},
        {"key": "ai_deepfake", "label_th": "ภาพ AI หรือ Deepfake", "label_en": "AI-generated / Deepfake"},
        {"key": "other", "label_th": "อื่น ๆ", "label_en": "Other"}
    ]
