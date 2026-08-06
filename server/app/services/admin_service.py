import os
from typing import List, Tuple, Dict, Any
from datetime import datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc, func, and_
from fastapi import HTTPException
from app.models.user import User
from app.models.scan import Scan
from app.models.report import ScamReport
from app.models.model_version import ModelVersion
from app.models.audit_log import AuditLog
from app.schemas.admin import ReportDecisionRequest, UserUpdateRequest
from sqlalchemy.orm import selectinload

async def get_dashboard_stats(db: AsyncSession) -> Dict[str, Any]:
    now = datetime.now(timezone.utc)
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_ago = today - timedelta(days=7)
    month_ago = today - timedelta(days=30)
    
    # User Stats
    total_users = await db.scalar(select(func.count(User.id)))
    active_users_today = await db.scalar(select(func.count(User.id)).where(User.updated_at >= today))
    
    # Scan Stats
    total_scans = await db.scalar(select(func.count(Scan.id)))
    scans_today = await db.scalar(select(func.count(Scan.id)).where(Scan.created_at >= today))
    scans_this_week = await db.scalar(select(func.count(Scan.id)).where(Scan.created_at >= week_ago))
    scans_this_month = await db.scalar(select(func.count(Scan.id)).where(Scan.created_at >= month_ago))
    
    # Risk Distribution
    low_risk = await db.scalar(select(func.count(Scan.id)).where(Scan.total_risk_score < 40))
    medium_risk = await db.scalar(select(func.count(Scan.id)).where(and_(Scan.total_risk_score >= 40, Scan.total_risk_score < 70)))
    high_risk = await db.scalar(select(func.count(Scan.id)).where(Scan.total_risk_score >= 70))
    
    # Reports Stats
    total_reports = await db.scalar(select(func.count(ScamReport.id)))
    pending = await db.scalar(select(func.count(ScamReport.id)).where(ScamReport.status == "pending"))
    reviewing = await db.scalar(select(func.count(ScamReport.id)).where(ScamReport.status == "reviewing"))
    approved = await db.scalar(select(func.count(ScamReport.id)).where(ScamReport.status == "approved"))
    rejected = await db.scalar(select(func.count(ScamReport.id)).where(ScamReport.status == "rejected"))
    
    # Category Breakdown
    cat_result = await db.execute(select(ScamReport.category, func.count(ScamReport.id)).group_by(ScamReport.category))
    category_breakdown = {row[0]: row[1] for row in cat_result.all()}
    
    # Model Status
    model_result = await db.execute(select(ModelVersion).where(ModelVersion.is_active == True))
    active_model = model_result.scalar_one_or_none()
    total_models = await db.scalar(select(func.count(ModelVersion.id)))
    
    # Scan Trend (Last 7 days)
    # Simple Python aggregation since SQLite/PostgreSQL group by date syntax varies
    trend_result = await db.execute(select(Scan.created_at).where(Scan.created_at >= week_ago))
    scans_in_week = trend_result.scalars().all()
    trend_dict = {}
    for i in range(7):
        d = (today - timedelta(days=6-i)).strftime("%Y-%m-%d")
        trend_dict[d] = 0
    for dt in scans_in_week:
        if dt:
            d = dt.strftime("%Y-%m-%d")
            if d in trend_dict:
                trend_dict[d] += 1
    scan_trend = [{"date": k, "count": v} for k, v in trend_dict.items()]
    
    return {
        "overview": {
            "total_users": total_users or 0,
            "active_users_today": active_users_today or 0,
            "total_scans": total_scans or 0,
            "scans_today": scans_today or 0,
            "scans_this_week": scans_this_week or 0,
            "scans_this_month": scans_this_month or 0
        },
        "risk_distribution": {
            "low": low_risk or 0,
            "medium": medium_risk or 0,
            "high": high_risk or 0
        },
        "reports": {
            "total": total_reports or 0,
            "pending": pending or 0,
            "reviewing": reviewing or 0,
            "approved": approved or 0,
            "rejected": rejected or 0
        },
        "category_breakdown": category_breakdown,
        "model": {
            "active_version": active_model.version_tag if active_model else None,
            "deployed_at": active_model.deployed_at if active_model else None,
            "total_versions": total_models or 0
        },
        "scan_trend": scan_trend
    }

