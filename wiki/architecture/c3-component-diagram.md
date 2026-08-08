---
title: "C3 Component Diagram - API Application"
category: architecture
tags: [architecture, c4, component, diagram, backend]
updated: 2026-08-08
---

# C3: Component Diagram (API Application)

แผนภาพ C3 นี้นำเสนอโครงสร้างภายในของ **API Application Container (FastAPI)** ซึ่งเป็นศูนย์กลาง (Orchestrator) ของระบบ Scam Image Detection โดยแสดงให้เห็นถึงการแบ่งเลเยอร์ตามโครงสร้างซอร์สโค้ดในโฟลเดอร์ `server/app/`

```mermaid
flowchart TB
    %% การตั้งค่า Class สีต่างๆ
    classDef clientFill fill:#dae8fc,stroke:#6c8ebf,color:black
    classDef routerFill fill:#d5e8d4,stroke:#82b366,color:black
    classDef serviceFill fill:#fff2cc,stroke:#d6b656,color:black
    classDef repoFill fill:#e1d5e7,stroke:#9673a6,color:black
    classDef storageFill fill:#ffe6cc,stroke:#d79b00,color:black
    classDef extFill fill:#f5f5f5,stroke:#666666,color:black

    %% Clients (จาก C2)
    MobileApp("Mobile App<br>[Flutter]")
    AdminPortal("Admin Portal<br>[React]")
    
    subgraph APIContainer ["API Application Container - FastAPI"]
        
        %% API Layer
        subgraph APILayer ["API Layer (Controllers)"]
            AuthRouter("Auth Router<br>[api/v1/auth.py]<br>รับข้อมูล Login/Register")
            AdminRouter("Admin Router<br>[api/v1/admin.py]<br>จัดการระบบสำหรับ Admin")
            ScanRouter("Scan Router<br>[api/v1/scan.py]<br>รับรูปภาพเพื่อตรวจสอบ")
            ReportRouter("Report Router<br>[api/v1/report.py]<br>รับรายงานภาพสแกม")
        end

        %% Business Logic Layer
        subgraph ServiceLayer ["Business Logic Layer (Services)"]
            AuthService("Auth Service<br>[core/security.py]<br>ออก Token และตรวจสอบสิทธิ์")
            AdminService("Admin Service<br>[services/admin_service.py]<br>ประมวลผลคำสั่ง Admin")
            ScanService("Scan Service<br>[services/scan_service.py]<br>Core Logic คำนวณความเสี่ยง")
            InferenceClient("Inference Coordinator<br>[services/inference_service.py]<br>จัดการคิวและการเรียก AI")
            ReportService("Report Service<br>[services/report_service.py]<br>ประมวลผลการรายงาน")
        end

        %% Data Access Layer
        subgraph RepoLayer ["Data Access Layer (Repositories)"]
            UserRepo("User Repository<br>[repositories/user.py]")
            ScanRepo("Scan Repository<br>[repositories/scan.py]")
            ReportRepo("Report Repository<br>[repositories/report.py]")
        end
    end

    %% Storage & Externals (จาก C2)
    Cache("Redis Cache")
    MainDB[("PostgreSQL Database")]
    ObjectStore("Cloud Storage (Local / S3)")
    AIWorker("ONNX Worker (Subprocess)<br>[services/onnx_worker.py]")

    %% Relationships - External to API
    MobileApp --->|HTTPS / JSON| AuthRouter
    MobileApp --->|HTTPS / Multipart| ScanRouter
    MobileApp --->|HTTPS / JSON| ReportRouter
    AdminPortal --->|HTTPS / JSON| AdminRouter
    AdminPortal --->|HTTPS / JSON| AuthRouter

    %% API to Services
    AuthRouter --->|เรียกใช้งาน| AuthService
    ScanRouter --->|มอบหมายงานตรวจสอบ| ScanService
    ReportRouter --->|มอบหมายงานรายงาน| ReportService
    AdminRouter --->|มอบหมายคำสั่ง| AdminService

    %% Services to Services
    ScanService --->|ส่งภาพให้ AI วิเคราะห์| InferenceClient
    AdminService -.->|ดูข้อมูล| ReportService

    %% Services to External/Cache
    ScanService --->|ตรวจสอบ Hit/Miss| Cache
    ScanService --->|จัดเก็บรูปต้นฉบับ| ObjectStore
    InferenceClient --->|ส่งคำสั่งผ่าน IPC / Queue| AIWorker
    AIWorker --->|คืนผลลัพธ์ Heatmap| ObjectStore

    %% Services to Repositories
    AuthService --->|ค้นหา/ตรวจสอบ User| UserRepo
    ScanService --->|บันทึกผลการสแกน| ScanRepo
    ReportService --->|บันทึกและดึงรายงาน| ReportRepo
    AdminService --->|ดึงข้อมูลเชิงสถิติ| ScanRepo
    AdminService --->|จัดการบัญชีผู้ใช้| UserRepo

    %% Repositories to DB
    UserRepo --->|SQLAlchemy| MainDB
    ScanRepo --->|SQLAlchemy| MainDB
    ReportRepo --->|SQLAlchemy| MainDB

    %% Apply Styles
    class MobileApp,AdminPortal clientFill
    class AuthRouter,ScanRouter,ReportRouter,AdminRouter routerFill
    class AuthService,ScanService,ReportService,AdminService,InferenceClient serviceFill
    class UserRepo,ScanRepo,ReportRepo repoFill
    class Cache,MainDB,ObjectStore storageFill
    class AIWorker extFill
```

