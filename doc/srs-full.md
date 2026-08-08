# เอกสารข้อกำหนดความต้องการทางซอฟต์แวร์ (Software Requirements Specification - SRS)
## โครงงาน: แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Image Forgery Detection Application for Fraud Prevention)

**หลักสูตรวิศวกรรมซอฟต์แวร์ สาขาวิศวกรรมไฟฟ้า คณะวิศวกรรมศาสตร์**  
**มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา ปีการศึกษา 2/2568**  
**รหัสโครงงานวิศวกรรม:** SE02

---

## คณะผู้ดำเนินงาน
1. **นาย ภานุวัฒน์ ต๋าคำ** (หัวหน้าโครงงาน)  
   รหัสนักศึกษา: 67543210044-3 ชั้นปี: วิศวกรรมซอฟต์แวร์ ปี 2ข (หลักสูตรเทียบโอน)  
   ความเชี่ยวชาญ: การพัฒนาโมบายแอปพลิเคชัน, การพัฒนาเว็บแอปพลิเคชัน, การวิเคราะห์และออกแบบระบบ, การออกแบบฐานข้อมูล, การออกแบบส่วนติดต่อผู้ใช้ (UI), การเขียนโปรแกรมภาษา Python และ JavaScript  
   ความรับผิดชอบ: วางแผนและกำหนดขอบเขตโครงงาน, เก็บและวิเคราะห์ความต้องการระบบ, วิเคราะห์และออกแบบระบบ, พัฒนาแอปพลิเคชันบนอุปกรณ์เคลื่อนที่, พัฒนาระบบฝั่งเซิร์ฟเวอร์, พัฒนาและฝึกสอนโมเดลปัญญาประดิษฐ์ (AI), จัดทำเอกสารประกอบโครงงาน  
   สัดส่วนความรับผิดชอบ: 70%  
   สถานที่ติดต่อ: มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา เชียงใหม่ ดอยสะเก็ด  
   โทรศัพท์: 083-923-0703  
   อีเมล: panuwat_ta67@live.rmutl.ac.th  

2. **นาย เอกพันธ์ ทศทิศรังสรรค์** (ผู้ร่วมโครงงาน)  
   รหัสนักศึกษา: 67543210050-0 ชั้นปี: วิศวกรรมซอฟต์แวร์ ปี 2ข (หลักสูตรเทียบโอน)  
   ความเชี่ยวชาญ: การพัฒนาโมบายแอปพลิเคชัน, การพัฒนาเว็บแอปพลิเคชัน, การวิเคราะห์และออกแบบระบบ  
   ความรับผิดชอบ: การวิเคราะห์และออกแบบระบบ, พัฒนาแอปพลิเคชันบนอุปกรณ์เคลื่อนที่, จัดทำเอกสารประกอบโครงงาน, ดำเนินการทดสอบระบบ  
   สัดส่วนความรับผิดชอบ: 30%  
   สถานที่ติดต่อ: มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา เชียงใหม่ ดอยสะเก็ด  
   โทรศัพท์: 093-149-1440  
   อีเมล: akkapan_to67@live.rmutl.ac.th  

**อาจารย์ที่ปรึกษาร่วม:** อาจารย์ สัญญา อุทธโยธา และ อาจารย์ ปิยผล ยืนยงสถาวร
**วันที่เสนอโครงงาน:** 20 มีนาคม พ.ศ. 2568  

---

## 1. บทนำ (Introduction)

### 1.1 วัตถุประสงค์ของเอกสาร (Purpose)
เอกสารฉบับนี้จัดทำขึ้นเพื่อระบุข้อกำหนดความต้องการทางซอฟต์แวร์ (Software Requirements Specification: SRS) สำหรับแอปพลิเคชันตรวจสอบรูปภาพตัดต่อเพื่อป้องกันการหลอกลวง โดยแสดงข้อมูลเกี่ยวกับความต้องการทางธุรกิจ (Business Requirements) ความต้องการเชิงฟังก์ชัน (Functional Requirements) ความต้องการที่ไม่ใช่ฟังก์ชัน (Non-Functional Requirements) สถาปัตยกรรมของระบบ และการออกแบบระบบเบื้องต้นเพื่อใช้เป็นแนวทางและข้อตกลงร่วมในการพัฒนาโครงงานวิศวกรรมซอฟต์แวร์นี้

### 1.2 ขอบเขตของผลิตภัณฑ์ (Product Scope)
ระบบ Scam Image Detection เป็นระบบตรวจสอบความเสี่ยงของรูปภาพที่สงสัยว่าถูกตัดต่อหรือสร้างขึ้นด้วยปัญญาประดิษฐ์เพื่อลดการตกเป็นเหยื่อของการหลอกลวงทางไซเบอร์ เช่น สลิปโอนเงินปลอม หรือภาพหน้าคนปลอม โดยระบบจะตรวจสอบผ่าน 3 เลเยอร์หลัก (Multi-layer Analysis):
1. **Textual Analysis (วิเคราะห์ข้อความในภาพ):** ดึงข้อความด้วย OCR และวิเคราะห์หาคำสำคัญหรือรูปแบบประโยคหลอกลวงด้วย NLP
2. **Source Verification (ตรวจสอบแหล่งที่มา):** ค้นหาภาพย้อนกลับ (Reverse Image Search) เพื่อตรวจสอบว่าภาพเคยปรากฏในอินเทอร์เน็ตมาก่อนหรือไม่
3. **Visual Anomaly Detection (วิเคราะห์ความผิดปกติทางทัศนภาพ):** ใช้โมเดลการเรียนรู้เชิงลึก (Deep Learning) เพื่อหาร่องรอยการตัดต่อ (Image Forgery) หรือภาพที่ถูกสร้างโดย Generative AI (AI-Generated Image)

### 1.3 คำสำคัญ (Keywords)
* **Image Forgery Detection:** การตรวจสอบการปลอมแปลงรูปภาพ
* **Explainable AI (XAI):** ปัญญาประดิษฐ์ที่อธิบายได้
* **Grad-CAM (Heatmap):** แผนที่ความร้อนระบุจุดผิดปกติ
* **Multi-layer Analysis:** การวิเคราะห์ข้อมูลแบบหลายชั้น
* **Microservices Architecture:** สถาปัตยกรรมไมโครเซอร์วิส
* **PDPA (Personal Data Protection Act):** พระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล

---

## 2. คำอธิบายโดยรวม (Overall Description)

### 2.1 มุมมองของผลิตภัณฑ์ (Product Perspective)
ระบบตรวจสอบภาพหลอกลวงได้รับการพัฒนาให้อยู่ในรูปของแอปพลิเคชันบนสมาร์ทโฟน (Flutter) เพื่อให้เข้าถึงง่าย ทำงานร่วมกับ API Gateway ฝั่งระบบหลังบ้าน (FastAPI) และระบบบริการตรวจสอบวิเคราะห์ปัญญาประดิษฐ์ (AI Inference Service) เพื่อส่งผลลัพธ์ที่เป็นระดับความเสี่ยง (Risk Score) และคำอธิบายเชิงภาพ (Grad-CAM Heatmap) กลับไปยังผู้ใช้

#### 2.1.1 แผนภาพ Context Diagram (C1)
แสดงขอบเขตและการแลกเปลี่ยนข้อมูลระหว่างผู้ใช้ ระบบ และบริการภายนอก:

```mermaid
flowchart TD
    %% การตั้งค่า Class สีต่างๆ (กำหนด color:black ตามคำสั่ง)
    classDef mainSystem fill:#0050ef,stroke:#001DBC,color:black
    classDef userFill fill:#fff2cc,stroke:#d6b656,color:black
    classDef adminFill fill:#dae8fc,stroke:#6c8ebf,color:black
    classDef extFill fill:#f5f5f5,stroke:#666666,color:black

    %% Title Area
    subgraph Context [C1: System Context Diagram]
        direction TB
        
        %% Nodes (โหนดต่างๆ)
        User("General User<br>[Person]")
        
        System("Mobile App: Scam Image Detection<br>[Software System]<br>Allows users to upload images to detect forgery,<br>AI generation, and existing scams.")
        
        Admin("Admin<br>[Person]")
        
        ExtSearch("Reverse Image Search Provider<br>[External System]<br>Google Vision API / Bing Visual Search<br>(Used to find similar images on the web)")
        
        ExtNotify("Push Notification Service<br>[External System]<br>Firebase Cloud Messaging (FCM)<br>(Sends alerts/results to mobile)")

        %% Relationships (เส้นเชื่อมโยง)
        User -- "1. อัปโหลดรูปเพื่อตรวจสอบ<br>2. ดูรายงานความเสี่ยง" --> System
        
        System -- "ส่ง URL รูปภาพ / ข้อมูลไบนารี" --> ExtSearch
        ExtSearch -.->|"ส่งคืน URL รูปภาพที่คล้ายกัน"| System
        
        System -- "ส่งข้อมูลการแจ้งเตือน (Payload)" --> ExtNotify
        
        Admin -- "ตรวจสอบรูปที่ถูกรายงาน /<br>อัปเดตข้อมูลโมเดล" --> System
    end

    %% Apply Styles (การระบายสี)
    class System mainSystem
    class User userFill
    class Admin adminFill
    class ExtSearch,ExtNotify extFill
```

##### คำอธิบายระบบในภาพรวม (System Context Details)

* **1. ระบบหลัก (The Software System):**
  * **Mobile App: Scam Image Detection:** เป็นแอปพลิเคชันบนมือถือที่พัฒนาด้วย Flutter สำหรับอำนวยความสะดวกให้ผู้ใช้งานทั่วไปสามารถอัปโหลดรูปภาพที่น่าสงสัยเข้ามาตรวจสอบความเสี่ยงของการปลอมแปลงและการหลอกลวง
* **2. ผู้ใช้งาน (People):**
  * **General User (ผู้ใช้งานทั่วไป):** ผู้รับรูปภาพน่าสงสัย เช่น สลิปโอนเงินปลอม หรือรูปโปรไฟล์หลอกลวง ส่งภาพเข้ามาตรวจสอบและดูรายงานระดับความเสี่ยงเพื่อประกอบการตัดสินใจ
  * **Admin (ผู้ดูแลระบบ):** ตรวจสอบรูปภาพสแกมที่ผู้ใช้รายงาน ส่งภาพเข้าคลังชุดข้อมูล หรือดำเนินงานอัปเดตข้อมูลไฟล์โมเดลปัญญาประดิษฐ์ให้เท่าทันรูปแบบกลโกงใหม่ๆ
* **3. ระบบภายนอก (External Systems):**
  * **Reverse Image Search Provider:** ระบบภายนอก (Google Vision API / Bing Visual Search) สำหรับสืบค้นและค้นหาว่าไฟล์ภาพดังกล่าวเคยปรากฏในอินเทอร์เน็ตที่ใดบ้าง เพื่อระบุแหล่งที่มาและบริบทที่แท้จริง
  * **Push Notification Service:** บริการส่งการแจ้งเตือน Firebase Cloud Messaging (FCM) ในการส่งข้อมูลแจ้งเตือน (Push Notification) ไปยังอุปกรณ์ของผู้ใช้เมื่อระบบวิเคราะห์ผลลัพธ์ในเบื้องหลังเสร็จสมบูรณ์
