from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, desc
from uuid import UUID

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.scan import Scan
from app.schemas.history import HistoryListResponse, HistoryItemResponse
from app.utils.risk_calculator import calculate_risk_score

router = APIRouter()

@router.get("", response_model=HistoryListResponse)
async def get_history(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    offset = (page - 1) * limit
    
    # Query total
    total_query = select(func.count()).select_from(Scan).where(Scan.user_id == current_user.id)
    total_result = await db.execute(total_query)
    total = total_result.scalar() or 0
    
    # Query items
    items_query = (
        select(Scan)
        .where(Scan.user_id == current_user.id)
        .order_by(desc(Scan.created_at))
        .offset(offset)
        .limit(limit)
    )
    items_result = await db.execute(items_query)
    scans = items_result.scalars().all()
    
    history_items = []
    for s in scans:
        # Calculate risk grade
        risk = calculate_risk_score(s.text_score, s.visual_score, s.source_score)
        
        title = s.title if s.title else "ผลการสแกน"
        
        history_items.append(HistoryItemResponse(
            scan_id=s.id,
            thumbnail_url=f"/uploads/{s.raw_image_url.split('/')[-1]}" if s.raw_image_url else None,
            risk_score=s.total_risk_score,
            risk_level=risk["grade"],
            status=s.status,
            created_at=s.created_at,
            title=title
        ))
        
    return HistoryListResponse(
        items=history_items,
        total=total,
        page=page,
        limit=limit
    )

@router.get("/{scan_id}", response_model=HistoryItemResponse)
async def get_history_item(
    scan_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Scan).where(Scan.id == scan_id, Scan.user_id == current_user.id))
    scan = result.scalars().first()
    
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    risk = calculate_risk_score(scan.text_score, scan.visual_score, scan.source_score)
    title = scan.title if scan.title else "ผลการสแกน"
    
    return HistoryItemResponse(
        scan_id=scan.id,
        thumbnail_url=f"/uploads/{scan.raw_image_url.split('/')[-1]}" if scan.raw_image_url else None,
        risk_score=scan.total_risk_score,
        risk_level=risk["grade"],
        status=scan.status,
        created_at=scan.created_at,
        title=title
    )

@router.delete("/{scan_id}")
async def delete_history_item(
    scan_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(Scan).where(Scan.id == scan_id, Scan.user_id == current_user.id))
    scan = result.scalars().first()
    
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    await db.delete(scan)
    await db.commit()
    
    return {"message": "Scan deleted successfully"}
