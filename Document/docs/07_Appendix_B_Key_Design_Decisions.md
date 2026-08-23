# Appendix B: Key Design Decisions

**Project Name:** แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Scam Image Detection)  
**Version:** 1.0  
**Date:** August 23, 2026

---

## 1. Introduction

เอกสารนี้รวบรวม **Key Design Decisions** ทั้งหมดที่ได้ตัดสินใจไปแล้วในระหว่างการจัดทำ SRS Baseline โดยแบ่งตามหมวดหมู่ และระบุแหล่งที่มาของข้อมูล (Evidence Source) เพื่อให้สามารถตรวจสอบย้อนกลับได้

### 1.1 Purpose

เอกสารนี้มีวัตถุประสงค์เพื่อ:
- **บันทึกการตัดสินใจ** — เพื่อให้ทีมพัฒนาและ Stakeholders เข้าใจเหตุผลและข้อจำกัดของแต่ละการตัดสินใจ
- **ป้องกันการสร้างความสับสนในอนาคต** — หากมีคำถามเกี่ยวกับการออกแบบ สามารถอ้างอิงเอกสารนี้ได้
- **รองรับการเปลี่ยนแปลง** — หากมีการปรับปรุงในอนาคต สามารถดูประวัติการตัดสินใจเดิมได้

### 1.2 Decision Categories

การตัดสินใจแบ่งเป็น 10 หมวดหมู่หลัก:
1. **Authentication & Authorization** — การตัดสินใจเกี่ยวกับการเข้าสู่ระบบและความปลอดภัย
2. **Image Processing** — การตัดสินใจเกี่ยวกับการอัปโหลดและประมวลผลภาพ
3. **Analysis Engine** — การตัดสินใจเกี่ยวกับการวิเคราะห์ความเสี่ยง
4. **Explainability (XAI)** — การตัดสินใจเกี่ยวกับการแสดงผล Heatmap
5. **PDPA & Consent** — การตัดสินใจเกี่ยวกับความเป็นส่วนตัวและสิทธิผู้ใช้
6. **Admin Portal** — การตัดสินใจเกี่ยวกับการจัดการระบบ
7. **Performance & Scalability** — การตัดสินใจเกี่ยวกับประสิทธิภาพ
8. **Security** — การตัดสินใจเกี่ยวกับความปลอดภัย
9. **Monitoring & DevOps** — การตัดสินใจเกี่ยวกับการติดตามระบบ
10. **User Experience** — การตัดสินใจเกี่ยวกับประสบการณ์ผู้ใช้

---

## 2. Authentication & Authorization Decisions

### 2.1 Email-Based Authentication Only

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Primary Auth Method** | Email + Password only | ลดความซับซ้อนในการพัฒนา | Project Decision |
| **Password Policy** | ≥ 8 ตัวอักษร (ไม่มี complexity requirements) | สมดุลระหว่างความปลอดภัยและ UX | Project Decision |
| **Password Hashing** | bcrypt (cost factor: 12) | Standard practice สำหรับ Django | Tech Stack Analysis |

---

### 2.2 Email OTP for Password Reset

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **OTP Format** | 6 หลัก (ตัวเลขเท่านั้น) | ง่ายต่อการพิมพ์และจดจำ | Project Decision |
| **OTP TTL** | 10 นาที | สมดุลระหว่างความปลอดภัยและความสะดวก | Project Decision |
| **OTP Delivery** | Email only (ไม่ใช้ SMS) | ลดต้นทุนและความซับซ้อน | Project Decision |

---

### 2.3 Social Login

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Supported Provider** | Google OAuth 2.0 only | ความนิยมสูงในประเทศไทย | Project Decision |
| **Apple Sign-In** | ไม่รองรับ | จำกัดทรัพยากรและเวลา | Project Decision |
| **Facebook Login** | ไม่รองรับ | ความนิยมลดลง และมีปัญหาด้านความเป็นส่วนตัว | Project Decision |

---

### 2.4 Token Management

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Access Token TTL** | 15 นาที | สมดุลระหว่างความปลอดภัยและ UX | Project Decision |
| **Refresh Token TTL** | 7 วัน | ลดการ Login ซ้ำบ่อยเกินไป | Project Decision |
| **Token Storage (Mobile)** | Flutter Secure Storage | Secure encryption ด้วย Keychain (iOS) และ Keystore (Android) | Tech Stack Analysis |
| **Token Revocation** | ไม่มี Token Blacklist | Token มีอายุสั้น (15 นาที) ลด Complexity | Project Decision |

