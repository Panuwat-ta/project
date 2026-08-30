# Requirement Candidates

**Project Name:** แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Scam Image Detection)  
**Version:** 1.0  
**Date:** August 23, 2026

---

## 1. Introduction

เอกสาร Requirement Candidates (RC) ฉบับนี้รวบรวม **ความต้องการที่รวบรวมได้จากหลักฐาน (Evidence-Based Requirements)** ก่อนที่จะถูกจัดรูปแบบเป็น Functional Requirements (FR) และ Non-Functional Requirements (NFR) ในเอกสาร 05_Software_Requirement_Specification.md

Requirement Candidates ถูกสกัดจาก:
- เอกสารวัตถุประสงค์ (objective.md)
- เอกสารขอบเขต (scop.md)
- เอกสาร SRS หลัก (srs-doc.md, srs-se02.md)
- เอกสาร Design (design/*.md)
- เอกสาร Architecture (Software Architecture/*.md)

**หมายเหตุสำคัญ:**  
ตามหลักการ Evidence-Based Requirement Engineering:
- **RC ≠ FR/NFR** — RC คือความต้องการที่รวบรวมได้ ยังไม่ผ่านการจัดรูปแบบและกำหนด Acceptance Criteria
- **ทุก RC ต้องมี Evidence** — ต้องระบุแหล่งที่มา (Source File + Section)
- **ไม่มีการสร้างข้อมูลขึ้นเอง** — หากไม่มีหลักฐาน ให้ใช้ [TODO] หรือ [CONFLICT]

---

## 2. Requirement Candidates by Category

### 2.1 Authentication & Authorization (RC-AUTH)

#### RC-AUTH-01: การสมัครสมาชิก
**Description:** ผู้ใช้ต้องสามารถสมัครสมาชิกด้วย Email และ Password พร้อมยืนยันเงื่อนไขการใช้งาน  
**Source:** srs-doc.md, Section: 4.1 บัญชีและความยินยอม, FR-AUTH-001  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- ผู้ใช้กรอก Full Name, Email, Password
- ระบบตรวจสอบรูปแบบอีเมล (Format Validation)
- ระบบปฏิเสธอีเมลซ้ำ (Unique Email)
- ระบบ Hash รหัสผ่านก่อนบันทึก (bcrypt, cost factor: 12)
- ผู้ใช้ต้องยอมรับ System Consent (บังคับ) และ Research Consent (ไม่บังคับ)
- บันทึก Consent เป็น Audit Record พร้อม Timestamp

---

#### RC-AUTH-02: การเข้าสู่ระบบ
**Description:** ผู้ใช้ต้องสามารถเข้าสู่ระบบด้วย Email และ Password และรับ JWT Token  
**Source:** srs-doc.md, Section: FR-AUTH-002  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- รับ Email/Password ผ่าน OAuth2 Password Flow
- ออก Access Token (TTL: 15 นาที) และ Refresh Token (TTL: 7 วัน)
- ปฏิเสธบัญชีที่ status = inactive (HTTP 403)
- ปฏิเสธรหัสผ่านผิด (HTTP 401)
- Mobile App เก็บ Token ใน Secure Storage (Flutter Secure Storage)

---

#### RC-AUTH-03: การต่ออายุ Token
**Description:** ผู้ใช้ต้องสามารถต่ออายุ Access Token ด้วย Refresh Token  
**Source:** srs-doc.md, Section: FR-AUTH-002  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- รับ Refresh Token ที่ถูกต้องและยังไม่หมดอายุ
- ออก Access Token ใหม่
- ปฏิเสธ Refresh Token ที่หมดอายุหรือไม่ถูกต้อง (HTTP 401)

---

#### RC-AUTH-04: การออกจากระบบ
**Description:** ผู้ใช้ต้องสามารถออกจากระบบและลบ Token ที่เก็บไว้  
**Source:** srs-doc.md, Section: FR-AUTH-002  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- ลบ Access Token และ Refresh Token จาก Secure Storage
- ลบ Cache ที่มีข้อมูลส่วนบุคคล
- Redirect ไปหน้า Login

---

#### RC-AUTH-05: การกู้คืนรหัสผ่าน
**Description:** ผู้ใช้ต้องสามารถรีเซ็ตรหัสผ่านเมื่อลืม  
**Source:** scop.md, Section: SC01 — ระบบลงทะเบียนและยืนยันตัวตน  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Should

**Details:**
- วิธีการส่ง Reset Link: **Email OTP** (6 หลัก)
- TTL ของ OTP: **10 นาที**
- ผู้ใช้กรอก Email และได้รับ OTP ทาง Email
- ผู้ใช้กรอก OTP และรหัสผ่านใหม่
- OTP ใช้ได้ครั้งเดียว (One-Time Use)

---

#### RC-AUTH-06: Social Login (Google Login)
**Description:** ผู้ใช้ต้องสามารถเข้าสู่ระบบด้วย Google OAuth  
**Source:** scop.md, Section: SC01 — ระบบลงทะเบียนและยืนยันตัวตน  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Should

**Details:**
- รองรับ **Google Login เท่านั้น** (ไม่มี Apple ID)
- ผู้ใช้คลิกปุ่ม "เข้าสู่ระบบด้วย Google"
- ระบบเชื่อมต่อกับ Google OAuth 2.0
- ระบบสร้างหรืออัปเดตบัญชีจาก Google Profile (email, name, picture)
- บันทึก oauth_provider = "google" ในฐานข้อมูล
- ออก JWT Token กลับไปยังผู้ใช้

---

### 2.2 Image Upload & Scan (RC-SCAN)

#### RC-SCAN-01: การเลือกรูปภาพจาก Gallery
**Description:** ผู้ใช้ต้องสามารถเลือกรูปภาพจากคลังภาพ (Gallery) ของอุปกรณ์  
**Source:** scop.md, Section: SC01 — ระบบนำเข้ารูปภาพ  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- ผู้ใช้คลิกปุ่ม "เลือกรูปภาพ"
- ระบบเปิด Image Picker (Flutter image_picker package)
- ผู้ใช้เลือกรูปภาพจาก Gallery
- ระบบแสดงภาพที่เลือก (Preview)

---

#### RC-SCAN-02: การครอบตัดรูปภาพ
**Description:** ผู้ใช้ต้องสามารถครอบตัดรูปภาพ (Crop) ก่อนส่งตรวจสอบ  
**Source:** scop.md, Section: SC01 — ระบบนำเข้ารูปภาพ  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- ระบบแสดง Image Cropper (Flutter image_cropper package)
- ผู้ใช้ปรับขอบเขตการครอบตัด
- ผู้ใช้ยืนยันการครอบตัด
- ระบบแสดงภาพที่ครอบตัดแล้ว

---

#### RC-SCAN-03: การตรวจสอบขนาดและประเภทไฟล์
**Description:** ระบบต้องตรวจสอบประเภทและขนาดไฟล์ก่อนอัปโหลด  
**Source:** srs-doc.md, Section: 3.1 กฎทางธุรกิจ BUS-04, BUS-05  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01, SC02  
**Priority:** Must

**Details:**
- รองรับไฟล์: JPG/JPEG, PNG, WebP
- ขนาดไฟล์สูงสุด: 10 MB (Mobile App) / 20 MB (API)
- ขนาดภาพหลังถอดรหัส: สูงสุด 100 ล้านพิกเซล (10,000 × 10,000)
- ตรวจสอบ Magic Bytes ไม่เชื่อ Content-Type เพียงอย่างเดียว
- หากเกินขนาด ให้แจ้งเตือนผู้ใช้หรือบีบอัดอัตโนมัติ

---

#### RC-SCAN-04: การอัปโหลดรูปภาพเพื่อตรวจสอบ
**Description:** ผู้ใช้ต้องสามารถอัปโหลดรูปภาพไปยังเซิร์ฟเวอร์เพื่อตรวจสอบ  
**Source:** scop.md, Section: SC01 — ระบบนำเข้ารูปภาพ  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01, SC02  
**Priority:** Must

**Details:**
- ผู้ใช้คลิกปุ่ม "ตรวจสอบความเสี่ยง"
- ระบบส่งรูปภาพไปยัง API (Multipart/form-data)
- ระบบแสดง Loading Screen พร้อมข้อความ "กำลังวิเคราะห์..."
- หากสำเร็จ ระบบแสดงผลการวิเคราะห์
- หากล้มเหลว ระบบแสดง Error Message

---

#### RC-SCAN-05: การตรวจสอบ Cache ก่อนวิเคราะห์
**Description:** ระบบต้องตรวจสอบว่ารูปภาพเคยถูกวิเคราะห์แล้วหรือไม่ (Cache Hit)  
**Source:** scop.md, Section: SC02 — งานพัฒนาฐานข้อมูลหลักและแคช  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-03, OBJ-04  
**Related Scope:** SC02  
**Priority:** Must

**Details:**
- คำนวณ Perceptual Hash (pHash) ของรูปภาพ
- ค้นหา pHash ใน Redis Cache
- หาก Cache Hit: ส่งผลลัพธ์เก่ากลับทันที (≤ 3 วินาที)
- หาก Cache Miss: ดำเนินการวิเคราะห์แบบเต็ม

---

### 2.3 Multi-layer Analysis (RC-ANALYSIS)

#### RC-ANALYSIS-01: Textual Analysis (OCR + NLP)
**Description:** ระบบต้องสกัดข้อความจากรูปภาพและตรวจจับคำสำคัญหลอกลวง  
**Source:** scop.md, Section: SC02 — งานพัฒนาโมดูลสกัดข้อความและการวิเคราะห์ประโยค; objective.md, OBJ-03  
**Related Stakeholder:** ST01, ST02  
**Related Objective:** OBJ-03  
**Related Scope:** SC02  
**Priority:** Must

**Details:**
- สกัดข้อความจากรูปภาพด้วย Surya-OCR (GGUF/Qwen2.5-VL)
- รองรับภาษาไทยและอังกฤษ
- ตรวจจับ Scam Keywords ด้วย RegEx และ NLP:
  - คำหลอกลวง: กู้เงินด่วน, ถอนยอด, โบนัสพิเศษ, ด่วน, รับเงิน, ลงทุน, แจกเงิน, รวยเร็ว
- คำนวณ Text Risk Score (0-100) จากจำนวนและความรุนแรงของคำหลอกลวง
- สูตร: `S_text = (keyword_count × severity_weight) / max_possible_score × 100`

---

#### RC-ANALYSIS-02: Visual Analysis (Image Forgery Detection)
**Description:** ระบบต้องตรวจจับการตัดต่อรูปภาพในระดับพิกเซล  
**Source:** scop.md, Section: SC03 — งานพัฒนาโมดูลตรวจสอบร่องรอยการดัดแปลงภาพ; objective.md, OBJ-02  
**Related Stakeholder:** ST01, ST02, ST03  
**Related Objective:** OBJ-02  
**Related Scope:** SC03  
**Priority:** Must

**Details:**
- ประมวลผล Error Level Analysis (ELA) Preprocessing
- รันโมเดล PSCC-Net + SegFormer เพื่อตรวจจับ:
  - Splicing (การสอดแทรกรูปภาพ)
  - Copy-Move (การคัดลอกและวาง)
  - Inpainting (การลบวัตถุ)
- เป้าหมายความแม่นยำ: Accuracy และ F1-Score ≥ 85%
- คำนวณ Forgery Confidence Score (0-100)

---

#### RC-ANALYSIS-03: AI-Generated Image Detection
**Description:** ระบบต้องตรวจจับภาพที่ถูกสร้างด้วย Generative AI  
**Source:** scop.md, Section: SC03 — งานพัฒนาโมดูลตรวจสอบภาพสังเคราะห์จากปัญญาประดิษฐ์; objective.md, OBJ-02  
**Related Stakeholder:** ST01, ST02, ST03  
**Related Objective:** OBJ-02  
**Related Scope:** SC03  
**Priority:** Must

**Details:**
- ตรวจจับ Artifacts จาก Generative AI (Stable Diffusion, Midjourney, DALL-E)
- วิเคราะห์ความผิดปกติทางฟิสิกส์:
  - ความไม่สมมาตรของใบหน้า
  - ข้อมือหรือนิ้วมือที่ผิดปกติ
  - พื้นหลังที่ไม่สอดคล้องกับแหล่งกำเนิดแสง
- คำนวณ AI-Gen Confidence Score (0-100)

---

#### RC-ANALYSIS-04: Visual Risk Score Calculation
**Description:** ระบบต้องคำนวณคะแนนความเสี่ยงทางภาพรวม  
**Source:** srs-doc.md, Section: 3.1 กฎทางธุรกิจ BUS-08; architecture.md, Multi-layer Analysis  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-02, OBJ-03  
**Related Scope:** SC03  
**Priority:** Must

**Details:**
- สูตร: `S_visual = (forgery_confidence × 0.6) + (ai_gen_confidence × 0.4)`
- ผลลัพธ์อยู่ในช่วง 0-100

---

#### RC-ANALYSIS-05: Source Analysis (Reverse Image Search)
**Description:** ระบบต้องค้นหาแหล่งที่มาของภาพบนอินเทอร์เน็ต  
**Source:** scop.md, Section: SC02 — งานพัฒนาสกัดข้อมูลแฝงและการค้นหาภาพย้อนกลับ; objective.md, OBJ-03  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-03  
**Related Scope:** SC02  
**Priority:** Must

**Details:**
- ส่งรูปภาพไป Google Vision API (Web Detection)
- รับรายการแหล่งที่มาที่คล้ายกัน (Similar URLs)
- วิเคราะห์บริบท:
  - จำนวนแหล่งที่พบ (> 10 แหล่ง = เสี่ยง)
  - ประเภทเว็บไซต์ (สื่อสังคมออนไลน์, เว็บข่าว, เว็บหลอกลวง)
  - ความเก่าของภาพ (ภาพเก่า > 1 ปี = เสี่ยง)
- คำนวณ Source Risk Score (0-100)
- สูตร: `S_source = (source_count_factor × 0.5) + (context_risk_factor × 0.5)`
- **Fallback Strategy:** เมื่อ Google Vision API Down → คืนค่า Neutral Score = 50, source_status = "unavailable"

---

#### RC-ANALYSIS-06: EXIF/Metadata Extraction
**Description:** ระบบต้องสกัดข้อมูล EXIF/GPS Metadata จากรูปภาพ  
**Source:** scop.md, Section: SC02 — งานพัฒนาสกัดข้อมูลแฝงและการค้นหาภาพย้อนกลับ  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-03  
**Related Scope:** SC02  
**Priority:** Should

**Details:**
- สกัดข้อมูล EXIF: Camera Model, Date Taken, GPS Coordinates, Software Used
- แสดงข้อมูล Metadata ในหน้าผลลัพธ์ (แบบ Read-Only)
- **ไม่ใช้ Metadata เพื่อคำนวณ Risk Score** — แสดงเพื่อให้ผู้ใช้พิจารณาเท่านั้น

---

#### RC-ANALYSIS-07: Weighted Risk Score Calculation
**Description:** ระบบต้องคำนวณคะแนนความเสี่ยงรวมจาก 3 ชั้นการวิเคราะห์  
**Source:** srs-doc.md, Section: 3.1 กฎทางธุรกิจ BUS-08; objective.md, OBJ-03  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-03  
**Related Scope:** SC02  
**Priority:** Must

**Details:**
- สูตร: `Risk Score = (S_text × 0.25) + (S_visual × 0.45) + (S_source × 0.30)`
- ปัดเศษเป็นจำนวนเต็ม
- จำกัดผลให้อยู่ในช่วง 0-100

---

#### RC-ANALYSIS-08: Risk Grade Mapping
**Description:** ระบบต้องแปลงคะแนนความเสี่ยงเป็นระดับความเสี่ยง (Risk Grade)  
**Source:** srs-doc.md, Section: 3.1 กฎทางธุรกิจ BUS-07  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-03  
**Related Scope:** SC02  
**Priority:** Must

**Details:**
- Low Risk (สีเขียว): 0-39
- Medium Risk (สีเหลือง): 40-69
- High Risk (สีแดง): 70-100
- **Special Rule:** หาก `visual_score ≥ 80` ให้ระดับเป็น High แม้คะแนนรวมต่ำกว่า 70

---

### 2.4 Explainability (RC-XAI)

#### RC-XAI-01: Grad-CAM Heatmap Generation
**Description:** ระบบต้องสร้างแผนที่ความร้อน (Grad-CAM Heatmap) เพื่ออธิบายผลการตัดสินใจของ AI  
**Source:** scop.md, Section: SC03 — งานพัฒนาเซอร์วิสประมวลผลและการอธิบายโมเดล; objective.md, OBJ-02, OBJ-04  
**Related Stakeholder:** ST01, ST03  
**Related Objective:** OBJ-02, OBJ-04  
**Related Scope:** SC03  
**Priority:** Must

**Details:**
- ใช้เทคนิค Gradient-weighted Class Activation Mapping (Grad-CAM)
- สร้างภาพ Heatmap ที่แสดงจุดพิกเซลที่มีความเสี่ยงสูง
- ใช้ Color Map: สีแดง (เสี่ยงสูง), สีเหลือง (เสี่ยงปานกลาง), สีเขียว (ปลอดภัย)
- บันทึก Heatmap เป็นไฟล์ภาพแยก (heatmap.jpg)
- อัปโหลดไปยัง Object Storage

---

#### RC-XAI-02: Heatmap Display
**Description:** ผู้ใช้ต้องสามารถดูแผนที่ความร้อนในแอปมือถือ  
**Source:** scop.md, Section: SC01 — ระบบแสดงผลความเสี่ยง; wiki/architecture/mobile-design.md (line 550); wiki/requirements/functional-requirements.md (FR-REPORT-03)  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-04  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- แสดงภาพต้นฉบับและภาพ Heatmap แบบ **Overlay** (ซ้อนทับ)
- **Toggle Button** เป็นตัวเลือกหลักสำหรับการสลับ On/Off Heatmap Layer
- **Opacity Slider** (แถบเลื่อนความโปร่งใส) สำหรับปรับความโปร่งแสงของ Heatmap (0-100%)
- ช่วยให้ผู้ใช้เทียบร่องรอยได้ชัดเจนที่สุด

---

#### RC-XAI-03: Risk Breakdown Display
**Description:** ผู้ใช้ต้องสามารถดูรายละเอียดคะแนนแต่ละชั้นการวิเคราะห์  
**Source:** scop.md, Section: SC01 — ระบบแสดงผลความเสี่ยง  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-04  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- แสดงคะแนนรวม (Weighted Risk Score) ในรูปแบบ Radial Gauge
- แสดงระดับความเสี่ยง (Low/Medium/High) พร้อมสีประกอบ
- แสดงรายละเอียดคะแนนแต่ละชั้น:
  - Text Risk Score: ผลตรวจสอบ OCR และคำสำคัญหลอกลวง
  - Visual Risk Score: ผลตรวจสอบการตัดต่อและภาพ AI-Generated
  - Source Risk Score: ผลตรวจสอบแหล่งที่มา
- แสดง OCR Text ที่สกัดได้
- แสดง Scam Keywords ที่พบ (Highlight)
- แสดงรายการแหล่งที่มาที่พบจาก Reverse Search

---

### 2.5 History & Reports (RC-HISTORY)

#### RC-HISTORY-01: แสดงประวัติการสแกน
**Description:** ผู้ใช้ต้องสามารถดูประวัติการสแกนย้อนหลัง  
**Source:** scop.md, Section: SC01 — ระบบจัดการประวัติและนโยบายความเป็นส่วนตัว  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- แสดงรายการประวัติการสแกน (List View)
- แสดง Thumbnail, วันที่, คะแนนความเสี่ยง, ระดับความเสี่ยง
- เรียงตามวันที่ล่าสุดก่อน (Descending Order)
- รองรับ Pagination หรือ Infinite Scroll

---

#### RC-HISTORY-02: ค้นหาและกรองประวัติ
**Description:** ผู้ใช้ต้องสามารถค้นหาและกรองประวัติการสแกน  
**Source:** scop.md, Section: SC01 — ระบบจัดการประวัติและนโยบายความเป็นส่วนตัว  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Should

**Details:**
- ค้นหาตามวันที่ (Date Range Picker)
- กรองตามระดับความเสี่ยง (Low/Medium/High)
- **ไม่รองรับการค้นหาตาม OCR Text** — เฉพาะกรองตามวันที่และระดับความเสี่ยง

---

#### RC-HISTORY-03: ลบประวัติทีละรายการ
**Description:** ผู้ใช้ต้องสามารถลบประวัติการสแกนทีละรายการ  
**Source:** scop.md, Section: SC01 — ระบบจัดการประวัติและนโยบายความเป็นส่วนตัว  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- ใช้ Slide to Delete Gesture
- แสดง Confirmation Dialog ก่อนลบ
- ลบข้อมูลจากฐานข้อมูลและ Object Storage
- **ลบ Heatmap ด้วย** — ลบทั้ง original.jpg และ heatmap.jpg

---

#### RC-HISTORY-04: ลบประวัติทั้งหมด
**Description:** ผู้ใช้ต้องสามารถลบประวัติการสแกนทั้งหมด  
**Source:** scop.md, Section: SC01 — ระบบจัดการประวัติและนโยบายความเป็นส่วนตัว  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Should

**Details:**
- แสดงปุ่ม "ลบประวัติทั้งหมด"
- แสดง Confirmation Dialog พร้อมคำเตือน "การกระทำนี้ไม่สามารถย้อนกลับได้"
- ผู้ใช้ต้องกด "ยืนยัน" 2 ครั้ง
- ลบข้อมูลทั้งหมดจากฐานข้อมูลและ Object Storage

---

#### RC-HISTORY-05: รายงานภาพหลอกลวง
**Description:** ผู้ใช้ต้องสามารถรายงานภาพที่เชื่อว่าเป็นภาพหลอกลวง  
**Source:** scop.md, Section: SC01 — ระบบรายงานและแชร์ข้อมูล; srs-doc.md, BUS-09  
**Related Stakeholder:** ST01, ST02  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- ผู้ใช้คลิกปุ่ม "รายงานภาพหลอกลวง" ในหน้าผลลัพธ์
- แสดงฟอร์มรายงาน:
  - หมวดหมู่: สลิปโอนเงินปลอม, รูปโปรไฟล์หลอกลวง, ภาพโฆษณาหลอกลวง, อื่นๆ
  - คำอธิบาย (อย่างน้อย 10 ตัวอักษร)
- ผู้ใช้ไม่สามารถรายงาน scan เดิมซ้ำ (BUS-09)
- บันทึกรายงานพร้อมสถานะ = "pending"

---

### 2.6 PDPA & Consent (RC-PDPA)

#### RC-PDPA-01: Consent Management (2-level)
**Description:** ระบบต้องรองรับการจัดการความยินยอม 2 ระดับ  
**Source:** scop.md, Section: SC01 — ระบบจัดการประวัติและนโยบายความเป็นส่วนตัว  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- **System Consent (บังคับ):** ยินยอมให้ระบบประมวลผลภาพเพื่อการวิเคราะห์
- **Research Consent (ไม่บังคับ):** ยินยอมให้นำข้อมูลไปใช้วิจัยและพัฒนาโมเดล
- ผู้ใช้สามารถถอน Research Consent ได้ตลอดเวลา
- บันทึก Consent เป็น Audit Record พร้อม Timestamp

---

#### RC-PDPA-02: Right to Access
**Description:** ผู้ใช้ต้องสามารถเข้าถึงข้อมูลส่วนตัวของตนเอง  
**Source:** srs-doc.md, NFR-06 — PDPA Compliance  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- ผู้ใช้สามารถดูข้อมูลบัญชี (Profile)
- ผู้ใช้สามารถดูประวัติการสแกนทั้งหมด
- ผู้ใช้สามารถดู Consent Logs

---

#### RC-PDPA-03: Right to Delete (Account & Data)
**Description:** ผู้ใช้ต้องสามารถลบข้อมูลส่วนตัวและบัญชีของตนเอง  
**Source:** srs-doc.md, NFR-06 — PDPA Compliance  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-01  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- ผู้ใช้สามารถลบประวัติการสแกน (รายการเดียวหรือทั้งหมด)
- **ผู้ใช้สามารถลบบัญชีทั้งหมดได้** (เฉพาะบัญชีของตนเอง)
- **ข้อมูลที่จะถูกลบ:**
  - ข้อมูลผู้ใช้ (users table)
  - ประวัติการสแกนทั้งหมด (scans table)
  - รายงานทั้งหมด (reports table)
  - Consent Logs (consent_logs table)
  - ไฟล์ภาพทั้งหมดใน Object Storage (original.jpg, heatmap.jpg)
- **ข้อมูลที่ไม่ลบ:** Audit Logs (เก็บไว้เพื่อ Compliance)

---

#### RC-PDPA-04: Data Retention Policy
**Description:** ระบบต้องมีนโยบายการเก็บข้อมูล  
**Source:** srs-doc.md, NFR-06 — PDPA Compliance (inferred)  
**Related Stakeholder:** ST01, ST02  
**Related Objective:** OBJ-01  
**Related Scope:** SC02  
**Priority:** Should

**Details:**
- เก็บข้อมูล Scan และ Images เป็นระยะเวลา **1 ปี**
- หลัง 1 ปี ลบข้อมูลอัตโนมัติ (Auto-delete)
- **Implementation:** Cron Job รันทุกวันเวลา 02:00 น. (Daily at 2 AM)
  - ตรวจสอบ scans ที่ created_at < (now() - interval '1 year')
  - ลบข้อมูลจาก Database (scans, reports)
  - ลบไฟล์จาก Object Storage
  - บันทึก Audit Log

---

### 2.7 Admin Portal (RC-ADMIN)

#### RC-ADMIN-01: Dashboard & Analytics
**Description:** Admin ต้องสามารถดูสถิติและแดชบอร์ดระบบ  
**Source:** scop.md, Section: SC04 — งานพัฒนาระบบควบคุมสิทธิ์ผู้ดูแลระบบ  
**Related Stakeholder:** ST02, ST03  
**Related Objective:** OBJ-04  
**Related Scope:** SC04  
**Priority:** Must

**Details:**
- จำนวนผู้ใช้งานทั้งหมดและผู้ใช้งานรายวัน/รายเดือน (DAU/MAU)
- จำนวนการสแกนทั้งหมดและการกระจายตามระดับความเสี่ยง (Low/Medium/High)
- ความแม่นยำของโมเดล AI (Accuracy Metrics)
- อัตราสัดส่วน Cache Hit vs New Analysis
- สถิติการรายงานตามหมวดหมู่

---

#### RC-ADMIN-02: User Management (CRUD)
**Description:** Admin ต้องสามารถจัดการผู้ใช้งาน (Read, Update Operations)  
**Source:** scop.md, Section: SC04 — งานพัฒนาระบบควบคุมสิทธิ์ผู้ดูแลระบบ  
**Related Stakeholder:** ST02  
**Related Objective:** OBJ-04  
**Related Scope:** SC04  
**Priority:** Must

**Details:**
- ดูรายการผู้ใช้ทั้งหมด (List Users)
- ค้นหาผู้ใช้ตาม Email, Full Name
- เปลี่ยนบทบาท (Role): User → Moderator → Admin
- เปลี่ยนสถานะ (Status): Active ↔ Inactive
- **Admin ไม่สามารถลบผู้ใช้ได้** — ใช้การเปลี่ยนสถานะเป็น Inactive แทน (Soft Delete)
- เหตุผล: ต้องเก็บ Audit Trail และข้อมูลสำหรับ Compliance
- ทุกการเปลี่ยนแปลงต้องบันทึกใน Audit Logs

---

#### RC-ADMIN-03: Report Queue Management
**Description:** Admin ต้องสามารถตรวจสอบและพิจารณารายงานที่ผู้ใช้ส่งเข้ามา  
**Source:** scop.md, Section: SC04 — งานพัฒนาระบบตรวจสอบรายงานประวัติการสแกม; srs-doc.md, BUS-10  
**Related Stakeholder:** ST02  
**Related Objective:** OBJ-04  
**Related Scope:** SC04  
**Priority:** Must

**Details:**
- แสดงรายการรายงาน (Report List Queue) พร้อมสถานะ:
  - Pending: รอตรวจสอบ
  - Reviewing: กำลังตรวจสอบ
  - Approved: อนุมัติ (นำเข้า Dataset)
  - Rejected: ปฏิเสธ
- Admin สามารถ:
  - ดูรายละเอียดรายงาน พร้อมรูปภาพและผลวิเคราะห์
  - เปลี่ยนสถานะเป็น "Reviewing" (กำลังตรวจสอบ)
  - อนุมัติ (Approve) รายงาน → เข้า Dataset
  - ปฏิเสธ (Reject) รายงาน พร้อมระบุเหตุผล (Admin Note)
- ทุกการดำเนินการต้องบันทึกใน Audit Logs (BUS-11)

---

#### RC-ADMIN-04: Model Management
**Description:** Admin ต้องสามารถจัดการโมเดล AI (อัปเดต, เปิด/ปิดใช้งาน, ลบ)  
**Source:** scop.md, Section: SC04 — งานพัฒนาระบบอัปเดตโมเดลและความยืดหยุ่น  
**Related Stakeholder:** ST02  
**Related Objective:** OBJ-04  
**Related Scope:** SC04  
**Priority:** Must

**Details:**
- แสดงรายการโมเดล AI ทั้งหมด พร้อมเวอร์ชัน วันที่ Deploy และสถานะ (Active/Inactive)
- Admin สามารถ:
  - อัปโหลดไฟล์น้ำหนักโมเดล (.onnx) เวอร์ชันใหม่
  - เปิดใช้งานโมเดลเวอร์ชันใหม่ (Activate) → ระบบปิดเวอร์ชันเก่าอัตโนมัติ
  - **ลบโมเดลเก่าได้เมื่อมีโมเดลในระบบ > 3 เวอร์ชัน** (เก็บไว้ 3 เวอร์ชันล่าสุดเท่านั้น)
  - ไม่สามารถลบโมเดลที่ status = "active"
- ทุกการดำเนินการต้องบันทึกใน Audit Logs (BUS-11)

---

#### RC-ADMIN-05: Audit Logs Viewer
**Description:** Admin ต้องสามารถดูบันทึกการดำเนินการทั้งหมด (Audit Logs)  
**Source:** scop.md, Section: SC04 — งานพัฒนาระบบตรวจสอบรายงานประวัติการสแกม; srs-doc.md, BUS-11  
**Related Stakeholder:** ST02, ST03  
**Related Objective:** OBJ-04  
**Related Scope:** SC04  
**Priority:** Must

**Details:**
- แสดงรายการ Audit Logs พร้อม:
  - Admin ID และ Username
  - Action (เช่น "Approve Report", "Change User Role", "Activate Model")
  - Details (รายละเอียดเพิ่มเติมเป็น JSON)
  - Timestamp
- Audit Logs เป็น Immutable (ไม่สามารถแก้ไขหรือลบได้)
- รองรับการค้นหาตาม Admin, Action, Date Range

---

#### RC-ADMIN-06: Role-Based Access Control (RBAC)
**Description:** ระบบต้องรองรับการควบคุมสิทธิ์ตามบทบาท  
**Source:** scop.md, Section: SC04 — งานพัฒนาระบบควบคุมสิทธิ์ผู้ดูแลระบบ  
**Related Stakeholder:** ST02  
**Related Objective:** OBJ-04  
**Related Scope:** SC04  
**Priority:** Must

**Details:**
- **Admin:** สิทธิ์เต็มในการจัดการทุกส่วน
- **Moderator:** สิทธิ์ตรวจสอบรายงานและจัดการผู้ใช้
- **Viewer:** สิทธิ์ดูสถิติเท่านั้น
- ตรวจสอบสิทธิ์ทุกครั้งก่อนดำเนินการ (Authorization Middleware)

---

### 2.8 Notification (RC-NOTIFY)

#### RC-NOTIFY-01: Push Notification (Analysis Complete)
**Description:** ระบบต้องส่งการแจ้งเตือนเมื่อการวิเคราะห์เสร็จสิ้น  
**Source:** scop.md, Section: SC01 — ระบบรายงานและแจ้งเตือน  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-04  
**Related Scope:** SC01, SC02  
**Priority:** Should

**Details:**
- ใช้ Firebase Cloud Messaging (FCM)
- ส่งการแจ้งเตือนเมื่อการวิเคราะห์เสร็จสิ้น (Async Processing)
- Notification Payload:
  - Title: "การวิเคราะห์เสร็จสิ้น"
  - Body: "คะแนนความเสี่ยง: {score} | ระดับ: {grade}"
  - Data: scan_id
- ผู้ใช้คลิก Notification → เปิดแอปและแสดงผลลัพธ์

---

#### RC-NOTIFY-02: Push Notification (Report Status Update)
**Description:** ระบบต้องส่งการแจ้งเตือนเมื่อ Admin อนุมัติ/ปฏิเสธรายงาน  
**Source:** scop.md, Section: SC01 — ระบบรายงานและแจ้งเตือน  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-04  
**Related Scope:** SC01, SC04  
**Priority:** Could

**Details:**
- **ส่งการแจ้งเตือนเฉพาะ Approved/Rejected เท่านั้น** (ไม่ส่งตอน Pending/Reviewing)
- Notification Payload:
  - Title: "อัปเดตสถานะรายงาน"
  - Body (Approved): "รายงานของคุณได้รับการอนุมัติและนำเข้า Dataset แล้ว"
  - Body (Rejected): "รายงานของคุณถูกปฏิเสธ: {admin_note}"
  - Data: report_id, status

---

### 2.9 Performance & Non-Functional (RC-NFR)

#### RC-NFR-01: Response Time (Cache Hit)
**Description:** การตอบสนองจาก Cache Hit ต้องไม่เกิน 3 วินาที  
**Source:** objective.md, OBJ-04 — Success Criteria  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-04  
**Related Scope:** SC02  
**Priority:** Must

**Details:**
- เมื่อ pHash Match ใน Redis Cache
- ระบบต้องส่งผลลัพธ์กลับภายใน ≤ 3 วินาที (P95)

---

#### RC-NFR-02: Response Time (New Analysis)
**Description:** การวิเคราะห์ใหม่ทั้งหมดต้องไม่เกิน 15 วินาที (median)  
**Source:** objective.md, OBJ-04 — Success Criteria  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-04  
**Related Scope:** SC02, SC03  
**Priority:** Must

**Details:**
- เมื่อไม่มี Cache Hit (ต้องรัน AI Inference เต็มรูปแบบ)
- **Performance Targets:**
  - Median (P50): ≤ 15 วินาที
  - P95: ≤ 25 วินาที
  - P99: ≤ 35 วินาที

---

#### RC-NFR-03: AI Inference Time
**Description:** เวลา Inference ของโมเดล AI ต้องไม่เกิน 10 วินาที  
**Source:** scop.md, Section: SC03 — Expected Outcome  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-02, OBJ-04  
**Related Scope:** SC03  
**Priority:** Must

**Details:**
- **เมื่อรันบน GPU** (NVIDIA T4 หรือสูงกว่า)
  - เวลา Inference เฉลี่ย: ≤ 10 วินาที/ภาพ
- **เมื่อรันบน CPU** (Fallback)
  - เวลา Inference เฉลี่ย: ≤ 60 วินาที/ภาพ
  - แสดงคำเตือน: "Processing may take longer (CPU mode)"

---

#### RC-NFR-04: System Uptime & Monitoring
**Description:** ระบบต้องมีความพร้อมใช้งาน ≥ 99.5% พร้อมระบบ Monitoring และ Alerting  
**Source:** objective.md, OBJ-04 — Success Criteria; Tech Stack (FastAPI + PyTorch/ONNX + PostgreSQL + Redis)  
**Related Stakeholder:** ST01, ST02  
**Related Objective:** OBJ-04  
**Related Scope:** SC02  
**Priority:** Must

**Details:**
- คำนวณจาก Uptime / Total Time × 100%
- ไม่นับเวลา Planned Maintenance
- **Monitoring Tools:**
  - **Prometheus** — เก็บ Metrics (API Uptime, Response Time, Error Rate, GPU Usage)
  - **Grafana** — Dashboard สำหรับแสดงผล Metrics แบบ Real-time
- **Alerting Strategy:**
  - **Grafana Alerts** หรือ **Sentry** สำหรับตรวจจับ Error
  - แจ้งเตือนไปยัง **Slack / LINE / Email** เมื่อ:
    - Error Rate > 5%
    - Response Time > 30 วินาที (P95)
    - System Uptime < 99.5%
    - GPU/CPU Usage > 90%

---

#### RC-NFR-05: Concurrent Users
**Description:** ระบบต้องรองรับผู้ใช้พร้อมกัน ≥ 100 คน  
**Source:** srs-doc.md, NFR-02 — Performance  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-04  
**Related Scope:** SC02  
**Priority:** Must

**Details:**
- ทดสอบด้วย Load Testing (e.g., JMeter, Locust)
- ระบบต้องรองรับ 100 Concurrent Users โดยไม่มีการตอบสนองช้าหรือ Error
- **Performance Target:**
  - Average Response Time: ≤ 20 วินาที (Cache Miss)
  - Average Response Time: ≤ 5 วินาที (Cache Hit)
  - Error Rate: < 1%

---

#### RC-NFR-06: Model Accuracy, Precision & Recall
**Description:** โมเดล AI ต้องมีความแม่นยำ ≥ 85%  
**Source:** objective.md, OBJ-02 — Success Criteria; wiki/concepts/configs.md (Section 5: Evaluation Metrics)  
**Related Stakeholder:** ST01, ST02, ST03  
**Related Objective:** OBJ-02  
**Related Scope:** SC03  
**Priority:** Must

**Details:**
- **Accuracy ≥ 85%** บนชุดข้อมูล Testing Set
- **F1-Score ≥ 85%** บนชุดข้อมูล Testing Set
- **Precision Target: ≥ 85%** (ลด False Positive — ภาพจริงแต่ระบบบอกว่าปลอม)
- **Recall Target: ≥ 85%** (ลด False Negative — ภาพปลอมแต่ระบบบอกว่าจริง)
- เป้าหมายคือความสมดุลระหว่าง Precision และ Recall เพื่อให้ F1-Score สูง

---

#### RC-NFR-07: Cache Hit Rate & Performance Tuning
**Description:** อัตราการ Cache Hit ต้อง ≥ 40%  
**Source:** architecture.md, Caching Strategy; wiki/requirements/objectives-kpis.md; wiki/architecture/database-schema.md  
**Related Stakeholder:** ST01  
**Related Objective:** OBJ-04  
**Related Scope:** SC02  
**Priority:** Should

**Details:**
- คำนวณจาก Cache Hit / Total Requests × 100%
- เป้าหมาย: ≥ 40%
- **กลยุทธ์เมื่อ Cache Hit Rate < 40%:**
  1. **เพิ่ม TTL (Time-To-Live) ใน Redis:**
     - ภาพที่มีลักษณะไวรัล หรือความเสี่ยงสูง → เพิ่ม TTL เป็น 60-90 วัน
     - เป้าหมาย: ให้ระบบจำผลวิเคราะห์ได้นานขึ้น
  2. **Auto-Scaling สำหรับ AI Worker:**
     - ขยายจำนวน ONNX Worker Instance ให้รองรับโหลดของ Queue
     - ป้องกัน Latency เกิน 15 วินาที
  3. **Graceful Degradation:**
     - แสดงข้อความเตือน: "มีผู้ใช้งานจำนวนมาก การวิเคราะห์อาจใช้เวลา 15-60 วินาที"
  4. **Monitoring & Alert:**
     - ตั้งแจ้งเตือนเมื่อ Cache Hit Rate < 35% (ต่ำกว่าเกณฑ์)

---

#### RC-NFR-08: Security (HTTPS, JWT, Rate Limiting)
**Description:** ระบบต้องมีความปลอดภัยตามมาตรฐาน  
**Source:** srs-doc.md, NFR-04 — Security  
**Related Stakeholder:** ST01, ST02  
**Related Objective:** OBJ-04  
**Related Scope:** SC02  
**Priority:** Must

**Details:**
- การสื่อสารทั้งหมดต้องใช้ HTTPS/TLS 1.3
- การยืนยันตัวตนใช้ JWT (Access Token + Refresh Token)
- Password Hashing ด้วย bcrypt (cost factor: 12)
- Rate Limiting:
  - Guest: 10 requests/minute
  - Authenticated User: 60 requests/minute
  - Admin: 300 requests/minute
- Input Validation (File Type, File Size, SQL Injection Prevention, XSS Prevention)

---

#### RC-NFR-09: User Satisfaction & UAT Sample Size
**Description:** คะแนนความพึงพอใจโดยรวมต้อง ≥ 4.00 คะแนน  
**Source:** objective.md, OBJ-04 — Success Criteria; wiki/requirements/objectives-kpis.md (ตัวชี้วัดเชิงคุณภาพ)  
**Related Stakeholder:** ST01, ST03  
**Related Objective:** OBJ-04  
**Related Scope:** SC01  
**Priority:** Must

**Details:**
- วัดด้วย Likert Scale 5 ระดับ (1-5)
- คะแนนเฉลี่ย ≥ 4.00 คะแนน
- **จำนวนผู้ทดสอบ UAT ขั้นต่ำ: 100 คน**
- อ้างอิงจาก KPI: "ผู้ใช้ ≥ 80% จาก 100 คน สามารถเข้าใจบริเวณที่น่าสงสัยจาก Heatmap ได้"
- เพื่อให้ได้ผลลัพธ์ทางสถิติที่มีนัยสำคัญ (Statistical Significance)

---

#### RC-NFR-10: Explainability (Heatmap Understandability) & UAT Questionnaire
**Description:** ผู้ใช้ ≥ 80% ต้องเข้าใจแผนที่ความร้อนโดยไม่ต้องมีพื้นฐานทางเทคนิค  
**Source:** objective.md, OBJ-04 — Success Criteria; wiki/requirements/objectives-kpis.md (ทดสอบความเข้าใจ XAI)  
**Related Stakeholder:** ST01, ST03  
**Related Objective:** OBJ-04  
**Related Scope:** SC01, SC03  
**Priority:** Must

**Details:**
- ทดสอบด้วย User Testing และ Interview (100 คน)
- ผู้ใช้ ≥ 80% ต้องตอบคำถาม "คุณเข้าใจแผนที่ความร้อนหรือไม่?" ว่า "เข้าใจ" หรือ "เข้าใจมาก"
- **คำถามทดสอบความเข้าใจ (Scenario-based):**

**คำถามเชิงความเข้าใจ (Comprehension):**
1. "จากภาพ บริเวณที่มีสีแดง สื่อความหมายถึงอะไร?"
   - ก. จุดที่ภาพมีความสวยงาม
   - ข. จุดที่เสี่ยงว่าอาจจะถูกดัดแปลงแก้ไข (คำตอบที่ถูกต้อง)
   - ค. จุดที่ปลอดภัย

2. "เปรียบเทียบระหว่างพื้นที่สีแดงกับสีเขียว ท่านคิดว่าส่วนใดที่น่าเชื่อถือมากกว่ากัน?"
   - ก. สีแดง
   - ข. สีเขียว (คำตอบที่ถูกต้อง)
   - ค. เท่ากัน

**คำถามเชิงประโยชน์ (Usefulness):**
3. "หลังจากที่ท่านเห็น Heatmap ซ้อนทับบนสลิปโอนเงินนี้แล้ว ช่วยให้ท่านมั่นใจในการแยกแยะสลิปปลอมได้มากขึ้นเพียงใด?"
   - Likert Scale 1-5: (1=ไม่มั่นใจเลย, 5=มั่นใจมากที่สุด)

**คำถามสรุป (Overall Understanding):**
4. "ท่านสามารถเข้าใจแผนที่ความร้อนได้โดยไม่ต้องให้ผู้เชี่ยวชาญอธิบายให้ฟังหรือไม่?"
   - ใช่ (เป้าหมาย: ≥ 80%)
   - ไม่ใช่

**เกณฑ์ผ่าน:**
- คำถาม 1, 2: ตอบถูก ≥ 80%
- คำถาม 3: คะแนนเฉลี่ย ≥ 4.00
- คำถาม 4: ตอบ "ใช่" ≥ 80%

---

## 3. Requirement Candidates Summary Table

| Category | Total RC | Priority Breakdown |
|----------|----------|--------------------|
| **Authentication & Authorization** | 6 | Must: 4, Should: 2 |
| **Image Upload & Scan** | 5 | Must: 5 |
| **Multi-layer Analysis** | 8 | Must: 7, Should: 1 |
| **Explainability (XAI)** | 3 | Must: 3 |
| **History & Reports** | 5 | Must: 3, Should: 2 |
| **PDPA & Consent** | 4 | Must: 3, Should: 1 |
| **Admin Portal** | 6 | Must: 6 |
| **Notification** | 2 | Should: 1, Could: 1 |
| **Performance & NFR** | 10 | Must: 7, Should: 1 |
| **TOTAL** | **49** | **Must: 38, Should: 10, Could: 1** |


**Evidence Sources:**
- Project Documentation: objective.md, scop.md, srs-doc.md, srs-se02.md
- Design Documents: architecture.md, design.md
- Architecture Diagrams: C1-System-Context-Diagram.md, C2-Container-Diagram.md
- Wiki Documentation: mobile-design.md, configs.md, objectives-kpis.md, database-schema.md

---

## 4. Document Summary

เอกสาร Requirement Candidates ฉบับนี้รวบรวมความต้องการทั้งหมด **49 รายการ** จาก Evidence-Based Analysis แบ่งเป็น:

**Priority Breakdown:**
- **Must:** 38 รายการ (77.6%)
- **Should:** 10 รายการ (20.4%)
- **Could:** 1 รายการ (2.0%)

**Evidence Quality:**
- **Complete Coverage:** ครอบคลุมทุก Category (Authentication, Scan, Analysis, XAI, History, PDPA, Admin, Notification, NFR)
- **Evidence-Based:** ทุก RC มี Source Reference จากเอกสารโครงการและ Wiki
- **Comprehensive Specifications:** ระบุรายละเอียดครบถ้วน พร้อมนำไปพัฒนา

**Key Design Decisions:**

**Authentication & Security:**
- Password Reset: Email OTP (6 หลัก, TTL: 10 นาที)
- Social Login: Google OAuth 2.0 เท่านั้น

**Performance & Scalability:**
- Response Time: P50 ≤ 15s, P95 ≤ 25s, P99 ≤ 35s
- Concurrent Users: 100 users (Cache Hit ≤ 5s, Cache Miss ≤ 20s)
- AI Inference: GPU ≤ 10s, CPU ≤ 60s
- Cache Strategy: TTL optimization, Auto-Scaling, Graceful Degradation

**Data Privacy (PDPA):**
- Account Deletion: ผู้ใช้สามารถลบข้อมูลทั้งหมด (ยกเว้น Audit Logs)
- Data Retention: Cron Job Daily at 2 AM, ลบข้อมูล > 1 ปี
- Heatmap Deletion: ลบพร้อมกับ Scan

**Admin Operations:**
- User Management: Soft Delete เท่านั้น (Inactive status)
- Model Management: ลบได้เมื่อมี > 3 เวอร์ชัน
- Notification: เฉพาะ Approved/Rejected

**AI/ML & Explainability:**
- Model Metrics: Accuracy/Precision/Recall/F1 ≥ 85%
- Heatmap UI: Toggle Button + Opacity Slider (Overlay mode)
- EXIF Metadata: แสดงเท่านั้น (ไม่ใช้คำนวณ Risk Score)
- Reverse Search Fallback: Neutral Score = 50 เมื่อ API Down
- UAT: 100 testers, 4 Scenario-based Questions

**Monitoring & DevOps:**
- Tools: Prometheus + Grafana + Sentry
- Alerts: Slack/LINE/Email
- Triggers: Error Rate > 5%, Response Time > 30s, Uptime < 99.5%, Resource > 90%

**Next Steps:**
ใน 05_Software_Requirement_Specification.md จะแปลง RC เหล่านี้เป็น FR/NFR ที่มี:
- Unique ID และ Priority
- Acceptance Criteria (Input → Processing → Output)
- Test Cases
- Traceability (ST → OBJ → SC → RC → FR/NFR → AC)

---


