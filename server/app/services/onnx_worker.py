import sys
import os
import json
import base64
import onnxruntime as ort
import numpy as np
import cv2
from PIL import Image
import io

MODEL_PATH = os.environ.get("ONNX_MODEL_PATH", "/home/panuwat/project/model/segformer/work_dirs/v1.0.0/segformer_v1_dynamic.onnx")

# Tiling strategy: ป้อนภาพที่ resolution ต้นฉบับผ่าน overlapping 512x512 patches
# แทนการ resize ภาพทั้งใบ -> 512x512 (จุดที่ทำให้รายละเอียดหลุด).
# โมเดลถูกเทรนที่ 512x512 ดังนั้นการป้อน tile ขนาด 512 เป็น on-distribution ที่แม่นที่สุด.
TILE_SIZE = int(os.environ.get("ONNX_TILE_SIZE", "512"))
TILE_OVERLAP = int(os.environ.get("ONNX_TILE_OVERLAP", "64"))
STRIDE = TILE_SIZE - TILE_OVERLAP

MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def generate_heatmap(prob_map, original_image_np):
    heatmap_uint8 = np.uint8(255 * prob_map)
    heatmap_color = cv2.applyColorMap(heatmap_uint8, cv2.COLORMAP_JET)
    original_bgr = cv2.cvtColor(original_image_np, cv2.COLOR_RGB2BGR)
    overlay = cv2.addWeighted(original_bgr, 0.6, heatmap_color, 0.4, 0)
    is_success, buffer = cv2.imencode(".jpg", overlay)
    if is_success:
        return buffer.tobytes()
    return b""


def run_patch(session, input_name, patch: np.ndarray) -> np.ndarray:
    """Run inference on a single HxWx3 uint8 patch, return full-res prob map (HxW)."""
    h, w = patch.shape[:2]
    img_resized = cv2.resize(patch, (TILE_SIZE, TILE_SIZE), interpolation=cv2.INTER_LANCZOS4)
    img_array = img_resized.astype(np.float32) / 255.0
    img_normalized = (img_array - MEAN) / STD
    input_tensor = np.transpose(img_normalized, (2, 0, 1))
    input_tensor = np.expand_dims(input_tensor, axis=0)

    outputs = session.run(None, {input_name: input_tensor})
    if len(outputs) == 0:
        return np.zeros((h, w), dtype=np.float32)

    logits = outputs[0]
    raw_map = logits[0, 0, :, :]
    prob_map = 1 / (1 + np.exp(-raw_map))  # true probability
    return cv2.resize(prob_map, (w, h), interpolation=cv2.INTER_LINEAR)


def tile_inference(session, input_name, image: Image.Image) -> np.ndarray:
    """
    Stitch a full-resolution probability map by running overlapping tiles
    and averaging overlaps. Returns prob map at original image size (HxW).
    """
    image_np = np.array(image)  # HxWx3 uint8
    h, w = image_np.shape[:2]

    if h <= TILE_SIZE and w <= TILE_SIZE:
        return run_patch(session, input_name, image_np)

    acc = np.zeros((h, w), dtype=np.float64)
    weight = np.zeros((h, w), dtype=np.float64)

    for y0 in range(0, h, STRIDE):
        for x0 in range(0, w, STRIDE):
            y1 = min(y0 + TILE_SIZE, h)
            x1 = min(x0 + TILE_SIZE, w)
            tile_h, tile_w = y1 - y0, x1 - x0

            # ขยาย tile ให้เต็ม TILE_SIZE (pad ด้านขวา/ล่าง) เพื่อไม่ให้ค้าง patch เล็ก
            if tile_h < TILE_SIZE or tile_w < TILE_SIZE:
                tile = np.zeros((TILE_SIZE, TILE_SIZE, 3), dtype=np.uint8)
                tile[:tile_h, :tile_w] = image_np[y0:y1, x0:x1]
            else:
                tile = image_np[y0:y1, x0:x1]

            prob = run_patch(session, input_name, tile)
            # prob ที่ได้เป็น TILE_SIZExTILE_SIZE (หลัง resize กลับ) เก็บเฉพาะส่วนจริง
            acc[y0:y1, x0:x1] += prob[:tile_h, :tile_w]
            weight[y0:y1, x0:x1] += 1.0

    weight = np.maximum(weight, 1e-8)
    return (acc / weight).astype(np.float32)


def main():
    input_data = sys.stdin.read()
    if not input_data:
        return
    image_bytes = base64.b64decode(input_data)

    session = ort.InferenceSession(MODEL_PATH, providers=['CUDAExecutionProvider'])
    input_name = session.get_inputs()[0].name

    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    original_size = image.size

    # Full-res probability map (tiling preserves high-res detail)
    prob_map_true = tile_inference(session, input_name, image)

    # Visual heatmap using Min-Max scaling for clear display
    pmin, pmax = prob_map_true.min(), prob_map_true.max()
    prob_map_visual = (prob_map_true - pmin) / (pmax - pmin + 1e-5)
    heatmap_bytes = generate_heatmap(prob_map_visual, np.array(image))

    # Visual risk using 99th percentile of true probabilities (captures peaks)
    ai_gen_prob = float(np.percentile(prob_map_true, 99))
    visual_risk_score = int(ai_gen_prob * 100)

    result = {
        "visual_risk_score": visual_risk_score,
        "ai_gen_probability": ai_gen_prob,
        "heatmap_b64": base64.b64encode(heatmap_bytes).decode('utf-8') if heatmap_bytes else ""
    }

    print(json.dumps(result))


if __name__ == "__main__":
    main()
