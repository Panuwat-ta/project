import os
from fastapi import UploadFile, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
from app.core.config import settings
from app.models.scan import Scan
from app.utils.hashing import calculate_image_hash
from app.utils.risk_calculator import calculate_risk_score
from app.services.inference_service import inference_service

async def analyze_image(file: UploadFile, user_id: int, db: AsyncSession) -> Scan:
    # 1. Validate file type
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=400, detail="Invalid file type. Only JPEG and PNG are allowed.")
    
    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="File is empty. Please upload a valid image file.")
    
    # 2. Calculate Hash
    image_hash = calculate_image_hash(file_bytes)
    
    # Ensure upload directories exist
    os.makedirs(settings.LOCAL_UPLOAD_DIR, exist_ok=True)
    heatmap_dir = os.path.join(settings.LOCAL_UPLOAD_DIR, "heatmaps")
    os.makedirs(heatmap_dir, exist_ok=True)
    
    # 3. Save raw file locally
    filename = f"{image_hash}.jpg" if file.content_type == "image/jpeg" else f"{image_hash}.png"
    file_path = os.path.join(settings.LOCAL_UPLOAD_DIR, filename)
    
    with open(file_path, "wb") as buffer:
        buffer.write(file_bytes)
        
    # 4. Run AI Inference (Phase 4)
    # The predict method might block the event loop a bit in a real scenario,
    # usually we run it in a threadpool, but for now we just call it directly.
    inference_result = inference_service.predict(file_bytes)
    
    # Save heatmap image
    heatmap_filename = f"{image_hash}_heatmap.jpg"
    heatmap_path = os.path.join(heatmap_dir, heatmap_filename)
    if inference_result.get("heatmap_bytes"):
        with open(heatmap_path, "wb") as f:
            f.write(inference_result["heatmap_bytes"])
    
    # 5. Calculate Other Analysis Data (OCR, EXIF)
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

    source_score = 20
    visual_score = inference_result.get("visual_risk_score", 0)
    ai_gen_probability = inference_result.get("ai_gen_probability", 0.0)
    
    risk_result = calculate_risk_score(text_score, visual_score, source_score)
    
    # 6. Create Scan record
    new_scan = Scan(
        user_id=user_id,
        image_hash=image_hash,
        raw_image_url=file_path,
        heatmap_image_url=heatmap_path if os.path.exists(heatmap_path) else None,
        text_score=text_score,
        visual_score=visual_score,
        source_score=source_score,
        total_risk_score=risk_result["total_risk_score"],
        exif_data={"Make": "Apple", "Model": "iPhone 13"}, # Mock
        ocr_text=ocr_text,
        scam_keywords_found=found_keywords,
        ai_gen_probability=ai_gen_probability,
        status="completed",
        completed_at=datetime.now(timezone.utc)
    )
    
    db.add(new_scan)
    await db.commit()
    await db.refresh(new_scan)
    
    # Set risk_grade manually for Pydantic schema
    new_scan.risk_grade = risk_result["grade"]
    
    return new_scan
