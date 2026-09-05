# Master Test Plan & Strategy: ScamGuard System

- **Project**: ScamGuard (Scam Image Detection System)
- **Standard**: ISO/IEC/IEEE 29119-3 (Software Testing Documentation)
- **Version**: 1.0.0
- **Author**: Senior Software Tester / Lead QA Engineer
- **Status**: Approved Baseline

---

## 1. บทนำและวัตถุประสงค์ (Introduction & Objectives)

### 1.1 วัตถุประสงค์ของเอกสาร (Purpose)
เอกสารฉบับนี้กำหนดกรอบแผนแม่บทการทดสอบ (Master Test Plan) และกลยุทธ์การประกันคุณภาพ (Quality Assurance Strategy) สำหรับระบบ **ScamGuard** เพื่อให้มั่นใจว่าระบบสามารถตรวจจับ วิเคราะห์ และรายงานภาพที่มีการดัดแปลงหรือเกี่ยวข้องกับภัยหลอกลวง (Scam-related images) ได้อย่างถูกต้อง แม่นยำ ปลอดภัย และมีประสิทธิภาพสูงสุดตามข้อกำหนดใน Software Requirements Specification (SRS)

### 1.2 วัตถุประสงค์ด้านคุณภาพ (Quality Objectives)
1. **ความถูกต้องแม่นยำ (Accuracy & Detection Precision)**:
   - ตรวจจับพิกเซลที่ถูกตัดต่อหรือดัดแปลงด้วย SegFormer Semantic Segmentation พร้อมสร้าง Heatmap ความละเอียดสูง
   - สกัดข้อความภาษาไทยและภาษาอังกฤษด้วย Surya OCR อย่างแม่นยำ
   - ให้คำอธิบายเชิงเหตุผลด้วย Qwen2.5-1.5B ที่สอดคล้องกับพิกเซลและข้อความจริง
2. **การจำแนกระดับความเสี่ยง (Risk Scoring Integrity)**:
   - จำแนกคะแนนความเสี่ยงอย่างเที่ยงตรงตามเกณฑ์ 3 ระดับ: Low (0-39), Medium (40-69), High (70-100) ปราศจากระดับ Safe
3. **ประสิทธิภาพและความพร้อมใช้งาน (Performance & Latency)**:
   - ประมวลผลการสแกนภาพทั่วไปแล้วเสร็จภายในเวลาไม่เกิน 3 วินาที (Scan Latency < 3s)
   - เร่งความเร็วการตอบกลับเมื่อภาพซ้ำด้วย Redis Caching (Image Hash Hit < 200ms)
4. **ความปลอดภัยและการปกป้องข้อมูล (Security & PDPA)**:
   - ปราศจากฮาร์ดโค้ด Credentials/Keys โดยโหลดจาก Environment Variables ทั้งหมด
   - ป้องกันช่องโหว่ OWASP Top 10 และตรวจสอบความถูกต้องของไฟล์รูปภาพอย่างเข้มงวด

---

## 2. ขอบเขตการทดสอบ (Test Scope)

### 2.1 ขอบเขตที่ครอบคลุม (In-Scope)
- **Mobile Application (Flutter)**:
  - Clean Architecture & BLoC/Cubit State Management
  - การลงทะเบียน ล็อกอิน และจัดการ Session Token
  - การเลือกรูปภาพจาก Gallery และการถ่ายภาพผ่าน Camera
  - Client-side File Validation (ขนาดไฟล์ไม่เกิน 10MB, นามสกุล PNG, JPG, WEBP)
  - หน้าแสดงผลคะแนนความเสี่ยงพร้อม Heatmap Overlay Interaction (เปิด/ปิด, ปรับ Opacity)
  - ประวัติการสแกนย้อนหลัง (Recent History, Thumbnails, Tap Navigation, Offline Cache Fallback)
  - การสลับภาษา (Localization ภาษาไทยและอังกฤษ) และ Dark/Light Mode
