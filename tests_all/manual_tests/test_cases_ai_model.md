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

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-TILE-01 | การตัดภาพความละเอียดสูงเป็น Patch 512x512 พร้อม Overlap 64px | FR-SYS-05 | เตรียมภาพความละเอียดสูง (Full-Resolution เช่น 1920x1080 พิกเซล)<br>โหลดโมเดล SegFormer ONNX เข้าสู่ Subprocess Worker | ภาพขนาด 1920x1080 พิกเซล มีการตัดต่อข้อความในสลิป | AI Inference / Overlapping Tiling (Functional / Algorithm) | ป้อนภาพเข้าสู่ฟังก์ชัน Tiling ใน `onnx_worker.py`<br>ตรวจสอบจำนวนและมิติของ Patch ที่ถูกสร้างขึ้น | ภาพขนาด 1920x1080 ถูกตัดเป็นชิ้นส่วน (Patches) ขนาด 512x512 พิกเซล<br>แต่ละชิ้นส่วนข้างเคียงมีขอบเขตทับซ้อนกันขนาด 64 พิกเซลทั้งแกน X และแกน Y<br>ไม่มีส่วนใดของภาพหลุดหาย หรือถูกย่อขนาด (Resize) จนเสียรายละเอียดพิกเซล | To Do | P0 (Blocker) |
| TC-AI-TILE-02 | การเฉลี่ยค่าน้ำหนักความน่าจะเป็นในบริเวณรอยต่อ (Weight Averaging on Overlap) | FR-SYS-05, FR-SYS-08 | มีผลลัพธ์ Probability Maps จากทุก Patch ที่รันผ่าน SegFormer | ผลลัพธ์ Tensor ของภาพ 1920x1080 | AI Inference / Patch Reconstruction (Mathematical / Accuracy) | รวม Probability Maps แต่ละ Patch คืนสู่ Canvas ขนาดภาพจริง<br>คำนวณค่าเฉลี่ยในพื้นที่ทับซ้อน (Weight Averaging Mask) | แผนที่ความร้อนความละเอียดเต็ม (Full-Res Heatmap) ต่อเนื่องไร้รอยต่อ: ค่าเฉลี่ยบริเวณทับซ้อนต่างจากค่าพิกเซลข้างเคียงไม่เกิน ±0.05<br>ไม่ปรากฏรอยตะเข็บรูปสี่เหลี่ยมตามขอบของ Patch (Seamless Patch Merging)<br>บริเวณที่มีการตัดต่อตรงรอยต่อพิกเซลมีค่าเฉลี่ยความน่าจะเป็น (mean prob) ≥0.7 และสูงกว่าพื้นหลังข้างเคียง ≥0.3 | To Do | P0 (Blocker) |

## 2. หมวดหมู่การสกัดข้อความและการตรวจจับความผิดปกติ (Surya OCR & NLP)

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-OCR-01 | การสกัดข้อความภาษาไทยและภาษาอังกฤษ (Thai Plus English OCR) | FR-SYS-02 | Surya OCR โมเดลพร้อมทำงานในหน่วยความจำ | ภาพสลิปที่มีข้อความภาษาไทย "โอนเงินสำเร็จ" และภาษาอังกฤษ "Transaction Successful" | OCR Engine / Surya OCR PyTorch (Functional / Accuracy) | ส่งภาพเข้าสู่ฟังก์ชัน OCR ในไปป์ไลน์ | สกัดข้อความภาษาไทยและภาษาอังกฤษได้ถูกต้องแม่นยำ (> 90% Character Accuracy)<br>ข้อความที่สกัดได้ถูกส่งต่อให้โมดูลค้นหาคีย์เวิร์ดหลอกลวงเพื่อคำนวณคะแนนข้อความ<br>กรณีภาพไม่มีข้อความ ระบบบันทึกว่าไม่พบข้อความและให้คะแนนข้อความเท่ากับ 0 | To Do | P1 (High) |
| TC-AI-OCR-02 | การตรวจจับคีย์เวิร์ดหลอกลวงจากข้อความที่สกัดได้ (Textual Anomaly Score) | FR-SYS-03 | รายการคีย์เวิร์ดและรูปแบบข้อความเฝ้าระวัง (Scam Dictionary) โหลดในระบบ | ภาพสลิปปลอมที่มีข้อความต้องสงสัย เช่น ชื่อธนาคารสะกดผิด หรือข้อความเร่งรัดการโอนเงิน | OCR Analysis / Keyword Matching (Functional / Algorithm) | ประมวลผลข้อความผ่านโมดูลประเมินความเสี่ยงด้านข้อความ | ระบบตรวจพบคำต้องสงสัยจากพจนานุกรมเฝ้าระวังในข้อความที่สกัดได้<br>ให้คะแนน Textual Score ในระดับสูง (> 70 คะแนน) เมื่อพบคำต้องสงสัยหลายคำ | To Do | P1 (High) |

