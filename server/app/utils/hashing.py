import hashlib

def calculate_image_hash(image_bytes: bytes) -> str:
    """
    คำนวณ SHA-256 Hash ของไฟล์รูปภาพ
    """
    sha256_hash = hashlib.sha256()
    sha256_hash.update(image_bytes)
    return sha256_hash.hexdigest()