* **สรุปขั้นตอนการทำงาน (Workflow Scenario):**
  1. **User** อัปโหลดรูปภาพที่ต้องการตรวจสอบเข้ามาในระบบผ่านแอปพลิเคชันมือถือ
  2. **System** ตรวจสอบความละเอียด ร่องรอยการตัดต่อ (ELA) และส่งข้อมูลสกัดภาพไปสืบค้นแหล่งที่มาผ่าน Google/Bing API
  3. ระบบประมวลผลคำนวณความเสี่ยง และส่งคำสั่งแจ้งเตือนผ่านบริการ FCM ไปยังผู้ใช้งาน
  4. ผู้ใช้เปิดตรวจสอบรายงานผลลัพธ์ดัชนีความเสี่ยงพร้อมแผนที่ความร้อน (Grad-CAM Heatmap)
  5. หากภาพเป็นรูปแบบกลโกงใหม่ ผู้ใช้สามารถกดรายงานเพื่อส่งข้อมูลไปให้ Admin ทำการอัปเดตโมเดลในอนาคต

#### 2.1.2 แผนภาพ Container Diagram (C2)
แสดงโครงสร้างส่วนประกอบย่อยภายในระบบที่ทำงานร่วมกันแบบ Microservices:

```mermaid
flowchart TB
    %% การตั้งค่า Class สีต่างๆ
    classDef userFill fill:#fff2cc,stroke:#d6b656,color:black
    classDef clientFill fill:#dae8fc,stroke:#6c8ebf,color:black
    classDef backendFill fill:#d5e8d4,stroke:#82b366,color:black
    classDef storageFill fill:#ffe6cc,stroke:#d79b00,color:black
    classDef extFill fill:#f5f5f5,stroke:#666666,color:black

    %% Actors Boundary
    User("General User<br>[Person]<br>ผู้ใช้งานทั่วไป")
    Admin("Admin<br>[Person]<br>ผู้ดูแลระบบ")

    %% System Boundary
    subgraph ScamSystem [Scam Image Detection - System Boundary]
        direction TB

        subgraph Frontends [Frontend Layer]
            MobileApp("Mobile App<br>[Container: Flutter]<br>อัปโหลดและเลือกรูปภาพ,<br>แสดงผลคะแนนความเสี่ยง (Risk Score)")
            AdminPortal("Admin Web Portal<br>[Container: React + Admin UI]<br>จัดการผู้ใช้ (CRUD), ตรวจสอบสแกมที่รายงาน,<br>จัดการชุดข้อมูล, อัปเดตโมเดล")
        end

        subgraph Backends [Backend & API Layer]
            APIGateway("API Application<br>[Container: Python FastAPI]<br>จัดการ Logic หลัก, ดึง Metadata,<br>ตรวจสอบ OCR")
            AIInference("AI Inference Service<br>[Container: PyTorch / ONNX]<br>ตรวจการตัดต่อ (ELA),<br>เช็คว่าเป็นภาพ AI")
        end

        subgraph Storages [Storage & Cache Layer]
            Cache("Cache<br>[Container: Redis]<br>เก็บผลตรวจชั่วคราว (Cache Hit)<br>เพื่อลดเวลาประมวลผลซ้ำ")
            ObjectStore("Object Storage<br>[Container: Cloud Storage]<br>เก็บไฟล์รูปภาพต้นฉบับ,<br>ภาพ Heatmap")
            MainDB[("Main Database<br>[Container: PostgreSQL]<br>เก็บข้อมูลผู้ใช้, ประวัติการสแกน,<br>ผลลัพธ์ (Risk Score)")]
        end
    end

    %% External Systems Boundary
    subgraph Externals [External Services]
        PushService("Push Notification Service<br>[External System: FCM]<br>แจ้งเตือนผลลัพธ์กลับไปยังแอป")
        ReverseSearch("Reverse Image Search<br>[External System: Google Vision API]<br>ระบบค้นหาแหล่งที่มาของรูปภาพ")
    end

    %% Relationships / Associations
    User -- "Uploads image & views result" --> MobileApp
    Admin -- "Manages system" --> AdminPortal

    MobileApp -- "API Calls<br>[HTTPS / JSON]" --> APIGateway
    AdminPortal -- "API Calls<br>[HTTPS / JSON]" --> APIGateway

    APIGateway -- "เช็คประวัติการสแกน" --> Cache
    APIGateway -- "ส่งตรวจร่องรอย / AI" --> AIInference
    APIGateway -- "จัดเก็บ / ดึงรูปภาพ" --> ObjectStore
    APIGateway -- "บันทึกผลลัพธ์ขั้นสุดท้าย" --> MainDB
    
    APIGateway -- "แจ้งเตือนเมื่อ Timeout / ประมวลผลเสร็จ<br>[HTTPS]" --> PushService
    APIGateway -- "ค้นหาแหล่งที่มา<br>[HTTPS]" --> ReverseSearch

    %% Apply Styles
    class User,Admin userFill
    class MobileApp,AdminPortal clientFill
    class APIGateway,AIInference backendFill
    class Cache,ObjectStore,MainDB storageFill
    class PushService,ReverseSearch extFill
```

##### คำอธิบาย Container Diagram

สถาปัตยกรรมของระบบ Scam Image Detection ถูกออกแบบภายใต้แนวคิด **Microservices** และ **Cloud-Native Architecture** เพื่อให้ระบบสามารถรองรับการประมวลผลข้อมูลรูปภาพและโมเดลปัญญาประดิษฐ์ (ซึ่งใช้ทรัพยากรการคำนวณสูง) ได้อย่างมีประสิทธิภาพ โดยไม่ส่งผลกระทบต่อความเร็วในการตอบสนองของแอปพลิเคชัน ภายในขอบเขตของระบบ (System Boundary) ประกอบด้วยคอนเทนเนอร์หลัก 3 ส่วน ดังนี้:

* **1. ส่วนติดต่อผู้ใช้งาน (Frontend Containers):**
  * **Mobile App (Flutter):** แอปพลิเคชันบนสมาร์ทโฟนสำหรับผู้ใช้งานทั่วไป (General User) ทำหน้าที่รับส่งไฟล์ภาพและแสดงผลคะแนนความเสี่ยง (Risk Score) พร้อมแผนที่ความร้อน (Grad-CAM Heatmap)
  * **Admin Web Portal (React + Admin UI):** เว็บแอปสำหรับแอดมินใช้ตรวจสอบสถิติระบบ บริหารจัดการบัญชีผู้ใช้งาน (CRUD) ตรวจสอบรูปภาพสแกมที่รายงาน และอัปเดตโมเดล AI
* **2. ส่วนประมวลผลหลัก (Backend Containers):**
  * **API Application (FastAPI):** ทำหน้าที่เป็น API Gateway รับส่งข้อมูล และประมวลผลตรรกะทางธุรกิจ เช่น การยืนยันตัวตน ดึงข้อมูลแฝง (Metadata) และตรวจสอบ OCR เบื้องต้น
  * **AI Inference Service (PyTorch / ONNX):** เซอร์วิสวิเคราะห์โมเดล AI โดยเฉพาะ ทำการตรวจสอบรูปภาพว่าถูกตัดต่อ (ELA) หรือสร้างจากปัญญาประดิษฐ์ (AI-Generated Image) หรือไม่
* **3. ส่วนจัดเก็บข้อมูล (Storage Containers):**
  * **Cache (Redis):** เก็บบันทึกข้อมูลผลการสแกนภาพล่าสุด เพื่อนำกลับมาแสดงผลทันทีโดยไม่ต้องประมวลผลใหม่ (Cache Hit) เมื่อส่งรูปเดิมเข้ามาซ้ำ
  * **Object Storage (Cloud Storage):** จัดเก็บข้อมูลรูปภาพดิบที่ผู้ใช้อัปโหลดเข้ามาและรูปภาพผลลัพธ์ของ Heatmap
  * **Main Database (PostgreSQL):** จัดเก็บข้อมูลระบบหลัก เช่น ข้อมูลบัญชีผู้ใช้ บันทึกประวัติการสแกน และล็อกระบบ RBAC
* **4. การเชื่อมต่อกับระบบภายนอก (External Systems):**
  * **Reverse Image Search (Google Vision API):** สืบค้นหาแหล่งที่มาดั้งเดิมของภาพจากเว็บไซต์ทั่วโลก
  * **Push Notification Service (FCM):** แจ้งเตือนผู้ใช้งานเมื่อรูปภาพที่รันในลักษณะ Asynchronous หลังบ้านทำการตรวจสอบเสร็จสิ้น

#### 2.1.3 แผนภาพ Component Diagram (C3)

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

#### 2.1.4 แผนภาพ Code Diagram (C4)

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

#### 2.1.5 เทคโนโลยีที่ใช้ในการพัฒนา (Technology Stack)
* **Frontend:** Flutter (แอปพลิเคชันมือถือ), React.js (หน้าเว็บแอดมิน)
* **Backend:** Python FastAPI (API Gateway และ Core Service)
* **AI Engine:** PyTorch / ONNX (สำหรับ AI Inference), รันการดัดแปลงภาพด้วย PSCC-Net และ SegFormer
* **Database & Caching:** PostgreSQL (ฐานข้อมูลหลัก), Redis (สำหรับจัดเก็บข้อมูลแคช)
* **Object Storage:** ระบบจัดเก็บไฟล์บนคลาวด์ (Cloud Storage) (สำหรับรูปภาพและ Heatmap)
* **Deployment:** Docker & Containerization

### 2.2 ฟังก์ชันการทำงานของระบบ (Product Functions)
* ระบบสมัครสมาชิกและล็อกอินแบบสากลและ OAuth
* เลือกและอัปโหลดรูปภาพเพื่อตรวจสอบ
* ถอดข้อความจากรูปภาพ วิเคราะห์ประเด็นหลอกลวง และค้นหาแหล่งที่มาของรูปภาพ
* ส่งรูปภาพตรวจสอบผ่านโมเดลปัญญาประดิษฐ์เพื่อหาจุดตัดต่อและระบุดัชนีความเสี่ยง
* แสดงผลวิเคราะห์ภาพพร้อมแผนที่ความร้อน (Grad-CAM Heatmap)
* การแจ้งเตือนผู้ใช้งานเมื่อวิเคราะห์ภาพในเบื้องหลังเสร็จสิ้น (Push Notification)
* บันทึกประวัติและรายงานรูปภาพที่น่าสงสัย
* แดชบอร์ดตรวจสอบสถิติและเครื่องมืออัปเดตโมเดล AI สำหรับผู้ดูแลระบบ

### 2.3 กลุ่มผู้ใช้และคุณลักษณะ (User Classes and Characteristics)
1. **General User (ผู้ใช้งานทั่วไป):**
   * ประชาชนทั่วไปที่ทำธุรกรรมออนไลน์ ซื้อของออนไลน์ หรือผู้ใช้สื่อสังคมออนไลน์
   * ต้องการความสามารถในการตรวจเช็กภาพอย่างรวดเร็วและเข้าใจง่าย (ผ่านผลลัพธ์ Visual Heatmap)
2. **Administrator (ผู้ดูแลระบบ):**
   * มีความเข้าใจด้านเทคนิคและระบบซอฟต์แวร์
   * ทำหน้าที่จัดการสิทธิ์เข้าถึง จัดการชุดข้อมูลรูปภาพ (Dataset) ที่ผู้ใช้รายงานเข้ามา และอัปโหลดไฟล์น้ำหนักโมเดล (AI Weights)

