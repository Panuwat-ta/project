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
        
        # Initialize Qwen2.5-1.5B (GGUF) using llama-cpp-python with GPU
        self.xai_model = None
        try:
            xai_path = getattr(settings, "XAI_MODEL_PATH", "/home/panuwat/project/model/Qwen2.5-1.5B/qwen2.5-1.5b-instruct-q4_k_m.gguf")
            if os.path.exists(xai_path):
                import site, ctypes
                for site_dir in site.getsitepackages():
                    nvidia_dir = os.path.join(site_dir, "nvidia")
                    if os.path.exists(nvidia_dir):
                        for pkg in ["cuda_runtime", "cublas"]:
                            pkg_lib = os.path.join(nvidia_dir, pkg, "lib")
                            if os.path.exists(pkg_lib):
                                for f in sorted(os.listdir(pkg_lib)):
                                    if f.endswith(".so.12"):
                                        try:
                                            ctypes.CDLL(os.path.join(pkg_lib, f), mode=ctypes.RTLD_GLOBAL)
                                        except Exception:
                                            pass
                    gomp_dir = os.path.join(site_dir, "llama_cpp_python.libs")
                    if os.path.exists(gomp_dir):
                        for f in os.listdir(gomp_dir):
                            if f.startswith("libgomp"):
                                try:
                                    ctypes.CDLL(os.path.join(gomp_dir, f), mode=ctypes.RTLD_GLOBAL)
                                except Exception:
                                    pass
                from llama_cpp import Llama

                free_vram = 0
                try:
                    import subprocess
                    out = subprocess.check_output(
                        ["nvidia-smi", "--query-gpu=memory.free", "--format=csv,noheader,nounits"],
                        timeout=2
                    ).decode()
                    free_vram = int(out.strip().split()[0])
                except Exception:
                    pass

                target_gpu_layers = getattr(settings, "XAI_GPU_LAYERS", -1)
                context_size = getattr(settings, "XAI_CONTEXT_SIZE", 1024)

                # Qwen2.5-1.5B Q4_K_M requires ~1500 MiB VRAM for full GPU offload.
                # If free VRAM is below 1500 MiB (e.g. concurrent server process or test suite), defer XAI model
                # to prevent multi-process GPU memory contention and CUDA errors on 4GB VRAM.
                if target_gpu_layers != 0 and free_vram > 0 and free_vram < 1500:
                    print(f"Available VRAM ({free_vram} MiB) < 1500 MiB. Deferring duplicate XAI model to avoid GPU contention.")
                    self.xai_model = None
                else:
                    self.xai_model = Llama(
                        model_path=xai_path,
                        n_gpu_layers=target_gpu_layers,
                        n_ctx=context_size,
                        verbose=False
                    )
                    if target_gpu_layers != 0:
                        print("Loaded Qwen2.5-1.5B XAI model successfully on GPU (CUDA)")
                    else:
                        print("Loaded Qwen2.5-1.5B XAI model on CPU")
            else:
                print(f"XAI model file not found at {xai_path}")
        except Exception as e:
            print(f"Failed to load Qwen2.5 XAI model: {e}")

        # Initialize Surya OCR models (PyTorch)
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
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
        except Exception as e:
            print(f"Failed to load Surya OCR models: {e}")

    def generate_xai_explanation(
        self,
        region: str,
        visual_score: int,
        ai_gen_probability: float,
        scam_keywords: list[str] | None = None
    ) -> str:
        """
        Generate natural, professional Thai explanation for anomalies detected.
        """
        scam_keywords = scam_keywords or []
        if not self.xai_model:
            return self._fallback_xai_explanation(region, visual_score, ai_gen_probability, scam_keywords)

        # 1. Semantic classification based on project 3-level scale
        if visual_score >= 70:
            visual_th = f"ระดับสูง ({visual_score}/100) พบร่องรอยการตัดต่อหรือดัดแปลงภาพอย่างเด่นชัด"
        elif visual_score >= 40:
            visual_th = f"ระดับปานกลาง ({visual_score}/100) พบร่องรอยความผิดปกติหรือการบีบอัดภาพบางจุด"
        else:
            visual_th = f"ระดับต่ำ ({visual_score}/100) โครงสร้างภาพค่อนข้างเป็นธรรมชาติ"

        ai_pct = int(round(ai_gen_probability * 100))
        if ai_gen_probability >= 0.70:
            ai_th = f"โอกาสสูง ({ai_pct}%) สอดคล้องกับภาพสังเคราะห์จาก AI"
        elif ai_gen_probability >= 0.40:
            ai_th = f"โอกาสปานกลาง ({ai_pct}%)"
        else:
            ai_th = f"โอกาสต่ำ ({ai_pct}%) พิกเซลมีความเป็นธรรมชาติ"

        if scam_keywords:
            keywords_th = f"ตรวจพบคำสำคัญน่าสงสัย ได้แก่ {', '.join(scam_keywords)}"
        else:
            keywords_th = "ไม่พบข้อความหรือคำสำคัญที่บ่งชี้การหลอกลวง"

        system_prompt = (
            "คุณเป็น AI วิเคราะห์ภาพตัดต่อและสแกมของ ScamGuard\n"
            "หน้าที่: เขียนบทวิเคราะห์สรุปผลสั้นๆ 1-2 ประโยค เป็นภาษาไทยที่สละสลวย เป็นธรรมชาติ ห้ามใส่หัวข้อ ห้ามคัดลอกคำสั่ง"
        )

        user_content = (
            f"ตำแหน่ง: {region}\n"
            f"ความผิดปกติ: {visual_th}\n"
            f"โอกาส AI: {ai_th}\n"
            f"ข้อความ OCR: {keywords_th}\n"
            "เขียนบทวิเคราะห์:"
        )

        prompt = (
            f"<|im_start|>system\n{system_prompt}<|im_end|>\n"
            f"<|im_start|>user\n"
            f"ตำแหน่ง: กลางภาพ\n"
            f"ความผิดปกติ: ระดับสูง (80/100) พบร่องรอยการตัดต่อตัวเลขอย่างเด่นชัด\n"
            f"โอกาส AI: โอกาสต่ำ (15%) พิกเซลมีความเป็นธรรมชาติ\n"
            f"ข้อความ OCR: ตรวจพบคำสำคัญน่าสงสัย ได้แก่ โอนเงินสำเร็จ\n"
            f"เขียนบทวิเคราะห์:<|im_end|>\n"
            f"<|im_start|>assistant\n"
            f"ตรวจพบความผิดปกติระดับสูงบริเวณกลางภาพ ซึ่งมีร่องรอยการตัดต่อตัวเลขอย่างชัดเจนและพบคำสำคัญน่าสงสัยในภาพ แม้โอกาสสังเคราะห์ด้วย AI จะอยู่ในเกณฑ์ต่ำก็ตาม<|im_end|>\n"
            f"<|im_start|>user\n{user_content}<|im_end|>\n"
            f"<|im_start|>assistant\n"
        )

        try:
            output = self.xai_model(
                prompt,
                max_tokens=180,
                temperature=0.2,
                top_p=0.85,
                stop=["<|im_end|>", "\n\n"]
            )
            text = output["choices"][0]["text"].strip()
            # Clean up potential robotic artifacts
            text = text.replace("คำสำคัญที่พบในภาพไม่พบ", "ไม่พบคำสำคัญที่เกี่ยวข้องกับการหลอกลวง")
            text = text.replace("คำสำคัญที่พบในภาพ: ไม่พบ", "ไม่พบคำสำคัญน่าสงสัยในภาพ")
            text = text.replace("คำสำคัญที่พบในภาพ ไม่พบ", "ไม่พบคำสำคัญน่าสงสัยในภาพ")
            
            # Ensure the sentence is complete and not truncated
            if text.endswith("ที่บ่งชี้"):
                text += "การหลอกลวง"
            elif text.endswith("ที่เกี่ยวข้องกับ"):
                text += "การหลอกลวง"

            if len(text) < 15:
                return self._fallback_xai_explanation(region, visual_score, ai_gen_probability, scam_keywords)
            return text
        except Exception as e:
            print(f"XAI Generation error: {e}")
            return self._fallback_xai_explanation(region, visual_score, ai_gen_probability, scam_keywords)

    def _fallback_xai_explanation(
        self,
        region: str,
        visual_score: int,
        ai_gen_prob: float,
        scam_keywords: list[str] | None = None
    ) -> str:
        scam_keywords = scam_keywords or []
        parts = []

        if visual_score >= 70:
            parts.append(f"AI ตรวจพบความผิดปกติระดับสูง{region} ซึ่งมีร่องรอยการตัดต่อหรือดัดแปลงภาพอย่างชัดเจน")
        elif visual_score >= 40:
            parts.append(f"AI ตรวจพบความผิดปกติระดับปานกลาง{region} ซึ่งอาจเกิดจากการตกแต่งภาพหรือการบีบอัดซ้ำซ้อน")
        else:
            parts.append(f"โครงสร้างพิกเซลของภาพมีความสม่ำเสมอ ตรวจพบความผิดปกติเพียงเล็กน้อย{region}")

        ai_pct = int(round(ai_gen_prob * 100))
        if ai_gen_prob >= 0.70:
            parts.append(f"โดยมีโอกาสสูง ({ai_pct}%) ที่เป็นภาพสังเคราะห์จากปัญญาประดิษฐ์")
        elif ai_gen_prob >= 0.40:
            parts.append(f"โดยมีโอกาสปานกลาง ({ai_pct}%) ที่อาจมีองค์ประกอบจาก AI")

        if scam_keywords:
            parts.append(f"ทั้งนี้ตรวจพบคำสำคัญน่าสงสัยในภาพ ได้แก่ {', '.join(scam_keywords)}")
        else:
            parts.append("และไม่พบข้อความหรือคำสำคัญที่เกี่ยวข้องกับการหลอกลวง")

        return " ".join(parts)

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
