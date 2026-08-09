import os
import json
import uuid
import tempfile
import zipfile
import asyncio
from datetime import datetime, timedelta, date
from typing import List, Tuple, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc, func, and_, or_, cast, String, text
from app.core.security import verify_password, hash_password
from app.core.websocket import manager
from fastapi import HTTPException
from starlette.concurrency import run_in_threadpool
from app.models.user import User
from app.models.scan import Scan
from app.models.report import ScamReport
from app.models.model_version import ModelVersion
from app.models.audit_log import AuditLog
from app.models.admin import Admin
from app.models.admin_session import AdminSession
from app.schemas.admin import ReportDecisionRequest, UserUpdateRequest, ExportRequest
from app.core.config import TH_TIMEZONE, settings
from app.core.security import (
    hash_token, create_access_token, create_refresh_token,
)


def _to_media_url(path: Optional[str]) -> Optional[str]:
    """Convert a local storage path (e.g. ./uploads/abc.png) to a publicly served URL."""
    if not path:
        return None
    name = os.path.basename(str(path))
    if not name:
        return None
    return f"/uploads/{name}"


def _risk_grade(score: int) -> str:
    if score >= 70:
        return "high"
    if score >= 40:
        return "medium"
    return "low"


def _admin_claims(admin: Admin) -> dict:
    return {"sub": str(admin.id), "role": "admin"}


async def create_admin_session(
    db: AsyncSession, admin: Admin, refresh_raw: str, ip: str = None, user_agent: str = None, sid: str = None
) -> str:
    """สร้าง session ให้ refresh token และคืน session id (ใช้ฝังใน access/refresh token)"""
    if not sid:
        sid = uuid.uuid4().hex
    session = AdminSession(
        id=sid,
        admin_id=admin.id,
        refresh_hash=hash_token(refresh_raw),
        expires_at=datetime.now(TH_TIMEZONE) + timedelta(minutes=settings.JWT_REFRESH_TOKEN_EXPIRE_MINUTES),
        user_agent=user_agent,
        ip_address=ip,
    )
    db.add(session)
    await db.commit()
    return sid


async def rotate_admin_session(
    db: AsyncSession, old_sid: str, claims: dict, ip: str = None, user_agent: str = None
) -> Tuple[str, str, str]:
    """Rotation: เพิกถอน session เก่า, สร้าง session ใหม่ และออก token คู่ใหม่"""
    result = await db.execute(select(AdminSession).where(AdminSession.id == old_sid))
    session = result.scalars().first()
    if session is None or session.revoked_at is not None:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    new_sid = uuid.uuid4().hex
    new_refresh = create_refresh_token(data=claims, sid=new_sid)
    new_access = create_access_token(data=claims, sid=new_sid)

    session.revoked_at = datetime.now(TH_TIMEZONE)
    session.replaced_by = new_sid

    new_session = AdminSession(
        id=new_sid,
        admin_id=session.admin_id,
        refresh_hash=hash_token(new_refresh),
        expires_at=datetime.now(TH_TIMEZONE) + timedelta(minutes=settings.JWT_REFRESH_TOKEN_EXPIRE_MINUTES),
        user_agent=user_agent,
        ip_address=ip,
    )
    db.add(new_session)
    await db.commit()
    return new_access, new_refresh, new_sid


async def revoke_admin_session(db: AsyncSession, admin_id: int, sid: str) -> AdminSession:
    result = await db.execute(select(AdminSession).where(AdminSession.id == sid))
    session = result.scalars().first()
    if session is None or session.admin_id != admin_id:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.revoked_at is None:
        session.revoked_at = datetime.now(TH_TIMEZONE)
        await db.commit()
    return session

async def get_dashboard_stats(db: AsyncSession) -> Dict[str, Any]:
    now = datetime.now(TH_TIMEZONE)
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_ago = today - timedelta(days=7)
    month_ago = today - timedelta(days=30)
    
    # User Stats
    total_users = await db.scalar(select(func.count(User.id)))
    active_users_from_scans = await db.execute(select(Scan.user_id).where(Scan.created_at >= today).distinct())
    active_users_from_reports = await db.execute(select(ScamReport.user_id).where(ScamReport.created_at >= today).distinct())
    active_user_ids = set(active_users_from_scans.scalars().all()).union(set(active_users_from_reports.scalars().all()))
    active_users_today = len(active_user_ids)
    
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
            "total_versions": total_models or 0,
            "a_acc": active_model.a_acc if active_model else None,
            "m_iou": active_model.m_iou if active_model else None,
            "m_acc": active_model.m_acc if active_model else None,
            "m_dice": active_model.m_dice if active_model else None
        },
        "scan_trend": scan_trend
    }