### 2.4 ข้อจำกัดในการพัฒนา (Design and Implementation Constraints)
* อุปกรณ์เคลื่อนที่ต้องเชื่อมต่ออินเทอร์เน็ตในการส่งรูปภาพไปประมวลผลบนคลาวด์
* การตรวจสอบทางด้านข้อความ (OCR) อาจได้ผลลัพธ์ไม่แม่นยำ 100% หากรูปภาพเบลอ มีความละเอียดต่ำ หรือแสงไม่เพียงพอ
* การประเมินผลความเสี่ยง (Risk Score) เป็นการประเมินเชิงสถิติจากโมเดล ไม่สามารถใช้เป็นข้อสรุปทางกฎหมายหรือพยานหลักฐานเด็ดขาดในชั้นศาลได้โดยตรง
* ระบบต้องปฏิบัติตามมาตรฐาน พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล (PDPA) อย่างเคร่งครัด

### 2.5 สมมติฐานและความขึ้นต่อกัน (Assumptions and Dependencies)
* สมมติว่าระบบบริการค้นหาข้อมูลภายนอก (Google Vision API) เปิดบริการตามปกติและมีอัตราการเชื่อมต่อที่เสถียร
* โมเดล AI จำเป็นต้องมีการเก็บรวบรวมรูปภาพสแกมไทย (Thai-Context Scam Images) เพิ่มเติมอย่างต่อเนื่องเพื่ออัปเดตโมเดลให้เข้ากับกลโกงรูปแบบใหม่ๆ

---

## 3. ข้อกำหนดความต้องการเชิงระบบ (System Requirements)

### 3.1 ความต้องการทางธุรกิจ (Business Requirements - BR)

| รหัส (BR-ID) | รายละเอียดความต้องการทางธุรกิจ | เหตุผล / คุณค่าทางธุรกิจ (Business Value) |
| :--- | :--- | :--- |
| **BR-01** | ระบบต้องช่วยให้ผู้ใช้สามารถอัปโหลดและตรวจสอบรูปภาพที่น่าสงสัยผ่านสมาร์ทโฟนได้ | ป้องกันความสูญเสียทรัพย์สินและทำให้ประชาชนรู้เท่าทันกลโกงได้ทุกที่ทุกเวลา |
| **BR-02** | ระบบต้องวิเคราะห์ภาพแบบหลายชั้น (ข้อความ, แหล่งที่มา, การตัดต่อ, AI) ได้อัตโนมัติ | เพิ่มความแม่นยำในการตรวจสอบและลดข้อผิดพลาดที่เกิดจากการประเมินด้วยสายตามนุษย์ |
| **BR-03** | ระบบต้องสามารถแสดงคำอธิบายผลลัพธ์ผ่านแผนที่ความร้อน (Heatmap) ได้ | สร้างความน่าเชื่อถือ (Trust) และเพิ่มความตระหนักรู้ทางดิจิทัล (Digital Literacy) ให้ผู้ใช้ |
| **BR-04** | ระบบต้องประมวลผลได้อย่างรวดเร็ว หรือมีการแจ้งเตือน (Push Notification) เมื่อเสร็จสิ้น | มอบประสบการณ์ใช้งานที่ดี (UX) ทำให้ผู้ใช้ไม่ต้องเปิดหน้าจอแอปพลิเคชันค้างไว้เพื่อรอผล |
| **BR-05** | ระบบต้องสามารถจัดเก็บประวัติการสแกนและเรียกดูย้อนหลังได้ | ช่วยให้ผู้ใช้มีระบบจัดเก็บข้อมูลที่เป็นระเบียบ และสามารถนำมาใช้เป็นหลักฐานอ้างอิงได้ในภายหลัง |
| **BR-06** | ระบบต้องเปิดให้ผู้ใช้สามารถส่งรายงาน (Report) รูปภาพตัดต่อหลอกลวงเข้าสู่ระบบส่วนกลางได้ | สร้างความร่วมมือในชุมชน (Crowdsourcing) และรวบรวมข้อมูลเพื่อใช้สอน AI ในอนาคต |
| **BR-07** | ระบบต้องสามารถแชร์ (Share) หรือส่งออกภาพผลลัพธ์ความเสี่ยงไปยังแอปพลิเคชันอื่นได้ | เพื่อให้ผู้ใช้สามารถส่งภาพแจ้งเตือนภัยไปยังบุคคลใกล้ชิด (เช่น ผ่าน LINE) ได้อย่างสะดวกรวดเร็ว |
| **BR-08** | ระบบต้องจัดเก็บข้อมูลและประวัติผู้ใช้งานด้วยมาตรการรักษาความปลอดภัย (PDPA Compliance) | ป้องกันการรั่วไหล of ข้อมูลส่วนบุคคล และสร้างความมั่นใจในการใช้งานแอปพลิเคชัน |
| **BR-09** | ระบบต้องมีหน้าแดชบอร์ด (Admin Dashboard) และระบบควบคุมสิทธิ์ผู้ใช้ (RBAC) | ช่วยให้ผู้ดูแลระบบสามารถควบคุม ตรวจสอบ และบริหารจัดการระบบได้อย่างมีประสิทธิภาพ |
| **BR-10** | ระบบต้องรองรับการจัดการชุดข้อมูล (Dataset) และการอัปเดตโมเดล AI โดยผู้ดูแลระบบ | เพื่อให้ระบบมีความยืดหยุ่น สามารถเรียนรู้กลโกงรูปแบบใหม่ๆ และรักษาความแม่นยำได้ในระยะยาว |

### 3.2 ความต้องการเชิงฟังก์ชัน (Functional Requirements - FR)

| รหัส (FR-ID) | รายละเอียดความต้องการเชิงฟังก์ชัน |
| :--- | :--- |
| **FR-01** | **ระบบเข้าสู่ระบบและยืนยันตัวตน (Authentication):** ผู้ใช้และผู้ดูแลระบบสามารถเข้าสู่ระบบผ่าน Email/Password หรือโซเชียลมีเดีย พร้อมระบบกู้คืนรหัสผ่าน |
| **FR-02** | **ระบบนำเข้ารูปภาพ (Image Input):** ผู้ใช้สามารถอัปโหลดรูปภาพที่ต้องการตรวจสอบได้จากคลังภาพ (Gallery) หรืออัปโหลดไฟล์ภาพเข้าสู่ระบบ |
| **FR-03** | **ระบบวิเคราะห์ข้อมูลชั้นต้น (Primary Analysis):** ระบบสามารถดึงข้อมูลแฝง (Metadata/EXIF), สกัดข้อความในภาพ (OCR), และค้นหาแหล่งที่มาของภาพ (Reverse Image Search) ได้โดยอัตโนมัติ |
| **FR-04** | **ระบบวิเคราะห์ด้วยปัญญาประดิษฐ์ (AI Inference):** ระบบส่งภาพเข้าสู่โมเดล Deep Learning เพื่อตรวจสอบร่องรอยการตัดต่อ (Image Forgery/ELA) และตรวจสอบภาพที่สร้างด้วยปัญญาประดิษฐ์ (AI-Generated) |
| **FR-05** | **ระบบแสดงผลลัพธ์ (Result & Visualization):** ระบบคำนวณคะแนนความเสี่ยงรวม (Weighted Risk Score) และสร้างแผนที่ความร้อน (Grad-CAM Heatmap) เพื่ออธิบายผลลัพธ์ให้ผู้ใช้เข้าใจ |
| **FR-06** | **ระบบแจ้งเตือน (Push Notification):** ระบบสามารถส่งข้อความแจ้งเตือนผู้ใช้งานผ่าน Firebase Cloud Messaging (FCM) เมื่อการวิเคราะห์ภาพเบื้องหลัง (Background Task) เสร็จสิ้น |
| **FR-07** | **ระบบจัดการประวัติการสแกน (History Management):** ระบบบันทึกประวัติการตรวจสอบภาพของผู้ใช้โดยสามารถเรียกดูผลลัพธ์ย้อนหลัง หรือลบประวัติได้ |
| **FR-08** | **ระบบรายงานและแชร์ข้อมูล (Report & Share):** ผู้ใช้สามารถกดรายงาน (Report) ภาพหลอกลวงเข้าสู่ฐานข้อมูลกลาง และสามารถแชร์ภาพผลลัพธ์/คำเตือนไปยังแอปพลิเคชันภายนอกได้ |
| **FR-09** | **ระบบผู้ดูแลและการจัดการสิทธิ์ (Admin & RBAC):** มีหน้าแดชบอร์ดให้ผู้ดูแลระบบตรวจสอบสถิติการใช้งาน, จัดการข้อมูลผู้ใช้, และกำหนดสิทธิ์การเข้าถึงระบบตามบทบาท |
| **FR-10** | **ระบบจัดการข้อมูลและโมเดล (Dataset & Model Management):** ผู้ดูแลระบบสามารถตรวจสอบรูปภาพที่ถูกผู้ใช้รายงาน นำไปจัดหมวดหมู่ชุดข้อมูล และอัปโหลดโมเดล AI (Weights) เวอร์ชันใหม่เข้าสู่ระบบได้ |

### 3.3 ความต้องการที่ไม่ใช่ฟังก์ชัน (Non-Functional Requirements - NFR)

| รหัส (NFR-ID) | รายละเอียดคุณภาพของระบบ (Non-Functional Requirements) |
| :--- | :--- |
| **NFR-01** | **ประสิทธิภาพความเร็ว (Performance):** ระบบต้องดึงผลลัพธ์จาก Cache ได้ภายใน 1 วินาที และหากต้องประมวลผลผ่าน AI ใหม่ทั้งหมด ต้องใช้เวลาไม่เกิน 15 วินาทีต่อภาพ |
| **NFR-02** | **สถาปัตยกรรมระบบ (Architecture):** ระบบต้องออกแบบเป็น Microservices โดยแยกส่วน API Gateway ออกจาก AI Inference Service เพื่อป้องกันปัญหาคอขวด (Resource Isolation) |
| **NFR-03** | **การคุ้มครองข้อมูลส่วนบุคคล (PDPA Compliance):** ระบบต้องมีการขอความยินยอม (Consent) และจัดเก็บข้อมูลประวัติการสแกนของผู้ใช้ด้วยความรัดกุม ป้องกันการเข้าถึงโดยไม่ได้รับอนุญาต |
| **NFR-04** | **ความมั่นคงปลอดภัยของข้อมูล (Security):** ข้อมูลที่มีการรับส่งระหว่างแอปพลิเคชันและเซิร์ฟเวอร์ต้องเข้ารหัสผ่านโปรโตคอล TLS 1.3 และรหัสผ่านต้องถูกเข้ารหัสแบบ Hashing ไว้ในฐานข้อมูลเสมอ |
| **NFR-05** | **การรองรับการใช้งาน:** แอปพลิเคชันฝั่งผู้ใช้ (Mobile App) ต้องรองรับการทำงานได้อย่างสมบูรณ์บนระบบปฏิบัติการ Android |
| **NFR-06** | **การเพิ่มขยายของระบบ (Scalability):** สถาปัตยกรรมฝั่งเซิร์ฟเวอร์ต้องรองรับการขยายตัว (Scale-out) ของคอนเทนเนอร์ AI Inference ได้อย่างอิสระ เมื่อมีปริมาณผู้ใช้งานเพิ่มสูงขึ้น |
| **NFR-07** | **ความเสถียรภาพ (Availability):** ระบบต้องมีเสถียรภาพสูง (Uptime) พร้อมใช้งาน และมีระบบจัดการข้อผิดพลาด (Error Handling) ที่ไม่ทำให้แอปพลิเคชันปิดตัวลงกะทันหัน (Crash) |
| **NFR-08** | **การเพิ่มประสิทธิภาพด้วยแคช (Caching Optimization):** ระบบต้องนำ Redis มาใช้จัดเก็บผลลัพธ์ชั่วคราว เพื่อลดภาระการทำงานซ้ำซ้อนของ AI และลดค่าใช้จ่ายในการเรียกใช้ External API |
| **NFR-09** | **ความง่ายในการใช้งาน (Usability):** ส่วนติดต่อผู้ใช้งาน (UI) ต้องออกแบบให้ใช้งานง่าย (Intuitive) ผู้ใช้งานทั่วไปสามารถเข้าใจผลลัพธ์ Heatmap ได้โดยไม่ต้องมีพื้นฐานด้านเทคนิคคอมพิวเตอร์ |
| **NFR-10** | **การตรวจสอบย้อนหลัง (Auditability):** ทุกการทำงานที่สำคัญของผู้ดูแลระบบ (เช่น การลบผู้ใช้, การอัปเดตโมเดล) จะต้องถูกเก็บบันทึก Log ไว้เพื่อการตรวจสอบด้านความปลอดภัยย้อนหลัง |