async def get_reports(db: AsyncSession, page: int = 1, limit: int = 20, status: str = None, category: str = None) -> Tuple[List[Dict], int]:
    # Need to join with User and Scan manually or use relationships.
    # To keep it simple, we do basic queries for relations.
    stmt = select(ScamReport).order_by(desc(ScamReport.created_at))
    if status:
        stmt = stmt.where(ScamReport.status == status)
    if category:
        stmt = stmt.where(ScamReport.category == category)
        
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = await db.scalar(count_stmt)
    
    stmt = stmt.offset((page - 1) * limit).limit(limit)
    result = await db.execute(stmt)
    reports = result.scalars().all()
    
    items = []
    for r in reports:
        # Load user
        user = None
        if r.user_id:
            user_result = await db.execute(select(User).where(User.id == r.user_id))
            u = user_result.scalar_one_or_none()
            if u:
                user = {"id": u.id, "email": u.email, "full_name": u.full_name}
                
        # Load scan
        scan_data = None
        if r.scan_id:
            scan_result = await db.execute(select(Scan).where(Scan.id == r.scan_id))
            s = scan_result.scalar_one_or_none()
            if s:
                risk_grade = "low"
                if s.total_risk_score >= 70:
                    risk_grade = "high"
                elif s.total_risk_score >= 40:
                    risk_grade = "medium"
                
                scan_data = {
                    "id": s.id,
                    "thumbnail_url": s.raw_image_url, # Using raw for thumb for now
                    "total_risk_score": s.total_risk_score,
                    "risk_grade": risk_grade
                }
                
        items.append({
            "id": r.id,
            "user": user,
            "scan": scan_data,
            "category": r.category,
            "description": r.reason,
            "platform": r.platform,
            "reference_url": r.reference_url,
            "allow_research_use": r.allow_research_use,
            "status": r.status,
            "admin_note": r.admin_note,
            "moderated_by": r.moderated_by,
            "moderated_at": r.moderated_at,
            "created_at": r.created_at
        })
        
    return items, total

async def review_report(db: AsyncSession, report_id: int, admin_id: int, decision: ReportDecisionRequest):
    stmt = select(ScamReport).where(ScamReport.id == report_id)
    result = await db.execute(stmt)
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    if decision.status not in ["approved", "rejected"]:
        raise HTTPException(status_code=400, detail="Invalid status")
        
    if decision.status == "rejected" and not decision.admin_note:
        raise HTTPException(status_code=400, detail="Admin note is required when rejecting")
        
    report.status = decision.status
    if decision.admin_note:
        report.admin_note = decision.admin_note
    report.moderated_by = admin_id
    report.moderated_at = datetime.now(timezone.utc)
    
    # Audit log
    audit = AuditLog(
        admin_id=admin_id,
        action=f"report_{decision.status}",
        details=f"Report #{report_id} {decision.status}"
    )
    db.add(audit)
    await db.commit()
    return report

async def get_users(db: AsyncSession, page: int = 1, limit: int = 20) -> Tuple[List[User], int]:
    stmt = select(User).order_by(desc(User.created_at))
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = await db.scalar(count_stmt)
    
    stmt = stmt.offset((page - 1) * limit).limit(limit)
    result = await db.execute(stmt)
    users = result.scalars().all()
    
    # We could calculate total_scans and total_reports, but let's keep it simple for now
    for u in users:
        u.total_scans = 0
        u.total_reports = 0
        
    return users, total

async def update_user(db: AsyncSession, user_id: int, admin_id: int, update_req: UserUpdateRequest):
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if update_req.role is not None:
        audit = AuditLog(
            admin_id=admin_id,
            action="user_role_changed",
            details=f"User #{user_id} role changed from {user.role} to {update_req.role}"
        )
        db.add(audit)
        user.role = update_req.role
        
    if update_req.is_active is not None:
        action = "user_unbanned" if update_req.is_active else "user_banned"
        audit = AuditLog(
            admin_id=admin_id,
            action=action,
            details=f"User #{user_id} {'unbanned' if update_req.is_active else 'banned'}"
        )
        db.add(audit)
        user.is_active = update_req.is_active
        
    await db.commit()
    await db.refresh(user)
    return user

async def get_model_versions(db: AsyncSession) -> Tuple[List[ModelVersion], int]:
    stmt = select(ModelVersion).order_by(desc(ModelVersion.deployed_at))
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = await db.scalar(count_stmt)
    
    result = await db.execute(stmt)
    return result.scalars().all(), total

async def deploy_model(db: AsyncSession, model_id: int, admin_id: int):
    # Find model
    stmt = select(ModelVersion).where(ModelVersion.id == model_id)
    result = await db.execute(stmt)
    model = result.scalar_one_or_none()
    
    if not model:
        raise HTTPException(status_code=404, detail="Model version not found")
        
    # Deactivate all others
    await db.execute(
        ModelVersion.__table__.update().values(is_active=False)
    )
    
    # Activate target
    model.is_active = True
    model.deployed_at = datetime.now(timezone.utc)
    
    audit = AuditLog(
        admin_id=admin_id,
        action="model_deployed",
        details=f"Model {model.version_tag} deployed"
    )
    db.add(audit)
    await db.commit()
    
    return model

async def get_audit_logs(db: AsyncSession, page: int = 1, limit: int = 50) -> Tuple[List[AuditLog], int]:
    stmt = select(AuditLog).order_by(desc(AuditLog.created_at))
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = await db.scalar(count_stmt)
    
    stmt = stmt.offset((page - 1) * limit).limit(limit)
    result = await db.execute(stmt)
    
    return result.scalars().all(), total
