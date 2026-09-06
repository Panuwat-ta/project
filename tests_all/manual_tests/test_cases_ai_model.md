# ชุดกรณีทดสอบ: โมเดลปัญญาประดิษฐ์และไปป์ไลน์การวิเคราะห์ภาพ (AI Model & Inference Pipeline)

- **Models**:
  - **Visual Tampering Detection**: SegFormer (Semantic Segmentation, ONNX Runtime)
  - **Optical Character Recognition**: Surya OCR v0.5.0 (PyTorch Native, TH/EN Support)
  - **Explainable AI (XAI)**: Qwen2.5-1.5B (Language & Reasoning Model)
  - **Source Verification**: คะแนนอ้างอิงคงที่จากค่าตั้งต้นของระบบ
- **Inference Strategy**: Overlapping Tiling (Patch 512x512 with 64px Overlap), Weight Averaging
- **Workload Isolation**: Dedicated Subprocess Isolation (`onnx_worker.py`)
- **Version**: 1.0.0
- **Status**: Baseline

---

## 1. หมวดหมู่การอนุมานแบบตัดส่วนภาพทับซ้อน (Overlapping Tiling Inference)

### TC-AI-TILE-01: การตัดภาพความละเอียดสูงเป็น Patch 512x512 พร้อม Overlap 64px
- **Module / Feature**: AI Inference / Overlapping Tiling
- **Requirement ID**: FR-SYS-05
- **Test Type**: Functional / Algorithm
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. เตรียมภาพความละเอียดสูง (Full-Resolution เช่น 1920x1080 พิกเซล)
  2. โหลดโมเดล SegFormer ONNX เข้าสู่ Subprocess Worker
- **Test Data**: ภาพขนาด 1920x1080 พิกเซล มีการตัดต่อข้อความในสลิป
- **Test Steps**:
  1. ป้อนภาพเข้าสู่ฟังก์ชัน Tiling ใน `onnx_worker.py`
  2. ตรวจสอบจำนวนและมิติของ Patch ที่ถูกสร้างขึ้น
- **Expected Results**:
  1. ภาพขนาด 1920x1080 ถูกตัดเป็นชิ้นส่วน (Patches) ขนาด 512x512 พิกเซล
  2. แต่ละชิ้นส่วนข้างเคียงมีขอบเขตทับซ้อนกันขนาด 64 พิกเซลทั้งแกน X และแกน Y
  3. ไม่มีส่วนใดของภาพหลุดหาย หรือถูกย่อขนาด (Resize) จนเสียรายละเอียดพิกเซล
- **Automation Mapping**: Manual Verification

---

### TC-AI-TILE-02: การเฉลี่ยค่าน้ำหนักความน่าจะเป็นในบริเวณรอยต่อ (Weight Averaging on Overlap)
- **Module / Feature**: AI Inference / Patch Reconstruction
- **Requirement ID**: FR-SYS-05, FR-SYS-08
- **Test Type**: Mathematical / Accuracy
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีผลลัพธ์ Probability Maps จากทุก Patch ที่รันผ่าน SegFormer
- **Test Data**: ผลลัพธ์ Tensor ของภาพ 1920x1080
- **Test Steps**:
  1. รวม Probability Maps แต่ละ Patch คืนสู่ Canvas ขนาดภาพจริง
  2. คำนวณค่าเฉลี่ยในพื้นที่ทับซ้อน (Weight Averaging Mask)
- **Expected Results**:
  1. แผนที่ความร้อนความละเอียดเต็ม (Full-Res Heatmap) เรียบเนียนต่อเนื่อง
  2. ไม่ปรากฏรอยตะเข็บรูปสี่เหลี่ยมตามขอบของ Patch (Seamless Patch Merging)
  3. บริเวณที่มีการตัดต่อตรงรอยต่อพิกเซลยังคงมีค่าความน่าจะเป็นสูงชัดเจน
- **Automation Mapping**: Manual Verification

---

## 2. หมวดหมู่การสกัดข้อความและการตรวจจับความผิดปกติ (Surya OCR & NLP)

### TC-AI-OCR-01: การสกัดข้อความภาษาไทยและภาษาอังกฤษ (Thai Plus English OCR)
- **Module / Feature**: OCR Engine / Surya OCR PyTorch
- **Requirement ID**: FR-SYS-02
- **Test Type**: Functional / Accuracy
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. Surya OCR โมเดลพร้อมทำงานในหน่วยความจำ
- **Test Data**: ภาพสลิปที่มีข้อความภาษาไทย "โอนเงินสำเร็จ" และภาษาอังกฤษ "Transaction Successful"
- **Test Steps**:
  1. ส่งภาพเข้าสู่ฟังก์ชัน OCR ในไปป์ไลน์
