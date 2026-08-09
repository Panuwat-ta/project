import io
import os
import json
import zipfile
from datetime import datetime, timedelta, date
from typing import List, Tuple, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc, func, and_, or_, cast, String
from fastapi import HTTPException
from app.models.user import User
from app.models.scan import Scan
from app.models.report import ScamReport
from app.models.model_version import ModelVersion
from app.models.audit_log import AuditLog
from app.schemas.admin import ReportDecisionRequest, UserUpdateRequest, ExportRequest
from app.core.config import TH_TIMEZONE, settings


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

async def get_dashboard_stats(db: AsyncSession) -> Dict[str, Any]:
    now = datetime.now(TH_TIMEZONE)
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
    report.moderated_at = datetime.now(TH_TIMEZONE)
    
    # Audit log
    audit = AuditLog(
        admin_id=admin_id,
        action=f"report_{decision.status}",
        details=f"Report #{report_id} {decision.status}"
    )
    db.add(audit)
    await db.commit()
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


async def export_dataset(db: AsyncSession, admin_id: int, export_req: ExportRequest) -> Tuple[bytes, str, int]:
    """Build an in-memory ZIP of approved reports (images + heatmaps + metadata)."""
    stmt = select(ScamReport).where(ScamReport.status == "approved", ScamReport.scan_id.isnot(None))
    if export_req.categories:
        stmt = stmt.where(ScamReport.category.in_(export_req.categories))
    if export_req.from_date:
        try:
            from_dt = datetime.combine(date.fromisoformat(export_req.from_date), datetime.min.time(), tzinfo=TH_TIMEZONE)
            stmt = stmt.where(ScamReport.created_at >= from_dt)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid from_date format (expected YYYY-MM-DD)")
    if export_req.to_date:
        try:
            to_dt = datetime.combine(date.fromisoformat(export_req.to_date), datetime.max.time(), tzinfo=TH_TIMEZONE)
            stmt = stmt.where(ScamReport.created_at <= to_dt)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid to_date format (expected YYYY-MM-DD)")

    result = await db.execute(stmt.order_by(desc(ScamReport.created_at)))
    reports = result.scalars().all()

    if not reports:
        raise HTTPException(status_code=404, detail="ไม่พบข้อมูลสำหรับ Export (ไม่มีรายงานที่อนุมัติแล้วในเงื่อนไขนี้)")

    scan_ids = {r.scan_id for r in reports if r.scan_id}
    scans_map = {}
    if scan_ids:
        scan_result = await db.execute(select(Scan).where(Scan.id.in_(scan_ids)))
        for s in scan_result.scalars().all():
            scans_map[s.id] = s

    buf = io.BytesIO()
    manifest = []
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        for r in reports:
            scan = scans_map.get(r.scan_id)
            if scan is None:
                continue
            entry_id = f"report_{r.id}"
            img_path = _resolve_export_file(scan.raw_image_url)
            mask_path = _resolve_export_file(scan.heatmap_image_url)

            if img_path:
                with open(img_path, "rb") as f:
                    img_bytes = f.read()
                ext = os.path.splitext(img_path)[1].lstrip(".") or "png"
                zf.writestr(f"images/{entry_id}.{ext}", img_bytes)
            if mask_path:
                with open(mask_path, "rb") as f:
                    mask_bytes = f.read()
                zf.writestr(f"masks/{entry_id}.jpg", mask_bytes)

            record = {
                "id": r.id,
                "image": f"images/{entry_id}.{ext}" if img_path else None,
                "mask": f"masks/{entry_id}.jpg" if mask_path else None,
                "category": r.category,
                "platform": r.platform,
                "risk_score": scan.total_risk_score,
                "risk_grade": _risk_grade(scan.total_risk_score),
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            if export_req.include_metadata:
                record["metadata"] = {
                    "description": r.reason,
                    "reference_url": r.reference_url,
                    "allow_research_use": r.allow_research_use,
                    "admin_note": r.admin_note,
                    "moderated_at": r.moderated_at.isoformat() if r.moderated_at else None,
                    "scan": {
                        "text_score": scan.text_score,
                        "visual_score": scan.visual_score,
                        "source_score": scan.source_score,
                        "total_risk_score": scan.total_risk_score,
                        "ai_gen_probability": scan.ai_gen_probability,
                        "ocr_text": scan.ocr_text,
                        "scam_keywords_found": scan.scam_keywords_found or [],
                    },
                }
            manifest.append(record)

        zf.writestr("manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2))

    buf.seek(0)

    audit = AuditLog(
        admin_id=admin_id,
        action="dataset_exported",
        details=f"Dataset export: {len(manifest)} approved reports"
    )
    db.add(audit)
    await db.commit()

    timestamp = datetime.now(TH_TIMEZONE).strftime("%Y%m%d_%H%M%S")
    return buf.getvalue(), f"scamguard_dataset_{timestamp}.zip", len(manifest)

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
    model.deployed_at = datetime.now(TH_TIMEZONE)
    
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