## 3. หมวดหมู่การอธิบายผลลัพธ์เชิงเหตุผล (Explainable AI - Qwen2.5)

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-XAI-01 | การสร้างข้อความสรุปและเหตุผลประกอบการตรวจจับ (XAI Reasoning) | FR-SYS-11 | โมเดล Qwen2.5-1.5B ถูกโหลดและตั้งค่า Prompt Template ภาษาไทย<br>มีผลลัพธ์จาก SegFormer (พิกัด Heatmap) และ Surya OCR (ข้อความที่พบ) | ผลสแกนภาพใบเสร็จปลอมที่มีรอยตัดต่อตัวเลขยอดเงิน | Explainable AI / Qwen2.5-1.5B (Integration / NLP) | ส่ง Context ข้อมูลพิกเซลและข้อความเข้าสู่โมเดล Qwen<br>สร้างข้อความสรุปผล | สร้างข้อความสรุปภาษาไทย 1-2 ประโยค เข้าใจง่าย (rubric ข้อ 1: ความยาวและภาษา)<br>ชี้แจงเหตุผลชัดเจน เช่น "ตรวจพบความผิดปกติของพิกเซลบริเวณยอดเงิน และมีลักษณะการวางทับข้อความเดิม" โดย region/score/keywords ต้องตรงกับอินพุต SegFormer+OCR จริง (rubric ข้อ 2: ความสอดคล้องกับอินพุต)<br>ไม่มีการเพ้อเจ้อ (Hallucination) ข้อมูลที่อยู่นอกเหนือจากผลการตรวจจับจริง — ทุกประโยคต้องอ้างอิงได้จากผลตรวจจับ (rubric ข้อ 3: ตรวจสอบย้อนกลับได้); เกณฑ์ผ่านคือ rubric ครบ 3 ข้อโดยผู้ตรวจอิสระ 2 คนเห็นตรงกัน | To Do | P1 (High) |