- **Expected Results**:
  1. สกัดข้อความภาษาไทยและภาษาอังกฤษได้ถูกต้องแม่นยำ (> 90% Character Accuracy)
  2. ข้อความที่สกัดได้ถูกส่งต่อให้โมดูลค้นหาคีย์เวิร์ดหลอกลวงเพื่อคำนวณคะแนนข้อความ
  3. กรณีภาพไม่มีข้อความ ระบบบันทึกว่าไม่พบข้อความและให้คะแนนข้อความเท่ากับ 0
- **Automation Mapping**: `server/tests/inference/test_surya.py`

---

### TC-AI-OCR-02: การตรวจจับคีย์เวิร์ดหลอกลวงจากข้อความที่สกัดได้ (Textual Anomaly Score)
- **Module / Feature**: OCR Analysis / Keyword Matching
- **Requirement ID**: FR-SYS-03
- **Test Type**: Functional / Algorithm
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. รายการคีย์เวิร์ดและรูปแบบข้อความเฝ้าระวัง (Scam Dictionary) โหลดในระบบ
- **Test Data**: ภาพสลิปปลอมที่มีข้อความต้องสงสัย เช่น ชื่อธนาคารสะกดผิด หรือข้อความเร่งรัดการโอนเงิน
- **Test Steps**:
  1. ประมวลผลข้อความผ่านโมดูลประเมินความเสี่ยงด้านข้อความ
- **Expected Results**:
  1. ระบบตรวจพบคำต้องสงสัยจากพจนานุกรมเฝ้าระวังในข้อความที่สกัดได้
  2. ให้คะแนน Textual Score ในระดับสูง (> 70 คะแนน) เมื่อพบคำต้องสงสัยหลายคำ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

## 3. หมวดหมู่การอธิบายผลลัพธ์เชิงเหตุผล (Explainable AI - Qwen2.5)

### TC-AI-XAI-01: การสร้างข้อความสรุปและเหตุผลประกอบการตรวจจับ (XAI Reasoning)
- **Module / Feature**: Explainable AI / Qwen2.5-1.5B
- **Requirement ID**: FR-SYS-11
- **Test Type**: Integration / NLP
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. โมเดล Qwen2.5-1.5B ถูกโหลดและตั้งค่า Prompt Template ภาษาไทย
  2. มีผลลัพธ์จาก SegFormer (พิกัด Heatmap) และ Surya OCR (ข้อความที่พบ)
- **Test Data**: ผลสแกนภาพใบเสร็จปลอมที่มีรอยตัดต่อตัวเลขยอดเงิน
- **Test Steps**:
  1. ส่ง Context ข้อมูลพิกเซลและข้อความเข้าสู่โมเดล Qwen
  2. สร้างข้อความสรุปผล
- **Expected Results**:
  1. สร้างข้อความสรุปภาษาไทยที่กระชับและเข้าใจง่าย (1-2 ประโยค)
  2. ชี้แจงเหตุผลชัดเจน เช่น "ตรวจพบความผิดปกติของพิกเซลบริเวณยอดเงิน และมีลักษณะการวางทับข้อความเดิม"
  3. ไม่มีการเพ้อเจ้อ (Hallucination) ข้อมูลที่อยู่นอกเหนือจากผลการตรวจจับจริง
- **Automation Mapping**: `server/tests/inference/test_qwen_xai.py`

---

## 4. หมวดหมู่สูตรการคำนวณคะแนนความเสี่ยง (Risk Scoring Formula)

### TC-AI-RISK-01: การคำนวณคะแนนความเสี่ยงแบบผสมผสาน (Hybrid Worst-Case Scoring Formula)
- **Module / Feature**: Risk Calculator / Scoring Engine
- **Requirement ID**: FR-SYS-07
- **Test Type**: Functional
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ระบบคำนวณความเสี่ยงเปิดใช้งานสูตร Hybrid Worst-Case
- **Test Data**:
  - Textual Score: 30
  - Source Verification Score: 20
  - Visual Anomaly Score: 85 (ตรวจพบรอยตัดต่อชัดเจน)