## 5. สถาปัตยกรรมและข้อกำหนดโมเดลปัญญาประดิษฐ์ (AI Model Specifications)

### 5.1 การตั้งค่าพารามิเตอร์ อัลกอริทึมและสมการคณิตศาสตร์ที่ใช้

เอกสารฉบับนี้รวบรวมสมการคณิตศาสตร์ อัลกอริทึม และค่าการตั้งค่า (Configurations) หลักที่ใช้ในกระบวนการประมวลผล ประเมินผลลัพธ์ และการฝึกสอนโมเดล AI ภายในระบบ Scam Image Detection พร้อมคำอธิบายเหตุผลและหลักการที่อยู่เบื้องหลังการออกแบบแต่ละส่วน

---

## 1. การคำนวณคะแนนความเสี่ยงรวม (Weighted Risk Score)

ระบบประมวลผลคะแนนความเสี่ยงของรูปภาพโดยรวมผลลัพธ์จากการวิเคราะห์หลายชั้นเข้าด้วยกัน โดยใช้สมการแบบถ่วงน้ำหนัก (Weighted Average) ซึ่งอ้างอิงตามสถาปัตยกรรมล่าสุด (2 ปัจจัยหลัก):

$$ S_{total} = (\alpha \times S_{visual}) + (\beta \times S_{textual}) $$

โดยที่:
* **$S_{total}$** คือ คะแนนความเสี่ยงรวม (Weighted Risk Score) มีค่าตั้งแต่ 0 ถึง 100
* **$S_{visual}$** คือ คะแนนความผิดปกติทางภาพ (Visual Anomaly Score) จากโมเดล SegFormer
* **$S_{textual}$** คือ คะแนนความเสี่ยงด้านข้อความ (Textual Analysis Score) จากโมเดล OCR + NLP
* **$\alpha$** คือ น้ำหนักของการวิเคราะห์ภาพ (ค่าปัจจุบันตั้งไว้ที่ **0.6** หรือ 60%)
* **$\beta$** คือ น้ำหนักของการวิเคราะห์ข้อความ (ค่าปัจจุบันตั้งไว้ที่ **0.4** หรือ 40%)

**คำอธิบายและเหตุผลที่ใช้:**
* **เหตุผลการถ่วงน้ำหนัก:** ระบบให้น้ำหนักทางด้านภาพ ($S_{visual}$) สูงถึง 60% เนื่องจากเป็นสัญญาณนิติวิทยาศาสตร์ที่มีความแม่นยำที่สุด เป็นหลักฐานที่เกิดจากการประมวลผลระดับพิกเซล ในขณะที่ข้อความ ($S_{textual}$) อาจมีความคลุมเครือตามบริบทหรือภาพบางชนิดอาจไม่มีข้อความเลย จึงได้น้ำหนักเพียง 40%
* **ประโยชน์:** ผู้ใช้งานจะได้รับตัวเลขเดียวเพื่อใช้ในการตัดสินใจได้อย่างรวดเร็ว โดยคำนึงถึงความเสี่ยงทั้งจากร่องรอยการตัดต่อภาพ และจากข้อความหลอกลวงที่ปรากฏอยู่ในภาพไปพร้อมๆ กัน

---

## 2. เกณฑ์การตัดสินระดับความเสี่ยง (Risk Grading Thresholds)

เมื่อคำนวณคะแนน $S_{total}$ ออกมาแล้ว ระบบจะนำไปจัดกลุ่มระดับความเสี่ยงตามเงื่อนไข (Threshold Configuration) ดังนี้:

$$
\text{Risk Grade} = 
\begin{cases} 
\text{Safe (ปลอดภัย)} & \text{if } S_{total} < 30 \\
\text{Suspicious (น่าสงสัย)} & \text{if } 30 \le S_{total} \le 70 \\
\text{Danger (อันตราย)} & \text{if } S_{total} > 70 
\end{cases}
$$

**คำอธิบายและเหตุผลที่ใช้:**
* **ช่วงปลอดภัย (< 30):** คะแนนตกอยู่ในช่วงที่ทั้งภาพและข้อความไม่มีลักษณะเข้าข่ายการหลอกลวง ถือว่าเชื่อถือได้ในระดับสูง
* **ช่วงน่าสงสัย (30 – 70):** โมเดลตัวใดตัวหนึ่ง (ภาพ หรือ ข้อความ) ตรวจพบความผิดปกติบางอย่าง แต่อีกตัวหนึ่งไม่พบ หรือพบหลักฐานแบบอ่อนๆ ผู้ใช้งานควรพิจารณาประกอบกับวิจารณญาณส่วนตัว
* **ช่วงอันตราย (> 70):** โมเดลทั้งคู่ชี้ไปในทิศทางเดียวกันว่าภาพถูกปรับแต่งหรือมีข้อความหลอกลวงที่ชัดเจน ให้ถือว่าภาพนี้มีความเสี่ยงสูงที่จะเป็นสแกม

---

## 3. การคำนวณคะแนนความเสี่ยงทางภาพ ($S_{visual}$)

การได้มาซึ่งคะแนน $S_{visual}$ จากโมเดล SegFormer อาศัยความน่าจะเป็นของการเป็นรอยตัดต่อ (Confidence Score) และสัดส่วนพื้นที่ที่พบความผิดปกติ (Mask Coverage):

$$ S_{visual} = \text{Normalize}(\text{Confidence} \times \text{Mask Coverage}) $$

**คำอธิบายและเหตุผลที่ใช้:**
* **Confidence Score:** คือค่าความมั่นใจของ AI ว่าพิกเซลนั้นๆ ถูกดัดแปลงจริงหรือไม่ (มีค่าความน่าจะเป็น 0 - 1)
* **Mask Coverage:** คือขนาดของพื้นที่ (Bounding Box หรือ Segmentation Mask) ที่พบการตัดต่อ เทียบกับพื้นที่ทั้งหมดของภาพ
* **หลักการคิด:** หากมีการแก้ไขภาพด้วยความเนียนที่ต่ำ (Confidence สูง) และแก้พื้นที่เยอะ (Coverage สูง) คะแนนความเสี่ยงทางภาพ ($S_{visual}$) จะยิ่งมีค่าสูงขึ้น ในขณะที่รอยแก้เล็กๆ แม้ Confidence สูง ก็จะมีผลต่อคะแนนลดลงบ้างตามสัดส่วน
* *(ค่าที่ได้จะถูกปรับสเกล (Normalize) ให้อยู่ในช่วง 0-100 ก่อนนำไปคำนวณ)*

---

## 4. สมการสำหรับการฝึกสอนโมเดลและการตั้งค่า Loss Function (Training Configurations)

เพื่อเพิ่มความแม่นยำในการเทรนโมเดลจำแนกพิกเซล (Semantic Segmentation) ระบบใช้ **Loss Function** แบบผสมผสานระหว่าง Binary Cross-Entropy (BCE) และ Dice Loss:

$$ L = L_{BCE} + L_{Dice} $$

การปรับน้ำหนักของโมเดล (Weight Update) ใช้เทคนิค **Differential Learning Rates** ผ่าน AdamW Optimizer โดยมีการตั้งค่าตัวคูณ (Multiplier) ที่แตกต่างกัน:

1. **Backbone Configuration (เรียนรู้ช้า):** `lr_mult = 0.1`
$$ \theta_{backbone}^{(t+1)} = \theta_{backbone}^{(t)} - (\eta \times 0.1) \frac{\partial L}{\partial \theta_{backbone}} $$

2. **Classification Head Configuration (เรียนรู้เร็ว):** `lr_mult = 10.0`
$$ \theta_{head}^{(t+1)} = \theta_{head}^{(t)} - (\eta \times 10.0) \frac{\partial L}{\partial \theta_{head}} $$
*(โดย $\eta$ คือค่า Base Learning Rate ของระบบ)*

**คำอธิบายและเหตุผลที่ใช้:**
* **การผสม BCE และ Dice Loss:** 
  * $L_{BCE}$ ช่วยบังคับให้โมเดลประเมินค่าความน่าจะเป็นของแต่ละพิกเซลได้อย่างแม่นยำ 
  * $L_{Dice}$ ช่วยรักษารูปทรงและขอบเขต (Boundary) ของรอยตัดต่อให้คมชัด ลดปัญหาความไม่สมดุลของข้อมูลระหว่างบริเวณพิกเซลจริงที่มีมาก กับพิกเซลรอยแก้ที่มีน้อย
* **Differential Learning Rates:** ระบบต้องการเก็บความสามารถเดิมในการสกัดจุดเด่นของภาพ (Feature Extraction) จากโมเดลที่พรีเทรนมาแล้วเอาไว้ (ป้องกัน Catastrophic Forgetting) จึงสั่งให้แกนหลัก (Backbone) เรียนรู้ช้าสุดๆ (`0.1`) แต่ขณะเดียวกันเราต้องการให้ส่วนประมวลผลปลายทาง (Classification Head) ปรับตัวเข้าหาความรู้ใหม่และข้อมูลภาพสลิปใบเสร็จใหม่ๆ จึงให้เรียนรู้เร็วถึง (`10.0`) เท่า

---

## 5. สมการประเมินประสิทธิภาพโมเดล (Evaluation Metrics)

ระบบอาศัยการวัดผลทั้งในระดับภาพรวมและระดับพิกเซล เพื่อนำมาตั้งค่า Validation Checkpoint

* **Accuracy:**
$$ \text{Accuracy} = \frac{TP + TN}{TP + TN + FP + FN} $$

* **F1-Score (ใช้จัดการ Imbalanced Data):**
$$ \text{F1-Score} = 2 \times \frac{\text{Precision} \times \text{Recall}}{\text{Precision} + \text{Recall}} $$