## 4. หมวดหมู่สูตรการคำนวณคะแนนความเสี่ยง (Risk Scoring Formula)

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-RISK-01 | การคำนวณคะแนนความเสี่ยงแบบผสมผสาน (Hybrid Worst-Case Scoring Formula) | FR-SYS-07 | ระบบคำนวณความเสี่ยงเปิดใช้งานสูตร Hybrid Worst-Case | Textual Score: 30<br>Source Verification Score: 20<br>Visual Anomaly Score: 85 (ตรวจพบรอยตัดต่อชัดเจน) | Risk Calculator / Scoring Engine (Functional) | ป้อนคะแนนทั้ง 3 ด้านเข้าสู่ฟังก์ชันคำนวณคะแนนความเสี่ยง | คะแนนฐานเท่ากับค่าสูงสุดของ 3 ด้าน คือ 85<br>ไม่มีการบวกเพิ่มเพราะไม่มีมิติด้านรองที่มีค่าไม่ต่ำกว่า 40<br>ได้รับคะแนนรวม 85 และระดับความเสี่ยงเป็น `high` ตัวพิมพ์เล็ก | To Do | P0 (Blocker) |
| TC-AI-RISK-02 | การจำแนกระดับความเสี่ยง 3 ระดับอย่างถูกต้อง (Risk Grading) | FR-REPORT-01, FR-SYS-07 | มีฟังก์ชันจัดระดับคะแนนความเสี่ยง | เคสที่ 1: คะแนน 0, 20, 39<br>เคสที่ 2: คะแนน 40, 55, 69<br>เคสที่ 3: คะแนน 70, 85, 100 | Risk Calculator / Grading (Boundary / Functional) | ป้อนคะแนนขอบเขตเข้าสู่ฟังก์ชันจัดระดับ | คะแนนช่วง 0 – 39: จัดอยู่ในระดับ `low` (ความเสี่ยงต่ำ)<br>คะแนนช่วง 40 – 69: จัดอยู่ในระดับ `medium` (ความเสี่ยงปานกลาง)<br>คะแนนช่วง 70 – 100: จัดอยู่ในระดับ `high` (ความเสี่ยงสูง)<br>ไม่พบคำว่าระดับ Safe ในผลลัพธ์ของระบบ | To Do | P0 (Blocker) |
| TC-AI-RISK-03 | การบวกคะแนนเพิ่มเมื่อพบความเสี่ยงหลายมิติพร้อมกัน (Multi-Factor Bonus) | FR-SYS-07 | ระบบคำนวณความเสี่ยงเปิดใช้งานสูตร Hybrid Worst-Case | Textual Score: 50<br>Source Verification Score: 60<br>Visual Anomaly Score: 80 | Risk Calculator / Multi-Factor Compounding (Functional) | ป้อนคะแนนทั้ง 3 ด้านเข้าสู่ฟังก์ชันคำนวณคะแนนความเสี่ยง | คะแนนฐานเท่ากับค่าสูงสุดของ 3 ด้าน คือ 80<br>มิติรองที่มีค่าไม่ต่ำกว่า 40 มี 2 มิติ จึงบวกเพิ่มมิติละ 5 คะแนน รวมเป็น 90<br>ได้รับระดับความเสี่ยงเป็น `high` ตัวพิมพ์เล็ก | To Do | P1 (High) |

## 5. หมวดหมู่การแยกโพรเซสประมวลผล (Subprocess Isolation & Memory Safety)

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-ISO-01 | การตัดวงจรเมื่อ Subprocess เกิดข้อผิดพลาดหรือ Timeout (Fault Tolerance) | NFR-PERF-03 | สคริปต์ `onnx_worker.py` ถูกรันแยกโพรเซสผ่าน `subprocess.Popen` โดยส่งภาพแบบ base64 ทาง stdin | ส่งคำสั่งประมวลผลที่จำลองสภาวะแฮงก์ (Infinite Loop หรือ OOM) | AI Infrastructure / Subprocess Worker (Functional) | ยิงภาพที่ทำให้ Subprocess ทำงานผิดพลาดหรือหยุดชะงัก | Main FastAPI Process ไม่แครชตาม และ `GET /health` ตอบ `200 OK` ภายใน 2 วินาทีหลัง Subprocess ล้มเหลว<br>คำขอถัดไปสามารถสร้าง Subprocess ใหม่เพื่อประมวลผลได้ (ตรวจด้วย `GET /health` ตอบ 200 ภายใน 2s เช่นกัน)<br>Client ได้รับข้อความแจ้งเตือนข้อผิดพลาดที่เหมาะสม (JSON `{"detail": ...}` ไม่ใช่ HTML/timeout) ไม่เกิด Connection Hang (TCP ไม่ค้างเกิน 10s) | To Do | P1 (High) |

