"""Locust load test — ยิง /health และ /api/v1/scan/upload"""
from locust import HttpUser, task, between
import io
from PIL import Image

def _img():
    im = Image.new("RGB", (512, 512), (120, 120, 200))
    buf = io.BytesIO()
    im.save(buf, format="PNG")
    buf.seek(0)
    return buf.getvalue()

class ScamGuardUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def health(self):
        self.client.get("/health")

    @task(1)
    def scan(self):
        # ต้องมี token ถ้า endpoint ต้อง auth — สำหรับ load test จะลองแบบไม่ auth ก่อน
        self.client.post(
            "/api/v1/scan/upload",
            files={"file": ("load.png", _img(), "image/png")},
            data={"consent": "true"},
        )
