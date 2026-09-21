import json
import os
from pathlib import Path
import zipfile
import asyncio
import tempfile
import hashlib
from datetime import datetime, date, timedelta
from typing import Optional, List
from sqlalchemy import select, and_, func, update
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException
from pydantic import UUID4

from app.models import ExportJob, ScamReport, Scan, AuditLog
from app.core.config import settings, TH_TIMEZONE
from app.core.database import async_session
from app.core.websocket import manager

SERVER_DIR = Path(__file__).resolve().parents[2]
STORAGE_DIR = os.getenv("EXPORT_STORAGE_DIR", str(SERVER_DIR / "private_storage" / "exports"))

try:
    os.makedirs(STORAGE_DIR, exist_ok=True)
except Exception:
    pass

def _resolve_scan_image(path: Optional[str]) -> Optional[str]:
    if not path:
        return None
    raw = str(path)
    candidates = [raw]
    candidates.append(os.path.join(settings.LOCAL_UPLOAD_DIR, os.path.basename(raw)))
    for candidate in candidates:
        if os.path.isfile(candidate):
            return candidate
    return None

async def _cleanup_expired_jobs(db: AsyncSession):
    now = datetime.now(TH_TIMEZONE)
    stmt = select(ExportJob).where(ExportJob.status == "succeeded", ExportJob.expires_at < now)
    result = await db.execute(stmt)
    expired_jobs = result.scalars().all()
    
    for job in expired_jobs:
        if job.file_path and os.path.exists(job.file_path):
            try:
                os.remove(job.file_path)
            except Exception:
                pass
        job.status = "expired"
        job.file_path = None
    
    if expired_jobs:
        await db.commit()

async def create_export_job(db: AsyncSession, admin_id: int, payload: dict) -> ExportJob:
    await _cleanup_expired_jobs(db)
    
    # Check concurrent limits
    stmt = select(func.count()).where(ExportJob.status.in_(["queued", "running"]))
    active_count = await db.scalar(stmt)
    if active_count >= 5:
        raise HTTPException(status_code=429, detail="Too many concurrent export jobs. Please wait.")
        
    job = ExportJob(
        admin_id=admin_id,
        status="queued",
        filter_config=payload
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)
    
    return job