## 6. หมวดหมู่กรณีทดสอบสภาวะขอบเขตภาพ (Edge Case Images)

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-EDGE-01 | การประมวลผลภาพความละเอียดสูงมากระดับ 4K / 8K | FR-SYS-05 | เตรียมภาพความละเอียด 3840x2160 (4K) และ 7680x4320 (8K) ขนาดไฟล์ไม่เกิน 20MB (Server) / Mobile 10MB + decode ไม่เกิน 100M px | ภาพ 4K Ultra-HD | Tiling Inference / Ultra-HD Images (Boundary / Stress) | ส่งภาพเข้าสู่ไปป์ไลน์ Tiling Inference | ไปป์ไลน์คำนวณจำนวน Patch เพิ่มขึ้นอย่างเป็นสัดส่วน<br>ไม่เกิดข้อผิดพลาด Out of Memory (OOM) ในระบบ<br>สามารถประกอบ Full-Resolution Heatmap ได้สำเร็จ | To Do | P2 (Medium) |
| TC-AI-EDGE-02 | การประมวลผลภาพสีเดียวล้วนหรือภาพว่างเปล่า (Monochrome / Blank Canvas) | FR-SYS-05 | เตรียมภาพสีขาวล้วน (RGB 255, 255, 255) และภาพสีดำล้วน (RGB 0, 0, 0) | `blank_white.png` (512x512) | AI Inference / Robustness (Negative / Robustness) | ส่งภาพเข้าสู่กระบวนการสแกน | ระบบไม่เกิด ZeroDivisionError หรือข้อผิดพลาดทางคณิตศาสตร์<br>ค่าคะแนนความเสี่ยงด้าน Visual Anomaly อยู่ในเกณฑ์ต่ำ (< 10)<br>ระบบสามารถส่งคืนผลลัพธ์ได้อย่างถูกต้องโดยไม่แครช | To Do | P2 (Medium) |