* **IoU (Intersection over Union) / Dice Coefficient (สำหรับระดับพิกเซล):**
$$ \text{IoU} = \frac{TP}{TP + FP + FN} $$
$$ \text{Dice} = \frac{2TP}{2TP + FP + FN} $$

**คำอธิบายและเหตุผลที่ใช้:**
* **ค่า TP, TN, FP, FN:** TP (ตรวจถูกว่าเป็นภาพปลอม), TN (ตรวจถูกว่าเป็นภาพจริง), FP (ตรวจผิดว่าเป็นภาพปลอม ทั้งที่จริง), FN (ตรวจหลุดว่าเป็นภาพจริง ทั้งที่ปลอม)
* **ข้อจำกัดของ Accuracy:** ความแม่นยำรวม (Accuracy) มักหลอกตาในกรณีที่ภาพสแกม (Scam) ในชุดข้อมูลมีน้อยมาก (Imbalanced Data) ตัวอย่างเช่น มีภาพแท้ 95 ภาพ ภาพสแกม 5 ภาพ โมเดลตอบภาพแท้เสมอ ก็จะได้ Accuracy 95% ทันที
* **การใช้ F1-Score, IoU, mDice:** จึงมีความจำเป็นในการใช้ F1-Score (ทั้งระดับภาพรวมและระดับพิกเซล) เพื่อบังคับให้โมเดลต้องหาความสมดุลระหว่างความไว (Recall) และความแม่นยำ (Precision) ทำให้การวัดผลภาพสแกมและการพ่นสี Heatmap ของรอยตัดต่อ มีความน่าเชื่อถือที่สุด


# รายละเอียดการฝึกสอนและการอัปเดตโมเดล (AI Model Training Strategy)
## โครงงาน: แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Scam Image Detection)

เอกสารฉบับนี้อธิบายรายละเอียดเกี่ยวกับกลยุทธ์การฝึกสอนโมเดล (Training Strategy) การอัปเดตน้ำหนักโมเดลอย่างต่อเนื่อง และการนำโมเดลไปใช้งาน (Deployment) ซึ่งเป็นส่วนต่อขยายจากข้อมูลใน `doc/model/model.md`

---

## 1. กลยุทธ์การเทรนและการอัปเดตโมเดล (Training Strategy)

เพื่อให้ระบบสามารถรับมือกับรูปแบบการหลอกลวงหรือภาพสแกมประเภทใหม่ๆ ได้อย่างรวดเร็วและใช้ทรัพยากรอย่างมีประสิทธิภาพ ระบบได้กำหนดกลยุทธ์การเทรนโมเดลหลักดังนี้:

* **Differential Learning Rates (การใช้อัตราการเรียนรู้ที่ต่างกัน):** ในกระบวนการเทรน (ทั้งโมเดลเริ่มต้นและโมเดลเพิ่มเติม) จะไม่มีการแช่แข็งค่าน้ำหนัก (Freeze) แบบ 100% แต่จะใช้วิธีปรับอัตราการเรียนรู้ให้ต่างกัน โดยให้ส่วน Feature Extractor หรือ Backbone เรียนรู้ช้ามากๆ เพื่อรักษาระดับความรู้เดิม (Catastrophic Forgetting) และให้ส่วน Classification Head หรือ Decoder เรียนรู้ได้อย่างรวดเร็ว
* **Incremental Training (การเทรนเพิ่มเติม):** ระบบอนุญาตให้รับข้อมูลภาพหลอกลวงรูปแบบใหม่เข้ามาเทรนเพิ่มเติมผ่านหน้า Admin Page แบบออนไลน์ได้
* **Hot Swap (การสลับใช้งานแบบทันที):** ระบบสามารถนำโมเดลตัวใหม่ที่ผ่านการเทรนเพิ่มเติมไปสลับใช้งานเข้าสู่ AI Inference Service ได้ทันทีโดยไม่ต้องหยุดการทำงานของเซิร์ฟเวอร์ (Zero-downtime)

### 1.1 อัลกอริทึมและสมการคณิตศาสตร์ที่ใช้ในการเทรน (Training Algorithm)

เนื่องจากระบบใช้แนวทางการ **Differential Learning Rates** ให้ $\theta_{backbone}$ แทนค่าน้ำหนักของเครือข่ายหลัก และ $\theta_{head}$ แทนค่าน้ำหนักของส่วนวิเคราะห์ผลลัพธ์ (Classification Head) 

ฟังก์ชันสูญเสีย (Loss Function) สำหรับการแยกแยะรูปภาพตัดต่อ (Binary Classification) สำหรับทุกระดับพิกเซล จะใช้ **Binary Cross-Entropy Loss (BCE Loss)** ผสมกับ **Dice Loss** (อ้างอิงตามโค้ดตั้งค่า `loss_decode`):
$$ L = L_{BCE} + L_{Dice} $$

การอัปเดตน้ำหนัก (Weight Update) ของโมเดลจะใช้การคำนวณผ่านอัลกอริทึม **AdamW Optimization** โดยมีค่าตัวคูณอัตราการเรียนรู้ (Learning Rate Multiplier) ที่ต่างกัน:

1. **สำหรับ Backbone (เรียนรู้ช้า `lr_mult=0.1`):**
$$ \theta_{backbone}^{(t+1)} = \theta_{backbone}^{(t)} - (\eta \times 0.1) \frac{\partial L}{\partial \theta_{backbone}} $$

2. **สำหรับ Classification Head / Decoder (เรียนรู้เร็ว `lr_mult=10.0`):**
$$ \theta_{head}^{(t+1)} = \theta_{head}^{(t)} - (\eta \times 10.0) \frac{\partial L}{\partial \theta_{head}} $$
*(โดย $\eta$ คือค่า Learning Rate มาตรฐาน)*

---

## 2. ขั้นตอนการประเมินและวัดผล (Evaluation & Metrics)

* **ความแม่นยำรวมของ AI (F1-Score / Accuracy):** เป้าหมายอยู่ที่ความแม่นยำ >= 85% สำหรับการตรวจจับภาพตัดต่อและการแยกแยะจุดเสี่ยง
* **Validation Checkpoint:** ในแต่ละรอบการเทรนจะมีการเซฟ Checkpoint เมื่อผลลัพธ์การเรียนรู้ (Loss) ต่ำสุด เพื่อนำไฟล์น้ำหนักเหล่านั้นไปใช้ต่อ หรือ Rollback หากเกิดความผิดพลาด

### 2.1 สมการคณิตศาสตร์สำหรับการวัดประสิทธิภาพ (Evaluation Metrics)

การวัดผลโมเดลจำแนกรูปภาพจะอ้างอิงจากค่า Confusion Matrix ประกอบด้วย:
- **TP (True Positive):** ทายว่าเป็นภาพตัดต่อ และเป็นภาพตัดต่อจริง
- **TN (True Negative):** ทายว่าเป็นภาพจริง และเป็นภาพจริงตามนั้น
- **FP (False Positive):** ทายว่าเป็นภาพตัดต่อ แต่จริงๆ เป็นภาพแท้ (Type I Error)
- **FN (False Negative):** ทายว่าเป็นภาพจริง แต่จริงๆ เป็นภาพตัดต่อ (Type II Error)

สมการที่ใช้ในการวัดผล ได้แก่:

**1. Accuracy (ความแม่นยำรวม):**
$$ \text{Accuracy} = \frac{TP + TN}{TP + TN + FP + FN} $$

**2. Precision (ความแม่นยำเชิงผลบวก):**
เพื่อดูว่าเมื่อระบบเตือนว่าเป็นภาพสแกม เชื่อถือได้แค่ไหน:
$$ \text{Precision} = \frac{TP}{TP + FP} $$

**3. Recall (ความไว หรือ Sensitivity):**
เพื่อดูว่าระบบสามารถตรวจจับภาพสแกมได้ครอบคลุมกี่เปอร์เซ็นต์ของภาพสแกมทั้งหมด:
$$ \text{Recall} = \frac{TP}{TP + FN} $$

**4. F1-Score (ค่าเฉลี่ยฮาร์มอนิก):**
ใช้ประเมินโมเดลในกรณีที่ข้อมูลภาพแท้และภาพสแกมอาจมีจำนวนไม่สมดุลกัน (Imbalanced Dataset):
$$ \text{F1-Score} = 2 \times \frac{\text{Precision} \times \text{Recall}}{\text{Precision} + \text{Recall}} $$

### 2.2 สมการคณิตศาสตร์สำหรับการวัดประสิทธิภาพของ Pixel (Semantic Segmentation Metrics)

เนื่องจากระบบใช้ SegFormer ในการวิเคราะห์และทำนายความผิดปกติในระดับพิกเซล (Pixel-level) การวัดผลจึงใช้เมทริกซ์เฉพาะทางสำหรับงาน Segmentation โดยอ้างอิงจากคลาสที่ระบบทำนาย ได้แก่ **mIoU (Mean Intersection over Union)** และ **mDice (Mean Dice Coefficient)**:

**1. IoU (Intersection over Union / Jaccard Index):**
ใช้วัดความทับซ้อนระหว่างพื้นที่พิกเซลที่โมเดลทำนายได้ ($A$) กับพื้นที่จริงที่เป็นรอยตัดต่อ ($B$):
$$ \text{IoU} = \frac{|A \cap B|}{|A \cup B|} = \frac{TP}{TP + FP + FN} $$
*mIoU คือการหาค่าเฉลี่ยของ IoU ในทุกๆ คลาส (ภาพจริง, ภาพตัดต่อ)*

**2. Dice Coefficient (F1-Score ระดับพิกเซล):**
ให้ความสำคัญกับการซ้อนทับกันของพิกเซลที่ตรวจจับได้คล้ายคลึงกับ F1-Score:
$$ \text{Dice} = \frac{2 |A \cap B|}{|A| + |B|} = \frac{2TP}{2TP + FP + FN} $$
*mDice คือการหาค่าเฉลี่ยของ Dice Coefficient ในทุกๆ คลาส*

---

## 3. เอกสารอ้างอิงและส่วนที่เกี่ยวข้อง

* **การออกแบบโมเดลโดยละเอียด:** สามารถอ่านสถาปัตยกรรมการทำงานของโมเดลทั้งหมดได้ที่เอกสาร [model.md](./model.md)
* **สถาปัตยกรรมระดับซอฟต์แวร์สำหรับการเทรน:** ดูข้อมูลทางด้าน Software Architecture สำหรับภาพรวมการเทรนโมเดลเต็มรูปแบบได้ที่เอกสาร [Model Training Design](../../design/training.md)
* **สถาปัตยกรรมโมเดลเชิงระบบ:** ดูภาพรวมและเหตุผลการเลือกใช้เทคโนโลยีระดับแอปพลิเคชันที่เอกสาร [AI Model Design](../../design/model.md)


## 6. เมตริกย้อนกลับความต้องการ (Traceability Matrix)

#### 6.1 ตารางตรวจสอบย้อนกลับความต้องการ (BR & FR/NFR Mapping)