---

## 3. Image Processing Decisions

### 3.1 Supported File Types

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Supported Formats** | JPG, PNG, WebP only | ครอบคลุม 95% use cases | Project Decision |
| **GIF Support** | ไม่รองรับ | GIF เป็น Animation ไม่เหมาะกับ Static Image Analysis | Project Decision |
| **BMP/TIFF Support** | ไม่รองรับ | ไม่นิยมใช้ในมือถือและมีขนาดใหญ่ | Project Decision |

---

### 3.2 File Size Limits

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Max File Size** | 10 MB | สมดุลระหว่างคุณภาพและเวลาอัปโหลด | Project Decision |
| **Max Resolution** | 10,000 × 10,000 พิกเซล | ป้องกัน Memory Overflow และ DoS Attack | Project Decision |
| **Min Resolution** | ไม่จำกัด (แนะนำ ≥ 512×512) | ให้ผู้ใช้ตัดสินใจเอง แต่แจ้งเตือนว่าความแม่นยำลดลง | Project Decision |

---

### 3.3 Image Cropping

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Cropping Tool** | Flutter image_cropper (Optional) | ให้ผู้ใช้ครอบตัดส่วนที่สนใจก่อนวิเคราะห์ | Project Decision |
| **Auto-Crop** | ไม่มี | ไม่สามารถตัดสินใจแทนผู้ใช้ได้ว่าส่วนไหนสำคัญ | Project Decision |
| **Aspect Ratio Lock** | ไม่บังคับ | ให้ผู้ใช้มีอิสระในการเลือก | Project Decision |

---

## 4. Analysis Engine Decisions

### 4.1 Risk Score Formula

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Weighted Formula** | `(S_text × 0.25) + (S_visual × 0.45) + (S_source × 0.30)` | Visual Analysis มีความสำคัญสูงสุด (45%) เพราะตรงกับ Objective | Project Decision |
| **Text Weight** | 0.25 (25%) | ข้อความเป็นสัญญาณเสริม แต่ไม่เพียงพอที่จะสรุปคนเดียว | Project Decision |
| **Visual Weight** | 0.45 (45%) | การตัดต่อและ AI-Gen เป็นหัวใจของระบบ | Project Decision |
| **Source Weight** | 0.30 (30%) | แหล่งที่มาช่วยระบุความน่าเชื่อถือ | Project Decision |

---

### 4.2 Risk Grade Mapping

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Low (Green)** | 0-39 | ความเสี่ยงต่ำ แต่ยังคงให้ผู้ใช้ระมัดระวัง | Project Decision |
| **Medium (Yellow)** | 40-69 | ความเสี่ยงปานกลาง ควรตรวจสอบเพิ่มเติม | Project Decision |
| **High (Red)** | 70-100 | ความเสี่ยงสูง ไม่ควรเชื่อถือ | Project Decision |
| **Special Rule** | หาก `visual_score ≥ 80` → High แม้ `risk_score < 70` | การตัดต่อชัดเจนควรได้ High เสมอ | Project Decision |

---

### 4.3 Reverse Search Fallback Strategy

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **API Down Handling** | Neutral Score = 50 | ไม่ควร Bias ต่ำหรือสูงเกินไป | Project Decision |
| **Status Field** | `source_status: "unavailable"` | แจ้งผู้ใช้ให้ทราบว่าข้อมูลนี้ไม่พร้อมใช้งาน | Project Decision |
| **Retry Logic** | ไม่มี Auto-Retry | หาก API Down ผู้ใช้สามารถ Scan ใหม่ภายหลัง | Project Decision |

---

### 4.4 EXIF Metadata Handling

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **EXIF Extraction** | แสดงเฉพาะข้อมูล (Camera Model, Date, Location) | ช่วยผู้ใช้ตรวจสอบบริบท | Project Decision |
| **EXIF in Risk Calculation** | ไม่นำมาคำนวณ | EXIF ถูกปลอมแปลงได้ง่าย ไม่น่าเชื่อถือ | Project Decision |
| **GPS Redaction** | ไม่ลบ GPS | ข้อมูล GPS ช่วยระบุจุดถ่ายภาพ (ผู้ใช้ตัดสินใจเอง) | Project Decision |