## 7. หมวดหมู่ภาพขอบเขตเพิ่มเติมและความแม่นยำ AI (Additional Edges Plus Accuracy GAP)

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-EDGE-03 | การประมวลผลภาพแนวยาวพาโนรามา (Panorama Image) | FR-SYS-05 | เตรียมภาพแนวยาว เช่น 4000x800 พิกเซล ขนาดไฟล์ไม่เกิน 20MB | ภาพพาโนรามาแชตหรือสลิปแนวยาว | Tiling Inference / Panorama Images (Boundary) | ส่งภาพเข้าสู่ไปป์ไลน์ Tiling Inference<br>ตรวจสอบการตัด Patch และการประกอบ Heatmap | ภาพถูกตัดเป็น Patch 512x512 พร้อม Overlap 64px ครบทุกส่วน<br>Heatmap ที่ประกอบกลับมีขนาดเท่าภาพต้นฉบับ<br>ไม่เกิดข้อผิดพลาดหน่วยความจำ | To Do | P2 (Medium) |
| TC-AI-EDGE-04 | การประมวลผลภาพที่มี Noise สูง (Noisy Image) | FR-SYS-05 | เตรียมภาพที่ถ่ายในที่แสงน้อยมี Noise ทั่วทั้งภาพ | ภาพสลิปที่มี Noise เกรนสูง | AI Inference / Robustness (Negative) | ส่งภาพเข้าสู่กระบวนการสแกน | ระบบประมวลผลจบโดยไม่แครช<br>คะแนน Visual Anomaly ไม่พุ่งสูงผิดปกติจาก Noise เพียงอย่างเดียว<br>คำอธิบาย XAI สรุปผลตามคะแนนที่ตรวจวัดได้โดยไม่หยุดชะงัก | To Do | P2 (Medium) |
| TC-AI-HEAT-01 | การประกอบ Heatmap ความละเอียดเต็มจาก Probability Map (Heatmap Reconstruction) | FR-SYS-08 | มี Probability Map จากทุก Patch ของภาพทดสอบ | Probability Map ของภาพ 1920x1080 | AI Inference / Heatmap Reconstruction (Functional) | เฉลี่ยค่าน้ำหนักบริเวณทับซ้อนและประกอบกลับขนาดเต็ม<br>ตรวจสอบความต่อเนื่องของรอยต่อและความละเอียด | ได้ Heatmap ขนาดเท่าภาพต้นฉบับแบบเต็มพิกเซล<br>ไม่พบรอยตะเข็บตามขอบ Patch (ค่าบริเวณทับซ้อนต่างจากข้างเคียงไม่เกิน ±0.05)<br>บริเวณตัดต่อมีค่าเฉลี่ยความน่าจะเป็น (mean prob) ≥0.7 และสูงกว่าพื้นหลังข้างเคียง ≥0.3 | To Do | P0 (Blocker) |
| TC-AI-ACC-01 | ความแม่นยำการตรวจจับภาพตัดต่อระดับ 85 เปอร์เซ็นต์ (GAP ยังไม่มีชุดทดสอบมาตรฐาน) | NFR-AI-01 | เตรียมชุดทดสอบมาตรฐานพร้อมเฉลย | ชุดภาพตัดต่อและภาพปกติพร้อมป้ายกำกับ | AI Accuracy / Tamper Detection Benchmark (Performance) | รันโมเดลกับชุดทดสอบทั้งหมด<br>คำนวณค่า mDice | สถานะนี้เป็น GAP เนื่องจากยังไม่มีชุดทดสอบมาตรฐานและสคริปต์วัด mDice ในระบบปัจจุบัน<br>เกณฑ์ยอมรับเมื่อมีชุดทดสอบคือ mDice ไม่ต่ำกว่า 85 เปอร์เซ็นต์<br>ผลต้องจำแนกระดับความเสี่ยงได้เพียง Low, Medium, High | To Do | P1 (High) |
| TC-AI-ACC-02 | ความแม่นยำการจำแนกภาพ AI-Generated ระดับ 85 เปอร์เซ็นต์ (GAP ยังไม่มีโมเดลจำแนกเฉพาะ) | NFR-AI-02 | เตรียมชุดภาพ AI-Generated และภาพถ่ายจริงพร้อมเฉลย | ชุดภาพทดสอบสองกลุ่มพร้อมป้ายกำกับ | AI Accuracy / AI-Generated Classification (Performance) | รันการจำแนกกับชุดทดสอบทั้งหมด<br>คำนวณความแม่นยำ | สถานะนี้เป็น GAP เนื่องจากยังไม่มีโมเดลจำแนก AI-Generated เฉพาะทางในระบบปัจจุบัน<br>เกณฑ์ยอมรับเมื่อมีโมเดลคือความแม่นยำไม่ต่ำกว่า 85 เปอร์เซ็นต์<br>ค่า `ai_gen_probability` ใน Response ต้องสอดคล้องกับผลการจำแนก | To Do | P2 (Medium) |