- **Test Steps**:
  1. ป้อนคะแนนทั้ง 3 ด้านเข้าสู่ฟังก์ชันคำนวณคะแนนความเสี่ยง
- **Expected Results**:
  1. คะแนนฐานเท่ากับค่าสูงสุดของ 3 ด้าน คือ 85
  2. ไม่มีการบวกเพิ่มเพราะไม่มีมิติด้านรองที่มีค่าไม่ต่ำกว่า 40
  3. ได้รับคะแนนรวม 85 และระดับความเสี่ยงเป็น `high` ตัวพิมพ์เล็ก
- **Automation Mapping**: `server/tests/utils/test_risk_calculator.py`

---

### TC-AI-RISK-02: การจำแนกระดับความเสี่ยง 3 ระดับอย่างถูกต้อง (Risk Grading)
- **Module / Feature**: Risk Calculator / Grading
- **Requirement ID**: FR-REPORT-01, FR-SYS-07
- **Test Type**: Boundary / Functional
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีฟังก์ชันจัดระดับคะแนนความเสี่ยง
- **Test Data**:
  - เคสที่ 1: คะแนน 0, 20, 39
  - เคสที่ 2: คะแนน 40, 55, 69
  - เคสที่ 3: คะแนน 70, 85, 100
- **Test Steps**:
  1. ป้อนคะแนนขอบเขตเข้าสู่ฟังก์ชันจัดระดับ
- **Expected Results**:
  1. คะแนนช่วง 0 – 39: จัดอยู่ในระดับ `low` (ความเสี่ยงต่ำ)
  2. คะแนนช่วง 40 – 69: จัดอยู่ในระดับ `medium` (ความเสี่ยงปานกลาง)
  3. คะแนนช่วง 70 – 100: จัดอยู่ในระดับ `high` (ความเสี่ยงสูง)
  4. ไม่พบคำว่าระดับ Safe ในผลลัพธ์ของระบบ
- **Automation Mapping**: `server/tests/utils/test_risk_calculator.py`

---

### TC-AI-RISK-03: การบวกคะแนนเพิ่มเมื่อพบความเสี่ยงหลายมิติพร้อมกัน (Multi-Factor Bonus)
- **Module / Feature**: Risk Calculator / Multi-Factor Compounding
- **Requirement ID**: FR-SYS-07
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. ระบบคำนวณความเสี่ยงเปิดใช้งานสูตร Hybrid Worst-Case
- **Test Data**:
  - Textual Score: 50
  - Source Verification Score: 60
  - Visual Anomaly Score: 80
- **Test Steps**:
  1. ป้อนคะแนนทั้ง 3 ด้านเข้าสู่ฟังก์ชันคำนวณคะแนนความเสี่ยง
- **Expected Results**:
  1. คะแนนฐานเท่ากับค่าสูงสุดของ 3 ด้าน คือ 80
  2. มิติรองที่มีค่าไม่ต่ำกว่า 40 มี 2 มิติ จึงบวกเพิ่มมิติละ 5 คะแนน รวมเป็น 90
  3. ได้รับระดับความเสี่ยงเป็น `high` ตัวพิมพ์เล็ก
- **Automation Mapping**: `server/tests/utils/test_risk_calculator.py`

---

## 5. หมวดหมู่การแยกโพรเซสประมวลผล (Subprocess Isolation & Memory Safety)

### TC-AI-ISO-01: การตัดวงจรเมื่อ Subprocess เกิดข้อผิดพลาดหรือ Timeout (Fault Tolerance)
- **Module / Feature**: AI Infrastructure / Subprocess Worker
- **Requirement ID**: NFR-PERF-03
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. สคริปต์ `onnx_worker.py` ถูกรันแยกโพรเซสผ่าน `subprocess.Popen` โดยส่งภาพแบบ base64 ทาง stdin
- **Test Data**: ส่งคำสั่งประมวลผลที่จำลองสภาวะแฮงก์ (Infinite Loop หรือ OOM)
- **Test Steps**:
  1. ยิงภาพที่ทำให้ Subprocess ทำงานผิดพลาดหรือหยุดชะงัก
- **Expected Results**:
  1. Main FastAPI Process ไม่แครชตาม และยังคงให้บริการ Endpoint อื่นๆ ได้ตามปกติ
  2. คำขอถัดไปสามารถสร้าง Subprocess ใหม่เพื่อประมวลผลได้ตามปกติ
  3. Client ได้รับข้อความแจ้งเตือนข้อผิดพลาดที่เหมาะสม ไม่เกิด Connection Hang
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

