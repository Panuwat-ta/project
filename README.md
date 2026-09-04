# โครงงาน: แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Scam Image Detection)
## หลักสูตรวิศวกรรมซอฟต์แวร์ สาขาวิศวกรรมไฟฟ้า คณะวิศวกรรมศาสตร์ มทร.ล้านนา (เชียงใหม่ ดอยสะเก็ด)

**อาจารย์ที่ปรึกษาโครงงานร่วม:**  
อาจารย์ สัญญา อุทธโยธา และ อาจารย์ ปิยผล ยืนยงสถาวร

**คณะผู้ดำเนินงาน:**  
1. นาย ภานุวัฒน์ ต๋าคำ (รหัสนักศึกษา 67543210044-3)
2. นาย เอกพันธ์ ทศทิศรังสรรค์ (รหัสนักศึกษา 67543210050-0)

---

## ภาพรวมโครงงาน (Project Overview)

**ScamGuard (Scam Image Detection)** เป็นระบบและแอปพลิเคชันมือถือสำหรับตรวจจับรูปภาพที่อาจถูกตัดต่อ ดัดแปลง ปลอมแปลง หรือสร้างขึ้นด้วยปัญญาประดิษฐ์ (AI) เพื่อนำมาใช้ในบริบทของการหลอกลวงทางดิจิทัล โดยช่วยให้ผู้ใช้งานทั่วไปสามารถตรวจสอบความถูกต้องและความน่าเชื่อถือของรูปภาพได้อย่างรวดเร็ว ก่อนตัดสินใจเชื่อ แชร์ หรือทำธุรกรรมทางการเงิน

ปัญหาหลักที่โครงงานมุ่งเน้นแก้ไขครอบคลุมภัยคุกคามจากภาพหลอกลวงในวงกว้าง ไม่จำกัดเฉพาะสลิปโอนเงินธนาคาร ได้แก่:
- **Romance Scam:** รูปโปรไฟล์ที่สร้างด้วย AI หรือถูกขโมยมาจากบุคคลอื่นเพื่อสวมรอย
- **Image Forgery & Manipulation:** ภาพตัดต่อดัดแปลงใบเสร็จ, สกรีนช็อตข้อความสนทนาปลอม, หรือเอกสารราชการที่ถูกแก้ไขข้อมูล
- **AI-Generated Synthetic Images:** ภาพบุคคลหรือสถานการณ์ที่สร้างขึ้นโดยสังเคราะห์ทั้งหมดเพื่อจูงใจให้หลงเชื่อ
- **Deceptive Screenshots & Payment Slips:** ภาพหลักฐานการชำระเงินหรือสลิปที่มีการตัดแต่งตัวเลขและเวลา

### การวิเคราะห์หลายชั้นแบบอิสระ (Independent Multi-layer Analysis)
เพื่อความโปร่งใสและแม่นยำทางนิติวิทยาศาสตร์ดิจิทัล ระบบประมวลผลการวิเคราะห์ภาพถ่ายแยกอิสระเต็ม 100% ใน 3 เลเยอร์หลัก:
1. **Visual Anomaly Detection (AI Model & Heatmap - 0–100%):** ตรวจสอบการตัดแต่งระดับพิกเซลด้วยโมเดล Deep Learning สถาปัตยกรรม SegFormer (PyTorch/ONNX Runtime) ผ่านเทคนิค Overlapping Tiling Inference (Patch ขนาด 512x512, Overlap 64px) เพื่อตรวจจับร่องรอยการปลอมแปลงบนภาพความละเอียดสูง พร้อมสร้างแผนที่ความร้อน (Heatmap Overlay) ตามหลักการ Explainable AI (XAI) และเสริมด้วยโมเดลภาษาขนาดเล็ก (Qwen2.5-1.5B) สำหรับช่วยสรุปเหตุผลความเสี่ยง
2. **Textual Analysis (OCR & NLP - 0–100%):** ดึงข้อความภาษาไทยและอังกฤษจากภาพด้วย Surya OCR (Native PyTorch) และวิเคราะห์คำสำคัญที่มักพบในบริบทการหลอกลวง (Scam Keywords)
3. **Source Verification (0–100%):** ตรวจสอบความซ้ำซ้อนกับฐานข้อมูลภาพภายใน (Internal DB Caching) เพื่อลดภาระระบบ และค้นหาประวัติการเผยแพร่ของภาพย้อนหลังบนอินเทอร์เน็ตผ่าน Reverse Image Search (Google Vision API)