async def get_reports(db: AsyncSession, page: int = 1, limit: int = 20, status: str = None, category: str = None, search: str = None) -> Tuple[List[Dict], int]:
    stmt = select(ScamReport).order_by(desc(ScamReport.created_at))
    if status:
        stmt = stmt.where(ScamReport.status == status)
    if category:
        stmt = stmt.where(ScamReport.category == category)
    if search:
        like = f"%{search.strip()}%"
        stmt = stmt.where(or_(
            ScamReport.reason.ilike(like),
            ScamReport.category.ilike(like),
            ScamReport.platform.ilike(like),
            ScamReport.reference_url.ilike(like),
            cast(ScamReport.id, String).ilike(like),
        ))
        
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = await db.scalar(count_stmt)
    
    stmt = stmt.offset((page - 1) * limit).limit(limit)
    result = await db.execute(stmt)
    reports = result.scalars().all()
    
    # Batch load related users and scans to avoid N+1 queries
    user_ids = {r.user_id for r in reports if r.user_id}
    scan_ids = {r.scan_id for r in reports if r.scan_id}
    
    users_map = {}
    if user_ids:
        user_result = await db.execute(select(User).where(User.id.in_(user_ids)))
        for u in user_result.scalars().all():
            users_map[u.id] = {
                "id": u.id,
                "email": u.email,
                "full_name": u.full_name,
                "total_reports_submitted": None,
            }
    
    scans_map = {}
    if scan_ids:
        scan_result = await db.execute(select(Scan).where(Scan.id.in_(scan_ids)))
        for s in scan_result.scalars().all():
            scans_map[s.id] = {
                "id": s.id,
                "thumbnail_url": _to_media_url(s.raw_image_url),
                "total_risk_score": s.total_risk_score,
                "risk_grade": _risk_grade(s.total_risk_score)
            }
    
    items = []
    for r in reports:
        items.append({
            "id": r.id,
            "user": users_map.get(r.user_id),
            "scan": scans_map.get(r.scan_id),
            "category": r.category,
            "description": r.reason,
            "platform": r.platform,
            "reference_url": r.reference_url,
            "allow_research_use": r.allow_research_use,
            "status": r.status,
            "admin_note": r.admin_note,
            "moderated_by": r.moderated_by,
            "moderated_at": r.moderated_at,
            "created_at": r.created_at,
            "version": r.version
        })
        
    return items, total

async def start_review_report(db: AsyncSession, report_id: int, admin_id: int, version: int, ip: str = None, user_agent: str = None):
    stmt = select(ScamReport).where(and_(ScamReport.id == report_id, ScamReport.version == version))
    result = await db.execute(stmt)
    report = result.scalar_one_or_none()
    if not report:
        # Check if it exists but version mismatch
        exists = await db.scalar(select(ScamReport.id).where(ScamReport.id == report_id))
        if exists:
            raise HTTPException(status_code=409, detail="Conflict: Report has been updated by another user")
        raise HTTPException(status_code=404, detail="Report not found")
        
    if report.status != "pending":
        raise HTTPException(status_code=400, detail=f"Cannot start review from status {report.status}")
        
    before_state = {"status": report.status, "version": report.version}
    
    report.status = "reviewing"
    report.version += 1
    report.moderated_by = admin_id
    report.moderated_at = datetime.now(TH_TIMEZONE)
    
    after_state = {"status": report.status, "version": report.version}
    
    audit = AuditLog(
        admin_id=admin_id,
        action="report_start_review",
        entity_type="report",
        entity_id=str(report_id),
        before_state=before_state,
        after_state=after_state,
        ip_address=ip,
        user_agent=user_agent,
        details=f"Started reviewing report #{report_id}"
    )
    db.add(audit)
    await db.commit()
    await manager.broadcast({"type": "refresh_dashboard"})
    return report

