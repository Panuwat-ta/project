import sys
import json
import base64
import onnxruntime as ort
import numpy as np
import cv2
from PIL import Image
import io

def generate_heatmap(prob_map, original_image_np):
    heatmap_uint8 = np.uint8(255 * prob_map)
    heatmap_color = cv2.applyColorMap(heatmap_uint8, cv2.COLORMAP_JET)
    original_bgr = cv2.cvtColor(original_image_np, cv2.COLOR_RGB2BGR)
    overlay = cv2.addWeighted(original_bgr, 0.6, heatmap_color, 0.4, 0)
    is_success, buffer = cv2.imencode(".jpg", overlay)
    if is_success:
        return buffer.tobytes()
    return b""

def main():
    # Read base64 image from stdin
    input_data = sys.stdin.read()
    if not input_data:
        return
    image_bytes = base64.b64decode(input_data)
    
    # Load model
    session = ort.InferenceSession("/home/panuwat/project/model/segformer/work_dirs/v1.0.0/segformer_v1.onnx", providers=['CUDAExecutionProvider'])
    input_name = session.get_inputs()[0].name
    
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    original_size = image.size
    
    img_resized = image.resize((512, 512), Image.BILINEAR)
    img_array = np.array(img_resized).astype(np.float32) / 255.0
    
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    img_normalized = (img_array - mean) / std
    
    input_tensor = np.transpose(img_normalized, (2, 0, 1))
    input_tensor = np.expand_dims(input_tensor, axis=0)
    
    outputs = session.run(None, {input_name: input_tensor})
    
    if len(outputs) > 0:
        logits = outputs[0]
        raw_map = logits[0, 0, :, :]
        
        # 1. True probabilities for scoring using Sigmoid
        prob_map_true = 1 / (1 + np.exp(-raw_map))
        
        # 2. Visual heatmap using Min-Max scaling for clear display
        prob_map_visual = (raw_map - np.min(raw_map)) / (np.max(raw_map) - np.min(raw_map) + 1e-5)
    else:
        prob_map_true = np.zeros((512, 512), dtype=np.float32)
        prob_map_visual = prob_map_true
        
    prob_map_resized = cv2.resize(prob_map_visual, original_size)
    heatmap_bytes = generate_heatmap(prob_map_resized, np.array(image))
    
    # Calculate visual risk using the 99th percentile of true probabilities (captures peaks)
    ai_gen_prob = float(np.percentile(prob_map_true, 99))
    visual_risk_score = int(ai_gen_prob * 100)
    ai_gen_probability = ai_gen_prob
    
    result = {
        "visual_risk_score": visual_risk_score,
        "ai_gen_probability": ai_gen_probability,
        "heatmap_b64": base64.b64encode(heatmap_bytes).decode('utf-8') if heatmap_bytes else ""
    }
    
    print(json.dumps(result))

if __name__ == "__main__":
    main()
