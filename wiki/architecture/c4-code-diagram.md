---
title: "C4 Code Diagram - Image Scanning Flow"
category: architecture
tags: [architecture, c4, code, sequence, diagram, backend]
updated: 2026-08-08
---

# C4: Code Diagram (Image Scanning Flow)

แผนภาพ C4 (ระดับ Code) นี้แสดงลำดับขั้นตอน (Sequence Diagram) การทำงานเชิงลึกของกระบวนการวิเคราะห์รูปภาพ (Image Scanning) ภายใน Backend ของระบบ Scam Image Detection ซึ่งครอบคลุมตั้งแต่การรับ Request จากผู้ใช้ ไปจนถึงการจัดเก็บผลลัพธ์ลงฐานข้อมูล โดยอ้างอิงจากคลาสและฟังก์ชันจริงในซอร์สโค้ด

```mermaid
sequenceDiagram
    autonumber
    
    actor Client as Mobile App
    participant Router as ScanRouter<br>(api/v1/scan.py)
    participant Service as ScanService<br>(services/scan_service.py)
    participant Utils as ImageUtils<br>(utils/image_utils.py)
    participant FS as Local Storage<br>(File System)
    participant Inference as InferenceService<br>(services/inference_service.py)
    participant ONNX as ONNX Worker<br>(onnx_worker.py)
    participant OCR as Surya OCR<br>(HuggingFace)
    participant RiskCalc as RiskCalculator<br>(utils/risk_calculator.py)
    participant DB as PostgreSQL<br>(SQLAlchemy)

    Client->>Router: POST /api/v1/scan<br>(Multipart: UploadFile)
    
    activate Router
    Router->>Service: await analyze_image(file, user_id, db)
    
    activate Service
    Note over Service: 1. อ่านไฟล์เป็น Bytes<br>และเช็คขนาดไฟล์ (Max MB)
    
    Service->>Utils: await run_in_threadpool(load_image_verified)
    Utils-->>Service: PIL Image, EXIF Data
    
    Service->>Utils: await run_in_threadpool(encode_lossless_png)
    Utils-->>Service: PNG Bytes
    
    Service->>FS: Save {hash}.png (เป็นหลักฐานรูปต้นฉบับ)
    FS-->>Service: Success
    
    Note over Service: ส่งงานให้ AI แบบ Threadpool<br>เพื่อไม่บล็อก Event Loop
    Service->>Inference: await run_in_threadpool(predict, png_bytes)
    
    activate Inference
    
    %% SegFormer Processing
    Inference->>ONNX: subprocess.Popen()<br>ส่งภาพผ่าน STDIN (Base64)
    activate ONNX
    Note over ONNX: ประมวลผล Semantic Segmentation<br>ด้วยโมเดล ONNX
    ONNX-->>Inference: STDOUT: JSON (visual_risk, heatmap_b64)
    deactivate ONNX
    
    %% OCR Processing
    Inference->>OCR: run_ocr([image], [["th", "en"]])
    activate OCR
    Note over OCR: สกัดข้อความภาษาไทย/อังกฤษ<br>ด้วย Surya OCR
    OCR-->>Inference: ocr_text (ข้อความที่สกัดได้)
    deactivate OCR
    
    Inference-->>Service: return {visual_risk_score, ai_gen_prob, heatmap_bytes, ocr_text}
    deactivate Inference
    
    Service->>FS: Save {hash}_heatmap.jpg
    
    Note over Service: วิเคราะห์ข้อความแบบ Rule-based<br>ค้นหา Scam Keywords
    
    %% Risk Calculation
    Service->>RiskCalc: calculate_risk_score(text_score, visual_score, source_score)
    activate RiskCalc
    Note over RiskCalc: ถ่วงน้ำหนัก<br>Visual (60%) + Text (40%)
    RiskCalc-->>Service: return {total_risk_score, grade}
    deactivate RiskCalc
    
    %% DB Persistence
    Service->>DB: db.add(Scan Model)<br>db.commit()<br>db.refresh()
    activate DB
    DB-->>Service: new_scan_record
    deactivate DB
    
    Service-->>Router: return new_scan (Scan Object)
    deactivate Service
    
    Router-->>Client: 200 OK<br>ScanResponse (JSON)
    deactivate Router
```