---

### 4.5 OCR Text Search

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Text Search in History** | ไม่รองรับ | ต้องใช้ Full-Text Search Engine (Elasticsearch) ซึ่งเพิ่ม Complexity | Project Decision |
| **Keyword Highlighting** | รองรับ (แสดง scam_keywords ใน UI) | ช่วยผู้ใช้เข้าใจว่าคำใดถูกระบุว่าเสี่ยง | Project Decision |

---

## 5. Explainability (XAI) Decisions

### 5.1 Heatmap Visualization

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Heatmap Method** | Grad-CAM (Gradient-weighted Class Activation Mapping) | Standard method สำหรับ CNN Explainability | Tech Stack Analysis |
| **Color Scheme** | แดง (High Risk) → เหลือง (Medium) → เขียว (Low) | สื่อความหมายตาม Universal Convention | wiki/architecture/mobile-design.md |
| **Overlay Opacity** | Default 50%, ปรับได้ 0-100% | ให้ผู้ใช้ควบคุมความโปร่งใส | wiki/architecture/mobile-design.md |

---

### 5.2 Heatmap UI Controls

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Toggle Button** | On/Off แบบ Switch | ง่ายและชัดเจน | wiki/architecture/mobile-design.md |
| **Opacity Slider** | Slider (0-100%) | ผู้ใช้สามารถปรับให้เห็นภาพต้นฉบับชัดเจนขึ้น | wiki/architecture/mobile-design.md |
| **Zoom & Pan** | รองรับ | ผู้ใช้ต้องการดูรายละเอียดในบริเวณเล็ก | Project Decision |

---

### 5.3 Heatmap Deletion

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Delete with Scan** | ใช่ (Cascade Delete) | Heatmap ไม่มีความหมายโดยไม่มี Scan ที่เกี่ยวข้อง | Project Decision |
| **Separate Delete Option** | ไม่มี | ไม่จำเป็น เพราะถูกลบอัตโนมัติ | Project Decision |

---

## 6. PDPA & Consent Decisions

### 6.1 Consent Types

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **System Consent** | บังคับ (จำเป็นต่อการใช้งาน) | ต้องยอมรับนโยบาย PDPA ก่อนใช้งาน | Project Decision |
| **Research Consent** | เลือกได้ (Optional) | ผู้ใช้สามารถเลือกไม่ให้ใช้ข้อมูลเพื่อการวิจัย | Project Decision |
| **Consent Withdrawal** | Research Consent ถอนได้ตลอดเวลา | สิทธิตาม PDPA | Project Decision |

---

### 6.2 Account Deletion (Right to Erasure)

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **User Can Delete** | ลบข้อมูลส่วนตัวทั้งหมด (ยกเว้น Audit Logs) | ตาม PDPA Right to Erasure | Project Decision |
| **Audit Logs Retention** | เก็บไว้ (แต่ Anonymize user_id) | จำเป็นเพื่อการตรวจสอบความปลอดภัย | Project Decision |
| **Confirmation Dialog** | 2 ระดับ (Confirm + Re-type Email) | ป้องกันการลบโดยไม่ตั้งใจ | Project Decision |

---

### 6.3 Data Retention Policy

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Scan Data Retention** | ลบอัตโนมัติหลัง 1 ปี (365 วัน) | สมดุลระหว่าง Storage Cost และความต้องการผู้ใช้ | Project Decision |
| **Cron Job Schedule** | ทุกวันเวลา 02:00 น. | ช่วงเวลาที่ผู้ใช้น้อย | Project Decision |
| **User Override** | ผู้ใช้สามารถลบด้วยตัวเองได้ทันที | ไม่ต้องรอ Cron Job | Project Decision |

---

## 7. Admin Portal Decisions

### 7.1 User Management

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Soft Delete Only** | เปลี่ยนสถานะเป็น `inactive` แทนการลบจริง | เก็บ Audit Trail และป้องกัน Foreign Key ข้อผิดพลาด | Project Decision |
| **Hard Delete** | ไม่รองรับ | อาจทำให้ข้อมูล Scan History และ Audit Log เสียหาย | Project Decision |
| **Bulk Actions** | ไม่รองรับ | ลด Complexity | Project Decision |