## 6. หมวดหมู่กรณีทดสอบสภาวะขอบเขตภาพ (Edge Case Images)

### TC-AI-EDGE-01: การประมวลผลภาพความละเอียดสูงมากระดับ 4K / 8K
- **Module / Feature**: Tiling Inference / Ultra-HD Images
- **Requirement ID**: FR-SYS-05
- **Test Type**: Boundary / Stress
- **Priority**: P2 (Medium)
- **Pre-conditions**:
  1. เตรียมภาพความละเอียด 3840x2160 (4K) และ 7680x4320 (8K) ขนาดไฟล์ไม่เกิน 20MB (Server) / Mobile 10MB + decode ไม่เกิน 100M px
- **Test Data**: ภาพ 4K Ultra-HD
- **Test Steps**:
  1. ส่งภาพเข้าสู่ไปป์ไลน์ Tiling Inference
- **Expected Results**:
  1. ไปป์ไลน์คำนวณจำนวน Patch เพิ่มขึ้นอย่างเป็นสัดส่วน
  2. ไม่เกิดข้อผิดพลาด Out of Memory (OOM) ในระบบ
  3. สามารถประกอบ Full-Resolution Heatmap ได้สำเร็จ
- **Automation Mapping**: Manual Verification

---

### TC-AI-EDGE-02: การประมวลผลภาพสีเดียวล้วนหรือภาพว่างเปล่า (Monochrome / Blank Canvas)
- **Module / Feature**: AI Inference / Robustness
- **Requirement ID**: FR-SYS-05
- **Test Type**: Negative / Robustness
- **Priority**: P2 (Medium)
- **Pre-conditions**:
  1. เตรียมภาพสีขาวล้วน (RGB 255, 255, 255) และภาพสีดำล้วน (RGB 0, 0, 0)
- **Test Data**: `blank_white.png` (512x512)
- **Test Steps**:
  1. ส่งภาพเข้าสู่กระบวนการสแกน
- **Expected Results**:
  1. ระบบไม่เกิด ZeroDivisionError หรือข้อผิดพลาดทางคณิตศาสตร์
  2. ค่าคะแนนความเสี่ยงด้าน Visual Anomaly อยู่ในเกณฑ์ต่ำ (< 10)
  3. ระบบสามารถส่งคืนผลลัพธ์ได้อย่างถูกต้องโดยไม่แครช
- **Automation Mapping**: Manual Verification

---

## 7. หมวดหมู่ภาพขอบเขตเพิ่มเติมและความแม่นยำ AI (Additional Edges Plus Accuracy GAP)

### TC-AI-EDGE-03: การประมวลผลภาพแนวยาวพาโนรามา (Panorama Image)
- **Module / Feature**: Tiling Inference / Panorama Images
- **Requirement ID**: FR-SYS-05
- **Test Type**: Boundary
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมภาพแนวยาว เช่น 4000x800 พิกเซล ขนาดไฟล์ไม่เกิน 20MB
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพพาโนรามาแชตหรือสลิปแนวยาว
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ส่งภาพเข้าสู่ไปป์ไลน์ Tiling Inference
  2. ตรวจสอบการตัด Patch และการประกอบ Heatmap
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ภาพถูกตัดเป็น Patch 512x512 พร้อม Overlap 64px ครบทุกส่วน
  2. Heatmap ที่ประกอบกลับมีขนาดเท่าภาพต้นฉบับ
  3. ไม่เกิดข้อผิดพลาดหน่วยความจำ
- **Automation Mapping**: Manual Verification

---

### TC-AI-EDGE-04: การประมวลผลภาพที่มี Noise สูง (Noisy Image)
- **Module / Feature**: AI Inference / Robustness
- **Requirement ID**: FR-SYS-05
- **Test Type**: Negative
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมภาพที่ถ่ายในที่แสงน้อยมี Noise ทั่วทั้งภาพ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพสลิปที่มี Noise เกรนสูง
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ส่งภาพเข้าสู่กระบวนการสแกน
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ระบบประมวลผลจบโดยไม่แครช
  2. คะแนน Visual Anomaly ไม่พุ่งสูงผิดปกติจาก Noise เพียงอย่างเดียว
  3. คำอธิบาย XAI สรุปผลตามคะแนนที่ตรวจวัดได้โดยไม่หยุดชะงัก
- **Automation Mapping**: Manual Verification

---

