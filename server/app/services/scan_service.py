import os
import json
from fastapi import UploadFile, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import datetime
from starlette.concurrency import run_in_threadpool
from app.core.config import settings, TH_TIMEZONE
from app.core.websocket import manager
from app.models.scan import Scan
from app.utils.hashing import calculate_image_hash
from app.utils.image_utils import load_image_verified, encode_lossless_png
from app.utils.risk_calculator import calculate_risk_score
from app.services.inference_service import inference_service
import app.core.redis as redis_core

MAX_UPLOAD_BYTES = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024

async def create_scan_task(file: UploadFile, user_id: int, db: AsyncSession, title: str | None = None) -> tuple[Scan, bytes, str]:
    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="File is empty. Please upload a valid image file.")
    if len(file_bytes) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum allowed size is {settings.MAX_UPLOAD_SIZE_MB} MB.",
        )

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

async def process_image_background(scan_id, file_bytes: bytes, image_hash: str):
    from app.core.database import async_session
    
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

            os.makedirs(settings.LOCAL_UPLOAD_DIR, exist_ok=True)
            heatmap_dir = os.path.join(settings.LOCAL_UPLOAD_DIR, "heatmaps")
            os.makedirs(heatmap_dir, exist_ok=True)

            # 5. Save PNG evidence
            filename = f"{image_hash}.png"
            file_path = os.path.join(settings.LOCAL_UPLOAD_DIR, filename)
            with open(file_path, "wb") as buffer:
                buffer.write(png_bytes)
                
            scan.raw_image_url = file_path
            scan.exif_data = exif_data
            scan.progress = 40
            await db.commit()

            # 6. Check Redis cache
            cache_key = f"scan_result:{image_hash}"
            cached_data = None
            
            if redis_core.redis_client:
                try:
                    cached_str = await redis_core.redis_client.get(cache_key)
                    if cached_str:
                        cached_data = json.loads(cached_str)
                except Exception as e:
                    print(f"Redis cache read error: {e}")

            heatmap_filename = f"{image_hash}_heatmap.jpg"
            heatmap_path = os.path.join(heatmap_dir, heatmap_filename)

            scan.status = "processing_visual"
            scan.progress = 50
            await db.commit()

            if cached_data:
                inference_result = cached_data
            else:
                inference_result = await run_in_threadpool(inference_service.predict, png_bytes)
                
                if inference_result.get("heatmap_bytes"):
                    with open(heatmap_path, "wb") as f:
                        f.write(inference_result["heatmap_bytes"])
                    del inference_result["heatmap_bytes"]
                    inference_result["has_heatmap"] = True

                if redis_core.redis_client:
                    try:
                        await redis_core.redis_client.setex(cache_key, 2592000, json.dumps(inference_result))
                    except Exception as e:
                        print(f"Redis cache write error: {e}")
                        
            if os.path.exists(heatmap_path):
                scan.heatmap_image_url = heatmap_path
                
            scan.status = "processing_text"
            scan.progress = 80
            await db.commit()

            # 7. Calculate Other Analysis Data (OCR)
            ocr_text = inference_result.get("ocr_text", "")
            scam_keywords = ["ด่วน", "โบนัส", "กู้เงิน", "รับเงิน", "ลงทุน", "อนุมัติไว", "ได้เงินจริง", "คลิก", "เครดิตฟรี", "แจกฟรี", "หลุด"]
            found_keywords = []

            text_score = 0
            if ocr_text:
                for kw in scam_keywords:
                    if kw in ocr_text:
                        found_keywords.append(kw)
                        text_score += 25
                text_score = min(text_score, 100)
            else:
                text_score = 0
                ocr_text = "No text detected."

            source_score = settings.DEFAULT_SOURCE_SCORE
            visual_score = inference_result.get("visual_risk_score", 0)
            ai_gen_probability = inference_result.get("ai_gen_probability", 0.0)

            risk_result = calculate_risk_score(text_score, visual_score, source_score)

            scan.text_score = text_score
            scan.visual_score = visual_score
            scan.source_score = source_score
            scan.total_risk_score = risk_result["total_risk_score"]
            scan.ocr_text = ocr_text
            scan.scam_keywords_found = found_keywords
            scan.ai_gen_probability = ai_gen_probability
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