---

### 7.2 Report Notification

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Notification Trigger** | เฉพาะ Approved/Rejected | ผู้ใช้ไม่จำเป็นต้องรู้ว่า Admin กำลัง Reviewing | Project Decision |
| **Notification Channel** | In-App + Email | ผู้ใช้ได้รับการแจ้งเตือนทั้ง 2 ช่องทาง | Project Decision |
| **Push Notification** | ไม่รองรับ | ลด Complexity (ต้องใช้ FCM/APNs) | Project Decision |

---

### 7.3 Model Management

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Model Deletion Policy** | ลบเมื่อมีโมเดลมากกว่า 3 เวอร์ชัน | เก็บประวัติ 3 เวอร์ชันล่าสุดเพื่อ Rollback | Project Decision |
| **Auto-Delete** | ไม่มี (Admin ตัดสินใจเอง) | ป้องกันการลบโมเดลที่ยังต้องใช้งาน | Project Decision |
| **Model Versioning** | Sequential (v1.0, v1.1, v2.0) | ง่ายต่อการติดตาม | Project Decision |

---

## 8. Performance & Scalability Decisions

### 8.1 Response Time Targets

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Cache Hit** | ≤ 3 วินาที (P95) | ประสบการณ์ผู้ใช้ที่ดี | Project Decision |
| **New Analysis (Median)** | ≤ 15 วินาที (P50) | ยอมรับได้สำหรับ Deep Learning Analysis | Project Decision |
| **New Analysis (P95)** | ≤ 25 วินาที | ครอบคลุม 95% ของ requests | Project Decision |
| **New Analysis (P99)** | ≤ 35 วินาที | ยอมรับได้สำหรับภาพที่ซับซ้อน | Project Decision |

---

### 8.2 CPU Fallback Strategy

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **CPU Inference Time** | ≤ 60 วินาที | เมื่อ GPU ไม่พร้อมใช้งาน | Project Decision |
| **UI Notification** | แสดงข้อความ "การวิเคราะห์อาจใช้เวลา 15-60 วินาที" | แจ้งผู้ใช้ให้รอ | Project Decision |
| **CPU Only Mode** | ไม่รองรับ (GPU เป็นหลัก) | CPU ใช้เฉพาะ Fallback เท่านั้น | Project Decision |

---

### 8.3 Concurrent User Target

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **100 Concurrent Users** | Cache Hit: ≤ 5s, Cache Miss: ≤ 20s, Error < 1% | เป้าหมายสำหรับ UAT | Project Decision |
| **Auto-Scaling** | Horizontal Scaling สำหรับ ONNX Workers | เพิ่ม Workers เมื่อ Queue Length > 50 | Project Decision |
| **Load Balancer** | Nginx Reverse Proxy | กระจาย Load ไปยัง API Servers | Tech Stack Analysis |

---

### 8.4 Cache Strategy

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Cache Method** | Perceptual Hash (pHash) ใน Redis | ตรวจจับภาพเดียวกันแม้มีการปรับขนาดหรือบีบอัด | wiki/architecture/database-schema.md |
| **Cache TTL (Default)** | 30 วัน | สมดุลระหว่าง Hit Rate และ Storage Cost | wiki/architecture/database-schema.md |
| **Cache TTL (Viral)** | 60-90 วัน | ภาพไวรัลมีโอกาสถูก Scan ซ้ำสูง | wiki/architecture/database-schema.md |
| **Cache Hit Rate Target** | ≥ 40% | เป้าหมายเริ่มต้น | wiki/architecture/database-schema.md |

---

### 8.5 Performance Tuning Strategy (Cache Hit < 40%)

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Strategy 1** | เพิ่ม TTL สำหรับภาพไวรัล/เสี่ยงสูง (60-90 วัน) | ภาพเหล่านี้มีโอกาส Scan ซ้ำสูง | wiki/architecture/database-schema.md |
| **Strategy 2** | Auto-Scale ONNX Workers เมื่อ Queue > 50 | เพิ่มกำลังประมวลผล | wiki/architecture/database-schema.md |
| **Strategy 3** | Graceful Degradation — แสดงข้อความ "มีผู้ใช้จำนวนมาก ใช้เวลา 15-60 วินาที" | แจ้งผู้ใช้ให้รอ | wiki/architecture/database-schema.md |
| **Strategy 4** | Monitoring Alert เมื่อ Cache Hit < 35% | แจ้งเตือน Admin ให้ตรวจสอบ | wiki/architecture/database-schema.md |

