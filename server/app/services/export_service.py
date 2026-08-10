import json
import os
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

STORAGE_DIR = "/home/panuwat/project/server/private_storage/exports"

os.makedirs(STORAGE_DIR, exist_ok=True)

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
                
            # We process them in chunks
            filename = f"scamguard_export_{job_id}.zip"
            filepath = os.path.join(STORAGE_DIR, filename)
            
            manifest_entries = []
            
            with zipfile.ZipFile(filepath, 'w', zipfile.ZIP_DEFLATED) as zf:
                result = await db.execute(stmt)
                reports = result.scalars().all() # In production we would yield in chunks, but for now fetch all is fine if limit < 100k
                
                for i, r in enumerate(reports):
                    # add metadata
                    if config.get("include_metadata", True):
                        meta = {
                            "id": r.id,
                            "category": r.category,
                            "platform": r.platform,
                            "reference_url": r.reference_url,
                            "description": r.description,
                            "status": r.status,
                            "created_at": r.created_at.isoformat() if r.created_at else None,
                        }
                        meta_filename = f"{r.id}_meta.json"
                        zf.writestr(meta_filename, json.dumps(meta, ensure_ascii=False, indent=2))
                        manifest_entries.append({"id": r.id, "file": meta_filename})
                        
                    # progress update every 100 items
                    if i % 100 == 0:
                        job.progress = min(99.0, (i / total_rows) * 100.0)
                        await db.commit()
                        await asyncio.sleep(0) # yield event loop
                        
                # Add Manifest
                manifest = {
                    "schema_version": "1.0",
                    "filter_config": config,
                    "total_rows": total_rows,
                    "exported_at": datetime.now(TH_TIMEZONE).isoformat(),
                    "entries": manifest_entries
                }
                zf.writestr("manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2))
            
            # success
            file_size = os.path.getsize(filepath)
            
            job.status = "succeeded"
            job.progress = 100.0
            job.total_rows = total_rows
            job.file_size_bytes = file_size
            job.file_path = filepath
            job.manifest = {"schema_version": "1.0", "total_rows": total_rows, "size_bytes": file_size}
            job.completed_at = datetime.now(TH_TIMEZONE)
            job.expires_at = datetime.now(TH_TIMEZONE) + timedelta(days=7) # keep for 7 days
            
            audit = AuditLog(
                admin_id=job.admin_id,
                action="dataset_exported",
                details=f"Exported {total_rows} reports. Job ID: {job_id}",
                entity_type="export_job",
                entity_id=str(job_id)
            )
            db.add(audit)
            await db.commit()
            
        except Exception as e:
            job.status = "failed"
            job.error_message = str(e)
            job.completed_at = datetime.now(TH_TIMEZONE)
            await db.commit()