### ระบบประเมินความเสี่ยงแบบไฮบริด (Hybrid Worst-Case Risk Scoring)
ระบบใช้หลักการ **Maximum Impact (Worst-Case Dominance) ร่วมกับ Multi-Factor Compounding** เพื่อป้องกันปัญหาคะแนนถูกเจือจาง (Dilution Effect) ในกรณีที่ภาพมีองค์ประกอบไม่ครบ (เช่น ภาพ Romance Scam ที่ไม่มีข้อความ):
- **คะแนนภาพรวม (Overall Risk Score):** ยึดตามมิติที่พบความเสี่ยงสูงสุดเป็นฐานหลัก $S_{base} = \max(S_{visual}, S_{textual}, S_{source})$ และหากพบความเสี่ยงระดับน่าสงสัยในมิติอื่นร่วมด้วย ($\ge 40$) จะเสริมค่าความเสี่ยงทวีคูณ (+5 คะแนนต่อมิติ)
- **การแจ้งเตือนและการแสดงผล (UI Presentation):** แสดง Overall Risk Level ควบคู่กับ Breakdown Cards แจกแจงผลคะแนนแยกอิสระ 3 มิติอย่างชัดเจน
- **ระดับการประเมินความเสี่ยง (Risk Grades - 3 ระดับ):**
  - **Low Risk (0–39%):** ความเสี่ยงต่ำ ไม่พบความผิดปกติที่เด่นชัด
  - **Medium Risk (40–69%):** ความเสี่ยงปานกลาง พบร่องรอยน่าสงสัยในมิติใดมิติหนึ่ง
  - **High Risk (70–100%):** ความเสี่ยงสูง ตรวจพบความผิดปกติระดับอันตรายในมิติใดมิติหนึ่ง ($S_{base} \ge 70$) หรือกรณี $S_{visual} \ge 80$ ถือเป็น High ทันที

---

## โครงสร้างระบบและโฟลเดอร์ (Repository Structure)

โครงสร้างไดเรกทอรีหลักของโปรเจกต์ประกอบไปด้วยส่วนประกอบต่างๆ ดังนี้:

```text
project/
├── scam_image_mobile/      # Flutter Mobile Application สำหรับผู้ใช้ทั่วไป (Clean Architecture + BLoC)
├── server/                 # Backend API Orchestrator (FastAPI, SQLAlchemy, Redis, Subprocess Workers)
├── model/                  # AI Model Files & Inference Engine (SegFormer ONNX, Surya OCR, Qwen2.5)
├── admin-portal/           # Admin Web Portal (React, Vite, Tailwind CSS, Dark Mode)
├── database/               # Database Services (PostgreSQL, Redis, Docker/Podman Compose, init.sql)
├── automate_test/          # Automated Testing Suite (Pytest สำหรับ API, E2E และ Performance Tests)
├── prototype/              # Web Prototype สำหรับทดสอบแนวคิดระบบ (React, Vite, TypeScript)
├── posman/                 # Postman API Collection สำหรับทดสอบ API Endpoints
├── Document/               # เอกสารวิศวกรรมซอฟต์แวร์ (SRS, Scope, Objectives, C1-C4 Diagrams)
├── design/                 # เอกสารการออกแบบสถาปัตยกรรมระบบ, UI/UX Specs, และรูปภาพจาก Figma
├── wiki/                   # ศูนย์รวมข้อมูลคลังความรู้โปรเจกต์ (Single Source of Truth)
├── web-ScamGuard/          # เอกสาร Wiki เวอร์ชัน Static HTML พร้อมเปิดดูผ่านเบราว์เซอร์
├── tests_report/           # บันทึกผลการรันการทดสอบระบบอัตโนมัติ (Automated Test Execution Reports)
├── .agents/                # บันทึกการทำงานและแนวทางการปฏิบัติงานของ Agent (AGENTS.md, log.md)
├── PRODUCT.md              # ข้อกำหนดทิศทางผลิตภัณฑ์และหลักการออกแบบ UX/UI
└── README.md               # เอกสารภาพรวมและคู่มือเริ่มต้นใช้งานโปรเจกต์
```

---

## สารบัญเอกสารประกอบโครงงาน (Project Documentation)

เอกสารข้อกำหนดทางวิศวกรรมซอฟต์แวร์และการออกแบบระบบได้รับการจัดระเบียบไว้ในไดเรกทอรี [Document/](Document/) และ [design/](design/):