---

## 9. Security Decisions

### 9.1 Transport Security

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **HTTPS/TLS** | TLS 1.3 บังคับทุก Endpoint | มาตรฐานความปลอดภัยปัจจุบัน | Project Decision |
| **HTTP Redirect** | HTTP → HTTPS (301 Permanent) | ป้องกันการเข้าถึงผ่าน HTTP | Project Decision |
| **Certificate** | Let's Encrypt (Free, Auto-Renewal) | ลดต้นทุนและ Maintenance | Tech Stack Analysis |

---

### 9.2 Rate Limiting

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Authenticated User** | 60 requests/minute | ป้องกัน Abuse และ DoS Attack | Project Decision |
| **Anonymous User** | 10 requests/minute | จำกัดการใช้งานโดยไม่ Login | Project Decision |
| **Endpoint-Specific** | `/api/scan/upload`: 5 requests/minute | อัปโหลดภาพมีต้นทุนสูง | Project Decision |

---

### 9.3 Input Validation

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **SQL Injection** | Django ORM (ป้องกันอัตโนมัติ) | ORM Parameterized Queries | Tech Stack Analysis |
| **XSS Prevention** | Django Template Escaping (ป้องกันอัตโนมัติ) | Template Engine Auto-Escape | Tech Stack Analysis |
| **File Upload Validation** | MIME Type Check (Magic Bytes) + File Size + Resolution | ป้องกัน Malicious Files | Project Decision |

---

## 10. Monitoring & DevOps Decisions

### 10.1 Monitoring Stack

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Metrics Collection** | Prometheus | Standard สำหรับ Kubernetes | Tech Stack Analysis |
| **Visualization** | Grafana | Dashboard ที่ยืดหยุ่นและมี Community Support | Tech Stack Analysis |
| **Error Tracking** | Sentry | Real-time Error Monitoring + Stack Traces | Tech Stack Analysis |
| **Log Aggregation** | ไม่มี (ใช้ Kubernetes Logs) | ลด Complexity | Project Decision |

---

### 10.2 Alerting Strategy

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Alert Channels** | Slack, LINE, Email | ครอบคลุมทีมพัฒนาและ Admin | Tech Stack Analysis |
| **Alert Triggers** | Error Rate > 5%, Response Time > 30s (P95), Uptime < 99.5%, GPU/CPU > 90% | Thresholds ที่สมเหตุสมผล | Project Decision |
| **On-Call Rotation** | ไม่มี (ทีมเล็ก) | ทุกคนรับแจ้งเตือน | Project Decision |

---

### 10.3 System Uptime Target

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Uptime Target** | ≥ 99.5% (ไม่นับ Planned Maintenance) | ประมาณ 3.6 ชั่วโมง Downtime/เดือน | Project Decision |
| **Planned Maintenance** | ทุกวันอาทิตย์ 02:00-04:00 น. (สูงสุด 2 ชั่วโมง/สัปดาห์) | ช่วงเวลาที่ผู้ใช้น้อย | Project Decision |
| **SLA** | ไม่มี SLA ที่เป็นทางการ | ระบบยังอยู่ในระหว่าง UAT | Project Decision |

---

## 11. User Experience Decisions

### 11.1 User Satisfaction Target

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Likert Scale** | 1-5 (1 = Not Satisfied, 5 = Very Satisfied) | มาตรฐาน UX Research | wiki/requirements/objectives-kpis.md |
| **Target Score** | ≥ 4.00/5.00 | เป้าหมายความพึงพอใจสูง | wiki/requirements/objectives-kpis.md |
| **Sample Size** | 100 testers (UAT) | ขนาดตัวอย่างเพียงพอ | wiki/requirements/objectives-kpis.md |

---

