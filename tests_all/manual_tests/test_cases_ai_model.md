# ชุดกรณีทดสอบ: โมเดลปัญญาประดิษฐ์และไปป์ไลน์การวิเคราะห์ภาพ (AI Model & Inference Pipeline)

- **Models**:
  - **Visual Tampering Detection**: SegFormer (Semantic Segmentation, ONNX Runtime)
  - **Optical Character Recognition**: Surya OCR 0.5.0 (PyTorch Native, TH/EN Support)
  - **Explainable AI (XAI)**: Qwen2.5-1.5B (Language & Reasoning Model)
  - **Source Verification**: Reverse Image Search Engine
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
- **Automation Mapping**: `server/tests/inference/test_segformer.py`

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
- **Automation Mapping**: `server/tests/inference/test_heatmap.py`

---

## 2. หมวดหมู่การสกัดข้อความและการตรวจจับความผิดปกติ (Surya OCR & NLP)

### TC-AI-OCR-01: การสกัดข้อความภาษาไทยและภาษาอังกฤษพร้อมพิกัด Bounding Boxes
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
  2. ได้รับพิกัด Bounding Box `[x_min, y_min, x_max, y_max]` ของข้อความแต่ละบรรทัดถูกต้องตรงตำแหน่ง
  3. จัดเก็บผลลัพธ์ในรูปแบบ Structured DTO พร้อมส่งต่อให้โมดูลคำนวณความเสี่ยง
- **Automation Mapping**: `server/tests/inference/test_surya.py`

---

### TC-AI-OCR-02: การตรวจจับคีย์เวิร์ดหลอกลวงและความผิดปกติของฟอนต์ (Textual Anomaly Score)
- **Module / Feature**: OCR Analysis / Keyword Matching
- **Requirement ID**: FR-SYS-03
- **Test Type**: Functional / Algorithm
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. รายการคีย์เวิร์ดและรูปแบบข้อความเฝ้าระวัง (Scam Dictionary) โหลดในระบบ
- **Test Data**: ภาพสลิปปลอมที่มีการสะกดชื่อธนาคารผิด หรือใช้ฟอนต์ตัวเลขที่มีขนาดไม่สม่ำเสมอ
- **Test Steps**:
  1. ประมวลผลข้อความผ่านโมดูลประเมินความเสี่ยงด้านข้อความ
- **Expected Results**:
  1. ระบบตรวจพบจุดสังเกต เช่น ฟอนต์ตัวเลขไม่ตรงมาตรฐาน หรือมีคำต้องสงสัย
  2. ให้คะแนน Textual Score ในระดับสูง (> 70 คะแนน)
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

## 3. หมวดหมู่การอธิบายผลลัพธ์เชิงเหตุผล (Explainable AI - Qwen2.5)

### TC-AI-XAI-01: การสร้างข้อความสรุปและเหตุผลประกอบการตรวจจับ (XAI Reasoning)
- **Module / Feature**: Explainable AI / Qwen2.5-1.5B
- **Requirement ID**: FR-SYS-10
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
  1. สร้างข้อความสรุปภาษาไทยที่กระชับและเข้าใจง่าย (ไม่เกิน 3-4 ประโยค)
  2. ชี้แจงเหตุผลชัดเจน เช่น "ตรวจพบความผิดปกติของพิกเซลบริเวณยอดเงิน และมีลักษณะการวางทับข้อความเดิม"
  3. ไม่มีการเพ้อเจ้อ (Hallucination) ข้อมูลที่อยู่นอกเหนือจากผลการตรวจจับจริง
- **Automation Mapping**: `server/tests/inference/test_qwen_xai.py`

---

## 4. หมวดหมู่สูตรการคำนวณคะแนนความเสี่ยง (Risk Scoring Formula)

### TC-AI-RISK-01: การคำนวณคะแนนความเสี่ยงแบบผสมผสาน (Hybrid Worst-Case Scoring Formula)
- **Module / Feature**: Risk Calculator / Scoring Engine
- **Requirement ID**: FR-SYS-07
- **Test Type**: Mathematical / Algorithm
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ระบบคำนวณความเสี่ยงเปิดใช้งานสูตร Hybrid Worst-Case
- **Test Data**:
  - Textual Score: 30
  - Source Verification Score: 20
  - Visual Anomaly Score: 85 (ตรวจพบรอยตัดต่อชัดเจน)
- **Test Steps**:
  1. ป้อนคะแนนทั้ง 3 ด้านเข้าสู่ฟังก์ชัน `calculate_overall_risk_score()`
- **Expected Results**:
  1. เนื่องจากคะแนน Visual Anomaly สูงเกินขีดจำกัดวิกฤต (Critical Override Threshold)
  2. คะแนน Overall Risk Score ต้องไม่ถูกเกลี่ยจนต่ำลง (Dilution Prevention)
  3. ได้รับคะแนนรวมอยู่ในช่วง High Risk (>= 70 ถึง 100) และระดับความเสี่ยงเป็น `High`
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
  1. คะแนนช่วง 0 – 39: จัดอยู่ในระดับ `Low` (ความเสี่ยงต่ำ)
  2. คะแนนช่วง 40 – 69: จัดอยู่ในระดับ `Medium` (ความเสี่ยงปานกลาง)
  3. คะแนนช่วง 70 – 100: จัดอยู่ในระดับ `High` (ความเสี่ยงสูง)
  4. **ไม่มีการใช้ระดับ "Safe" ในผลลัพธ์ของระบบเด็ดขาด**
- **Automation Mapping**: `server/tests/utils/test_risk_calculator.py`

---

## 5. หมวดหมู่การแยกโพรเซสประมวลผล (Subprocess Isolation & Memory Safety)

### TC-AI-ISO-01: การตัดวงจรเมื่อ Subprocess เกิดข้อผิดพลาดหรือ Timeout (Fault Tolerance)
- **Module / Feature**: AI Infrastructure / Subprocess Worker
- **Requirement ID**: NFR-PERF-03
- **Test Type**: Reliability / Stress
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. สคริปต์ `onnx_worker.py` ถูกรันแยกโพรเซสผ่าน `subprocess` / `asyncio`
- **Test Data**: ส่งคำสั่งประมวลผลที่จำลองสภาวะแฮงก์ (Infinite Loop หรือ OOM)
- **Test Steps**:
  1. ยิงภาพที่ทำให้ Subprocess ใช้เวลานานเกิน Timeout ที่กำหนด (เช่น 30 วินาที)
- **Expected Results**:
  1. Main FastAPI Process ไม่แครชตาม และยังคงให้บริการ Endpoint อื่นๆ ได้ตามปกติ
  2. Subprocess ที่ค้างจะถูก Kill และ Spawn ขึ้นมาใหม่โดยอัตโนมัติ
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
  1. เตรียมภาพความละเอียด 3840x2160 (4K) และ 7680x4320 (8K) ขนาดไฟล์ไม่เกิน 10MB
- **Test Data**: ภาพ 4K Ultra-HD
- **Test Steps**:
  1. ส่งภาพเข้าสู่ไปป์ไลน์ Tiling Inference
- **Expected Results**:
  1. ไปป์ไลน์คำนวณจำนวน Patch เพิ่มขึ้นอย่างเป็นสัดส่วน
  2. ไม่เกิดข้อผิดพลาด Out of Memory (OOM) ในระบบ
  3. สามารถประกอบ Full-Resolution Heatmap ได้สำเร็จ
- **Automation Mapping**: `server/tests/inference/test_segformer.py`

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
- **Automation Mapping**: `server/tests/inference/test_segformer.py`
