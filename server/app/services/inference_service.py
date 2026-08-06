import os
import base64
import json
import subprocess
import sys
from app.core.config import settings

class InferenceService:
    def __init__(self):
        # We run ONNX in a separate subprocess to avoid CUDA 12 vs 13.3 conflicts.

        # Initialize Llama CPP for Surya OCR
        self.llm = None
        try:
            from llama_cpp import Llama
            from llama_cpp.llama_chat_format import Qwen25VLChatHandler
            
            model_path = "/home/panuwat/project/model/surya/surya-2.gguf"
            mmproj_path = "/home/panuwat/project/model/surya/surya-2-mmproj.gguf"
            if os.path.exists(model_path) and os.path.exists(mmproj_path):
                chat_handler = Qwen25VLChatHandler(clip_model_path=mmproj_path)
                self.llm = Llama(
                    model_path=model_path, 
                    chat_handler=chat_handler, 
                    n_ctx=8192, 
                    n_gpu_layers=-1, 
                    verbose=False
                )
                print(f"Loaded Surya OCR model from {model_path}")
        except Exception as e:
            print(f"Failed to load Surya OCR model: {e}")

    def predict(self, image_bytes: bytes) -> dict:
        """
        Process image and run inference via isolated ONNX worker + LLaMA.
        """
        visual_risk_score = 50
        ai_gen_probability = 0.5
        heatmap_bytes = self.generate_mock_heatmap(image_bytes)
        
        # 1. Run ONNX in isolated subprocess
        try:
            env = os.environ.copy()
            # Force LD_LIBRARY_PATH for ONNX worker to find pip CUDA 12 libs
            import glob
            venv_lib_path = os.path.join(os.getcwd(), "venv/lib/python3.10/site-packages/nvidia")
            nvidia_lib_dirs = glob.glob(f"{venv_lib_path}/*/lib")
            env["LD_LIBRARY_PATH"] = ":".join(nvidia_lib_dirs)
            
            worker_path = os.path.join(os.path.dirname(__file__), "onnx_worker.py")
            process = subprocess.Popen(
                [sys.executable, worker_path],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env
            )
            
            b64_image = base64.b64encode(image_bytes).decode('utf-8')
            stdout, stderr = process.communicate(input=b64_image.encode('utf-8'))
            
            if process.returncode == 0:
                result = json.loads(stdout.decode('utf-8'))
                visual_risk_score = result.get("visual_risk_score", visual_risk_score)
                ai_gen_probability = result.get("ai_gen_probability", ai_gen_probability)
                if result.get("heatmap_b64"):
                    heatmap_bytes = base64.b64decode(result["heatmap_b64"])
            else:
                print(f"ONNX worker failed: {stderr.decode('utf-8')}")
        except Exception as e:
            print(f"Failed to run ONNX worker: {e}")
            
        # 2. Run Surya OCR via LLaMA (in this process)
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

    def generate_mock_heatmap(self, image_bytes: bytes) -> bytes:
        """Fallback mock heatmap generation if model fails"""
        return b""

# Create singleton instance to be used across requests
inference_service = InferenceService()