async def review_report(db: AsyncSession, report_id: int, admin_id: int, decision: ReportDecisionRequest, ip: str = None, user_agent: str = None):
    stmt = select(ScamReport).where(and_(ScamReport.id == report_id, ScamReport.version == decision.version))
    result = await db.execute(stmt)
    report = result.scalar_one_or_none()
    if not report:
        exists = await db.scalar(select(ScamReport.id).where(ScamReport.id == report_id))
        if exists:
            raise HTTPException(status_code=409, detail="Conflict: Report has been updated by another user")
        raise HTTPException(status_code=404, detail="Report not found")
        
    if decision.status not in ["approved", "rejected", "pending"]:
        raise HTTPException(status_code=400, detail="Invalid status")
        
    if decision.status in ["approved", "rejected"] and report.status != "reviewing":
        raise HTTPException(status_code=400, detail=f"Report must be in 'reviewing' state to approve/reject. Current: {report.status}")
        
    if decision.status == "pending" and report.status not in ["approved", "rejected"]:
         raise HTTPException(status_code=400, detail="Only approved/rejected reports can be reopened to pending")

    if decision.status in ["rejected", "pending"] and not decision.admin_note:
        raise HTTPException(status_code=400, detail=f"Admin note is required when status is {decision.status}")
        
    before_state = {"status": report.status, "admin_note": report.admin_note, "version": report.version}
    
    report.status = decision.status
    if decision.admin_note is not None:
        report.admin_note = decision.admin_note
    report.version += 1
    report.moderated_by = admin_id
    report.moderated_at = datetime.now(TH_TIMEZONE)
    
    after_state = {"status": report.status, "admin_note": report.admin_note, "version": report.version}
    
    action_name = f"report_{decision.status}"
    if decision.status == "pending":
        action_name = "report_reopened"
        
    audit = AuditLog(
        admin_id=admin_id,
        action=action_name,
        entity_type="report",
        entity_id=str(report_id),
        before_state=before_state,
        after_state=after_state,
        reason=decision.admin_note,
        ip_address=ip,
        user_agent=user_agent,
        details=f"Report #{report_id} {decision.status}"
    )
    db.add(audit)
    await db.commit()
    await manager.broadcast({"type": "refresh_dashboard"})
    return report


async def get_report_detail(db: AsyncSession, report_id: int) -> Dict[str, Any]:
    stmt = select(ScamReport).where(ScamReport.id == report_id)
    result = await db.execute(stmt)
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    user_dict = None
    if report.user_id:
        user_result = await db.execute(select(User).where(User.id == report.user_id))
        user = user_result.scalars().first()
        total_reports = 0
        if user:
            total_reports = await db.scalar(
                select(func.count(ScamReport.id)).where(ScamReport.user_id == report.user_id)
            ) or 0
            user_dict = {
                "id": user.id,
                "email": user.email,
                "full_name": user.full_name,
                "total_reports_submitted": total_reports,
            }

    scan_dict = None
    if report.scan_id:
        scan_result = await db.execute(select(Scan).where(Scan.id == report.scan_id))
        scan = scan_result.scalars().first()
        if scan:
            scan_dict = {
                "id": scan.id,
                "image_hash": scan.image_hash,
                "thumbnail_url": _to_media_url(scan.raw_image_url),
                "raw_image_url": _to_media_url(scan.raw_image_url),
                "heatmap_image_url": _to_media_url(scan.heatmap_image_url),
                "total_risk_score": scan.total_risk_score,
                "risk_grade": _risk_grade(scan.total_risk_score),
                "text_score": scan.text_score,
                "visual_score": scan.visual_score,
                "source_score": scan.source_score,
                "exif_data": scan.exif_data,
                "ocr_text": scan.ocr_text,
                "scam_keywords_found": scan.scam_keywords_found,
                "ai_gen_probability": scan.ai_gen_probability,
                "created_at": scan.created_at,
                "status": scan.status,
            }

    return {
        "id": report.id,
        "user": user_dict,
        "scan": scan_dict,
        "category": report.category,
        "description": report.reason,
        "platform": report.platform,
        "reference_url": report.reference_url,
        "allow_research_use": report.allow_research_use,
        "status": report.status,
        "admin_note": report.admin_note,
        "moderated_by": report.moderated_by,
        "moderated_at": report.moderated_at,
        "created_at": report.created_at,
        "version": report.version,
    }