- **Backend API & Database (FastAPI & PostgreSQL)**:
  - Authentication Endpoints (`/api/v1/auth/*`)
  - Image Scan Endpoint (`POST /api/v1/scan/`) พร้อม Multipart Upload
  - Magic Bytes Validation และ Image File Sanitization
  - Redis Caching Mechanism (SHA-256 `image_hash`)
  - Slowapi Rate Limiting Middleware และ CORS Origin Filtering
  - Admin Endpoints (`/api/v1/admin/*`) พร้อมการแยกสิทธิ์ Role-Based Access Control
  - Model Version Registry (Deploy, Rollback พร้อม Database Row Lock)
  - Audit Logging ลงตาราง `audit_logs` พร้อม Structured JSON
  - Timezone UTC+7 (Asia/Bangkok) และ Database Cascades
- **AI Inference Pipeline**:
  - Overlapping Tiling Inference (Patch 512x512, Overlap 64px, Probability Weight Averaging)
  - Full-Resolution Heatmap Reconstruction
  - Surya OCR Engine สำหรับภาษาไทยและภาษาอังกฤษ
  - XAI Reasoning Pipeline (Qwen2.5-1.5B)
  - Hybrid Worst-Case Risk Scoring Formula
  - Subprocess Isolation (`onnx_worker.py`)
- **Admin Portal (React / Vite)**:
  - Admin Authentication และ Token Refresh
  - Dashboard KPIs, Real-time WebSocket Telemetry
  - Model Version Management พร้อม Modal ยืนยัน Deploy/Rollback
  - Report Moderation Flow พร้อม Optimistic Concurrency Control (`version` column)
  - User Management และการระงับการใช้งาน (Ban with Reason)
  - Audit Log Diff Viewer และ UI Accessibility (WCAG AA Contrast)
- **Non-Functional Testing**:
  - Performance Testing ด้วย Locust (50 - 200 Concurrent Users)
  - Security Testing (OWASP Top 10, File Upload Tampering, IDOR)
  - Privacy & PDPA Compliance

### 2.2 ขอบเขตนอกการทดสอบ (Out-of-Scope)
- การทดสอบการเชื่อมต่อกับ Payment Gateway ภายนอก (ระบบไม่มีธุรกรรมการเงิน)
- การทดสอบฮาร์ดแวร์ Physical GPU ในระดับชิปเซ็ต (ทดสอบเฉพาะระดับ Driver / CUDA Container API)
- การทดสอบบนระบบปฏิบัติการที่ไม่อยู่ในขอบเขต v1 (โครงการรุ่นแรกมุ่งเน้นเฉพาะระบบปฏิบัติการ Android เท่านั้น โดยระบบปฏิบัติการ iOS ถูกจัดอยู่นอกขอบเขต และเป็นแผนการพัฒนาในอนาคต - Future Release ตามข้อกำหนดโครงการ)

---

## 3. กลยุทธ์และระดับการทดสอบ (Testing Strategy & Levels)

ระบบ ScamGuard ใช้การทดสอบตามโมเดล **Agile Test Pyramid**:

```text
               / \
              /   \
             / E2E \             <-- System Integration & User Journeys (tests_all/manual_tests/test_cases_e2e.md)
            /-------\
           /   API   \           <-- Backend Integration & Security (tests_all/automate_tests/tests/api/)
          / Integration\
         /--------------\
        /  Unit & Logic  \       <-- BLoC States, Helpers, DTOs, Risk Formula (Pytest & Flutter Test)
       /------------------\
```

### 3.1 Unit & Logic Testing
- **Backend & AI Logic**: ทดสอบการคำนวณสูตรคะแนนความเสี่ยง (Hybrid Worst-Case Scoring Formula), Data Validation (Pydantic), Image Preprocessing และ Helper Functions ใน `server/tests/`
- **Mobile**: ทดสอบ Model Serialization, BLoC State Emits และ Utility Classes ใน `scam_image_mobile/test/`

### 3.2 Integration Testing
- **API Integration**: ทดสอบการทำงานร่วมกันระหว่าง API Router, Services, PostgreSQL Database และ Redis ใน `tests_all/automate_tests/tests/api/`
- **AI Pipeline Integration**: ทดสอบการส่งภาพผ่าน `scan_service.py` ไปยัง Subprocess `onnx_worker.py` และการประกอบ Heatmap

