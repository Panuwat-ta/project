# เอกสารสรุปการทำงานของระบบเซิร์ฟเวอร์ (Server Documentation)
## โครงงาน: แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Scam Image Detection)

เอกสารฉบับนี้อธิบายถึงภาพรวม หน้าที่หลัก และองค์ประกอบของระบบหลังบ้าน (Backend Server) เพื่อให้นักพัฒนาและผู้เกี่ยวข้องเข้าใจขอบเขตการทำงานของเซิร์ฟเวอร์ในโครงงานนี้

---

## 1. ภาพรวมของเซิร์ฟเวอร์ (Server Overview)

เซิร์ฟเวอร์ในระบบทำหน้าที่เป็น **API Gateway และ Core Orchestrator** ควบคุมและประสานงานกระบวนการทำงานทั้งหมด ตั้งแต่การรับข้อมูลจากแอปพลิเคชันมือถือ การตรวจสอบความปลอดภัย การจัดการข้อมูลในฐานข้อมูล ไปจนถึงการส่งคำสั่งให้ AI ประมวลผลรูปภาพ เซิร์ฟเวอร์ถูกออกแบบมาให้มีความปลอดภัยและรองรับการทำงานที่รวดเร็ว

---

## 2. เทคโนโลยีหลักที่ใช้ (Technology Stack)

* **ภาษาการเขียนโปรแกรม:** Python 3.10+
* **เว็บเฟรมเวิร์ก (Web Framework):** FastAPI (มีความรวดเร็วสูงและรองรับ Asynchronous)
* **ระบบฐานข้อมูล (Database):** PostgreSQL (ใช้ SQLAlchemy เป็น ORM ในการจัดการ Schema)
* **ระบบแคช (Caching):** Redis (สำหรับเก็บผลลัพธ์รูปภาพที่มีคนสแกนซ้ำเพื่อลดเวลาประมวลผล)
* **การจัดการไฟล์ (Storage):** code v1 ใช้ Local Storage สำหรับรูปต้นฉบับและ Heatmap (`LOCAL_UPLOAD_DIR`, default `./uploads`) และ FastAPI static mount `/uploads`; Cloud Object Storage เป็น future deployment option
* **สถาปัตยกรรมการรัน AI:** ONNX Runtime ผ่าน worker subprocess ภายใน FastAPI application เดียว (ไม่ใช่ microservice แยก deploy)

---

## 3. หน้าที่หลักของเซิร์ฟเวอร์ (Core Responsibilities)

ระบบหลังบ้านแบ่งความรับผิดชอบหลักออกเป็น 3 ส่วน ได้แก่:

### 3.1 การยืนยันตัวตนและการจัดการสิทธิ์ (Authentication & RBAC)
* ใช้ **JWT (JSON Web Token)** ในการยืนยันตัวตนเมื่อมีการร้องขอ API
* บัญชี Mobile เก็บในตาราง `users` และมี role `user` หรือ `researcher`
* บัญชี Admin Portal เก็บในตาราง `admins` แยกจาก `users` และใช้ `admin_sessions`; ทุก Admin endpoint ตรวจ admin session/`is_superadmin`

### 3.2 การจัดการและตรวจสอบรูปภาพ (Image Processing & Validation)
* ตรวจสอบชนิดไฟล์ (client ประกาศ JPG/PNG/WebP; server verify ด้วยการ decode จริง ไม่เชื่อ content-type), ขนาดไฟล์ (server ปฏิเสธ > 20MB ด้วย 413, decode ≤ 100M px — รายละเอียดดู `design/server.md` มติ DOC-03)
* แปลงไฟล์รูปภาพเป็นค่า Hash (SHA-256) เพื่อใช้ค้นหาในแคช (Redis)
* code v1 เก็บไฟล์ใน `LOCAL_UPLOAD_DIR` (default `./uploads`) และเสิร์ฟด้วย FastAPI static mount `/uploads`; ยังไม่มี Presigned URL หรือ Cloud Object Storage

### 3.3 การประสานงานกับ AI Inference Pipeline
* ทำการดึงข้อมูล EXIF จากภาพ เช่น รุ่นกล้อง, ซอฟต์แวร์ที่แต่งภาพ, พิกัด 
* ส่งต่อภาพไปให้ **AI Inference Service** เพื่อ:
  - สกัดข้อความด้วย Surya-OCR และค้นหาคำหลอกลวง (Scam Keywords)
  - วิเคราะห์จุดดัดแปลงพิกเซล (Visual Forgery) ด้วย SegFormer (ผ่าน ONNX Worker)
* รวบรวมคะแนนความเสี่ยงทั้งหมด (Total Risk Score) แล้วส่งผลลัพธ์กลับไปยังโมบายแอป

---

## 4. โครงสร้างข้อมูลที่จัดเก็บ (Data Management)

ข้อมูลที่เซิร์ฟเวอร์เก็บรักษาประกอบด้วย:
1. **บัญชีผู้ใช้และผู้ดูแล:** `users` เก็บบัญชี Mobile (`user`/`researcher`); `admins` เก็บบัญชี Admin Portal แยกกัน
2. **ประวัติการสแกน (Scans):** วันเวลาที่สแกน, รูปต้นฉบับ, รูป Heatmap, ผลคะแนนความเสี่ยงแต่ละด้าน
3. **ประวัติการยินยอม (Consent Logs):** การยินยอม PDPA หรือการให้นำข้อมูลไปใช้วิจัย
4. **รายงานสแกมเมอร์ (Scam Reports):** ประวัติที่ผู้ใช้กดรายงานเข้ามาเพื่อแจ้งว่าเป็นภาพหลอกลวง

---

## 5. สรุปเส้นทาง API (API Endpoints Overview)

กลุ่ม API หลักที่เปิดให้บริการ ได้แก่:

* `POST /api/v1/auth/register` - ลงทะเบียนผู้ใช้
* `POST /api/v1/auth/login` - ล็อกอินเพื่อรับ JWT Token
* `POST /api/v1/scan/` - อัปโหลดรูปภาพเพื่อตรวจหาการหลอกลวง (multipart: `file` บังคับ + `title` ไม่บังคับ; async)
* `GET /api/v1/scan/{scan_id}` - ดูผลลัพธ์หรือ poll สถานะด้วย UUID ของ scan
* `POST /api/v1/reports` - ส่งรายงานรูปภาพหลอกลวง
* `POST /api/v1/admin/train` - แอดมินสั่งเทรนโมเดลเพิ่มเติม (Incremental Training)

---

## 6. แหล่งอ้างอิงเอกสารการออกแบบเชิงลึก (Design References)

เอกสารฉบับนี้เป็นเพียงการสรุปภาพรวม หากต้องการดูสถาปัตยกรรมการออกแบบระดับลึก โครงสร้างโค้ด และตารางฐานข้อมูล สามารถดูได้ที่:
* **[การออกแบบสถาปัตยกรรมระบบหลังบ้าน (Backend Design)](../../design/server.md)** 
* **[การออกแบบการเทรนโมเดลและ AI (Model & AI Design)](../../design/model.md)**