### TC-AI-HEAT-01: การประกอบ Heatmap ความละเอียดเต็มจาก Probability Map (Heatmap Reconstruction)
- **Module / Feature**: AI Inference / Heatmap Reconstruction
- **Requirement ID**: FR-SYS-08
- **Test Type**: Functional
- **Priority**: P0 (Blocker)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มี Probability Map จากทุก Patch ของภาพทดสอบ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Probability Map ของภาพ 1920x1080
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เฉลี่ยค่าน้ำหนักบริเวณทับซ้อนและประกอบกลับขนาดเต็ม
  2. ตรวจสอบความต่อเนื่องของรอยต่อและความละเอียด
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ได้ Heatmap ขนาดเท่าภาพต้นฉบับแบบเต็มพิกเซล
  2. ไม่พบรอยตะเข็บตามขอบ Patch
  3. บริเวณตัดต่อยังคงค่าความน่าจะเป็นสูงชัดเจน
- **Automation Mapping**: `server/tests/inference/test_heatmap.py`

---

### TC-AI-ACC-01: ความแม่นยำการตรวจจับภาพตัดต่อระดับ 85 เปอร์เซ็นต์ (GAP ยังไม่มีชุดทดสอบมาตรฐาน)
- **Module / Feature**: AI Accuracy / Tamper Detection Benchmark
- **Requirement ID**: NFR-AI-01
- **Test Type**: Performance
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมชุดทดสอบมาตรฐานพร้อมเฉลย
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ชุดภาพตัดต่อและภาพปกติพร้อมป้ายกำกับ
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. รันโมเดลกับชุดทดสอบทั้งหมด
  2. คำนวณค่า mDice
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. สถานะนี้เป็น GAP เนื่องจากยังไม่มีชุดทดสอบมาตรฐานและสคริปต์วัด mDice ในระบบปัจจุบัน
  2. เกณฑ์ยอมรับเมื่อมีชุดทดสอบคือ mDice ไม่ต่ำกว่า 85 เปอร์เซ็นต์
  3. ผลต้องจำแนกระดับความเสี่ยงได้เพียง Low, Medium, High
- **Automation Mapping**: Manual Verification

---

### TC-AI-ACC-02: ความแม่นยำการจำแนกภาพ AI-Generated ระดับ 85 เปอร์เซ็นต์ (GAP ยังไม่มีโมเดลจำแนกเฉพาะ)
- **Module / Feature**: AI Accuracy / AI-Generated Classification
- **Requirement ID**: NFR-AI-02
- **Test Type**: Performance
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมชุดภาพ AI-Generated และภาพถ่ายจริงพร้อมเฉลย
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ชุดภาพทดสอบสองกลุ่มพร้อมป้ายกำกับ
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. รันการจำแนกกับชุดทดสอบทั้งหมด
  2. คำนวณความแม่นยำ
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. สถานะนี้เป็น GAP เนื่องจากยังไม่มีโมเดลจำแนก AI-Generated เฉพาะทางในระบบปัจจุบัน
  2. เกณฑ์ยอมรับเมื่อมีโมเดลคือความแม่นยำไม่ต่ำกว่า 85 เปอร์เซ็นต์
  3. ค่า `ai_gen_probability` ใน Response ต้องสอดคล้องกับผลการจำแนก
- **Automation Mapping**: Manual Verification

---

## 8. หมวดหมู่ขอบเขตรอยต่อคะแนนและรูปแบบไฟล์ภาพเพิ่มเติม

### TC-AI-RISK-04: การเปลี่ยนระดับที่รอยต่อ 39/40 และ 69/70 พร้อมโบนัสข้ามเกณฑ์
- **Module / Feature**: Risk Calculator / Boundary Grading
- **Requirement ID**: FR-SYS-07
- **Test Type**: Functional
- **Priority**: P0 (Blocker)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มีฟังก์ชันคำนวณคะแนนแบบ Hybrid Worst-Case พร้อมโบนัสมิติรอง
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ชุดที่ 1: Text 10, Visual 39, Source 20 คาดหวัง low
  - ชุดที่ 2: Text 10, Visual 40, Source 20 คาดหวัง medium
  - ชุดที่ 3: Text 10, Visual 69, Source 20 คาดหวัง medium
  - ชุดที่ 4: Text 10, Visual 70, Source 20 คาดหวัง high
  - ชุดที่ 5: Text 45, Visual 65, Source 10 คาดหวัง 70 high จากโบนัส
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ป้อนคะแนนทั้ง 5 ชุดเข้าสู่ฟังก์ชันคำนวณทีละชุด
  2. บันทึกคะแนนรวม ระดับ และสถานะหลายมิติที่ได้
  3. เปรียบเทียบคู่รอยต่อ 39 กับ 40 และ 69 กับ 70
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. คะแนน 39 ได้ระดับ `low` ส่วนคะแนน 40 ได้ระดับ `medium`
  2. คะแนน 69 ได้ระดับ `medium` ส่วนคะแนน 70 ได้ระดับ `high`
  3. ชุดที่ 5 ได้ฐาน 65 บวกโบนัส 5 เป็น 70 และได้ระดับ `high`
  4. ระดับที่ได้มีเพียง `low`, `medium`, `high` ตัวพิมพ์เล็กเท่านั้น