### 1. ข้อกำหนดและความต้องการเชิงระบบ (Requirements & Scope)
* **[เอกสารข้อกำหนดความต้องการซอฟต์แวร์ (SRS)](Document/docs/05_Software_Requirement_Specification.md)** - Software Requirements Specification ฉบับสมบูรณ์
* **[วัตถุประสงค์และตัวชี้วัดโครงงาน (Objectives & KPIs)](Document/objective.md)** - รายละเอียดเป้าหมายหลัก (OBJ-01 ถึง OBJ-04) และเกณฑ์วัดผลเชิงปริมาณ
* **[ขอบเขตระบบและงานที่พัฒนา (Project Scope & Tasks)](Document/scop.md)** - ตารางแบ่งงาน ขอบเขตงาน และรายละเอียด Work Packages
* **[ภาพรวมความต้องการของระบบ (Project Overview Doc)](Document/docs/01_Project_Overview.md)** - สรุปที่มา ปัญหา และแนวทางการพัฒนา
* **[ความต้องการที่ผ่านการคัดเลือก (Requirement Candidates)](Document/docs/04_Requirement_Candidates.md)** - รายการ Functional & Non-Functional Requirements
* **[เมทริกซ์การตรวจสอบย้อนกลับความต้องการ (Traceability Matrix)](Document/docs/06_Requirement_Traceability.md)** - Traceability Matrix และ [ภาคผนวกฉบับเต็ม](Document/docs/07_Appendix_A_Full_Traceability_Matrix.md)
* **[การตัดสินใจสำคัญในการออกแบบระบบ (Key Design Decisions)](Document/docs/07_Appendix_B_Key_Design_Decisions.md)** - สรุปเหตุผลเชิงวิศวกรรมในการเลือกสถาปัตยกรรมและเทคโนโลยี

### 2. แผนภาพสถาปัตยกรรมระบบ (Software Architecture Diagrams)
* **[C1: แผนภาพบริบทระบบ (System Context Diagram)](Document/Software Architecture/C1-System-Context-Diagram.md)** - ขอบเขตระบบและการเชื่อมต่อระหว่าง Actors กับ External Services
* **[C2: แผนภาพคอนเทนเนอร์ (Container Diagram)](Document/Software Architecture/C2-Container-Diagram.md)** - สถาปัตยกรรมระบบระดับ Container (Mobile, Backend, AI Node, DB, Cache)
* **[C3: แผนภาพส่วนประกอบระบบหลังบ้าน (Component Diagram)](Document/Software Architecture/C3-Component-Diagram.md)** - สถาปัตยกรรมภายใน Backend API (FastAPI Layered Architecture)
* **[C4: แผนภาพลำดับการทำงานระดับโค้ด (Code Sequence Diagram)](Document/Software Architecture/C4-code-Diagram.md)** - ลำดับการประมวลผลแบบ Non-blocking, Subprocess Isolation, และ DB Interaction
* **[แผนภาพกรณีการใช้งาน (Use Case Diagram)](Document/Software Architecture/Use-Case-Diagram.md)** - รายละเอียด Use Cases และการทำงานของผู้ใช้ทั่วไปและแอดมิน
* **[แผนผังกระบวนการทำงานระบบ (Flowchart)](Document/Software Architecture/flowchart.md)** - ขั้นตอนการทำงานตั้งแต่การอัปโหลดจนถึงการแสดงผลลัพธ์

### 3. เอกสารการออกแบบรายละเอียดเชิงลึก (Design Specifications)
* **[ภาพรวมสถาปัตยกรรมระบบ (System Architecture)](design/architecture.md)** - สถาปัตยกรรมรวมของระบบทั้งหมด (Cloud-Native 3-Tier)
* **[การออกแบบสถาปัตยกรรมแอปพลิเคชันมือถือ (Mobile Design)](design/mobile/mobile.md)** - Clean Architecture, BLoC State Management, โฟลเดอร์ Flutter, และหน้าจอ
* **[การออกแบบ UI/UX ของแอปพลิเคชัน (UI/UX Design Overview)](design/design.md)** - ธีมสี, Typography, Interaction Pattern, และ Design Tokens
* **[การออกแบบระบบหลังบ้าน (Backend & Database Architecture)](design/server.md)** - FastAPI Structure, Alembic Migrations, PostgreSQL Schemas, และ API Contracts
* **[การออกแบบโมเดล AI และการฝึกสอน (Model & AI Pipeline Design)](design/model.md)** - สถาปัตยกรรม SegFormer, Differential Learning Rates, และ Tiling Inference
* **[การออกแบบการเทรนโมเดล (Model Training Specification)](design/training.md)** - ขั้นตอนและแนวทางการเทรนโมเดล AI
* **[การออกแบบเว็บแอดมิน (Admin Portal Design)](design/admin.md)** - สถาปัตยกรรม React Admin Portal, Role-based Access, และ Moderation Workflow
* **[แผนผังฐานข้อมูลความสัมพันธ์ (Entity Relationship Diagram)](database/ER_Diagram.md)** - รายละเอียดตาราง คอลัมน์ ความสัมพันธ์ และดัชนี (Indexes) ใน PostgreSQL