| รหัส BR | รายละเอียดความต้องการทางธุรกิจ | รหัส FR ที่เกี่ยวข้อง | รหัส NFR ที่เกี่ยวข้อง | หมายเหตุ / การเชื่อมโยง |
| :--- | :--- | :--- | :--- | :--- |
| **BR-01** | อัปโหลดและตรวจสอบรูปภาพผ่านสมาร์ทโฟน | FR-02 | NFR-05 | ฟังก์ชันหลักฝั่ง Mobile App (Cross-Platform) |
| **BR-02** | วิเคราะห์ภาพแบบหลายชั้นอัตโนมัติ | FR-03, FR-04 | NFR-02 | ประมวลผลผ่านสถาปัตยกรรม Microservices |
| **BR-03** | แสดงแผนที่ความร้อน (Heatmap) อธิบายผล | FR-05 | NFR-09 | แสดงผลภาพ XAI เพื่อเพิ่มความเข้าใจ (Usability) |
| **BR-04** | ประมวลผลรวดเร็ว / แจ้งเตือนเมื่อเสร็จสิ้น | FR-06 | NFR-01, NFR-08 | ใช้ Redis Cache และ Firebase Push Notification |
| **BR-05** | จัดเก็บประวัติการสแกนย้อนหลัง | FR-07 | NFR-03 | เรียกดูประวัติโดยอิงตามข้อกำหนด PDPA |
| **BR-06** | ส่งรายงาน (Report) รูปภาพหลอกลวง | FR-08 | NFR-09 | ผู้ใช้ช่วยแจ้งเบาะแสเพื่อให้แอดมินตรวจสอบ |
| **BR-07** | แชร์ภาพผลลัพธ์ไปยังแอปพลิเคชันอื่น | FR-08 | NFR-04 | แชร์คำเตือนภัยไปยังแอปแชทภายนอกอย่างปลอดภัย |
| **BR-08** | รักษาความปลอดภัยตามมาตรการ (PDPA) | FR-01 | NFR-03, NFR-04 | การเข้ารหัสข้อมูล (TLS 1.3/Hashing) และ Auth |
| **BR-09** | หน้าแดชบอร์ดจัดการผู้ดูแลระบบ (RBAC) | FR-09 | NFR-10 | แอดมินตรวจสอบข้อมูลและมีการเก็บ Log |
| **BR-10** | จัดการชุดข้อมูลและอัปเดตโมเดล AI | FR-10 | NFR-06, NFR-07 | รองรับการขยายตัว (Scalability) โดยระบบไม่ขัดข้อง |

#### 6.2 ตารางตรวจสอบย้อนกลับระหว่างวัตถุประสงค์และความต้องการ (Objectives-Requirements Mapping)

| ลำดับวัตถุประสงค์ | วัตถุประสงค์ของโครงงาน | รหัส FR ที่เกี่ยวข้อง | รหัส NFR ที่เกี่ยวข้อง | หมายเหตุ |
| :---: | :--- | :--- | :--- | :--- |
| **OBJ-01** | เพื่อพัฒนาแอปพลิเคชันบนอุปกรณ์เคลื่อนที่สำหรับคัดกรองรูปภาพที่มีความเสี่ยง | FR-01, FR-02, FR-05, FR-07 | NFR-05, NFR-09 | ครอบคลุมการทำงานตั้งแต่ล็อกอิน อัปโหลด แสดงผล และดูประวัติ บน Android |
| **OBJ-02** | เพื่อประยุกต์ใช้เทคโนโลยี Deep Learning ตรวจสอบ Image Forgery และ AI-Generated | FR-04, FR-10 | NFR-02, NFR-06 | ระบบ AI Inference แยกการทำงานอิสระ และแอดมินสามารถอัปเดตโมเดลได้ |
| **OBJ-03** | เพื่อพัฒนาระบบวิเคราะห์ความเสี่ยงแบบบูรณาการ (Multi-layer Analysis) | FR-03, FR-04 | NFR-01, NFR-08 | วิเคราะห์ Metadata, OCR และ Source ควบคู่กับการประมวลผลให้รวดเร็วด้วย Cache |
| **OBJ-04** | เพื่อทดสอบและประเมินประสิทธิภาพของระบบ รวมถึงความพึงพอใจของผู้ใช้งาน | FR-06, FR-08, FR-09 | NFR-07, NFR-10 | มีการแจ้งเตือนเพื่อรักษา UX การแชร์เพื่อทดสอบการใช้งานจริง และระบบเก็บ Log |

---

## 4. กรณีการใช้งานของระบบ (Use Cases)

### 4.1 ตารางสรุป Use Case (Use Case Summary Table)

| UC-ID | Use Case Name | Primary Actor | Description | Related FR |
| :--- | :--- | :---: | :--- | :---: |
| **UC-01** | เข้าสู่ระบบ / ยืนยันตัวตน (Login & Authentication) | User / Admin | ผู้ใช้และผู้ดูแลระบบเข้าสู่ระบบโดยใช้ Email/Password หรือโซเชียลมีเดีย เพื่อเข้าถึงระบบตามสิทธิ์ | FR-01 |
| **UC-02** | นำเข้ารูปภาพ (Upload Image) | User | ผู้ใช้อัปโหลดรูปภาพที่น่าสงสัยจากคลังภาพ (Gallery) หรืออัปโหลดไฟล์ภาพ | FR-02 |
| **UC-03** | ประมวลผลภาพขั้นต้น (Primary Analysis) | System | ระบบดำเนินการสกัดข้อความ (OCR), ดึง Metadata, และสืบค้นแหล่งที่มา (Reverse Image Search) อัตโนมัติ | FR-03 |
| **UC-04** | วิเคราะห์ด้วยปัญญาประดิษฐ์ (AI Inference) | System | ระบบประมวลผลผ่านโมเดล Deep Learning เพื่อตรวจหาการตัดต่อ (ELA) และการใช้ AI สร้างภาพ | FR-04 |
| **UC-05** | ตรวจสอบผลลัพธ์และแผนที่ความร้อน (View Result & Heatmap) | User | ผู้ใช้ตรวจสอบคะแนนความเสี่ยงรวม (Risk Score) และดูแผนที่ความร้อน (Grad-CAM) ที่อธิบายจุดผิดปกติ | FR-05 |
| **UC-06** | รับการแจ้งเตือน (Receive Push Notification) | User | ผู้ใช้รับการแจ้งเตือนผ่าน Firebase Cloud Messaging เมื่อระบบ AI วิเคราะห์ภาพเสร็จสิ้น | FR-06 |
| **UC-07** | จัดการประวัติการสแกน (History Management) | User | ผู้ใช้สามารถเรียกดูผลลัพธ์ย้อนหลัง หรือลบประวัติการสแกนภาพของตนเองได้ | FR-07 |
| **UC-08** | รายงานและแชร์ผลลัพธ์ (Report & Share) | User | ผู้ใช้สามารถกดรายงาน (Report) ภาพสแกมเมอร์ หรือแชร์ภาพเตือนภัยไปยังแอปพลิเคชันภายนอกได้ | FR-08 |
| **UC-09** | จัดการผู้ใช้และแดชบอร์ด (Admin Dashboard & RBAC) | Admin | ผู้ดูแลระบบตรวจสอบสถิติ เพิ่ม/ลบผู้ใช้ และกำหนดสิทธิ์การเข้าถึงระบบ | FR-09 |
| **UC-10** | จัดการชุดข้อมูลและอัปเดตโมเดล (Dataset & Model Management) | Admin | ผู้ดูแลระบบตรวจสอบรูปภาพที่ถูก Report เพื่อรวบรวมเป็น Dataset และอัปเดตโมเดล AI ใหม่เข้าสู่ระบบ | FR-10 |

### 4.2 ตารางเชื่อมโยง Use Case และ Functional Requirements

| FR-ID | รายละเอียดความต้องการเชิงฟังก์ชัน | Use Case ที่เกี่ยวข้อง |
| :--- | :--- | :--- |
| **FR-01** | ระบบเข้าสู่ระบบและยืนยันตัวตน (Authentication) | UC-01 |
| **FR-02** | ระบบนำเข้ารูปภาพผ่านกล้องหรือคลังภาพ (Image Input) | UC-02 |
| **FR-03** | ระบบวิเคราะห์ข้อมูลขั้นต้น (Metadata, OCR, Source) | UC-03 |
| **FR-04** | ระบบวิเคราะห์ด้วยปัญญาประดิษฐ์ (AI Inference) | UC-04 |
| **FR-05** | ระบบแสดงผลลัพธ์ Risk Score และภาพ Heatmap | UC-05 |
| **FR-06** | ระบบแจ้งเตือน (Push Notification) เบื้องหลัง | UC-06 |
| **FR-07** | ระบบจัดการประวัติการสแกน (History Management) | UC-07 |
| **FR-08** | ระบบรายงานและแชร์ข้อมูล (Report & Share) | UC-08 |
| **FR-09** | ระบบผู้ดูแลและการจัดการสิทธิ์ (Admin & RBAC) | UC-09 |
| **FR-10** | ระบบจัดการข้อมูลและโมเดล AI (Dataset & Model) | UC-10 |

### 4.3 แผนภาพกรณีการใช้งาน (Use Case Diagram)

```mermaid
flowchart LR
    %% การตั้งค่า Class สีต่างๆ (กำหนด color:black ตามมาตรฐานเดิม)
    classDef actorFill fill:#fff2cc,stroke:#d6b656,color:black
    classDef ucFill fill:#dae8fc,stroke:#6c8ebf,color:black
    classDef extFill fill:#f5f5f5,stroke:#666666,color:black

    %% Actors Boundary
    subgraph Actors [ผู้เกี่ยวข้อง / Actors]
        User("General User<br>[Actor]")
        Admin("Admin<br>[Actor]")
        SystemActor("System (Automated)<br>[Actor]")
    end

    %% System Boundary
    subgraph SystemBoundary [Scam Image Detection System]
        direction TB
        
        UC01("UC-01: เข้าสู่ระบบ / ยืนยันตัวตน<br>(Login & Authentication)")
        UC02("UC-02: นำเข้ารูปภาพ<br>(Upload Image)")
        UC03("UC-03: ประมวลผลภาพขั้นต้น<br>(Primary Analysis)")
        UC04("UC-04: วิเคราะห์ด้วย AI<br>(AI Inference)")
        UC05("UC-05: ตรวจสอบผลลัพธ์และแผนที่ความร้อน<br>(View Result & Heatmap)")
        UC06("UC-06: รับการแจ้งเตือน<br>(Receive Push Notification)")
        UC07("UC-07: จัดการประวัติการสแกน<br>(History Management)")
        UC08("UC-08: รายงานและแชร์ผลลัพธ์<br>(Report & Share)")
        UC09("UC-09: จัดการผู้ใช้และแดชบอร์ด<br>(Admin Dashboard & RBAC)")
        UC10("UC-10: จัดการชุดข้อมูลและอัปเดตโมเดล<br>(Dataset & Model Management)")
    end

    %% External Services
    subgraph ExternalServices [External Services]
        GoogleVision("Google Vision API<br>[Reverse Search]")
        FCM("Firebase Cloud Messaging<br>[FCM]")
    end

    %% Relationships / Associations
    User --> UC01
    User --> UC02
    User --> UC05
    User --> UC06
    User --> UC07
    User --> UC08

    Admin --> UC01
    Admin --> UC09
    Admin --> UC10

    SystemActor --> UC03
    SystemActor --> UC04

    %% External Connections
    UC03 --> GoogleVision
    UC06 --> FCM

    %% Apply Styles
    class User,Admin,SystemActor actorFill
    class UC01,UC02,UC03,UC04,UC05,UC06,UC07,UC08,UC09,UC10 ucFill
    class GoogleVision,FCM extFill
```

