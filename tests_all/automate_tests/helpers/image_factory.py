"""Image factory — สร้างไฟล์รูปทดสอบแบบไม่ต้องพึ่งไฟล์จริง"""
from io import BytesIO
from PIL import Image

def make_test_image_bytes(width=512, height=512, color=(200, 50, 50), text="SCAM TEST", fmt="PNG"):
    img = Image.new("RGB", (width, height), color)
    buf = BytesIO()
    img.save(buf, format=fmt)
    buf.seek(0)
    return buf.getvalue()

def make_test_image_file(width=512, height=512, fmt="PNG"):
    data = make_test_image_bytes(width, height, fmt=fmt)
    ext = fmt.lower()
    if ext == "jpeg":
        ext = "jpg"
    return (f"test_{width}x{height}.{ext}", data, f"image/{ext if ext != 'jpg' else 'jpeg'}")