## 8. หมวดหมู่ขอบเขตรอยต่อคะแนนและรูปแบบไฟล์ภาพเพิ่มเติม

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-RISK-04 | การเปลี่ยนระดับที่รอยต่อ 39/40 และ 69/70 พร้อมโบนัสข้ามเกณฑ์ | FR-SYS-07 | มีฟังก์ชันคำนวณคะแนนแบบ Hybrid Worst-Case พร้อมโบนัสมิติรอง | ชุดที่ 1: Text 10, Visual 39, Source 20 คาดหวัง low<br>ชุดที่ 2: Text 10, Visual 40, Source 20 คาดหวัง medium<br>ชุดที่ 3: Text 10, Visual 69, Source 20 คาดหวัง medium<br>ชุดที่ 4: Text 10, Visual 70, Source 20 คาดหวัง high<br>ชุดที่ 5: Text 45, Visual 65, Source 10 คาดหวัง 70 high จากโบนัส | Risk Calculator / Boundary Grading (Functional) | ป้อนคะแนนทั้ง 5 ชุดเข้าสู่ฟังก์ชันคำนวณทีละชุด<br>บันทึกคะแนนรวม ระดับ และสถานะหลายมิติที่ได้<br>เปรียบเทียบคู่รอยต่อ 39 กับ 40 และ 69 กับ 70 | คะแนน 39 ได้ระดับ `low` ส่วนคะแนน 40 ได้ระดับ `medium`<br>คะแนน 69 ได้ระดับ `medium` ส่วนคะแนน 70 ได้ระดับ `high`<br>ชุดที่ 5 ได้ฐาน 65 บวกโบนัส 5 เป็น 70 และได้ระดับ `high`<br>ระดับที่ได้มีเพียง `low`, `medium`, `high` ตัวพิมพ์เล็กเท่านั้น | To Do | P0 (Blocker) |
| TC-AI-EDGE-05 | การรองรับภาพ CMYK ภาพหมุน EXIF ภาพ WebP โปร่งใส และนามสกุลปลอม | FR-SYS-05 | เตรียมภาพ 4 แบบขนาดไม่เกิน 20MB และจำนวนพิกเซล decode ไม่เกิน 100M px | ภาพ JPEG โหมด CMYK ขนาด 1024x768<br>ภาพ JPEG มีค่า EXIF Orientation หมุน 90 องศา<br>ภาพ WebP แบบโปร่งใสพื้นหลัง<br>ไฟล์ข้อความเปลี่ยนนามสกุลเป็น .jpg | AI Inference / Image Format Robustness (Functional) | ส่งภาพ CMYK เข้าสู่กระบวนการสแกนแล้วตรวจผล<br>ส่งภาพหมุน EXIF เข้าสู่กระบวนการสแกนแล้วตรวจผล<br>ส่งภาพ WebP โปร่งใสเข้าสู่กระบวนการสแกนแล้วตรวจผล<br>ส่งไฟล์นามสกุลปลอมเข้าสู่กระบวนการตรวจสอบแล้วตรวจผล | ภาพ CMYK ถูกแปลงเป็น RGB และประมวลผลจบโดยไม่แครช ได้คะแนน 0-100<br>ภาพหมุน EXIF ประมวลผลจบโดยไม่แครช มีการเก็บค่า EXIF ไว้ในผลการสแกน<br>ภาพ WebP โปร่งใสประมวลผลจบโดยไม่แครช ได้คะแนนและ heatmap ตามปกติ<br>ไฟล์นามสกุลปลอมถูกปฏิเสธว่าเป็นภาพไม่ถูกต้องโดยไม่แครชทั้งระบบ | To Do | P2 (Medium) |
| TC-AI-OCR-03 | การสกัดข้อความจากภาพถ่ายเอียงและภาพเบลอ | FR-SYS-02 | เตรียมภาพสลิปที่มีข้อความไทยและอังกฤษชุดเดียวกับภาพปกติ | ภาพถ่ายเอียง 15-30 องศา<br>ภาพเบลอจากการสั่นและโฟกัสหลุด<br>ภาพอ้างอิงถ่ายตรงชัดสำหรับเปรียบเทียบ | OCR Engine / Degraded Images (Functional) | ส่งภาพถ่ายเอียงเข้าสู่กระบวนการสกัดข้อความภาษาไทยและอังกฤษ<br>ส่งภาพเบลอเข้าสู่กระบวนการสกัดข้อความชุดเดียวกัน<br>เปรียบเทียบข้อความและคะแนนข้อความกับภาพอ้างอิง | ระบบประมวลผลจบทุกภาพโดยไม่แครช<br>ภาพเอียงให้ Character Accuracy ไม่ต่ำกว่า 70% ของภาพอ้างอิง ภาพเบลอไม่ต่ำกว่า 50% ของภาพอ้างอิง (ต่ำกว่านี้ถือว่า FAIL — เกณฑ์ตก)<br>กรณีสกัดไม่ได้ ระบบบันทึกว่าไม่พบข้อความและให้คะแนนข้อความเท่ากับ 0 | To Do | P2 (Medium) |