---

## คำอธิบายองค์ประกอบภายใน (Component Details)

สถาปัตยกรรมภายในของ Backend ยึดหลักการ **Layered Architecture** เพื่อแยกส่วนหน้าที่ (Separation of Concerns) ทำให้โค้ดอ่านง่าย ทดสอบง่าย (Testable) และดูแลรักษาง่าย โดยแบ่งเป็น 3 เลเยอร์หลัก:

### 1. API Layer (Controllers)
โฟลเดอร์ `server/app/api/v1/`
ทำหน้าที่เป็นด่านหน้าในการรับ HTTP Request, ตรวจสอบความถูกต้องของข้อมูลเบื้องต้น (Data Validation) ผ่าน Pydantic Schemas และส่งต่อ (Route) งานไปยัง Service ที่เกี่ยวข้อง
- **Auth Router:** จัดการ Endpoint สำหรับ Login และ Register
- **Scan Router:** รับไฟล์รูปภาพแบบ Multipart Form Data สำหรับตรวจสอบสแกม
- **Report Router:** รับแจ้งรูปภาพหลอกลวงจากผู้ใช้ (Crowdsourcing)
- **Admin Router:** เปิด Endpoint ให้นักวิจัยและ Admin จัดการข้อมูลโมเดลและระบบ

### 2. Business Logic Layer (Services)
โฟลเดอร์ `server/app/services/`
เป็นหัวใจหลักของแอปพลิเคชัน ทำหน้าที่ประมวลผลตามกฎทางธุรกิจ (Business Rules)
- **Scan Service:** ควบคุมขั้นตอนการตรวจสอบภาพทั้งหมด เริ่มตั้งแต่เช็ค Cache, สกัด EXIF, และคำนวณ **Weighted Risk Score**
- **Inference Coordinator (`inference_service.py`):** ตัวประสานงานระหว่าง Backend กับ AI Model ทำหน้าที่จัดคิวรูปภาพและส่งคำสั่งข้าม Process ไปให้ ONNX Worker
- **Auth Service:** จัดการการเข้ารหัสผ่าน (Hashing) และออก JWT Token 

### 3. Data Access Layer (Repositories)
โฟลเดอร์ `server/app/repositories/`
ทำหน้าที่ติดต่อกับฐานข้อมูลหลักผ่าน **SQLAlchemy ORM** ช่วยให้ Business Logic Layer ไม่ต้องเขียนคำสั่ง SQL (หรือยึดติดกับ Database มากเกินไป) 
- **User Repository:** Query ข้อมูลบัญชีและสิทธิ์ของผู้ใช้งาน
- **Scan Repository:** บันทึกและดึงประวัติ Risk Score ของแต่ละรูปภาพ
- **Report Repository:** บันทึกข้อมูลที่ผู้ใช้แจ้งเข้ามาว่ารูปไหนเป็นสแกมของจริง

### การทำงานร่วมกับ AI (ONNX Worker)
โมเดล AI ถูกออกแบบให้ทำงานแยกส่วน (Isolation) จาก Web Server หลัก โดยรันผ่าน Subprocess (`onnx_worker.py`) เพื่อแยกภาระงานประมวลผลที่กินทรัพยากรสูง (Heavy Computation Workload) ออกจาก Thread หลักของ FastAPI ทำให้ API ยังคงสามารถตอบสนอง Request อื่นๆ ได้อย่างรวดเร็วและไม่สะดุด
