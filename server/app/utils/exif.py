import io
import logging
from typing import Dict, Any

from PIL import Image, ExifTags

logger = logging.getLogger(__name__)

def extract_exif(image_bytes: bytes) -> Dict[str, Any]:
    """
    ดึงข้อมูล EXIF/metadata จริงจากไฟล์รูปภาพ
    คืนค่า dict ว่างถ้ารูปไม่มี metadata หรืออ่านไม่ได้
    """
    try:
        image = Image.open(io.BytesIO(image_bytes))
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