### 11.2 Explainability Comprehension Test

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Test Format** | 4 คำถามแบบ Scenario-based | วัดความเข้าใจจริงจากสถานการณ์ | wiki/requirements/objectives-kpis.md |
| **Target Comprehension** | ≥ 80% ตอบถูก (Q1, Q2), Likert ≥ 4.00 (Q3), "Yes" ≥ 80% (Q4) | เป้าหมายความเข้าใจสูง | wiki/requirements/objectives-kpis.md |
| **Questions** | 1. บริเวณสีแดงคืออะไร? 2. สีแดง vs สีเขียว? 3. Heatmap ช่วยมั่นใจแค่ไหน? 4. เข้าใจโดยไม่ต้องอธิบาย? | ครอบคลุมความเข้าใจหลักของ Heatmap | wiki/requirements/objectives-kpis.md |

---

## 12. Model Accuracy Decisions

### 12.1 Accuracy Targets

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Overall Accuracy** | ≥ 85% | ตาม Objective OBJ-02 | wiki/concepts/configs.md |
| **F1-Score** | ≥ 85% | สมดุลระหว่าง Precision และ Recall | wiki/concepts/configs.md |
| **Precision** | ≥ 85% | ลด False Positive (ภาพจริงแต่บอกว่าปลอม) | wiki/concepts/configs.md |
| **Recall** | ≥ 85% | ลด False Negative (ภาพปลอมแต่บอกว่าจริง) | wiki/concepts/configs.md |

---

### 12.2 Testing Set

| Decision Area | Specification | Rationale | Evidence Source |
|---------------|---------------|-----------|-----------------|
| **Testing Set Size** | 1,000 ภาพ | ขนาดตัวอย่างเพียงพอสำหรับการประเมิน | Project Decision |
| **Class Distribution** | 50% Real, 50% Fake (Balanced) | ป้องกัน Bias จาก Imbalanced Dataset | Project Decision |
| **Testing Set Source** | ไม่ซ้ำกับ Training/Validation Set | ป้องกัน Data Leakage | Project Decision |

---

## 13. Summary Table

| # | Decision Area | Specification | Evidence Source |
|---|---------------|---------------|-----------------|
| 1 | **Authentication** | Email OTP (6 หลัก, TTL: 10 นาที) | Project Decision |
| 2 | **Social Login** | Google OAuth 2.0 only | Project Decision |
| 3 | **Reverse Search Fallback** | Neutral Score = 50, status="unavailable" | Project Decision |
| 4 | **EXIF Metadata** | Display only, no risk calculation | Project Decision |
| 5 | **OCR Text Search** | Not supported | Project Decision |
| 6 | **Heatmap Deletion** | Delete with scan (Cascade) | Project Decision |
| 7 | **Account Deletion** | User can delete all (except Audit Logs) | Project Decision |
| 8 | **Data Retention** | Cron Job Daily at 2 AM, delete > 1 year | Project Decision |
| 9 | **User Management** | Soft Delete only (Inactive status) | Project Decision |
| 10 | **Model Management** | Delete when > 3 versions | Project Decision |
| 11 | **Report Notification** | Approved/Rejected only | Project Decision |
| 12 | **Heatmap UI** | Toggle Button + Opacity Slider | wiki/architecture/mobile-design.md |
| 13 | **Response Time Targets** | P50: ≤ 15s, P95: ≤ 25s, P99: ≤ 35s | Project Decision |
| 14 | **CPU Inference** | ≤ 60 วินาที | Project Decision |
| 15 | **Monitoring Stack** | Prometheus + Grafana + Sentry | Tech Stack Analysis |
| 16 | **Concurrent Users** | Cache Hit: ≤ 5s, Cache Miss: ≤ 20s | Project Decision |
| 17 | **Model Metrics** | Precision & Recall ≥ 85% | wiki/concepts/configs.md |
| 18 | **Cache Strategy** | 4-step: ↑TTL, Auto-Scale, Degrade, Alert | wiki/architecture/database-schema.md |
| 19 | **UAT Sample** | 100 testers | wiki/requirements/objectives-kpis.md |
| 20 | **Comprehension Test** | 4 scenario-based questions | wiki/requirements/objectives-kpis.md |

---

## 14. Change History

| Date | Version | Changed By | Changes |
|------|---------|------------|---------|
| 2026-08-23 | 1.0 | Project Team | Initial creation from SRS Baseline and Traceability Matrix |

---

**END OF DOCUMENT**