## 9. หมวดหมู่ความถูกต้องเชิงพิกเซลและคำอธิบายเมื่อไม่มีข้อความ

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-HEAT-02 | ความตรงพิกเซลของ Heatmap กับตำแหน่งตัดต่อจริง | FR-SYS-08 | เตรียมภาพขนาด 1280x720 ที่มีบริเวณตัดต่อทราบพิกัดแน่นอน | ภาพทดสอบพร้อมกรอบเฉลยบริเวณยอดเงิน<br>ผล Probability Map ขนาดเต็มภาพต้นฉบับ | AI Inference / Heatmap Pixel Accuracy (Functional) | รันภาพผ่าน Tiling 512x512 Overlap 64px แล้วประกอบ Heatmap<br>วัดขนาด Heatmap เทียบกับภาพต้นฉบับแบบพิกเซลต่อพิกเซล<br>ตรวจสอบค่าความน่าจะเป็นบริเวณกรอบเฉลยและบริเวณปกติ | Heatmap มีความกว้างยาวเท่าภาพต้นฉบับทุกพิกเซล<br>บริเวณกรอบเฉลยมีค่าเฉลี่ยความน่าจะเป็น (mean prob) ≥0.7 และสูงกว่าบริเวณปกติ ≥0.3<br>ตำแหน่งที่รายงานอยู่ในกลุ่มคำมาตรฐาน เช่น กึ่งกลาง ด้านซ้าย ด้านขวา ส่วนบน ส่วนล่าง หรือมุม | To Do | P1 (High) |
| TC-AI-XAI-02 | การอธิบายผลของภาพที่ไม่มีข้อความ | FR-SYS-11 | เตรียมภาพวิวหรือภาพสีล้วนที่ไม่มีข้อความ<br>โมเดล Qwen2.5-1.5B พร้อมเทมเพลตภาษาไทย 1-2 ประโยค | ภาพไม่มีข้อความ 2 ภาพ ได้แก่ภาพวิวปกติและภาพมีรอยตัดต่อแต่ไม่มีข้อความ | Explainable AI / No-Text Image (Functional) | ส่งภาพไม่มีข้อความเข้าสู่กระบวนการสแกนครบทั้งภาพและข้อความ<br>ตรวจสอบข้อความ OCR คะแนนข้อความ และคำอธิบายที่ได้<br>นับจำนวนประโยคและตรวจสอบคำสำคัญหลอกลวงในคำอธิบาย | ข้อความ OCR ว่างและคะแนนข้อความเท่ากับ 0<br>คำอธิบายเป็นภาษาไทย 1-2 ประโยค ระบุว่าไม่พบข้อความน่าสงสัย (rubric เดียวกับ TC-AI-XAI-01: ครบ 3 ข้อโดยผู้ตรวจ 2 คน)<br>คำอธิบายไม่มีการอ้างคำสำคัญที่ไม่ได้พบจริงและไม่มีข้อมูลนอกผลตรวจจับ | To Do | P1 (High) |