def _resolve_export_file(path: Optional[str]) -> Optional[str]:
    """Resolve a stored local path to an absolute file path when possible."""
    if not path:
        return None
    candidate = str(path)
    # Nested stored paths are relative to the server working directory.
    for p in (candidate, os.path.join(settings.LOCAL_UPLOAD_DIR, os.path.basename(candidate))):
        if os.path.isfile(p):
            return p
    return None



async def get_health_status(db: AsyncSession) -> dict:
    from sqlalchemy import text
    from datetime import datetime
    try:
        await db.execute(text("SELECT 1"))
        db_status = "ok"
    except Exception:
        db_status = "error"
        
    return {
        "database": db_status,
        "storage": "ok",
        "models": "ok",
        "queue": "ok",
        "last_check": datetime.utcnow()
    }

async def get_model_versions(db: AsyncSession) -> Tuple[List[Dict[str, Any]], int]:
    from app.models.model_version import ModelVersion
    from sqlalchemy import select, func, desc
    
    count_stmt = select(func.count(ModelVersion.id))
    total = await db.scalar(count_stmt)
    
    stmt = select(ModelVersion).order_by(desc(ModelVersion.deployed_at))
    result = await db.execute(stmt)
    models = result.scalars().all()
    
    items = []
    for m in models:
        items.append({
            "id": m.id,
            "version_tag": m.version_tag,
            "file_path": m.file_path,
            "is_active": m.is_active,
            "deployed_at": m.deployed_at,
            "artifact_checksum": m.artifact_checksum,
            "framework_compatibility": m.framework_compatibility,
            "a_acc": m.a_acc,
            "m_iou": m.m_iou,
            "m_acc": m.m_acc,
            "m_dice": m.m_dice,
            "dataset_reference": m.dataset_reference,
            "created_by": m.created_by,
            "status": m.status,
            "deployment_history": m.deployment_history,
        })
    return items, total

async def get_users(db: AsyncSession, page: int, limit: int, search: str = None) -> Tuple[List[Dict[str, Any]], int]:
    stmt = select(User).order_by(desc(User.created_at))
    if search:
        stmt = stmt.where(
            or_(
                User.email.ilike(f"%{search}%"),
                User.full_name.ilike(f"%{search}%")
            )
        )
    
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    
    stmt = stmt.offset((page - 1) * limit).limit(limit)
    result = await db.execute(stmt)
    users = result.scalars().all()
    
    items = []
    for u in users:
        scan_count = await db.scalar(select(func.count()).select_from(Scan).where(Scan.user_id == u.id))
        report_count = await db.scalar(select(func.count()).select_from(ScamReport).where(ScamReport.user_id == u.id))
        
        items.append({
            "id": u.id,
            "email": u.email,
            "full_name": u.full_name,
            "role": u.role,
            "is_active": u.is_active,
            "created_at": u.created_at,
            "updated_at": u.updated_at,
            "total_scans": scan_count,
            "total_reports": report_count,
        })
    
    return items, total

async def get_user_detail(db: AsyncSession, user_id: int) -> Dict[str, Any]:
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    scan_count = await db.scalar(select(func.count()).select_from(Scan).where(Scan.user_id == user.id))
    report_count = await db.scalar(select(func.count()).select_from(ScamReport).where(ScamReport.user_id == user.id))
    
    return {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role,
        "is_active": user.is_active,
        "created_at": user.created_at,
        "updated_at": user.updated_at,
        "total_scans": scan_count,
        "total_reports": report_count,
    }

async def update_user(db: AsyncSession, user_id: int, admin_id: int, req, ip: str = None, user_agent: str = None) -> Dict[str, Any]:
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.is_active = req.is_active
    
    # Save role if exist
    if hasattr(req, 'role') and req.role is not None:
        user.role = req.role
        
    audit = AuditLog(
        admin_id=admin_id,
        action="update_user",
        target_resource=f"user_{user_id}",
        ip_address=ip,
        user_agent=user_agent,
        details=f"Updated user {user_id}: active={user.is_active}"
    )
    db.add(audit)
    await db.commit()
    await manager.broadcast({"type": "refresh_dashboard"})
    
    return {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role,
        "is_active": user.is_active,
        "created_at": user.created_at,
        "updated_at": user.updated_at
    }