### 3.3 System & End-to-End Testing
- ทดสอบ User Journey เต็มรูปแบบ ตั้งแต่การถ่ายภาพบน Mobile ส่งผ่าน Gateway ประมวลผลบน AI และแสดงผลลัพธ์บนมือถือ พร้อมการตรวจสอบข้อมูลย้อนหลังจาก Admin Portal

### 3.4 Non-Functional Testing
- **Performance**: ยิงโหลดทดสอบ Throughput และ Latency ด้วย Locust
- **Security**: ทดสอบ Payload อันตราย, MIME Spoofing, Magic Byte Tampering, SQL Injection และ Broken Object Level Auth

---

## 4. สภาพแวดล้อมการทดสอบ (Test Environment)

| สภาพแวดล้อม | รายละเอียดและคอมโพเนนต์ | คอนฟิกูเรชัน / พอร์ต |
|---|---|---|
| **Database Container** | PostgreSQL 15 (Alpine) | Port 5432, TZ=Asia/Bangkok, Shared Volume |
| **Cache Container** | Redis 7 (Alpine) | Port 6379, Caching Image Hash SHA-256 |
| **Backend API Node** | FastAPI (Python 3.10+ Virtual Environment) | Port 8000, Uvicorn Workers, Slowapi Limiter |
| **Admin Portal Node** | React 18, Vite, Tailwind CSS | Port 5173, Vite Proxy to Backend |
| **Mobile Test Bed** | Android Physical Devices (Pixel 6, Galaxy S21) / Android Emulator (API 33, 34) | Flutter SDK 3.x, Local Network Bridge |
| **AI Inference Node** | ONNX Runtime (CPU / CUDA), PyTorch for Surya OCR | Subprocess Worker, Model Cache in `model/` |

---

## 5. เกณฑ์การเริ่ม ระงับ และสิ้นสุดการทดสอบ (Test Criteria)

### 5.1 เกณฑ์การเริ่มทดสอบ (Entry Criteria)
1. Environment ทั้งหมด (PostgreSQL, Redis, Backend API, Admin Portal) ทำงานอยู่ในสถานะ Healthy
2. ซอร์สโค้ดผ่านการ Build และ Lint โดยไม่มีข้อผิดพลาด (Zero Compiler/Linter Errors)
3. ฐานข้อมูลผ่านการรัน Alembic Migration ล่าสุด (`alembic upgrade head`)
4. คอนฟิกูเรชันทั้งหมดโหลดจาก `.env` สำเร็จ ปราศจากฮาร์ดโค้ดคีย์

### 5.2 เกณฑ์การระงับและเริ่มใหม่ (Suspension & Resumption Criteria)
- **Suspension Criteria**:
  - ระบบ Backend ไม่สามารถเชื่อมต่อกับ Database หรือ Redis ได้ (Database Crash)
  - เกิด Fatal Crash หรือ CUDA Out-Of-Memory ใน Subprocess AI Pipeline ระหว่างการสแกนภาพ
  - พบข้อบกพร่องระดับ P0 (Blocker) ที่ทำให้ไม่สามารถดำเนินกระบวนการหลักของระบบได้
- **Resumption Criteria**:
  - ทีมพัฒนาแก้ไขปัญหาและมี Hotfix พร้อมผ่านการ Smoke Test เบื้องต้น
  - นำชุดทดสอบที่ล้มเหลวมารันซ้ำจนกระทั่งผ่านเกณฑ์

### 5.3 เกณฑ์การสิ้นสุดและส่งมอบงาน (Exit Criteria / Definition of Done)
1. 100% ของ Test Cases ระดับ P0 (Blocker) และ P1 (High) ผ่านการทดสอบทั้งหมด (Pass Rate = 100%)
2. อัตราการผ่านของ Test Cases ระดับ P2 (Medium) ไม่ต่ำกว่า 95%
3. ไม่มีข้อบกพร่องระดับ Critical หรือ Major ที่ยังค้างอยู่ในระบบ (0 Open Critical Bugs)
4. การทดสอบโหลดด้วย Locust ยืนยันว่า Response Time เฉลี่ยของการสแกนภาพต่ำกว่า 3 วินาที
5. เอกสารตารางสอบย้อนกลับ (RTM) ครอบคลุมความต้องการ FR-01 ถึง FR-18 และ NFR-01 ถึง NFR-10 ครบถ้วน 100%

