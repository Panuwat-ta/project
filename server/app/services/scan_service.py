import os
import asyncio
import functools
import anyio
from fastapi import UploadFile, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import datetime
from starlette.concurrency import run_in_threadpool
from app.core.config import settings, TH_TIMEZONE
from app.core.websocket import manager
from app.models.scan import Scan
from app.utils.hashing import calculate_image_hash
from app.utils.image_utils import (
    load_image_verified,
    encode_lossless_png,
    save_evidence_png,
    save_heatmap_file,
    heatmap_path,
)
from app.utils.risk_calculator import calculate_risk_score, build_text_analysis, build_source_score
from app.utils.scan_cache import get_cached_scan, store_cached_scan
from app.services.inference_service import inference_service
import app.core.redis as redis_core

MAX_UPLOAD_BYTES = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024

async def _generate_xai_with_timeout(region: str, visual_score: int, ai_gen_probability: float, found_keywords: list[str]) -> str:
    """Generate XAI without letting a blocking worker defeat the async timeout.

    AnyIO worker threads ignore host-task cancellation by default. Using
    abandon_on_cancel=True lets asyncio.wait_for return on time; the worker may
    finish in the background, but its late result is discarded.
    """
    call = functools.partial(
        inference_service.generate_xai_explanation,
        region=region,
        visual_score=visual_score,
        ai_gen_probability=ai_gen_probability,
        scam_keywords=found_keywords,
    )
    try:
        return await asyncio.wait_for(
            anyio.to_thread.run_sync(call, abandon_on_cancel=True),
            timeout=settings.XAI_TIMEOUT,
        )
    except (asyncio.TimeoutError, TimeoutError):
        print(f"XAI timeout after {settings.XAI_TIMEOUT}s, using fallback")
        return inference_service.fallback_xai_explanation(
            region, visual_score, ai_gen_probability, found_keywords
        )
    except Exception as exc:
        print(f"XAI phase failed, using fallback: {exc}")
        return inference_service.fallback_xai_explanation(
            region, visual_score, ai_gen_probability, found_keywords
        )

async def create_scan_task(file: UploadFile, user_id: int, db: AsyncSession, title: str | None = None) -> tuple[Scan, bytes, str]:
    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="File is empty. Please upload a valid image file.")
    if len(file_bytes) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum allowed size is {settings.MAX_UPLOAD_SIZE_MB} MB.",
        )

    # Validate ว่าเป็นรูปจริงก่อนสร้าง record — ได้ 400 ทันที ไม่ต้องรอ background task
    await run_in_threadpool(load_image_verified, file_bytes)

    image_hash = calculate_image_hash(file_bytes)

    # Initial Scan record
    new_scan = Scan(
        user_id=user_id,
        image_hash=image_hash,
        raw_image_url="",
        title=title,
        text_score=0,
        visual_score=0,
        source_score=0,
        total_risk_score=0,
        ai_gen_probability=0.0,
        status="uploading",
        progress=0
    )

    db.add(new_scan)
    await db.commit()
    await db.refresh(new_scan)
    
    new_scan.risk_grade = "low" # default for schema

    return new_scan, file_bytes, image_hash

async def process_image_background(scan_id, file_bytes: bytes, image_hash: str,
                                 predict_fn=None, cache_client=None):
    """Background scoring pipeline. Deps injectable for tests; defaults are prod.

    predict_fn: (png_bytes) -> inference dict. Defaults to inference_service.predict.
    cache_client: Redis-like client (get/setex). Defaults to global redis_client.
    Flow + Phase 1/2 split unchanged.
    """
    from app.core.database import async_session

    if predict_fn is None:
        predict_fn = inference_service.predict
    if cache_client is None:
        cache_client = redis_core.redis_client
    
    async with async_session() as db:
        result = await db.execute(select(Scan).where(Scan.id == scan_id))
        scan = result.scalars().first()
        if not scan: return
        
        try:
            scan.status = "queued"
            scan.progress = 10
            await db.commit()
            
            # 2. Verify + decode-once
            scan.status = "processing_source"
            scan.progress = 20
            await db.commit()
            
            image, exif_data = await run_in_threadpool(load_image_verified, file_bytes)

            # 3. Normalize to lossless PNG
            png_bytes = await run_in_threadpool(encode_lossless_png, image)

            # 5. Save PNG evidence via image store seam
            file_path = save_evidence_png(png_bytes, image_hash)
                
            scan.raw_image_url = file_path
            scan.exif_data = exif_data
            scan.progress = 40
            await db.commit()

            # 6. Check result cache via cache seam
            cached_data = await get_cached_scan(cache_client, image_hash)

            heatmap_file = heatmap_path(image_hash)

            scan.status = "processing_visual"
            scan.progress = 50
            await db.commit()

            if cached_data:
                inference_result = cached_data
            else:
                inference_result = await run_in_threadpool(predict_fn, png_bytes)
                
                if inference_result.get("heatmap_bytes"):
                    save_heatmap_file(inference_result["heatmap_bytes"], image_hash)
                    del inference_result["heatmap_bytes"]
                    inference_result["has_heatmap"] = True

                await store_cached_scan(cache_client, image_hash, inference_result)
                        
            if os.path.exists(heatmap_file):
                scan.heatmap_image_url = heatmap_file
                
            scan.status = "processing_text"
            scan.progress = 80
            await db.commit()

            # 7. Calculate Other Analysis Data (OCR) via risk module builders
            ocr_text = inference_result.get("ocr_text", "")
            if ocr_text:
                text_score, found_keywords = build_text_analysis(ocr_text)
            else:
                text_score, found_keywords = 0, []
                ocr_text = "No text detected."

            source_score = build_source_score()
            visual_score = inference_result.get("visual_risk_score", 0)
            ai_gen_probability = inference_result.get("ai_gen_probability", 0.0)
            anomaly_region = inference_result.get("anomaly_region", "บริเวณที่น่าสงสัยในภาพ")

            risk_result = calculate_risk_score(text_score, visual_score, source_score)

            # Phase 1: ส่งผล visual/OCR/cscore ให้ client ก่อน XAI (Qwen รันบน CPU ช้ากว่า)
            scan.text_score = text_score
            scan.visual_score = visual_score
            # DB column is non-null in the current schema. Keep 0 only as a
            # storage compatibility placeholder; unavailable source evidence is
            # exposed through source_status and source_score=null at the API.
            scan.source_score = source_score if source_score is not None else 0
            scan.total_risk_score = risk_result["total_risk_score"]
            scan.ocr_text = ocr_text
            scan.scam_keywords_found = found_keywords
            scan.ai_gen_probability = ai_gen_probability
            scan.xai_explanation = None
            scan.status = "processing_text"
            scan.progress = 90
            await db.commit()

            # Broadcast ให้ dashboard/client เห็นผลรอบแรกทันที
            await manager.broadcast({"type": "refresh_dashboard"})

            # Phase 2: XAI explanation ตามมาทีหลัง — พัง/หมดเวลาก็ไม่ล้มสแกน ใช้ fallback แทน
            xai_explanation = await _generate_xai_with_timeout(
                anomaly_region, visual_score, ai_gen_probability, found_keywords
            )

            scan.xai_explanation = xai_explanation
            scan.status = "completed"
            scan.progress = 100
            scan.completed_at = datetime.now(TH_TIMEZONE)

            await db.commit()
            
            # Broadcast to admin dashboard
            await manager.broadcast({"type": "refresh_dashboard"})

        except Exception as e:
            scan.status = "failed"
            scan.progress = 0
            # Optional: save error message to some field if exists
            await db.commit()

