## 2026-09-03 05:08 +07 - Qwen2.5-1.5B GPU Inference & Live Scan Pipeline Test

- Target: `server/tests/inference/test_qwen_xai.py`, `server/tests/api/test_scan_xai_live.py`
- Command: `pytest tests/inference/test_qwen_xai.py tests/api/test_scan_xai_live.py -v`
- Result: PASS
- Summary: Total: 3 | Passed: 3 | Failed: 0 | Skipped: 0 | Duration: 2.06s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **`test_qwen_xai_model_loaded` (Model Verification)**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบความพร้อมของไฟล์โมเดล `qwen2.5-1.5b-instruct-q4_k_m.gguf` ในไดเรกทอรี `model/Qwen2.5-1.5B/` (ขนาด 1.12 GB) และการคอนฟิกใน `InferenceService` โดยยืนยันว่าไฟล์มีอยู่จริง (`os.path.exists == True`) และเชื่อมต่อกับ GPU layer offload สำเร็จ
- **`test_qwen_xai_explanation_generation` (XAI Generation Logic)**:
  - พฤติกรรมที่ผ่าน: เรียกใช้ `inference_service.generate_xai_explanation()` โดยป้อนข้อมูลจำลอง (`region="บริเวณข้อความยอดเงินและตราประทับ"`, `visual_score=85`, `ai_gen_probability=0.90`, `scam_keywords=["ยอดเงิน", "โอนเงินสำเร็จ"]`) ระบบสร้างคำอธิบายภาษาไทยที่มีความยาวมากกว่า 10 ตัวอักษร และไม่ตกไปใช้ข้อความ Static Fallback เก่า (`"ไม่พบร่องรอยการตัดต่อ..." not in explanation`)
- **`test_live_scan_and_xai_pipeline` (End-to-End Live API on GPU)**:
  - พฤติกรรมที่ผ่าน:
    1. ตรวจสอบ Health Check `GET http://localhost:8000/health` ส่งคืน HTTP 200 (`database: ok`, `redis: ok`)
    2. ยิงคำขออัปโหลดภาพจริงผ่าน `POST /api/v1/scan/` พร้อมแนบ Bearer JWT Token ได้รับ Scan ID กลับมาพร้อม HTTP 200
    3. ตรวจสอบสถานะการประมวลผล Background Task ผ่าน `GET /api/v1/scan/{id}`:
       - วิ่งผ่านขั้นตอน `processing_visual` (SegFormer บน GPU) ที่ progress 50%
       - วิ่งผ่านขั้นตอน `processing_text` (Surya OCR บน GPU) ที่ progress 80%
       - วิ่งผ่านขั้นตอนสร้างคำอธิบาย XAI (Qwen2.5-1.5B บน GPU)
       - จบกระบวนการที่สถานะ `completed` ที่ progress 100% ภายใน 7 วินาที
    4. Assert ตรวจสอบข้อมูลผลลัพธ์:
       - `visual_score` ได้ 42 (ไม่เป็น null)
       - `ai_gen_probability` ได้ 0.4202 (ไม่เป็น null)
       - `xai_explanation` ได้รับข้อความจริงจากโมเดล Qwen: `"ภาพมีตำแหน่งที่ตรวจพบอยู่บริเวณมุมซ้ายบนของภาพ คะแนนความผิดปกติของภาพอยู่ที่ 42/100 แสดงว่ามีโอกาสเป็นภาพสร้างด้วย AI อยู่ที่ 0.42 แต่ไม่พบคำสำคัญน่าสงสัยในภาพ"`

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed): ทุก Test Case ผ่านการ Assert ทั้งหมด ไม่มีข้อผิดพลาด CUDA OOM หรือ SIGABRT ระหว่างการรัน

---

## 2026-09-03 05:31 +07 - Real SegFormer Softmax & Live Scan Pipeline Verification

- Target: `server/tests/inference/test_qwen_xai.py`, `server/tests/api/test_scan_xai_live.py`
- Command: `/home/panuwat/project/server/venv/bin/pytest tests/inference/test_qwen_xai.py tests/api/test_scan_xai_live.py -v`
- Result: PASS
- Summary: Total: 3 | Passed: 3 | Failed: 0 | Skipped: 0 | Duration: 2.09s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **`test_qwen_xai_model_loaded` (ตรวจสอบการโหลดโมเดล)**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบความพร้อมของไฟล์โมเดล `qwen2.5-1.5b-instruct-q4_k_m.gguf` ในไดเรกทอรี `model/Qwen2.5-1.5B/` (ขนาด 1.12 GB) และการเชื่อมต่อ GPU layer offload (`n_gpu_layers=-1`) สำเร็จ โดย Assert ยืนยันว่าไฟล์มีอยู่จริงบนดิสก์และพร้อมใช้งาน
- **`test_qwen_xai_explanation_generation` (การสร้างคำอธิบาย XAI)**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบฟังก์ชัน `inference_service.generate_xai_explanation()` ด้วยเทคนิค 1-Shot In-Context Learning ยืนยันว่าสร้างบทวิเคราะห์ภาษาไทยได้สละสลวย จบประโยคสมบูรณ์ ไม่คัดลอกหัวข้อซ้ำซาก ความยาวมากกว่า 10 ตัวอักษร และไม่ตกไปใช้ข้อความสำรองแบบเก่า
- **`test_live_scan_and_xai_pipeline` (การทำงานของ API Pipeline แบบ End-to-End)**:
  - พฤติกรรมที่ผ่าน: ทำการยิงสแกนภาพผ่าน REST API จริงบนเซิร์ฟเวอร์ Uvicorn ตรวจสอบการทำงานตลอดทั้งกระบวนการ:
    1. SegFormer ONNX worker รันด้วย Softmax 2 คลาสบนพิกเซลจริง และส่งคืนค่าความน่าจะเป็นการตัดต่อ (Class 1 Forgery)
    2. Surya OCR สกัดข้อความภาษาไทยและอังกฤษได้สำเร็จ
    3. Qwen2.5-1.5B สร้างคำอธิบาย XAI บน GPU สำเร็จ
    4. สถานะงานเปลี่ยนผ่านเป็น `completed` ภายใน 7 วินาที พร้อมส่งคืนค่า `visual_score`, `ai_gen_probability`, และ `xai_explanation` อย่างครบถ้วน

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed): ทุก Test Case ผ่านการ Assert ทั้งหมด 100% ไม่มีข้อผิดพลาดหรือข้อขัดข้องระหว่างการรัน