##### คำอธิบายรายละเอียดกรณีการใช้งาน (Use Case Details)

* **UC-01: เข้าสู่ระบบ / ยืนยันตัวตน (Login & Authentication):**
  * **ผู้เกี่ยวข้อง (Actors):** General User, Admin
  * **รายละเอียด:** กระบวนการยืนยันตัวตนเพื่อรักษาความปลอดภัยก่อนเข้าใช้งานระบบ โดยเข้าผ่าน Email/Password หรือ Social Login เพื่อทำการตรวจสอบและกำหนดสิทธิ์การดูข้อมูลตามบทบาท (Role-Based Access Control)
  * **ความต้องการทางระบบ (FR):** FR-01 - ระบบเข้าสู่ระบบและยืนยันตัวตน (Authentication): ผู้ใช้และผู้ดูแลระบบสามารถเข้าสู่ระบบผ่าน Email/Password หรือโซเชียลมีเดีย พร้อมระบบกู้คืนรหัสผ่าน

* **UC-02: นำเข้ารูปภาพ (Upload Image):**
  * **ผู้เกี่ยวข้อง (Actors):** General User
  * **รายละเอียด:** ผู้ใช้งานสามารถอัปโหลดภาพที่ต้องการตรวจสอบ เช่น สลิปโอนเงิน หรือรูปโปรไฟล์บุคคลอื่น โดยเลือกรูปที่มีอยู่แล้วในคลังรูปภาพ (Gallery) ของอุปกรณ์เคลื่อนที่
  * **ความต้องการทางระบบ (FR):** FR-02 - ระบบนำเข้ารูปภาพ (Image Input): ผู้ใช้สามารถอัปโหลดรูปภาพที่ต้องการตรวจสอบได้จากคลังภาพ (Gallery) หรืออัปโหลดไฟล์ภาพเข้าสู่ระบบ

* **UC-03: ประมวลผลภาพขั้นต้น (Primary Analysis):**
  * **ผู้เกี่ยวข้อง (Actors):** System (Automated)
  * **รายละเอียด:** การดึงข้อมูลเมทาดาตา (Metadata/EXIF) ของภาพ, การสกัดตัวอักษรด้วยเทคนิค OCR เพื่อวิเคราะห์ Keyword อันตรายร่วมกับเทคนิค NLP และการส่งข้อมูลรูปภาพไปสืบค้นหาแหล่งที่มาดั้งเดิมด้วย Google Vision API
  * **ความต้องการทางระบบ (FR):** FR-03 - ระบบวิเคราะห์ข้อมูลชั้นต้น (Primary Analysis): ระบบสามารถดึงข้อมูลแฝง (Metadata/EXIF), สกัดข้อความในภาพ (OCR), และค้นหาแหล่งที่มาของภาพ (Reverse Image Search) ได้โดยอัตโนมัติ

* **UC-04: วิเคราะห์ด้วย AI (AI Inference):**
  * **ผู้เกี่ยวข้อง (Actors):** System (Automated)
  * **รายละเอียด:** ส่งรูปภาพเพื่อนำเข้าโมเดลปัญญาประดิษฐ์เชิงลึก (Deep Learning) ในการตรวจสอบการแก้ไขระดับพิกเซล (ELA) เพื่อหาร่องรอยการตัดต่อ (Image Forgery) และตรวจสอบลักษณะว่าภาพถูกสังเคราะห์ด้วย Generative AI หรือไม่
  * **ความต้องการทางระบบ (FR):** FR-04 - ระบบวิเคราะห์ด้วยปัญญาประดิษฐ์ (AI Inference): ระบบส่งภาพเข้าสู่โมเดล Deep Learning เพื่อตรวจสอบร่องรอยการตัดต่อ (Image Forgery/ELA) และตรวจสอบภาพที่สร้างด้วยปัญญาประดิษฐ์ (AI-Generated)

* **UC-05: ตรวจสอบผลลัพธ์และแผนที่ความร้อน (View Result & Heatmap):**
  * **ผู้เกี่ยวข้อง (Actors):** General User
  * **รายละเอียด:** หน้าจอแสดงค่าคะแนนความเสี่ยงรวม (Weighted Risk Score) พร้อมแสดงผลสรุปเหตุผลความผิดปกติ และแสดงแผนที่ความร้อน (Grad-CAM Heatmap) บนจุดที่น่าสงสัยของภาพ เพื่อตอบโจทย์ความโปร่งใสของปัญญาประดิษฐ์ (XAI)
  * **ความต้องการทางระบบ (FR):** FR-05 - ระบบแสดงผลลัพธ์ (Result & Visualization): ระบบคำนวณคะแนนความเสี่ยงรวม (Weighted Risk Score) และสร้างแผนที่ความร้อน (Grad-CAM Heatmap) เพื่ออธิบายผลลัพธ์ให้ผู้ใช้เข้าใจ

* **UC-06: รับการแจ้งเตือน (Receive Push Notification):**
  * **ผู้เกี่ยวข้อง (Actors):** General User
  * **รายละเอียด:** การรับข้อความการแจ้งเตือนแบบพุช (Push Notification) ผ่านระบบ Firebase Cloud Messaging (FCM) เมื่อระบบทำการตรวจสอบวิเคราะห์รูปภาพบนเซิร์ฟเวอร์เบื้องหลัง (Background Task) เสร็จสิ้นสมบูรณ์
  * **ความต้องการทางระบบ (FR):** FR-06 - ระบบแจ้งเตือน (Push Notification): ระบบสามารถส่งข้อความแจ้งเตือนผู้ใช้งานผ่าน Firebase Cloud Messaging (FCM) เมื่อการวิเคราะห์ภาพเบื้องหลัง (Background Task) เสร็จสิ้น

* **UC-07: จัดการประวัติการสแกน (History Management):**
  * **ผู้เกี่ยวข้อง (Actors):** General User
  * **รายละเอียด:** ผู้ใช้งานทั่วไปสามารถเรียกดูประวัติรูปภาพและผลคะแนนความเสี่ยงย้อนหลังที่เคยส่งตรวจสอบ เพื่อเก็บบันทึกข้อมูลหรือเรียกดูใหม่ และผู้ใช้สามารถกดลบข้อมูลการสแกนประวัติตนเองได้ตามนโยบาย PDPA
  * **ความต้องการทางระบบ (FR):** FR-07 - ระบบจัดการประวัติการสแกน (History Management): ระบบบันทึกประวัติการตรวจสอบภาพของผู้ใช้โดยสามารถเรียกดูผลลัพธ์ย้อนหลัง หรือลบประวัติได้

* **UC-08: รายงานและแชร์ผลลัพธ์ (Report & Share):**
  * **ผู้เกี่ยวข้อง (Actors):** General User
  * **รายละเอียด:** การกดรายงาน (Report) ส่งยืนยันภาพหลอกลวงเข้าคลังสแกมเมอร์ส่วนกลางเพื่อเป็นประโยชน์ในอนาคต และสามารถกดแชร์ภาพสรุปความเสี่ยงหรือคำเตือนภัยไปยังสื่อโซเชียลภายนอก (เช่น LINE) เพื่อเตือนภัยบุคคลใกล้ชิด
  * **ความต้องการทางระบบ (FR):** FR-08 - ระบบรายงานและแชร์ข้อมูล (Report & Share): ผู้ใช้สามารถกดรายงาน (Report) ภาพหลอกลวงเข้าสู่ฐานข้อมูลกลาง และสามารถแชร์ภาพผลลัพธ์/คำเตือนไปยังแอปพลิเคชันภายนอกได้

* **UC-09: จัดการผู้ใช้และแดชบอร์ด (Admin Dashboard & RBAC):**
  * **ผู้เกี่ยวข้อง (Actors):** Admin
  * **รายละเอียด:** แอดมินเข้าใช้งานหน้าเว็บแผงควบคุมระบบ (Admin Panel) เพื่อติดตามกราฟสถิติการใช้งาน, จัดการข้อมูลของผู้ใช้งาน, ตรวจสอบสิทธิ์การเข้าถึง และการอนุมัติจัดการรายงานต่าง ๆ
  * **ความต้องการทางระบบ (FR):** FR-09 - ระบบผู้ดูแลและการจัดการสิทธิ์ (Admin & RBAC): มีหน้าแดชบอร์ดให้ผู้ดูแลระบบตรวจสอบสถิติการใช้งาน, จัดการข้อมูลผู้ใช้, และกำหนดสิทธิ์การเข้าถึงระบบตามบทบาท

* **UC-10: จัดการชุดข้อมูลและอัปเดตโมเดล (Dataset & Model Management):**
  * **ผู้เกี่ยวข้อง (Actors):** Admin
  * **รายละเอียด:** แอดมินทำหน้าที่ตรวจสอบรูปภาพสแกมที่ผู้ใช้รายงาน ตรวจจัดหมวดหมู่เพื่อส่งเข้าชุดข้อมูล (Scam Dataset) สำหรับนำไปเทรนและวิเคราะห์เพิ่มเติม พร้อมทำการอัปโหลดไฟล์น้ำหนักโมเดล (Model Weights) เวอร์ชันใหม่ขึ้นระบบ
  * **ความต้องการทางระบบ (FR):** FR-10 - ระบบจัดการข้อมูลและโมเดล (Dataset & Model Management): ผู้ดูแลระบบสามารถตรวจสอบรูปภาพที่ถูกผู้ใช้รายงาน นำไปจัดหมวดหมู่ชุดข้อมูล และอัปโหลดโมเดล AI (Weights) เวอร์ชันใหม่เข้าสู่ระบบได้

---

## 5. การเปรียบเทียบกระบวนการทำงานระบบเดิมและระบบใหม่ (AS-IS vs TO-BE)

| หัวข้อเปรียบเทียบ | ระบบเดิม (AS-IS) | ระบบใหม่ (TO-BE: Scam Image Detection) |
| :--- | :--- | :--- |
| **ขั้นตอนการตรวจสอบ** | ใช้สายตามนุษย์คาดเดา หรือต้องบันทึกรูปไปสืบค้นบน Google Images ด้วยตนเองทีละขั้นตอน | อัปโหลดรูปภาพผ่านสมาร์ทโฟน ระบบทำการตรวจสอบแบบหลายชั้น (Multi-layer Analysis) ให้โดยอัตโนมัติในแอปเดียว |
| **เครื่องมือที่ใช้** | ต้องใช้คอมพิวเตอร์และซอฟต์แวร์นิติวิทยาศาสตร์ (Digital Forensics) ที่มีความซับซ้อน | ใช้งานง่ายผ่านแอปพลิเคชันบนสมาร์ทโฟน (Cross-Platform) ไม่ต้องมีพื้นฐานด้านไอที |
| **ความสามารถของ AI** | สายตามนุษย์และซอฟต์แวร์ดั้งเดิมไม่สามารถแยกแยะภาพที่สร้างจาก Generative AI รุ่นใหม่ได้ | ประยุกต์ใช้โมเดล Deep Learning ตรวจสอบความผิดปกติของสเปกตรัมภาพระดับพิกเซลได้อย่างแม่นยำ |
| **การทำความเข้าใจผลลัพธ์** | ทราบเพียงแค่ภาพนี้ "น่าจะจริง" หรือ "น่าจะปลอม" แต่ไม่ทราบพิกัดที่ถูกแก้ไข | ระบบแสดงผลแบบ Explainable AI ผ่านแผนที่ความร้อน (Heatmap) ชี้พิกัดที่ถูกตัดต่อให้เห็นอย่างเป็นรูปธรรม |
| **ประสิทธิภาพและเวลา** | ใช้เวลาหลายนาทีถึงหลักชั่วโมงในการสืบหาข้อมูลแหล่งที่มาและการตัดต่อ | ใช้เวลาเพียงเสี้ยววินาที (กรณี Cache Hit) หรือไม่เกิน 15 วินาที พร้อมส่ง Push Notification เมื่อเสร็จสิ้น |
| **การจัดเก็บและการมีส่วนร่วม**| รูปภาพหลอกลวงไม่ถูกบันทึกเป็นฐานข้อมูล ทำให้เกิดเหยื่อรายใหม่ซ้ำซาก | มีระบบ History จัดเก็บประวัติและระบบ Report ที่ช่วยรวบรวมข้อมูลภาพหลอกลวงส่งให้ส่วนกลางอัปเดต AI ต่อไป |

