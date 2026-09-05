---
title: "C4 Code Diagram - Image Scanning Flow"
category: architecture
tags: [architecture, c4, code, sequence, diagram, backend]
updated: 2026-08-08
---

# C4: Code Diagram (Image Scanning Flow)

แผนภาพ C4 นี้แสดงลำดับขั้นตอนการทำงานของกระบวนการวิเคราะห์รูปภาพ (Image Scanning) ภายใน Backend ของระบบ Scam Image Detection ซึ่งครอบคลุมตั้งแต่การรับ Request จากผู้ใช้ ไปจนถึงการจัดเก็บผลลัพธ์ลงฐานข้อมูล

```mermaid
sequenceDiagram
    autonumber
    
    actor Client as Mobile App
    participant Router as ScanRouter
    participant Service as ScanService
    participant Utils as ImageUtils
    participant FS as Local Storage
    participant Inference as InferenceService
    participant ONNX as ONNX Worker
    participant OCR as Surya OCR
    participant RiskCalc as RiskCalculator
    participant DB as PostgreSQL

    Client->>Router: POST /api/v1/scan (Multipart)
    
    activate Router
    Router->>Service: analyze_image(file, user_id, db)
    
    activate Service
    Note over Service: 1. อ่านไฟล์เป็น Bytes<br>และเช็คขนาดไฟล์ (Max MB)
    
    Service->>Utils: load_image_verified
    Utils-->>Service: PIL Image, EXIF Data
    
    Service->>Utils: encode_lossless_png
    Utils-->>Service: PNG Bytes
    
    Service->>FS: Save {hash}.png (เป็นหลักฐานรูปต้นฉบับ)
    FS-->>Service: Success
    
    Note over Service: ส่งงานให้ AI แบบแยกโปรเซส<br>เพื่อไม่บล็อก Event Loop
    Service->>Inference: predict(png_bytes)
    
    activate Inference
    
    %% SegFormer Processing
    Inference->>ONNX: ส่งภาพเพื่อประมวลผล
    activate ONNX
    Note over ONNX: ประมวลผล Semantic Segmentation<br>ด้วยโมเดล ONNX
    ONNX-->>Inference: JSON (visual_risk, heatmap)
    deactivate ONNX
    
    %% OCR Processing
    Inference->>OCR: สกัดข้อความไทย/อังกฤษ
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
    Note over RiskCalc: Hybrid Worst-Case<br>Max-Impact + Multi-factor
    RiskCalc-->>Service: return {total_risk_score, grade}
    deactivate RiskCalc
    
    %% DB Persistence
    Service->>DB: บันทึกผลการสแกน
    activate DB
    DB-->>Service: new_scan_record
    deactivate DB
    
    Service-->>Router: return new_scan
    deactivate Service
    
    Router-->>Client: 200 OK (ScanResponse JSON)
    deactivate Router
```

---

## คำอธิบายการทำงาน (Details)

แผนภาพนี้แสดงการทำงานของฟังก์ชันหลัก `analyze_image` ภายใน ScanService ซึ่งแสดงให้เห็นถึงการทำงานแบบ Non-blocking และวิธีการที่ Backend สื่อสารกับ AI

### 1. API Layer (ScanRouter)
**หน้าที่:** ตรวจสอบสิทธิ์ผู้ใช้งาน และรับไฟล์รูปแบบ Multipart Form Data จากนั้นส่งต่อให้ Service ประมวลผล

### 2. Business Logic Layer (ScanService)
**หน้าที่:** 
    1.  ตรวจสอบความปลอดภัยของไฟล์ (ขนาดไฟล์ และการแปลงเป็นภาพ Lossless PNG ป้องกันมัลแวร์แฝง)
    2.  สร้าง Hash จากไฟล์ต้นฉบับเพื่อใช้ตั้งชื่อไฟล์ (Deduplication)
    3.  เรียกงานประมวลผลหนัก (AI และ Image Processing) ใน worker แยก เพื่อไม่ให้ Event Loop ของ API ถูกบล็อก
    4.  วิเคราะห์คำหลอกลวงเบื้องต้นจากผลลัพธ์ OCR ด้วย scam keywords
    5.  บันทึกผลสู่ฐานข้อมูล

### 3. AI Integration Layer (InferenceService)
**หน้าที่:** ทำงานประสาน AI โมเดลทั้ง 2 ตัว
    *   **ONNX Worker (SegFormer):** รันในโปรเซสแยกต่างหาก (AI Workload Isolation) เพื่อแยกการจัดการทรัพยากรและหน่วยความจำของฝั่ง AI ออกจาก Web Server หลัก
    *   **Surya OCR:** โมเดลจะถูกเตรียมพร้อมไว้ในหน่วยความจำหลักตั้งแต่ระบบเริ่มทำงาน เพื่อให้สามารถประมวลผลข้อความจากรูปภาพได้ทันทีโดยไม่ต้องเสียเวลาโหลดโมเดลใหม่ ช่วยลดความหน่วง (Latency) ในการตอบสนอง 

### 4. Utility & Calculation
*   **โมดูล:** RiskCalculator
*   **หน้าที่:** รับค่าตัวเลขคะแนนดิบเข้าไปคำนวณตามสูตร Hybrid max+bonus และส่งค่าความเสี่ยงรวม (Total Risk) กลับมา