---

## 6. การประเมินความเสี่ยงและแผนบรรเทา (Risk Assessment & Mitigation Matrix)

| ความเสี่ยง (Risk Description) | ระดับผลกระทบ | โอกาสเกิด | แผนบรรเทาความเสี่ยง (Mitigation Plan) |
|---|---|---|---|
| **AI Subprocess Crash / Memory Leak** | สูงมาก | ปานกลาง | ใช้การแยก Subprocess Isolation ใน `onnx_worker.py` เพื่อจำกัดหน่วยความจำและเริ่มโพรเซสใหม่ทันทีเมื่อเกิดข้อผิดพลาด |
| **False Positive / Negative อัตราสูง** | สูง | ปานกลาง | ใช้สูตร Hybrid Worst-Case Scoring ร่วมกับการวิเคราะห์หลายชั้น (Multi-layer) เพื่อป้องกันการตัดสินใจผิดพลาด |
| **การอัปโหลดไฟล์ขนาดใหญ่ทำให้เน็ตเวิร์กตัน** | ปานกลาง | สูง | มีการจำกัดขนาดไฟล์ที่ Client (10MB) ก่อนอัปโหลด และมี Stream Reading บน FastAPI พร้อม Timeout |
| **Admin แย่งกันแก้ไขสถานะรายงานพร้อมกัน** | ปานกลาง | ปานกลาง | ใช้ Optimistic Concurrency Control ผ่านคอลัมน์ `version` ในตาราง `scam_reports` เพื่อป้องกัน Race Condition |
| **ความไม่สอดคล้องของเวลาใน Audit Log** | ปานกลาง | ต่ำ | บังคับเขตเวลาเป็น `Asia/Bangkok` (UTC+7) ทั้งใน Docker Database, Server App และ Client UI |

---

## 7. กระบวนการจัดการข้อบกพร่อง (Defect Management Lifecycle)

### 7.1 ระดับความรุนแรงของข้อบกพร่อง (Severity Levels)
- **Critical (วิกฤต)**: ระบบแครช, ข้อมูลสูญหาย, ความปลอดภัยรั่วไหล, ไม่สามารถสแกนภาพได้เลย
- **Major (รุนแรง)**: ฟังก์ชันหลักทำงานผิดพลาด เช่น Heatmap แสดงพิกเซลผิดตำแหน่ง, คำนวณคะแนนความเสี่ยงผิดช่วงระดับ
- **Medium (ปานกลาง)**: ปัญหาการแสดงผล UI บิดเบี้ยว, ปัญหาการสลับภาษาบางจุด, การกรองรายงานไม่ตรงเงื่อนไข
- **Minor (เล็กน้อย)**: ปัญหาการสะกดคำ, ความคลาดเคลื่อนของสีคอนทราสต์เล็กน้อยที่ไม่กระทบการใช้งานหลัก

### 7.2 ลำดับความสำคัญในการแก้ไข (Priority Levels)
- **P0 (Blocker)**: ต้องแก้ไขทันที หยุดการปล่อยเวอร์ชัน
- **P1 (High)**: ต้องแก้ไขก่อนปล่อยเวอร์ชันสู่ผู้ใช้งาน
- **P2 (Medium)**: สามารถจัดเข้าคิวแก้ไขใน Sprint ถัดไป
- **P3 (Low)**: แก้ไขเมื่อมีเวลาว่างหรือรอบปรับปรุงความประณีต

### 7.3 วงจรชีวิตของ Bug (Bug Lifecycle)
```text
[New] ---> [Assigned] ---> [In Progress] ---> [Resolved] ---> [Verified] ---> [Closed]
                                 |                                 |
                                 v                                 v
                             [Rejected]                       [Reopened]
```