---

## 6. ขอบเขตการทำงานของระบบโดยละเอียด (Detailed System Scope)

### 6.1 ขอบเขตของผู้ใช้ (User Scope)
* **General User (ผู้ใช้งานทั่วไป):**
  * ลงทะเบียนและยืนยันตัวตนก่อนเข้าใช้งานระบบ
  * นำเข้ารูปภาพเพื่อตรวจสอบความเสี่ยง จากการเลือกรูปภาพในแกลเลอรีของเครื่อง
  * เรียกดูรายงานผลลัพธ์ความเสี่ยง (Risk Score) และดูตรรกะเหตุผลผ่านแผนที่ความร้อน (Heatmap)
  * ดูรายการประวัติการตรวจสอบย้อนหลังของตนเองและลบได้
  * รายงาน (Report) ข้อมูลรูปภาพที่เป็นการหลอกลวงเข้าสู่คลังฐานข้อมูลกลาง
* **Administrator (ผู้ดูแลระบบ):**
  * เข้าสู่ระบบผ่านหน้าเว็บแอปพลิเคชัน (Admin Portal)
  * บริหารจัดการข้อมูลผู้ใช้งานและกำหนดระดับความปลอดภัย (RBAC)
  * ตรวจสอบรายงานรูปภาพตัดต่อที่ส่งเข้ามาโดยผู้ใช้เพื่อพิจารณาอัปเดตเข้าคลังข้อมูลวิจัย
  * อัปเดตไฟล์น้ำหนักโมเดล AI (Model Weights) เวอร์ชันใหม่เพื่อใช้ในการประมวลผลตรวจจับที่ดียิ่งขึ้น

### 6.2 ขอบเขตการประมวลผลและการจัดเก็บข้อมูล (System & Data Scope)
* **การประมวลผลภาพขั้นต้น (Primary Analysis):**
  * ดึงค่า Metadata ของรูปภาพเพื่อตรวจสอบรายละเอียดของไฟล์ภาพ อุปกรณ์ที่ใช้บันทึก และประวัติตำแหน่ง (ถ้ามี)
  * สกัดอักษร (OCR) เพื่อตรวจสอบเนื้อความเบื้องต้น โดยจะตรวจจับประเด็นคำหรือตัวเลขที่มีความเสี่ยงสูง (เช่น คำที่มักใช้ในการโกงหรือข้อความแปลกปลอม)
  * ใช้ Google Vision API เพื่อทำธุรกรรม Reverse Image Search ค้นหาความถี่ของการปรากฏของภาพในสื่อออนไลน์
* **การตรวจจับภาพตัดต่อด้วย AI (AI Inference):**
  * ประมวลผลบนเซิร์ฟเวอร์แยกต่างหาก (AI Inference Container)
  * ใช้โครงข่ายประสาทเทียมแบบ Deep Learning (PyTorch) ในการประเมินร่องรอยการแก้ไขพิกเซล (ELA) และตรวจเช็กการสังเคราะห์ภาพจาก Generative AI
* **สถาปัตยกรรมความปลอดภัยและการจัดเก็บข้อมูล:**
  * จัดเก็บรายละเอียดบัญชีผู้ใช้งาน ประวัติรายการสแกน และรายงานความปลอดภัยลงในฐานข้อมูล PostgreSQL
  * เก็บรูปภาพต้นฉบับและรูปภาพผลลัพธ์แผนที่ความร้อนลงในระบบจัดเก็บไฟล์บนคลาวด์ (Cloud Storage)
  * ใช้ Redis ในฐานะระบบจัดเก็บข้อมูลชั่วคราว (Caching) เพื่อตอบสนองความเร็วกรณีตรวจสอบรูปภาพซ้ำ

---

## 7. แผนการดำเนินงานและงบประมาณ (Project Plan & Budget)

### 7.1 แผนการดำเนินงาน (Gantt Chart / Timeline)
โครงการใช้เวลาในการดำเนินงานทั้งสิ้น 8 เดือน ตั้งแต่เดือนพฤศจิกายน พ.ศ. 2568 ถึง เดือนมิถุนายน พ.ศ. 2569:

```mermaid
gantt
    title แผนการดำเนินโครงงานวิศวกรรมซอฟต์แวร์ (พ.ย. 2568 - มิ.ย. 2569)
    dateFormat  YYYY-MM-DD
    section วางแผน & วิเคราะห์ความต้องการ
    การวางแผนและวิเคราะห์ความต้องการ (Planning & Requirements) :active, p1, 2025-11-01, 2025-12-31
    section การออกแบบระบบ
    การออกแบบสถาปัตยกรรม & ระบบ (System Architecture Design) : p2, 2025-12-01, 2026-01-31
    section การพัฒนาซอฟต์แวร์
    พัฒนา Mobile App (Flutter) : p3_1, 2026-02-01, 2026-04-30
    พัฒนาและ Fine-tune โมเดล AI : p3_2, 2026-02-01, 2026-04-30
    พัฒนา Backend API & Caching (FastAPI & Redis) : p3_3, 2026-02-01, 2026-04-30
    section การบูรณาการ & ทดสอบ
    รวมระบบและทดสอบการทำงาน (SIT & Performance Testing) : p4, 2026-05-01, 2026-05-31
    section การติดตั้ง & ประเมินผล
    ติดตั้งขึ้นระบบจริง & UAT (Deployment & UAT) : p5, 2026-05-01, 2026-05-31
    section สรุปผลโครงงาน
    สรุปผลการวิจัยและจัดทำเล่มรายงานฉบับสมบูรณ์ : p6, 2026-06-01, 2026-06-30
```

### 7.2 ผลงานที่คาดว่าจะสำเร็จในแต่ละช่วงเวลา (Deliverables)

* **เดือนที่ 1-2 (พ.ย. - ธ.ค. 2568):**
  * เอกสารข้อกำหนดความต้องการทางซอฟต์แวร์ (SRS) และเอกสารขอบเขตโครงงาน (Scope)
  * แบบร่างหน้าจอผู้ใช้งาน (Wireframes) และหน้าจอแอปพลิเคชันต้นแบบ (UI Prototype)
  * เอกสารแผนภาพสถาปัตยกรรมระบบระดับ C1, C2 และ C3
* **เดือนที่ 3-5 (ม.ค. - เม.ย. 2569):**
  * โมเดลปัญญาประดิษฐ์ที่ผ่านการ Fine-tuning สำหรับตรวจร่องรอยการตัดต่อและภาพจาก GenAI
  * ระบบ Backend API (FastAPI) ที่เชื่อมต่อระบบฐานข้อมูลหลักและ Redis Cache เรียบร้อย
  * หน้าจอแอปพลิเคชันมือถือ (Flutter) ส่วนหน้าบ้านเชื่อมต่อฟังก์ชันการรับและส่งรูปภาพ
* **เดือนที่ 6-7 (พ.ค. 2569):**
  * ระบบรักษาความปลอดภัยข้อมูล (Auth, TLS 1.3) และมาตรการยินยอมข้อมูลตาม PDPA
  * รายงานการประเมินค่าความแม่นยำของ AI (AI Metrics) และรายงานผลการทดสอบระบบแบบบูรณาการ (SIT)
  * ผลประเมินการทดสอบการยอมรับจากผู้ใช้ (UAT) และการแก้ไขจุดแสดงผล Heatmap ตามผลตอบรับ
* **เดือนที่ 8 (มิ.ย. 2569):**
  * ติดตั้งระบบจริงบนระบบคลาวด์ (Cloud Deployment) และตั้งค่า Firebase Cloud Messaging
  * คู่มือการใช้งานแอปพลิเคชัน (User Manual) และเล่มรายงานโครงงานวิศวกรรมซอฟต์แวร์ฉบับสมบูรณ์

### 7.3 งบประมาณโครงงาน (Budget)

| ลำดับ | รายการ | จำนวนเงิน (บาท) |
| :---: | :--- | :---: |
| 1 | **ค่าวัสดุและอุปกรณ์**<br>- วัสดุสำนักงานทั่วไป กระดาษ แฟ้ม สำหรับจัดทำเล่มรายงาน | 500 |
| 2 | **ค่าดำเนินงานระบบ**<br>- ค่าเช่า Cloud Server / บริการรันโมเดล AI (เช่น AWS/GCP) และ Firebase สำหรับระบบแจ้งเตือน<br>- ค่าเช่าบริการชื่อโดเมน (Domain Name) และใบรับรองความปลอดภัย (SSL) สำหรับ API | 4,000 |
| 3 | **ค่าจัดทำเล่มรายงาน**<br>- ค่าพิมพ์เอกสารโครงงานฉบับสมบูรณ์ รูปเล่ม และเอกสารนำเสนอผลงาน | 1,000 |
| | **รวมทั้งสิ้น** | **5,500** |

### 7.4 วิธีการประเมินผลโครงการ (Evaluation Criteria)

* **การประเมินเชิงคุณภาพ (Qualitative):**
  * สัมภาษณ์ผู้ใช้งานกลุ่มตัวอย่างเพื่อประเมินความง่ายในการใช้งาน (Usability) และความเข้าใจต่อผลวิเคราะห์ Heatmap
  * มีเกณฑ์เป้าหมายคือ ผู้ใช้งานไม่น้อยกว่าร้อยละ 80 เห็นว่าระบบใช้งานง่ายและเข้าใจเหตุผลของ AI ได้อย่างชัดเจน
  * แบบสอบถามความพึงพอใจการใช้ระบบอ้างอิง Likert Scale 5 ระดับ จากกลุ่มตัวอย่าง 100 คน ต้องได้คะแนนเฉลี่ยรวมไม่น้อยกว่า 4.00 (ระดับดี)
* **การประเมินเชิงปริมาณ (Quantitative):**
  * ตรวจประเมินความแม่นยำทางสถิติของโมเดล Deep Learning ในการคัดกรองรูปภาพหลอกลวงผ่านชุดข้อมูลทดสอบ (Testing Set)
  * วัดประสิทธิภาพความเร็วในการดึงข้อมูลผลลัพธ์ตรวจสอบจาก Cache ต้องเสร็จสิ้นใน 3 วินาที และการประมวลผลวิเคราะห์ผ่าน AI ใหม่ทั้งหมดต้องใช้เวลาเฉลี่ยไม่เกิน 15 วินาทีต่อภาพ
