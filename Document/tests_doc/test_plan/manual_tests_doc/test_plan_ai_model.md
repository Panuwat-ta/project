# แผนการทดสอบ: โมเดลปัญญาประดิษฐ์และไพป์ไลน์การวิเคราะห์ (AI Model & Inference Pipeline Test Plan)

- **System / Component**: ScamGuard AI Inference Pipeline
- **Architecture**: Multi-Layer Analysis Pipeline, Subprocess Worker Isolation, Tiling Inference Engine
- **Models**:
  - **Visual Anomaly**: SegFormer B0 Fine-Tuned (Semantic Segmentation)
  - **Text Extraction**: Surya OCR (รองรับภาษาไทยและภาษาอังกฤษ TH/EN)
  - **Explainable AI**: Qwen2.5-1.5B Instruct (XAI Reasoning & Contextual Summary)
- **Document Version**: 1.0.0
- **Status**: Approved

---

## 1. ขอบเขตการทดสอบ (Scope of Testing)

### 1.1 สิ่งที่อยู่ในขอบเขต (In-Scope)
1. **SegFormer Tiling Inference Engine**:
   - การตัดภาพเป็น Tile ขนาดคงที่ 512x512 พิกเซล พร้อมขอบเหลื่อมซ้อน (Overlap) ขนาด 64 พิกเซล
   - การรวมภาพคืนสู่ความละเอียดเดิม (Stitching / Reconstruction) ด้วยวิธีถัวเฉลี่ยค่าน้ำหนัก (Weight Averaging) บริเวณรอยต่อเพื่อป้องกันรอยต่อไม่เรียบ (Seam Artifacts)
   - ความแม่นยำในการสร้าง Binary / Probability Mask
2. **Surya OCR Text Extraction**:
   - ความถูกต้องในการสกัดตัวอักษรภาษาไทยและภาษาอังกฤษ
   - การประเมินคำศัพท์ต้องสงสัยในบริบทการหลอกลวง (เช่น "โอนด่วน", "ยกเลิกออเดอร์", "บัญชีม้า")
3. **Qwen2.5-1.5B XAI Reasoning Engine**:
   - การสร้างคำอธิบายเชิงเหตุผลภาษาไทยที่สอดคล้องกับตำแหน่งร่องรอยการตัดต่อ
   - การควบคุมไม่ให้โมเดลเกิดอาการ Hallucination
4. **Hybrid Risk Calculator**:
   - การคำนวณตามสูตรทางการ: Worst-Case Dominance `S_base = max(Visual, Textual, Source)` ร่วมกับ Multi-Factor Compounding (+5 คะแนนต่อมิติรองที่ >= 40) และ Visual Override (หาก Visual >= 80 ปรับเป็น High ทันที)
   - การจัดกลุ่มความเสี่ยง 3 ระดับอย่างเข้มงวด:
     - ต่ำ (Low): 0-39
     - ปานกลาง (Medium): 40-69
     - สูง (High): 70-100
     - ต้องไม่ปรากฏคำว่า "Safe" หรือการจำแนก 4 ระดับแบบเดิม
5. **Full-Resolution Heatmap Generation**:
   - การแปลง Probability Map เป็นภาพสี (Color Map เช่น JET/Turbo) และซ้อนทับภาพต้นฉบับ
6. **Subprocess Isolation & Fault Tolerance**:
   - การแยกโปรเซสของ AI เพื่อป้องกันไม่ให้ข้อผิดพลาด OOM (CUDA Out Of Memory) ส่งผลกระทบต่อ Web Server หลัก

### 1.2 สิ่งที่อยู่นอกขอบเขต (Out-of-Scope)
1. การเตรียม Dataset หรือขั้นตอน Data Annotation
2. การคำนวณค่า Hyperparameter Tuning ในระหว่างการฝึกโมเดล (เน้นการทดสอบโมเดลที่ฝึกเสร็จแล้ว)

---

## 2. กลยุทธ์และวิธีการทดสอบ (Testing Strategy)

### 2.1 สภาพแวดล้อมการทดสอบ (Test Environment)
- **Hardware**: NVIDIA RTX GPU (VRAM >= 8GB) สำหรับทดสอบ GPU Acceleration และ CPU Server สำหรับทดสอบ CPU Fallback Mode
- **Software Stack**: PyTorch 2.x, Transformers, ONNX Runtime, OpenCV, NumPy
- **Dataset ทดสอบ (Validation / Test Sets)**:
  - ชุดภาพตัดต่อสลิปและใบเสร็จ (Manipulated Slips/Receipts) จำนวน 200 ภาพ
  - ชุดภาพสังเคราะห์จาก AI (Midjourney, Stable Diffusion) จำนวน 200 ภาพ
  - ชุดภาพปกติที่ไม่ผ่านการดัดแปลง (Authentic Pristine Images) จำนวน 200 ภาพ

### 2.2 ระดับและประเภทการทดสอบ (Test Levels & Types)
1. **Benchmark Metric Verification**: ตรวจสอบเกณฑ์ชี้วัด mDice >= 85%, mIoU >= 80%, aAcc >= 90%
2. **Inference Performance Testing**: วัดความเร็วในการตัด Tiling และการรันโมเดลต่อ 1 ภาพ (เป้าหมาย <= 10s บน GPU)
3. **Edge Case Testing**: ทดสอบภาพขนาดใหญ่พิเศษ (เช่น 4K/8K), ภาพสัดส่วนผิดปกติ (Panorama ยาวมาก), และภาพมืดสนิท/ขาวสนิท
4. **Resilience Testing**: สั่ง Kill Subprocess ของ AI ในระหว่างประมวลผล เพื่อตรวจสอบว่าระบบมี Fallback Error Handler คืนสถานะให้ Client ได้อย่างถูกต้อง

---

## 3. เกณฑ์การตรวจรับ (Entry & Exit Criteria)

### 3.1 เกณฑ์การเริ่มต้นทดสอบ (Entry Criteria)
- ไฟล์ Model Weights (.pt / .onnx) ถูกจัดวางในไดเรกทอรีที่ถูกต้อง และ Checksum ตรงกับข้อมูลในฐานข้อมูล Model Registry
- ไดรเวอร์ GPU และไลบรารี PyTorch สามารถตรวจพบ CUDA Core ปกติ

### 3.2 เกณฑ์การสิ้นสุดการทดสอบ (Exit Criteria)
- mDice บนชุดภาพทดสอบต้องมากกว่าหรือเท่ากับ 85% (NFR-AI-01)
- ความแม่นยำในการคัดกรองภาพ AI-Generated ต้องมากกว่าหรือเท่ากับ 85% (NFR-AI-02)
- กรณีทดสอบใน `tests_all/manual_tests/test_cases_ai_model.md` ผ่านทุกรายการ
- คำตอบและคำอธิบายภาษาไทยจาก Qwen2.5 ต้องมีความสมเหตุสมผลและตรงกับตำแหน่งของ Heatmap

---

## 4. ความเชื่อมโยงไปยังชุดกรณีทดสอบจริง
- **เอกสารกรณีทดสอบละเอียด**: `tests_all/manual_tests/test_cases_ai_model.md`
- **ตารางความสอดคล้องความต้องการ**: `tests_all/rtm.md` (หมวดหมู่ FR-SYS-02, FR-SYS-05 ถึง FR-SYS-10, NFR-AI-01, NFR-AI-02)
