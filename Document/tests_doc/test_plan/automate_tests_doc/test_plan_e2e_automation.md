# แผนการทดสอบอัตโนมัติ: การทดสอบข้ามระบบครบวงจร (End-to-End Automation Test Plan)

- **System / Component**: ScamGuard Integrated Ecosystem (Client-Backend-Worker Bridge)
- **Framework**: Pytest, Asyncio, HTTPX, Mobile Contract Bridge
- **Execution Scripts**: `tests_all/automate_tests/run.sh e2e` และ `tests_all/automate_tests/run.sh mobile`
- **Document Version**: 1.0.0
- **Status**: Approved

---

## 1. วัตถุประสงค์และภาพรวมสถาปัตยกรรม (Objectives & Architecture)

การทดสอบแบบ End-to-End Automation มีเป้าหมายเพื่อจำลองพฤติกรรมจริงของผู้ใช้งานตั้งแต่ต้นจนจบโฟลว โดยตรวจสอบความสอดคล้องของการเชื่อมต่อระหว่างคอมโพเนนต์ต่างๆ ที่ทำงานร่วมกันในระบบนิเวศของ ScamGuard

```text
+-------------------+      Multipart Scan      +-------------------+
|  Mobile Client /  | -----------------------> |  FastAPI Backend  |
|  Synthetic Tester |                          +-------------------+
+-------------------+                                    |
          ^                                              | Subprocess / IPC
          | JSON Result & Heatmap                        v
          |                                    +-------------------+
          +----------------------------------- | AI Inference Pipe |
                                               | (SegFormer, Surya)|
                                               +-------------------+
```

---

## 2. ขอบเขตและสคริปต์การทดสอบ (Test Scripts & Scope)

### 2.1 Full User Journey (`test_e2e_scam_flow.py`)
- **โฟลวการทำงาน**:
  1. `Register & Login`: สร้างบัญชีใหม่และรับ JWT Access Token
  2. `Scan Submission`: อัปโหลดภาพเสมือนพร้อมพารามิเตอร์ Multipart
  3. `Polling & Result Verification`: ดึงผลการสแกนผ่าน `GET /api/v1/scan/{scan_id}` ยืนยันว่าได้ผลลัพธ์สมบูรณ์
  4. `History Verification`: เรียกดู `GET /api/v1/history/` และยืนยันว่าพบรายการที่เพิ่งส่งไป
  5. `Session Persistence`: ตรวจสอบความถูกต้องของสิทธิ์ผ่าน `GET /api/v1/auth/me`
- **คำสั่งรัน**:
  ```bash
  cd /home/panuwat/project/tests_all/automate_tests
  ./run.sh e2e
  ```

### 2.2 Mobile Contract & API Bridge (`test_mobile_bridge.py`)
- **วัตถุประสงค์**: ป้องกันปัญหา API Drift หรือ Schema Mismatch ระหว่างแอปพลิเคชันมือถือ (Flutter) กับ FastAPI Backend
- **สิ่งที่ตรวจสอบ**:
  1. ค่า Base URL และ Endpoints ในโค้ด Dart (`scam_image_mobile/lib/core/network/api_endpoints.dart`) สอดคล้องกับเส้นทาง API ใน Backend
  2. รูปแบบ Payload ใน Model Dart (เช่น `ScanResultModel`) มีฟิลด์ตรงตาม JSON Response ที่ Backend คืนค่ากลับมา (เช่น `risk_score`, `risk_level`, `visual_anomalies`, `explanation`)
  3. ช่วงค่า Risk Level ของ Dart Helper ตรงกับสเกล 3 ระดับ (Low: 0-39, Medium: 40-69, High: 70-100)
- **คำสั่งรัน**:
  ```bash
  cd /home/panuwat/project/tests_all/automate_tests
  ./run.sh mobile
  ```

---

## 3. สภาพแวดล้อมและข้อกำหนดก่อนรัน (Pre-requisites)
1. Backend Service ต้องเปิดทำงานอยู่ที่ `http://localhost:8000` (หรือพอร์ตที่กำหนดใน `.env`)
2. ฐานข้อมูล PostgreSQL และ Redis ต้องทำงานปกติ
3. โฟลเดอร์ `scam_image_mobile/` ต้องมีโค้ด Dart ที่คอมไพล์ได้และไม่มี Syntax Error

---

## 4. การวินิจฉัยข้อผิดพลาด (Failure Diagnosis)
- หากเกิดข้อผิดพลาดในขั้นตอน Polling: ให้ตรวจสอบ Worker Logs ใน `server/` เพื่อดูว่าเกิด GPU/CPU Subprocess Exception หรือไม่
- หากเกิดข้อผิดพลาดในขั้นตอน Mobile Bridge: ให้ตรวจสอบว่ามีการเพิ่มหรือลบฟิลด์ใน Pydantic Schema โดยยังไม่ได้ปรับโค้ด Model ฝั่ง Flutter หรือไม่
