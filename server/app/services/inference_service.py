import onnxruntime as ort
import numpy as np
import cv2
from PIL import Image
import io
import uuid
import os
import base64
from app.core.config import settings

class InferenceService:
    def __init__(self):
        # Initialize ONNX Runtime session
        try:
            self.session = ort.InferenceSession(settings.ONNX_MODEL_PATH)
            self.input_name = self.session.get_inputs()[0].name
            print(f"Loaded ONNX model from {settings.ONNX_MODEL_PATH}")
        except Exception as e:
            print(f"Failed to load ONNX model: {e}")
            self.session = None

        # Initialize Llama CPP for Surya OCR
        self.llm = None
        try:
            from llama_cpp import Llama
            from llama_cpp.llama_chat_format import Qwen25VLChatHandler
            
            model_path = "/home/panuwat/project/model/surya/surya-2.gguf"
            mmproj_path = "/home/panuwat/project/model/surya/surya-2-mmproj.gguf"
            if os.path.exists(model_path) and os.path.exists(mmproj_path):
                chat_handler = Qwen25VLChatHandler(clip_model_path=mmproj_path)
                self.llm = Llama(model_path=model_path, chat_handler=chat_handler, n_ctx=8192, verbose=False)
                print(f"Loaded Surya OCR model from {model_path}")
        except Exception as e:
            print(f"Failed to load Surya OCR model: {e}")

    def predict(self, image_bytes: bytes) -> dict:
        """
        Process image and run inference.
        For a real SegFormer model, this handles resizing, normalization, and mask extraction.
        """
        if not self.session:
            # Fallback mock if model fails to load
            return {
                "visual_risk_score": 65,
                "ai_gen_probability": 0.45,
                "heatmap_bytes": self.generate_mock_heatmap(image_bytes),
                "ocr_text": ""
            }
            
        try:
            # 1. Decode image
            image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            original_size = image.size
            
            # 2. Resize and Normalize (assume 512x512 for SegFormer)
            input_size = (512, 512)
            img_resized = image.resize(input_size, Image.BILINEAR)
            img_array = np.array(img_resized).astype(np.float32) / 255.0
            
            # Normalize with ImageNet mean and std
            mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
            std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
            img_normalized = (img_array - mean) / std
            
            # Transpose to [1, C, H, W]
            input_tensor = np.transpose(img_normalized, (2, 0, 1))
            input_tensor = np.expand_dims(input_tensor, axis=0)
            
            # 3. Inference
            outputs = self.session.run(None, {self.input_name: input_tensor})
            
            # 4. Post-processing
            # Assuming output is shape [1, num_classes, H, W]
            logits = outputs[0]
            
            # Mocking probability map extraction for demonstration
            # In a real model: prob_map = softmax(logits)[:, 1, :, :] for forgery class
            # Here we just take a dummy channel or generate one for safety if model shape is unexpected
            if len(logits.shape) == 4:
                prob_map = logits[0, 0, :, :] # Just use the first channel as dummy prob map
                # Normalize to 0-1
                prob_map = (prob_map - np.min(prob_map)) / (np.max(prob_map) - np.min(prob_map) + 1e-5)
            else:
                prob_map = np.zeros((512, 512), dtype=np.float32)
                
            # Resize prob map back to original image size
            prob_map_resized = cv2.resize(prob_map, original_size)
            
            # 5. Generate Heatmap
            heatmap_bytes = self.generate_heatmap(prob_map_resized, np.array(image))
            
            # Calculate a dummy visual risk score based on prob map mean
            visual_risk_score = int(np.mean(prob_map) * 100)
            
            # Mock AI Gen Probability
            ai_gen_probability = float(np.random.uniform(0.1, 0.6))
            
            # 6. Surya OCR
            ocr_text = ""
            if self.llm:
                try:
                    image_b64 = base64.b64encode(image_bytes).decode('utf-8')
                    response = self.llm.create_chat_completion(
                        messages=[
                            {
                                "role": "user",
                                "content": [
                                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"}},
                                    {"type": "text", "text": "Extract all text from the image."}
                                ]
                            }
                        ]
                    )
                    ocr_text = response["choices"][0]["message"]["content"]
                except Exception as e:
                    print(f"Surya OCR error: {e}")
            
            return {
                "visual_risk_score": visual_risk_score,
                "ai_gen_probability": ai_gen_probability,
                "heatmap_bytes": heatmap_bytes,
                "ocr_text": ocr_text
            }
            
        except Exception as e:
            print(f"Inference error: {e}")
            return {
                "visual_risk_score": 50,
                "ai_gen_probability": 0.5,
                "heatmap_bytes": self.generate_mock_heatmap(image_bytes),
                "ocr_text": ""
            }

    def generate_heatmap(self, prob_map: np.ndarray, original_image_np: np.ndarray) -> bytes:
        """
        Convert Probability Map to Jet Colormap and overlay on original image.
        """
        # Convert prob_map (0-1) to 0-255 uint8
        heatmap_uint8 = np.uint8(255 * prob_map)
        
        # Apply Jet colormap
        heatmap_color = cv2.applyColorMap(heatmap_uint8, cv2.COLORMAP_JET)
        
        # Convert original image from RGB to BGR for OpenCV
        original_bgr = cv2.cvtColor(original_image_np, cv2.COLOR_RGB2BGR)
        
        # Overlay
        overlay = cv2.addWeighted(original_bgr, 0.6, heatmap_color, 0.4, 0)
        
        # Encode to JPEG bytes
        is_success, buffer = cv2.imencode(".jpg", overlay)
        if is_success:
            return buffer.tobytes()
        return b""
        
    def generate_mock_heatmap(self, image_bytes: bytes) -> bytes:
        """Fallback mock heatmap generation if model fails"""
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img_np = np.array(image)
        prob_map = np.zeros((img_np.shape[0], img_np.shape[1]), dtype=np.float32)
        # Add a fake red circle
        cv2.circle(prob_map, (img_np.shape[1]//2, img_np.shape[0]//2), 100, 1.0, -1)
        return self.generate_heatmap(prob_map, img_np)

# Create singleton instance to be used across requests
inference_service = InferenceService()
