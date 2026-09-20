import sys
import os
import json
import base64
import onnxruntime as ort
import numpy as np
import cv2
from PIL import Image
import io

from pathlib import Path
from dotenv import load_dotenv

# โหลดคอนฟิกจาก .env.local และ .env ของ server หากยังไม่มีในสภาพแวดล้อม
_SERVER_DIR = Path(__file__).resolve().parents[2]
if str(_SERVER_DIR) not in sys.path:
    sys.path.insert(0, str(_SERVER_DIR))

from app.services.tiling import det_score_image as _det_score_image
from app.services.tiling import tile_inference as _shared_tile_inference

load_dotenv(_SERVER_DIR / ".env.local")
load_dotenv(_SERVER_DIR / ".env")

MODEL_PATH = os.environ.get("ONNX_MODEL_PATH")
if not MODEL_PATH:
    sys.stderr.write("FATAL ERROR: ONNX_MODEL_PATH environment variable is required and must be set in .env\n")
    sys.exit(1)

# Tiling strategy: ป้อนภาพที่ resolution ต้นฉบับผ่าน overlapping 512x512 patches
# แทนการ resize ภาพทั้งใบ -> 512x512 (จุดที่ทำให้รายละเอียดหลุด).
# โมเดลถูกเทรนที่ 512x512 ดังนั้นการป้อน tile ขนาด 512 เป็น on-distribution ที่แม่นที่สุด.
TILE_SIZE = int(os.environ.get("ONNX_TILE_SIZE", 512))
TILE_OVERLAP = int(os.environ.get("ONNX_TILE_OVERLAP", 64))


def get_custom_colormap():
    cmap = np.zeros((256, 1, 3), dtype=np.uint8)
    for i in range(256):
        if i < 85:
            # Green (0) to Blue (85)
            t = i / 85.0
            b = int(255 * t)
            g = int(255 * (1 - t))
            r = 0
        elif i < 170:
            # Blue (85) to Yellow (170)
            t = (i - 85) / 85.0
            b = int(255 * (1 - t))
            g = int(255 * t)
            r = int(255 * t)
        else:
            # Yellow (170) to Red (255)
            t = (i - 170) / 85.0
            b = 0
            g = int(255 * (1 - t))
            r = 255
        cmap[i, 0, :] = [b, g, r]
    return cmap

CUSTOM_COLORMAP = get_custom_colormap()

def generate_heatmap(prob_map, original_image_np):
    heatmap_uint8 = np.uint8(255 * prob_map)
    heatmap_color = cv2.applyColorMap(heatmap_uint8, CUSTOM_COLORMAP)
    original_bgr = cv2.cvtColor(original_image_np, cv2.COLOR_RGB2BGR)
    overlay = cv2.addWeighted(original_bgr, 0.6, heatmap_color, 0.4, 0)
    is_success, buffer = cv2.imencode(".jpg", overlay)
    if is_success:
        return buffer.tobytes()
    return b""


def tile_inference(session, input_name, image: Image.Image) -> np.ndarray:
    """Env-bound wrapper: stitch prob map with worker TILE_SIZE/OVERLAP."""
    return _shared_tile_inference(session, input_name, image, TILE_SIZE, TILE_OVERLAP)


def run_det_image(session, input_name, image: Image.Image):
    """Env-bound wrapper: Track B det score (None for single-output models)."""
    return _det_score_image(session, image, TILE_SIZE)


def main():
    input_data = sys.stdin.read()
    if not input_data:
        return
    image_bytes = base64.b64decode(input_data)

    # จำกัด CUDA arena ของ ORT: default กวาด VRAM ว่างทั้งใบ (gpu_mem_limit=SIZE_MAX)
    # ชนกับ Surya (process หลัก) ตอนสแกนซ้อนกัน -> OOM. โมเดลเล็ก (2MB + 95MB data,
    # tile 512) 512MB เหลือเฟือ
    session = ort.InferenceSession(
        MODEL_PATH,
        providers=[('CUDAExecutionProvider', {
            'gpu_mem_limit': 512 * 1024 * 1024,
            'arena_extend_strategy': 'kSameAsRequested',
        })],
    )
    input_name = session.get_inputs()[0].name

    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    original_size = image.size

    # Full-res probability map of forgery (tiling preserves high-res detail)
    prob_map_true = tile_inference(session, input_name, image)

    # Visual heatmap using Min-Max scaling for clear display
    pmin, pmax = prob_map_true.min(), prob_map_true.max()
    prob_map_visual = (prob_map_true - pmin) / (pmax - pmin + 1e-5)
    heatmap_bytes = generate_heatmap(prob_map_visual, np.array(image))

    # Real visual risk score based on maximum forgery probability in the image
    ai_gen_prob = float(prob_map_true.max())
    visual_risk_score = int(round(ai_gen_prob * 100))

    # Track B det score (None ถ้าโมเดลไม่มี det head) — ขั้นนี้ยังไม่รวมเข้า total
    det_score = run_det_image(session, input_name, image)

    h, w = prob_map_true.shape[:2]
    threshold = max(0.35, float(prob_map_true.mean() + 0.10))
    tampered_pixels = np.argwhere(prob_map_true >= threshold)
    if len(tampered_pixels) > 0 and ai_gen_prob >= 0.35:
        mean_y, mean_x = tampered_pixels.mean(axis=0)
        v = "บน" if mean_y < h * 0.38 else ("ล่าง" if mean_y > h * 0.62 else "กลาง")
        h_pos = "ซ้าย" if mean_x < w * 0.38 else ("ขวา" if mean_x > w * 0.62 else "กลาง")
        
        if v == "กลาง" and h_pos == "กลาง":
            region = "บริเวณกึ่งกลางของภาพ"
        elif v == "กลาง":
            region = f"บริเวณด้าน{h_pos}ของภาพ"
        elif h_pos == "กลาง":
            region = f"บริเวณส่วน{v}ของภาพ"
        else:
            region = f"บริเวณมุม{h_pos}{v}ของภาพ"
    else:
        region = "ทั่วทั้งภาพอยู่ในเกณฑ์ปกติ"
    
    result = {
        "visual_risk_score": visual_risk_score,
        "ai_gen_probability": ai_gen_prob,
        "det_score": det_score,
        "anomaly_region": region,
        "heatmap_b64": base64.b64encode(heatmap_bytes).decode('utf-8') if heatmap_bytes else ""
    }

    print(json.dumps(result))


if __name__ == "__main__":
    main()