- **Automation Mapping**: `server/tests/utils/test_risk_calculator.py`

---

### TC-AI-EDGE-05: การรองรับภาพ CMYK ภาพหมุน EXIF ภาพ WebP โปร่งใส และนามสกุลปลอม
- **Module / Feature**: AI Inference / Image Format Robustness
- **Requirement ID**: FR-SYS-05
- **Test Type**: Functional
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมภาพ 4 แบบขนาดไม่เกิน 20MB และจำนวนพิกเซล decode ไม่เกิน 100M px
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพ JPEG โหมด CMYK ขนาด 1024x768
  - ภาพ JPEG มีค่า EXIF Orientation หมุน 90 องศา
  - ภาพ WebP แบบโปร่งใสพื้นหลัง
  - ไฟล์ข้อความเปลี่ยนนามสกุลเป็น .jpg
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ส่งภาพ CMYK เข้าสู่กระบวนการสแกนแล้วตรวจผล
  2. ส่งภาพหมุน EXIF เข้าสู่กระบวนการสแกนแล้วตรวจผล
  3. ส่งภาพ WebP โปร่งใสเข้าสู่กระบวนการสแกนแล้วตรวจผล
  4. ส่งไฟล์นามสกุลปลอมเข้าสู่กระบวนการตรวจสอบแล้วตรวจผล
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ภาพ CMYK ถูกแปลงเป็น RGB และประมวลผลจบโดยไม่แครช ได้คะแนน 0-100
  2. ภาพหมุน EXIF ประมวลผลจบโดยไม่แครช มีการเก็บค่า EXIF ไว้ในผลการสแกน
  3. ภาพ WebP โปร่งใสประมวลผลจบโดยไม่แครช ได้คะแนนและ heatmap ตามปกติ
  4. ไฟล์นามสกุลปลอมถูกปฏิเสธว่าเป็นภาพไม่ถูกต้องโดยไม่แครชทั้งระบบ
- **Automation Mapping**: Manual Verification

---

### TC-AI-OCR-03: การสกัดข้อความจากภาพถ่ายเอียงและภาพเบลอ
- **Module / Feature**: OCR Engine / Degraded Images
- **Requirement ID**: FR-SYS-02
- **Test Type**: Functional
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมภาพสลิปที่มีข้อความไทยและอังกฤษชุดเดียวกับภาพปกติ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพถ่ายเอียง 15-30 องศา
  - ภาพเบลอจากการสั่นและโฟกัสหลุด
  - ภาพอ้างอิงถ่ายตรงชัดสำหรับเปรียบเทียบ
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ส่งภาพถ่ายเอียงเข้าสู่กระบวนการสกัดข้อความภาษาไทยและอังกฤษ
  2. ส่งภาพเบลอเข้าสู่กระบวนการสกัดข้อความชุดเดียวกัน
  3. เปรียบเทียบข้อความและคะแนนข้อความกับภาพอ้างอิง
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ระบบประมวลผลจบทุกภาพโดยไม่แครช
  2. ภาพเอียงและภาพเบลอให้ข้อความครบถ้วนน้อยกว่าหรือเท่าภาพอ้างอิง
  3. กรณีสกัดไม่ได้ ระบบบันทึกว่าไม่พบข้อความและให้คะแนนข้อความเท่ากับ 0
- **Automation Mapping**: `server/tests/inference/test_surya.py`

---

## 9. หมวดหมู่ความถูกต้องเชิงพิกเซลและคำอธิบายเมื่อไม่มีข้อความ