### 4. คลังความรู้ศูนย์กลาง (Wiki Knowledge Base)
* **[สารบัญ Wiki หลัก (Wiki Catalog)](wiki/index.md)** - สารบัญคลังความรู้โปรเจกต์ที่เป็น Single Source of Truth
* **[ภาพรวมโปรเจกต์ใน Wiki (Wiki Overview)](wiki/overview.md)** - ภาพรวมระบบ แนวทางการวิเคราะห์ และการประเมินผล
* **[แนวคิดการวิเคราะห์หลายชั้น (Multi-layer Analysis Concept)](wiki/concepts/multi-layer-analysis.md)** - รายละเอียดเชิงลึกของการสแกน 3 เลเยอร์
* **[เกณฑ์การคิดคะแนนความเสี่ยง (Risk Scoring Formulation)](wiki/concepts/risk-scoring.md)** - สูตรคณิตศาสตร์และเกณฑ์การตัดเกรดความเสี่ยง
* **[การอธิบายผลลัพธ์ด้วย AI (Explainable AI & Heatmap)](wiki/concepts/explainable-ai.md)** - ทฤษฎีและวิธีการสร้าง Heatmap ซ้อนทับภาพ

---

## เทคโนโลยีหลักที่ใช้ในโปรเจกต์ (Technology Stack)

| ส่วนของระบบ | เทคโนโลยีที่เลือกใช้ | รายละเอียดการทำงาน |
| :--- | :--- | :--- |
| **Mobile Application** | Flutter (Dart) | สถาปัตยกรรม Clean Architecture ร่วมกับ BLoC State Management บน Android |
| **Admin Portal** | React 18, Vite, Tailwind CSS | หน้าเว็บจัดการระบบสำหรับแอดมินและนักวิจัย รองรับ Dark Mode, Review และ Audit Log |
| **Backend API** | Python, FastAPI | Orchestrator รับคำขอ, ตรวจสอบสิทธิ์ (JWT), จัดการคิวงาน และติดต่อฐานข้อมูล |
| **AI Vision Model** | SegFormer (PyTorch / ONNX) | ตรวจจับการตัดต่อระดับพิกเซลด้วย Overlapping Tiling Inference ขนาด 512x512 |
| **OCR & Text NLP** | Surya OCR 0.5.0, NLP Pattern Matcher | สกัดข้อความภาษาไทยและอังกฤษแบบ Native PyTorch ตรวจจับคำหลอกลวง |
| **Explainable AI (XAI)** | Qwen2.5-1.5B (GGUF via llama-cpp) | สรุปวิเคราะห์ผลลัพธ์และอธิบายเหตุผลความผิดปกติที่ตรวจพบในรูปภาพ |
| **Database** | PostgreSQL 15 | ฐานข้อมูลเชิงสัมพันธ์สำหรับเก็บข้อมูลผู้ใช้, สถิติการสแกน, และรายงานการหลอกลวง |
| **Cache & Message Store** | Redis | Caching ผลการวิเคราะห์ด้วย `image_hash` เพื่อตอบกลับทันทีเมื่อมีการส่งภาพซ้ำ |
| **Search Integration** | Google Vision API | บริการค้นหาภาพย้อนกลับ (Reverse Image Search) เพื่อตรวจสอบแหล่งที่มาภายนอก |
| **Automated Testing** | Pytest, Flutter Test, Locust | ชุดทดสอบครอบคลุม Unit Tests, API Tests, E2E Integration Tests, และ Load Testing |
| **Container & Dev Environment** | Podman / Docker Compose | จัดการสภาพแวดล้อมฐานข้อมูล PostgreSQL, Redis และ pgAdmin |

---

## แนวทางการติดตั้งและการเริ่มต้นใช้งาน (Getting Started)

### 1. ข้อกำหนดเบื้องต้นของระบบ (Prerequisites)
- Linux / macOS / Windows (WSL2)
- Python 3.10+
- Node.js 18+ และ npm
- Flutter SDK 3.x และ Android SDK
- Podman หรือ Docker พร้อม Docker Compose
- การ์ดจอ NVIDIA พร้อมไดรเวอร์ CUDA (สำหรับการรัน AI Model และ GPU-accelerated Inference)

---

