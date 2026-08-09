import io
import logging
from typing import Dict, Any, Tuple

from fastapi import HTTPException, status
from PIL import Image, ExifTags, UnidentifiedImageError

from app.core.config import settings

logger = logging.getLogger(__name__)

# เปิดให้ Pillow อ่าน HEIC (iPhone) ได้
try:
    from pillow_heif import register_heif_opener
    register_heif_opener()
except Exception as e:
    logger.warning(f"pillow-heif not available, HEIC uploads will be rejected: {e}")

# กัน Decompression Bomb (ภาพเล็กแต่บีบอัดข้อมูลมหาศาล)
Image.MAX_IMAGE_PIXELS = settings.MAX_IMAGE_PIXELS


def load_image_verified(image_bytes: bytes) -> Tuple[Image.Image, Dict[str, Any]]:
    """
    ตรวจสอบ + decode ภาพจาก bytes ต้นฉบับเป็น RGB image
    - ยืนยันว่าเป็นไฟล์รูปจริง (ไม่เชื่อ content_type)
    - decode-once: กลับเป็นชุดพิกเซล RGB เดียวที่จะใช้กับทุกส่วน
    - ดึง EXIF จากต้นฉบับ (ก่อนแปลงเป็น PNG ซึ่งส่วนใหญ่ไม่มี EXIF)
    คืนค่า (rgb_image, exif_data)
    """
    if not image_bytes:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="File is empty. Please upload a valid image file.")

    try:
        image = Image.open(io.BytesIO(image_bytes))
        image.load()  # force decode -> trigger bomb guard / corruption error
    except UnidentifiedImageError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="File is not a valid image.")
    except Image.DecompressionBombError:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Image is too large to process (max {settings.MAX_IMAGE_PIXELS} pixels).",
        )
    except Exception as e:
        logger.warning(f"Failed to decode image: {e}")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Image is corrupted or unsupported.")

    exif_data = _extract_exif(image)

    if image.mode != "RGB":
        image = image.convert("RGB")

    return image, exif_data


def encode_lossless_png(image: Image.Image) -> bytes:
    """แปลง RGB image เป็น PNG bytes (lossless) สำหรับเก็บเป็นหลักฐาน/ส่ง AI"""
    buf = io.BytesIO()
    image.save(buf, format="PNG", optimize=False)
    return buf.getvalue()


def _extract_exif(image: Image.Image) -> Dict[str, Any]:
    """ดึง EXIF จาก PIL Image (ยังไม่ถูก re-encode)"""
    try:
        exif_data = image.getexif()
        if not exif_data:
            return {}
        return {
            ExifTags.TAGS.get(tag_id, str(tag_id)): str(value)
            for tag_id, value in exif_data.items()
        }
    except Exception as e:
        logger.warning(f"Failed to extract EXIF: {e}")
        return {}