### TC-AI-HEAT-02: ความตรงพิกเซลของ Heatmap กับตำแหน่งตัดต่อจริง
- **Module / Feature**: AI Inference / Heatmap Pixel Accuracy
- **Requirement ID**: FR-SYS-08
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมภาพขนาด 1280x720 ที่มีบริเวณตัดต่อทราบพิกัดแน่นอน
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพทดสอบพร้อมกรอบเฉลยบริเวณยอดเงิน
  - ผล Probability Map ขนาดเต็มภาพต้นฉบับ
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. รันภาพผ่าน Tiling 512x512 Overlap 64px แล้วประกอบ Heatmap
  2. วัดขนาด Heatmap เทียบกับภาพต้นฉบับแบบพิกเซลต่อพิกเซล
  3. ตรวจสอบค่าความน่าจะเป็นบริเวณกรอบเฉลยและบริเวณปกติ
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. Heatmap มีความกว้างยาวเท่าภาพต้นฉบับทุกพิกเซล
  2. บริเวณกรอบเฉลยมีค่าความน่าจะเป็นสูงกว่าบริเวณปกติชัดเจน
  3. ตำแหน่งที่รายงานอยู่ในกลุ่มคำมาตรฐาน เช่น กึ่งกลาง ด้านซ้าย ด้านขวา ส่วนบน ส่วนล่าง หรือมุม
- **Automation Mapping**: `server/tests/inference/test_heatmap.py`

---

### TC-AI-XAI-02: การอธิบายผลของภาพที่ไม่มีข้อความ
- **Module / Feature**: Explainable AI / No-Text Image
- **Requirement ID**: FR-SYS-11
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมภาพวิวหรือภาพสีล้วนที่ไม่มีข้อความ
  2. โมเดล Qwen2.5-1.5B พร้อมเทมเพลตภาษาไทย 1-2 ประโยค
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพไม่มีข้อความ 2 ภาพ ได้แก่ภาพวิวปกติและภาพมีรอยตัดต่อแต่ไม่มีข้อความ
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ส่งภาพไม่มีข้อความเข้าสู่กระบวนการสแกนครบทั้งภาพและข้อความ
  2. ตรวจสอบข้อความ OCR คะแนนข้อความ และคำอธิบายที่ได้
  3. นับจำนวนประโยคและตรวจสอบคำสำคัญหลอกลวงในคำอธิบาย
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ข้อความ OCR ว่างและคะแนนข้อความเท่ากับ 0
  2. คำอธิบายเป็นภาษาไทยกระชับ 1-2 ประโยค ระบุว่าไม่พบข้อความน่าสงสัย
  3. คำอธิบายไม่มีการอ้างคำสำคัญที่ไม่ได้พบจริงและไม่มีข้อมูลนอกผลตรวจจับ
- **Automation Mapping**: `server/tests/inference/test_qwen_xai.py`

---

## 10. หมวดหมู่การถดถอย ประสิทธิภาพ และความปลอดภัยของไปป์ไลน์

### TC-AI-REG-01: การเปรียบเทียบโมเดลใหม่กับโมเดลเดิมก่อนใช้งานจริง
- **Module / Feature**: Model Registry / Version Regression
- **Requirement ID**: FR-ADM-04
- **Test Type**: Regression
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มีโมเดลเวอร์ชันใช้งานอยู่และเวอร์ชันรอ Deploy พร้อมไฟล์ครบ
  2. มีชุดภาพอ้างอิงเดิมพร้อมผลคะแนนที่บันทึกไว้
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ชุดภาพอ้างอิง 20 ภาพพร้อมคะแนน Visual เดิม
  - Endpoint `POST /api/v1/admin/models/{model_id}/dry-run`
  - Endpoint `POST /api/v1/admin/models/{model_id}/deploy` พร้อมเหตุผล
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เรียก Dry-Run ของโมเดลรอ Deploy แล้วบันทึกสถานะ ความหน่วง และหน่วยความจำ
  2. รันชุดภาพอ้างอิงด้วยโมเดลรอ Deploy แล้วเทียบคะแนนกับผลเดิม
  3. Deploy โมเดลรอ Deploy แล้วตรวจลำดับ Active และประวัติการ Deploy
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. Dry-Run ตอบสำเร็จพร้อมความหน่วงและหน่วยความจำโดยประมาณ
  2. คะแนนภาพอ้างอิงเบี่ยงเบนไม่เกินเกณฑ์ที่กำหนดและระดับ low medium high ไม่พลิกผิดปกติ
  3. หลัง Deploy โมเดลใหม่เป็น Active อันดับแรกและมีบันทึกการ Deploy ครบ