### 2. การเปิดใช้งานฐานข้อมูลและ Cache (Database & Redis)
เข้าไปที่โฟลเดอร์ `database` และเริ่มต้นบริการทั้งหมดผ่านคอนเทนเนอร์:

```bash
cd database
podman compose up -d
# หรือ docker compose up -d
```

บริการที่จะพร้อมใช้งาน:
- **PostgreSQL:** Port `5432` (User: `scamguard`, DB: `scamguard_db`)
- **Redis:** Port `6379`
- **pgAdmin:** `http://localhost:5050` (Email: `admin@scamguard.com`, Password: `admin123`)

---

### 3. การเริ่มต้นระบบหลังบ้าน (Backend API Server)
เข้าไปที่โฟลเดอร์ `server` สร้างและเปิดใช้งาน Virtual Environment จากนั้นรันการอัปเดต Schema ฐานข้อมูลและเริ่มเซิร์ฟเวอร์:

```bash
cd server
source venv/bin/activate
pip install -r requirements.txt

# อัปเดต Schema ฐานข้อมูลด้วย Alembic
alembic upgrade head

# เริ่มการทำงานของ Backend API (หรือรันผ่าน ./run.sh)
./run.sh
```

- API Server จะเปิดให้บริการที่: `http://localhost:8000`
- เอกสาร Interactive API Docs (Swagger UI): `http://localhost:8000/docs`
- Health Check Endpoint: `http://localhost:8000/health`

---

### 4. การเปิดใช้งานเว็บจัดการระบบ (Admin Portal)
เข้าไปที่โฟลเดอร์ `admin-portal` เพื่อติดตั้ง Dependencies และรัน Development Server:

```bash
cd admin-portal
npm install
npm run dev
# หรือรันผ่านสคริปต์ ./run.sh
```

- เข้าใช้งานระบบ Admin Portal ผ่านเบราว์เซอร์ได้ที่: `http://localhost:5173`

---

### 5. การรันแอปพลิเคชันมือถือ (Flutter Mobile Application)
เข้าไปที่โฟลเดอร์ `scam_image_mobile` เพื่อดาวน์โหลดแพ็กเกจและรันบนอุปกรณ์ Android:

```bash
cd scam_image_mobile
flutter pub get
flutter run
```

---

### 6. การรันชุดทดสอบระบบอัตโนมัติ (Automated Testing)
สามารถรันการทดสอบ API และ E2E ผ่านชุดทดสอบอัตโนมัติในโฟลเดอร์ `automate_test`:

```bash
cd automate_test
./run.sh all       # รันทั้ง API และ E2E Tests
./run.sh api       # รันเฉพาะ API Tests
./run.sh e2e       # รันเฉพาะ E2E Tests
```

ผลการทดสอบแบบละเอียดจะถูกสร้างขึ้นในโฟลเดอร์ `automate_test/reports/html/report.html`

---

## ลิงก์พื้นที่ทำงานสำหรับการดำเนินงาน (Workspace Links)

* **[Discord Channel](https://discord.gg/WSEXfzrb)** - ช่องทางการสื่อสารและประสานงานของทีมพัฒนา
* **[Miro Board](https://miro.com/welcomeonboard/WUdKOXhEY2V6QlV1ZDVMTFlHTEJBQlhxSnUxVW5NMkFCTFIyc1dIVUR6cTFzSEdFQmVaelQwa2V4bnNqWVFtRkRFeERidTlrVGx3S2pVWGE0aG1iVVVHeEhvMWNmVHNWUUlMZGx1VU41WGlkMmpmYktKbE0wSzN1c3ArWmtURDVnbHpza3F6REdEcmNpNEFOMmJXWXBBPT0hdjE=?share_link_id=787643582535)** - พื้นที่ระดมสมองและวิเคราะห์ความต้องการเชิงระบบ
* **[Figma Design](https://www.figma.com/design/gFrjAWWl0ZmT7h7vzu9011/project-Mobile-App--Scam-Image-Detection?node-id=0-1&t=seKA8vjnzcKV9HMq-1)** - ต้นแบบหน้าจอ UI/UX Design ของโมบายแอปพลิเคชัน
* **[Jira Board](https://panuwattakham2002.atlassian.net/jira/software/projects/SCM/boards/35)** - กระดานติดตามสถานะการดำเนินงาน (Task & Sprint Tracking)
* **[System Architecture Diagram (Google Drive)](https://drive.google.com/file/d/1I2ksLvZp0x3iNYt57_46cqnTDfPgWvzR/view?usp=sharing)** - ไฟล์ไดอะแกรมสถาปัตยกรรมระบบฉบับสำรอง