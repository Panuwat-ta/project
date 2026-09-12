# แผนการทดสอบ: โมเดลปัญญาประดิษฐ์และไพป์ไลน์การวิเคราะห์ (AI Model & Inference Pipeline Test Plan)

> Version: 1.0.1 | Date: 2026-09-06 | Status: Baseline

- **System / Component**: ScamGuard AI Inference Pipeline
- **Architecture**: Multi-Layer Analysis Pipeline, Subprocess Worker Isolation, Tiling Inference Engine
- **Models**:
  - **Visual Anomaly**: SegFormer B0 Fine-Tuned (Semantic Segmentation)
  - **Text Extraction**: Surya OCR (รองรับภาษาไทยและภาษาอังกฤษ TH/EN)
  - **Explainable AI**: Qwen2.5-1.5B Instruct (XAI Reasoning & Contextual Summary)
- **Document Version**: 1.0.1
- **Date**: 2026-09-06
- **Status**: Baseline

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
   - การจัดกลุ่มความเสี่ยง 3 ระดับ: Low 0-39 / Medium 40-69 / High 70-100
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
- **Dataset ทดสอบ (Validation / Test Sets) — ความจริง + แผนจัดหา (ไม่แต่งว่ามีแล้ว)**:
  - ความจริงรอบนี้: ยังไม่มี test set มาตรฐานที่ตรึงเวอร์ชัน (GAP เดียวกับ TC-AI-ACC-01/02) ตัวเลข 200+200+200=600 ภาพเป็น **องค์ประกอบเป้าหมาย** ไม่ใช่ชุดพร้อมใช้
  - แผนจัดหา (ตัวเลือกพร้อมข้อเสนอ): A (เสนอ) รวบรวมภาพภายใน+สังเคราะห์เองพร้อมเฉลย ตรึงเป็น dataset v1.0 (id+version+sha256+ที่มา/สิทธิการใช้) ผูก M4; B ใช้ชุดเปิดสาธารณะที่อนุญาตเชิงพาณิชย์ + ภาพภายในบางส่วน
  - เกณฑ์ก่อนนับเป็น exit เต็ม: dataset มี id/version/hash จำนวนจริงครบ และ TC-AI-ACC-01/02 รันซ้ำได้ (repro) มิฉะนั้นใช้ gate ชั่วคราว (§3.2 + master §5.3 ข้อ 7)

### 2.2 ระดับและประเภทการทดสอบ (Test Levels & Types)
1. **Benchmark Metric Verification (เป้าหมายชั่วคราว — interim)**: ตรวจสอบเกณฑ์ชี้วัด mDice >= 85%, mIoU >= 80%, aAcc >= 90% — มีผลบังคับเป็น Exit Criteria เต็มเมื่อมีชุดทดสอบมาตรฐานที่ตรึงเวอร์ชันแล้วเท่านั้น (ปัจจุบัน TC-AI-ACC-01/02 ยังไม่มี test set มาตรฐาน จึงเป็น Partial)
2. **Inference Performance Testing**: วัดความเร็วในการตัด Tiling และการรันโมเดลต่อ 1 ภาพ (เป้าหมาย <= 10s บน GPU)
3. **Edge Case Testing**: ทดสอบภาพขนาดใหญ่พิเศษ (เช่น 4K/8K), ภาพสัดส่วนผิดปกติ (Panorama ยาวมาก), และภาพมืดสนิท/ขาวสนิท
4. **Resilience Testing**: สั่ง Kill Subprocess ของ AI ในระหว่างประมวลผล เพื่อตรวจสอบว่าระบบมี Fallback Error Handler คืนสถานะให้ Client ได้อย่างถูกต้อง

---

## 3. เกณฑ์การตรวจรับ (Entry & Exit Criteria)

### 3.1 เกณฑ์การเริ่มต้นทดสอบ (Entry Criteria)
- ไฟล์ Model Weights (.pt / .onnx) ถูกจัดวางในไดเรกทอรีที่ถูกต้อง และ Checksum ตรงกับข้อมูลในฐานข้อมูล Model Registry
- ไดรเวอร์ GPU และไลบรารี PyTorch สามารถตรวจพบ CUDA Core ปกติ

### 3.2 เกณฑ์การสิ้นสุดการทดสอบ (Exit Criteria)
- mDice บนชุดภาพทดสอบมาตรฐานที่ตรึงเวอร์ชันแล้วต้องมากกว่าหรือเท่ากับ 85% — **เป้าหมายชั่วคราว (interim)**: จนกว่าชุดทดสอบมาตรฐานจะพร้อม (GAP เดียวกับ TC-AI-ACC-01) ข้อนี้ไม่ block การปล่อย แต่ต้องรายงานค่า/แผนปิด GAP ใน execution log
- ความแม่นยำในการคัดกรองภาพ AI-Generated ต้องมากกว่าหรือเท่ากับ 85% — **เป้าหมายชั่วคราว (interim)**: จนกว่าโมเดลจำแนกเฉพาะและชุดทดสอบจะพร้อม (GAP เดียวกับ TC-AI-ACC-02) ข้อนี้ไม่ block การปล่อย
- กรณีทดสอบใน `tests_all/manual_tests/test_cases_ai_model.md` ผ่านทุกรายการ
- คำตอบและคำอธิบายภาษาไทยจาก Qwen2.5 ต้องผ่าน rubric 3 ข้อ (blind scoring โดยผู้ตรวจที่ไม่เห็น heatmap ก่อน): (1) grounding — อ้างตำแหน่ง/หลักฐานตรงกับ heatmap จริง (2) ไม่ hallucinate — ไม่กล่าวอ้างข้อความ/พิกเซลที่ไม่มีในภาพ (3) ภาษาไทยอ่านรู้เรื่อง ไม่ปนภาษาผิดบริบท เกณฑ์ผ่าน: 3/3 ข้อต่อเคสสุ่มตรวจ (seed/model commit/prompt/temp=0 คงที่)

---

## 4. ความเชื่อมโยงไปยังชุดกรณีทดสอบจริง
- **เอกสารกรณีทดสอบละเอียด**: `tests_all/manual_tests/test_cases_ai_model.md`
- **ตารางความสอดคล้องความต้องการ**: `tests_all/rtm.md` (หมวดหมู่ FR-SYS-02, FR-SYS-05 ถึง FR-SYS-09, FR-SYS-11 [wiki baseline → Document FR-XAI-01 AC-1], หมวด NFR-01..09 ของ SRS ตาม Document 05 §3)
