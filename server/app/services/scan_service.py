import os
from fastapi import UploadFile, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
from starlette.concurrency import run_in_threadpool
from app.core.config import settings, TH_TIMEZONE
from app.core.websocket import manager
from app.models.scan import Scan
from app.utils.hashing import calculate_image_hash
from app.utils.image_utils import load_image_verified, encode_lossless_png
from app.utils.risk_calculator import calculate_risk_score
from app.services.inference_service import inference_service

MAX_UPLOAD_BYTES = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024

async def analyze_image(file: UploadFile, user_id: int, db: AsyncSession) -> Scan:
    # 1. Read file
    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="File is empty. Please upload a valid image file.")
    if len(file_bytes) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum allowed size is {settings.MAX_UPLOAD_SIZE_MB} MB.",
        )

    # 2. Verify + decode-once -> RGB pixels (real image check, not trusting content_type)
    image, exif_data = await run_in_threadpool(load_image_verified, file_bytes)

    # 3. Normalize to lossless PNG for evidence + inference (same pixels everywhere)
    png_bytes = await run_in_threadpool(encode_lossless_png, image)

    # 4. Calculate Hash (จาก bytes ต้นฉบับ เพื่อ dedupe/หลักฐาน)
    image_hash = calculate_image_hash(file_bytes)

    # Ensure upload directories exist
    os.makedirs(settings.LOCAL_UPLOAD_DIR, exist_ok=True)
    heatmap_dir = os.path.join(settings.LOCAL_UPLOAD_DIR, "heatmaps")
    os.makedirs(heatmap_dir, exist_ok=True)

    # 5. Save PNG evidence (lossless)
    filename = f"{image_hash}.png"
    file_path = os.path.join(settings.LOCAL_UPLOAD_DIR, filename)
    with open(file_path, "wb") as buffer:
        buffer.write(png_bytes)

    # 6. Run AI Inference off the event loop (CPU/GPU bound -> threadpool).
    #    ส่งชุด pixels เดียวกัน (PNG lossless) ให้ทั้ง SegFormer และ Surya
    inference_result = await run_in_threadpool(inference_service.predict, png_bytes)

    # Save heatmap image
    heatmap_filename = f"{image_hash}_heatmap.jpg"
    heatmap_path = os.path.join(heatmap_dir, heatmap_filename)
    if inference_result.get("heatmap_bytes"):
        with open(heatmap_path, "wb") as f:
            f.write(inference_result["heatmap_bytes"])

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

    # 8. Create Scan record
    new_scan = Scan(
        user_id=user_id,
        image_hash=image_hash,
        raw_image_url=file_path,
        heatmap_image_url=heatmap_path if os.path.exists(heatmap_path) else None,
        text_score=text_score,
        visual_score=visual_score,
        source_score=source_score,
        total_risk_score=risk_result["total_risk_score"],
        exif_data=exif_data,
        ocr_text=ocr_text,
        scam_keywords_found=found_keywords,
        ai_gen_probability=ai_gen_probability,
        status="completed",
        completed_at=datetime.now(TH_TIMEZONE)
    )

    db.add(new_scan)
    await db.commit()
    await db.refresh(new_scan)
    
    # Broadcast to admin dashboard
    await manager.broadcast({"type": "refresh_dashboard"})

    # Set risk_grade manually for Pydantic schema
    new_scan.risk_grade = risk_result["grade"]

    return new_scan