async def process_export_job(job_id: str):
    async with async_session() as db:
        stmt = select(ExportJob).where(ExportJob.id == str(job_id))
        job = (await db.execute(stmt)).scalar_one_or_none()
        
        if not job or job.status != "queued":
            return
            
        job.status = "running"
        await db.commit()
        filepath = None

        try:
            config = job.filter_config
            
            stmt = select(ScamReport).where(
                ScamReport.status == "approved",
                ScamReport.scan_id.isnot(None),
                ScamReport.allow_research_use == True
            )
            if config.get("categories"):
                stmt = stmt.where(ScamReport.category.in_(config["categories"]))
            if config.get("from_date"):
                from_dt = datetime.combine(date.fromisoformat(config["from_date"]), datetime.min.time(), tzinfo=TH_TIMEZONE)
                stmt = stmt.where(ScamReport.created_at >= from_dt)
            if config.get("to_date"):
                to_dt = datetime.combine(date.fromisoformat(config["to_date"]), datetime.max.time(), tzinfo=TH_TIMEZONE)
                stmt = stmt.where(ScamReport.created_at <= to_dt)
                
            count_stmt = select(func.count()).select_from(stmt.subquery())
            total_rows = await db.scalar(count_stmt)
            
            if total_rows == 0:
                raise Exception("No data matches the selected filters.")
                
            if total_rows > 100000:
                raise Exception("Dataset too large (limit 100,000 rows). Please narrow your date range.")
                
            filename = f"scamguard_export_{job_id}.zip"
            filepath = os.path.join(STORAGE_DIR, filename)

            result = await db.execute(stmt)
            reports = result.scalars().all()
            scan_ids = {r.scan_id for r in reports if r.scan_id}
            scan_map = {}
            if scan_ids:
                scan_result = await db.execute(select(Scan).where(Scan.id.in_(scan_ids)))
                scan_map = {scan.id: scan for scan in scan_result.scalars().all()}

            manifest_entries = []
            metadata_entries = []

            with zipfile.ZipFile(filepath, 'w', zipfile.ZIP_DEFLATED) as zf:
                for i, r in enumerate(reports):
                    scan = scan_map.get(r.scan_id)
                    if scan is None:
                        raise RuntimeError(f"Scan {r.scan_id} not found for report {r.id}")
                    source_image = _resolve_scan_image(scan.raw_image_url)
                    if source_image is None:
                        raise RuntimeError(f"Source image not found for scan {scan.id}")

                    suffix = Path(source_image).suffix.lower() or ".jpg"
                    image_filename = f"{scan.id}{suffix}"
                    image_archive_path = f"images/{r.category}/{image_filename}"
                    zf.write(source_image, image_archive_path)
                    manifest_entries.append({
                        "report_id": r.id,
                        "scan_id": str(scan.id),
                        "file": image_archive_path,
                    })
                    metadata_entries.append({
                        "filename": f"{r.category}/{image_filename}",
                        "category": r.category,
                        "risk_score": scan.total_risk_score,
                        "report_id": r.id,
                        "reported_at": r.created_at.isoformat() if r.created_at else None,
                        "approved_at": r.moderated_at.isoformat() if r.moderated_at else None,
                    })

                    if i % 100 == 0:
                        job.progress = min(99.0, (i / total_rows) * 100.0)
                        await db.commit()
                        await asyncio.sleep(0)

                if config.get("include_metadata", True):
                    zf.writestr("metadata.json", json.dumps(metadata_entries, ensure_ascii=False, indent=2))
                zf.writestr(
                    "README.md",
                    "# ScamGuard Research Dataset\n\n"
                    "ไฟล์นี้สร้างจากรายงานที่อนุมัติและยินยอมให้ใช้เพื่อการวิจัยเท่านั้น\n"
                    "ข้อมูลผู้รายงานส่วนบุคคลไม่ถูกรวมในชุดข้อมูลนี้\n",
                )
                manifest = {
                    "schema_version": "1.0",
                    "filter_config": config,
                    "total_rows": len(manifest_entries),
                    "exported_at": datetime.now(TH_TIMEZONE).isoformat(),
                    "entries": manifest_entries,
                }
                zf.writestr("manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2))
            
            # Re-read status before publishing success so a cancel from another
            # admin session cannot be overwritten by this long-running worker.
            await db.refresh(job)
            if job.status == "canceled":
                if os.path.exists(filepath):
                    os.remove(filepath)
                job.file_path = None
                job.completed_at = datetime.now(TH_TIMEZONE)
                await db.commit()
                await manager.broadcast({"type": "refresh_dashboard"})
                return

            # success
            file_size = os.path.getsize(filepath)
            
            job.status = "succeeded"
            job.progress = 100.0
            job.total_rows = len(manifest_entries)
            job.file_size_bytes = file_size
            job.file_path = filepath
            job.manifest = {"schema_version": "1.0", "total_rows": len(manifest_entries), "size_bytes": file_size}
            job.completed_at = datetime.now(TH_TIMEZONE)
            job.expires_at = datetime.now(TH_TIMEZONE) + timedelta(days=7) # keep for 7 days
            
            audit = AuditLog(
                admin_id=job.admin_id,
                action="dataset_exported",
                details=f"Exported {len(manifest_entries)} images. Job ID: {job_id}",
                entity_type="export_job",
                entity_id=str(job_id)
            )
            db.add(audit)
            await db.commit()
            await manager.broadcast({"type": "refresh_dashboard"})
            
        except Exception as e:
            if filepath and os.path.exists(filepath):
                try:
                    os.remove(filepath)
                except OSError:
                    pass
            job.status = "failed"
            job.file_path = None
            job.error_message = str(e)
            job.completed_at = datetime.now(TH_TIMEZONE)
            await db.commit()
            await manager.broadcast({"type": "refresh_dashboard"})
