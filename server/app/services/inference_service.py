import os
import base64
import json
import subprocess
import sys
from app.core.config import settings

class InferenceService:
    def __init__(self):
        # We run ONNX in a separate subprocess to avoid CUDA 12 vs 13.3 conflicts.

        # Initialize Surya OCR using official library (v0.5.0)
        self.det_processor = None
        self.det_model = None
        self.rec_model = None
        self.rec_processor = None
        
        try:
            import ctypes
            import sys
            try:
                ctypes.CDLL(os.path.join(sys.prefix, "lib", "libbz2.so.1.0"), mode=ctypes.RTLD_GLOBAL)
            except Exception:
                pass
            
            # Set HF cache directory to the local model folder so models are saved there
            os.environ["HF_HOME"] = "/home/panuwat/project/model/surya"
            
            import torch
            # Disable cuDNN to prevent CUDNN_STATUS_SUBLIBRARY_VERSION_MISMATCH
            torch.backends.cudnn.enabled = False
            
            from surya.ocr import run_ocr
            from surya.model.detection.model import load_model as load_det_model, load_processor as load_det_processor
            from surya.model.recognition.model import load_model as load_rec_model
            from surya.model.recognition.processor import load_processor as load_rec_processor
            
            # Load models (will download from HF if not present)
            self.det_processor, self.det_model = load_det_processor(), load_det_model()
            self.rec_model, self.rec_processor = load_rec_model(), load_rec_processor()
            print("Loaded official Surya OCR models successfully")
        except Exception as e:
            print(f"Failed to load Surya OCR models: {e}")

        # Initialize Qwen2.5-1.5B (GGUF) using llama-cpp-python with GPU
        self.xai_model = None
        try:
            xai_path = getattr(settings, "XAI_MODEL_PATH", "/home/panuwat/project/model/Qwen2.5-1.5B/qwen2.5-1.5b-instruct-q4_k_m.gguf")
            if os.path.exists(xai_path):
                from llama_cpp import Llama
                self.xai_model = Llama(
                    model_path=xai_path,
                    n_gpu_layers=getattr(settings, "XAI_GPU_LAYERS", -1),
                    n_ctx=getattr(settings, "XAI_CONTEXT_SIZE", 1024),
                    verbose=False
                )
                print("Loaded Qwen2.5-1.5B XAI model successfully with GPU")
            else:
                print(f"XAI model file not found at {xai_path}")
        except Exception as e:
            print(f"Failed to load Qwen2.5 XAI model: {e}")

    def generate_xai_explanation(
        self,
        region: str,
        visual_score: int,
        ai_gen_probability: float,
        scam_keywords: list = None
    ) -> str:
        """
        Generate Thai explanation for visual anomalies detected.
        """
        if not self.xai_model:
            return self._fallback_xai_explanation(region, visual_score, ai_gen_probability)

        system_prompt = (
            "คุณเป็นระบบปัญญาประดิษฐ์อธิบายผลนิติวิทยาศาสตร์ดิจิทัล (Explainable AI)\n"
            "หน้าที่: เขียนสรุปเหตุผลความผิดปกติของภาพตามข้อมูลที่กำหนดให้เป็นภาษาไทย 2-3 ประโยค สุภาพ กระชับ เข้าใจง่าย\n"
            "กฎเหล็ก: ระบุตำแหน่งและความผิดปกติตามข้อมูลที่ได้รับเท่านั้น ห้ามแต่งข้อมูลตำแหน่งอื่นขึ้นมาเองเด็ดขาด"
        )

        keywords_str = ", ".join(scam_keywords) if scam_keywords else "ไม่พบ"
        user_content = (
            f"- ตำแหน่งที่ตรวจพบ: {region}\n"
            f"- คะแนนความผิดปกติของภาพ (Visual Score): {visual_score}/100\n"
            f"- โอกาสเป็นภาพสร้างด้วย AI (AI-Gen Probability): {ai_gen_probability:.2f}\n"
            f"- คำสำคัญน่าสงสัยที่พบในภาพ: {keywords_str}\n"
            "กรุณาเขียนคำอธิบายสั้นๆ:"
        )

        prompt = (
            f"<|im_start|>system\n{system_prompt}<|im_end|>\n"
            f"<|im_start|>user\n{user_content}<|im_end|>\n"
            f"<|im_start|>assistant\n"
        )

        try:
            output = self.xai_model(
                prompt,
                max_tokens=120,
                temperature=0.2,
                top_p=0.9,
                stop=["<|im_end|>", "\n\n"]
            )
            return output["choices"][0]["text"].strip()
        except Exception as e:
            print(f"XAI Generation error: {e}")
            return self._fallback_xai_explanation(region, visual_score, ai_gen_probability)

    def _fallback_xai_explanation(self, region: str, visual_score: int, ai_gen_prob: float) -> str:
        if visual_score >= 60:
            return f"AI ตรวจพบความผิดปกติ{region} ซึ่งมีลักษณะของการตัดต่อที่ไม่เป็นธรรมชาติ นอกจากนี้ยังพบความไม่สม่ำเสมอของคุณภาพพิกเซลที่เกิดจากการบีบอัดภาพซ้อนทับกัน"
        elif ai_gen_prob >= 0.6:
            return "ตรวจพบร่องรอยโครงสร้างพิกเซลที่สอดคล้องกับภาพสังเคราะห์จากปัญญาประดิษฐ์ (AI-Generated)"
        return "โครงสร้างพิกเซลของภาพมีความสม่ำเสมอ ไม่พบร่องรอยการตัดต่อที่ส่งผลต่อความเสี่ยงอย่างมีนัยสำคัญ"

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
            env["ONNX_MODEL_PATH"] = settings.ONNX_MODEL_PATH
            env["ONNX_TILE_SIZE"] = str(settings.ONNX_TILE_SIZE)
            env["ONNX_TILE_OVERLAP"] = str(settings.ONNX_TILE_OVERLAP)
            
            # Re-enable CUDA for ONNX worker
            if "CUDA_VISIBLE_DEVICES" in env and env["CUDA_VISIBLE_DEVICES"] == "":
                del env["CUDA_VISIBLE_DEVICES"]
            
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
                # Parse only the last line as JSON to ignore any other print statements
                lines = stdout.decode('utf-8').strip().split('\n')
                result = json.loads(lines[-1])
                visual_risk_score = result.get("visual_risk_score", visual_risk_score)
                ai_gen_probability = result.get("ai_gen_probability", ai_gen_probability)
                anomaly_region = result.get("anomaly_region", "บริเวณที่น่าสงสัยในภาพ")
                if result.get("heatmap_b64"):
                    heatmap_bytes = base64.b64decode(result["heatmap_b64"])
            else:
                print(f"ONNX worker failed: {stderr.decode('utf-8')}")
        except Exception as e:
            print(f"Failed to run ONNX worker: {e}")
            
        # 2. Run Surya OCR
        ocr_text = ""
        if self.det_model and self.rec_model:
            try:
                from surya.ocr import run_ocr
                import io
                from PIL import Image
                
                image = Image.open(io.BytesIO(image_bytes))
                
                # run_ocr expects list of images and list of language lists
                predictions = run_ocr(
                    [image], 
                    [["th", "en"]], # Thai and English
                    self.det_model, 
                    self.det_processor, 
                    self.rec_model, 
                    self.rec_processor
                )
                
                # Extract text from prediction results
                if predictions and len(predictions) > 0:
                    text_lines = [line.text for line in predictions[0].text_lines]
                    ocr_text = "\n".join(text_lines)
            except Exception as e:
                print(f"Surya OCR error: {e}")
                
        return {
            "visual_risk_score": visual_risk_score,
            "ai_gen_probability": ai_gen_probability,
            "anomaly_region": locals().get("anomaly_region", "บริเวณที่น่าสงสัยในภาพ"),
            "heatmap_bytes": heatmap_bytes,
            "ocr_text": ocr_text
        }

    def generate_mock_heatmap(self, image_bytes: bytes) -> bytes:
        """Fallback mock heatmap generation if model fails"""
        return b""

# Create singleton instance to be used across requests
inference_service = InferenceService()
