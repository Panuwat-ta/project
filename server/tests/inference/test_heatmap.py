import cv2
import numpy as np
import base64

def generate_heatmap(prob_map: np.ndarray, original_image_np: np.ndarray) -> bytes:
    # Convert prob_map (0-1) to 0-255 uint8
    heatmap_uint8 = np.uint8(255 * prob_map)
    
    # Apply Jet colormap
    heatmap_color = cv2.applyColorMap(heatmap_uint8, cv2.COLORMAP_JET)
    
    # Convert original image from RGB to BGR for OpenCV
    original_bgr = cv2.cvtColor(original_image_np, cv2.COLOR_RGB2BGR)
    
    # Overlay
    print("heatmap_color shape:", heatmap_color.shape)
    print("original_bgr shape:", original_bgr.shape)
    overlay = cv2.addWeighted(original_bgr, 0.6, heatmap_color, 0.4, 0)
    
    # Encode to JPEG bytes
    is_success, buffer = cv2.imencode(".jpg", overlay)
    print("is_success:", is_success)
    if is_success:
        return buffer.tobytes()
    return b""

if __name__ == "__main__":
    prob = np.random.rand(512, 512).astype(np.float32)
    img = np.random.randint(0, 255, (512, 512, 3), dtype=np.uint8)
    b = generate_heatmap(prob, img)
    print("Result size:", len(b))