---

## คำอธิบายคลาสและฟังก์ชันที่เกี่ยวข้อง (Code-Level Details)

แผนภาพนี้เจาะลึกการทำงานของฟังก์ชันหลัก `analyze_image()` ภายใน `ScanService` ซึ่งแสดงให้เห็นถึงการทำงานแบบ Non-blocking (Asynchronous) และวิธีการที่ Backend สื่อสารกับ AI

### 1. API Layer (`ScanRouter`)
*   **ฟังก์ชัน:** `create_scan(file: UploadFile, db: AsyncSession, current_user: User)`
*   **หน้าที่:** ตรวจสอบสิทธิ์ผู้ใช้งาน (`Depends(get_current_user)`) และรับไฟล์รูปแบบ Multipart Form Data จากนั้นส่งต่อให้ Service ประมวลผล

### 2. Business Logic Layer (`ScanService`)
*   **ฟังก์ชัน:** `analyze_image(file: UploadFile, user_id: int, db: AsyncSession)`
*   **หน้าที่:** 
    1.  ตรวจสอบความปลอดภัยของไฟล์ (ขนาดไฟล์ และการแปลงเป็นภาพ Lossless PNG ป้องกันมัลแวร์แฝง)
    2.  สร้าง Hash จากไฟล์ต้นฉบับเพื่อใช้ตั้งชื่อไฟล์ (Deduplication)
    3.  ครอบการเรียกฟังก์ชันประมวลผลหนักๆ เช่น AI และ Image Processing ด้วย `run_in_threadpool()` เพื่อไม่ให้ Event Loop ของ FastAPI ถูกบล็อก (Block)
    4.  วิเคราะห์คำหลอกลวงเบื้องต้นจากผลลัพธ์ OCR ด้วย `scam_keywords`
    5.  บันทึกออบเจกต์ (Model) สู่ฐานข้อมูลผ่าน `db.commit()`

### 3. AI Integration Layer (`InferenceService`)
*   **ฟังก์ชัน:** `predict(image_bytes: bytes)`
*   **หน้าที่:** ทำงานประสาน AI โมเดลทั้ง 2 ตัว
    *   **ONNX Worker (SegFormer):** ออกแบบให้รันสคริปต์ `onnx_worker.py` ใน **Subprocess** แยกต่างหาก (AI Workload Isolation) โดยส่งรูปผ่าน Pipe (STDIN) รูปแบบ Base64 และรับผลลัพธ์กลับมาทาง STDOUT เพื่อแยกการจัดการทรัพยากรและหน่วยความจำของฝั่ง AI ออกจาก Web Server หลักอย่างเด็ดขาด
    *   **Surya OCR:** โมเดลจะถูกเตรียมพร้อมไว้ในหน่วยความจำหลัก (RAM-resident) ตั้งแต่ระบบเริ่มทำงาน เพื่อให้สามารถประมวลผลข้อความจากรูปภาพได้ทันทีโดยไม่ต้องเสียเวลาโหลดโมเดลใหม่ ช่วยลดความหน่วง (Latency) ในการตอบสนอง 

### 4. Utility & Calculation
*   **คลาส/โมดูล:** `RiskCalculator`
*   **ฟังก์ชัน:** `calculate_risk_score(text, visual, source)`
*   **หน้าที่:** เป็นเพียวฟังก์ชัน (Pure Function) ที่รับค่าตัวเลขคะแนนดิบเข้าไปคำนวณตามสูตรน้ำหนักคณิตศาสตร์ และส่งค่าความเสี่ยงรวม (Total Risk) กลับมา