## 10. หมวดหมู่การถดถอย ประสิทธิภาพ และความปลอดภัยของไปป์ไลน์

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-AI-REG-01 | การเปรียบเทียบโมเดลใหม่กับโมเดลเดิมก่อนใช้งานจริง | FR-ADM-04 | มีโมเดลเวอร์ชันใช้งานอยู่และเวอร์ชันรอ Deploy พร้อมไฟล์ครบ<br>มีชุดภาพอ้างอิงเดิมพร้อมผลคะแนนที่บันทึกไว้ | ชุดภาพอ้างอิง 20 ภาพพร้อมคะแนน Visual เดิม<br>Endpoint `POST /api/v1/admin/models/{model_id}/dry-run`<br>Endpoint `POST /api/v1/admin/models/{model_id}/deploy` พร้อมเหตุผล | Model Registry / Version Regression (Regression) | เรียก Dry-Run ของโมเดลรอ Deploy แล้วบันทึกสถานะ ความหน่วง และหน่วยความจำ<br>รันชุดภาพอ้างอิงด้วยโมเดลรอ Deploy แล้วเทียบคะแนนกับผลเดิม<br>Deploy โมเดลรอ Deploy แล้วตรวจลำดับ Active และประวัติการ Deploy | Dry-Run ตอบสำเร็จพร้อมความหน่วงและหน่วยความจำโดยประมาณ<br>คะแนนภาพอ้างอิงเบี่ยงเบนไม่เกิน \|Δ\| ≤5 คะแนน และระดับ low/medium/high ไม่ข้ามเกรด (ข้ามเกรดถือว่า FAIL)<br>หลัง Deploy โมเดลใหม่เป็น Active อันดับแรกและมีบันทึกการ Deploy ครบ | To Do | P1 (High) |
| TC-AI-PERF-01 | การทำงานเมื่อหน่วยประมวลผลกราฟิกไม่พร้อมและการหมดเวลา (GAP ยังไม่มีทางสำรอง) | NFR-PERF-03 | เตรียมภาพทดสอบมาตรฐาน 512x512 และ 1920x1080 | ภาพทดสอบ 2 ขนาดพร้อมจับเวลาตั้งแต่ส่งจนได้ผล<br>สภาวะจำลองหน่วยประมวลผลกราฟิกไม่พร้อม | AI Infrastructure / Fallback and Timeout (Performance) | ส่งภาพทดสอบในสภาวะปกติแล้วบันทึกเวลาตอบสนอง<br>จำลองสภาวะหน่วยประมวลผลกราฟิกไม่พร้อมแล้วส่งภาพซ้ำ<br>ส่งภาพขนาดใหญ่แล้วสังเกตการสิ้นสุดของคำขอ | สถานะนี้เป็น GAP เนื่องจากยังไม่มีทางสำรองซีพียูและการจำกัดเวลาที่ตรวจพบในระบบปัจจุบัน<br>เกณฑ์ยอมรับเมื่อมีทางสำรองคือประมวลผลจบหรือแจ้งหมดเวลาอย่างสุภาพโดย Main Process ไม่แครช<br>คำขอถัดไปยังประมวลผลต่อได้ตามปกติหลังสภาวะผิดปกติ | To Do | P2 (Medium) |
| TC-AI-SEC-01 | การป้องกันคำสั่งแทรกผ่านข้อความ OCR | FR-SYS-03, FR-SYS-11 | เตรียมภาพที่มีข้อความปกติปนข้อความแทรกคำสั่งภาษาไทยและอังกฤษ | ภาพที่มีข้อความว่าโอนเงินสำเร็จปนข้อความสั่งให้ละเลยคำสั่งเดิม<br>ภาพที่มีข้อความสั่งให้เปิดเผยคำสั่งระบบ | XAI Prompt / OCR Injection Guard (Security) | ส่งภาพที่มีข้อความแทรกเข้าสู่กระบวนการสกัดข้อความ<br>ตรวจสอบข้อความ OCR และคำสำคัญที่พบ<br>ตรวจสอบคำอธิบายภาษาไทยที่สร้างจากข้อความชุดนั้น | ข้อความแทรกถูกปฏิบัติเป็นข้อมูลทั่วไป ไม่ถูกปฏิบัติเป็นคำสั่ง<br>คำอธิบายยังเป็นภาษาไทย 1-2 ประโยคตามผลคะแนนจริง (rubric เดียวกับ TC-AI-XAI-01: region/score/keywords ตรงอินพุต ผู้ตรวจ 2 คน)<br>คำอธิบายไม่เปิดเผยคำสั่งระบบและไม่ทำตามคำสั่งแทรก | To Do | P1 (High) |

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