- **Automation Mapping**: Manual Verification

---

### TC-AI-PERF-01: การทำงานเมื่อหน่วยประมวลผลกราฟิกไม่พร้อมและการหมดเวลา (GAP ยังไม่มีทางสำรอง)
- **Module / Feature**: AI Infrastructure / Fallback and Timeout
- **Requirement ID**: NFR-PERF-03
- **Test Type**: Performance
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมภาพทดสอบมาตรฐาน 512x512 และ 1920x1080
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพทดสอบ 2 ขนาดพร้อมจับเวลาตั้งแต่ส่งจนได้ผล
  - สภาวะจำลองหน่วยประมวลผลกราฟิกไม่พร้อม
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ส่งภาพทดสอบในสภาวะปกติแล้วบันทึกเวลาตอบสนอง
  2. จำลองสภาวะหน่วยประมวลผลกราฟิกไม่พร้อมแล้วส่งภาพซ้ำ
  3. ส่งภาพขนาดใหญ่แล้วสังเกตการสิ้นสุดของคำขอ
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. สถานะนี้เป็น GAP เนื่องจากยังไม่มีทางสำรองซีพียูและการจำกัดเวลาที่ตรวจพบในระบบปัจจุบัน
  2. เกณฑ์ยอมรับเมื่อมีทางสำรองคือประมวลผลจบหรือแจ้งหมดเวลาอย่างสุภาพโดย Main Process ไม่แครช
  3. คำขอถัดไปยังประมวลผลต่อได้ตามปกติหลังสภาวะผิดปกติ
- **Automation Mapping**: Manual Verification

---

### TC-AI-SEC-01: การป้องกันคำสั่งแทรกผ่านข้อความ OCR
- **Module / Feature**: XAI Prompt / OCR Injection Guard
- **Requirement ID**: FR-SYS-03, FR-SYS-11
- **Test Type**: Security
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เตรียมภาพที่มีข้อความปกติปนข้อความแทรกคำสั่งภาษาไทยและอังกฤษ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพที่มีข้อความว่าโอนเงินสำเร็จปนข้อความสั่งให้ละเลยคำสั่งเดิม
  - ภาพที่มีข้อความสั่งให้เปิดเผยคำสั่งระบบ
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ส่งภาพที่มีข้อความแทรกเข้าสู่กระบวนการสกัดข้อความ
  2. ตรวจสอบข้อความ OCR และคำสำคัญที่พบ
  3. ตรวจสอบคำอธิบายภาษาไทยที่สร้างจากข้อความชุดนั้น
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ข้อความแทรกถูกปฏิบัติเป็นข้อมูลทั่วไป ไม่ถูกปฏิบัติเป็นคำสั่ง
  2. คำอธิบายยังเป็นภาษาไทยกระชับ 1-2 ประโยคตามผลคะแนนจริง
  3. คำอธิบายไม่เปิดเผยคำสั่งระบบและไม่ทำตามคำสั่งแทรก
- **Automation Mapping**: Manual Verification

---

## ภาคผนวก ก. ตารางครอบคลุม 10 หมวดหลักของไฟล์นี้

| หมวดหลัก | รหัสที่ครอบคลุม | สถานะ |
|---|---|---|
| 1 Functional | TILE-01, TILE-02, OCR-01, OCR-02, OCR-03, RISK-01, RISK-02, RISK-03, RISK-04, EDGE-05, HEAT-01, HEAT-02, XAI-02, ISO-01 | ครอบคลุม |
| 2 UI/UX | ไม่มีส่วนแสดงผลในไฟล์นี้ | GAP |
| 3 API | ไม่มี endpoint สแกนเฉพาะในไฟล์นี้ | GAP |
| 4 Database | ไม่มี TC ฐานข้อมูลเฉพาะในไฟล์นี้ | GAP |
| 5 Integration | XAI-01, ISO-01 | ครอบคลุม |
| 6 Regression | REG-01 | ครอบคลุม |
| 7 Performance | EDGE-01, ACC-01 (GAP), ACC-02 (GAP), PERF-01 (GAP) | ครอบคลุมบางส่วน |
| 8 Security | SEC-01 | ครอบคลุม |
| 9 Compatibility | ไม่มี TC เบราว์เซอร์หรืออุปกรณ์ในไฟล์นี้ | GAP |
| 10 Usability และ Accessibility | ไม่มี TC การใช้งานเฉพาะในไฟล์นี้ | GAP |
