# โครงงาน: แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Scam Image Detection)
## หลักสูตรวิศวกรรมซอฟต์แวร์ สาขาวิศวกรรมไฟฟ้า คณะวิศวกรรมศาสตร์ มทร.ล้านนา (เชียงใหม่ ดอยสะเก็ด)

**อาจารย์ที่ปรึกษาโครงงาน:**  
อาจารย์   

**คณะผู้ดำเนินงาน:**  
1. นาย ภานุวัฒน์ ต๋าคำ (รหัสนักศึกษา 67543210044-3)
2. นาย เอกพันธ์ ทศทิศรังสรรค์ (รหัสนักศึกษา 67543210050-0)

---

## ภาพรวมโครงงาน (Project Overview)

โครงงานนี้มีวัตถุประสงค์เพื่อพัฒนา Mobile Application สำหรับการตรวจจับรูปภาพที่มีความเสี่ยงในการหลอกลวง (Scam Image Detection) โดยช่วยให้ผู้ใช้สามารถตรวจสอบความน่าเชื่อถือของรูปภาพก่อนนำไปใช้ แชร์ หรือเชื่อถือในบริบทต่าง ๆ เช่น การซื้อขายออนไลน์ การโฆษณา และสื่อสังคมออนไลน์

ปัญหาหลักที่โครงงานมุ่งแก้ไขคือการนำรูปภาพไปใช้ในการหลอกลวงในหลายรูปแบบ เช่น การใช้ภาพปลอมของบุคคล (Romance Scam), ภาพดัดแปลง (Image Forgery), การแต่งสลิปโอนเงินปลอม หรือภาพที่มีข้อความชักจูงให้โอนเงิน ซึ่งผู้ใช้งานทั่วไปไม่สามารถตรวจสอบได้ง่ายด้วยตนเอง

เพื่อแก้ไขปัญหาดังกล่าว ระบบถูกออกแบบโดยใช้แนวคิด Multi-layer Analysis วิเคราะห์ภาพถ่ายในหลายมิติ และนำผลลัพธ์มาร่วมประเมินระดับความเสี่ยง (Risk Score) ผ่าน 3 เลเยอร์การสแกนหลัก:
1. Textual Analysis: ดึงข้อมูลข้อความในภาพ (OCR) และวิเคราะห์ประเด็นคำค้นหาหลอกลวง (Scam Keywords) ด้วยระบบ NLP
2. Source Verification: ค้นหาประวัติการเผยแพร่ของภาพย้อนหลัง (Reverse Image Search) เพื่อระบุแหล่งที่มาและบริบทจริง
3. Visual Anomaly Detection: ใช้โมเดล Deep Learning (PyTorch) ตรวจสอบการแก้ไขตัดแต่งภาพระดับพิกเซล (ELA) และตรวจจับภาพสังเคราะห์ปัญญาประดิษฐ์ (AI-Generated Image) พร้อมแสดงผลแผนที่ความร้อน (Grad-CAM Heatmap) ตามแนวคิด Explainable AI (XAI)

---

## สารบัญเอกสารประกอบโครงงาน (Project Documentation)

เอกสารระบุข้อกำหนดทางวิศวกรรมซอฟต์แวร์และผลวิเคราะห์การออกแบบระบบทั้งหมด จัดเก็บไว้ในโฟลเดอร์ doc/ สามารถเรียกดูได้จากลิงก์ด้านล่างนี้:

* **[เอกสารข้อกำหนดความต้องการระบบหลัก (SRS)](doc/srs.md)** - เอกสารความต้องการทางซอฟต์แวร์ฉบับสมบูรณ์ (System Requirements Specification)
* **[วัตถุประสงค์และตัวชี้วัดโครงงาน (Objectives & KPIs)](doc/objective.md)** - รายละเอียดเป้าหมายหลักและเกณฑ์การวัดผลสำเร็จ
* **[ขอบเขตและตารางแบ่งงาน (Project Scope & Tasks)](doc/scop.md)** - รายการชิ้นงานที่ต้องพัฒนาในแต่ละส่วนพร้อมตารางมอบหมายหน้าที่
* **[แผนภาพระดับ C1 (System Context Diagram)](doc/C1-System-Context-Diagram.md)** - ขอบเขตระบบและการสื่อสารกับ Actor/External Services
* **[แผนภาพระดับ C2 (Container Diagram)](doc/C2-Container-Diagram.md)** - สถาปัตยกรรมระดับคอนเทนเนอร์หลังบ้าน และฐานข้อมูล
* **[แผนภาพและรายละเอียดกรณีการใช้งาน (Use Case Diagram)](doc/Use-Case-Diagram.md)** - หน้าที่ ความเกี่ยวข้อง และคำอธิบายความต้องการเชิงฟังก์ชัน (FR)
* **[แผนผังการทำงานระบบ (Flowchart)](doc/flowchart.md)** - แผนผังการทำงานฝั่งผู้ใช้ (User Flow)

### เอกสารการออกแบบสถาปัตยกรรม (System Design & Architecture)
เอกสารการออกแบบรายละเอียดเชิงลึกสำหรับระบบโมบายแอปและระบบหลังบ้าน จัดเก็บไว้ในโฟลเดอร์ design/:

* **[เอกสารสถาปัตยกรรมระบบฉบับรวม (System Architecture)](design/architecture.md)** - โครงสร้างสถาปัตยกรรมระบบทั้งหมด (Frontend, Backend, AI)
* **[การออกแบบส่วนหน้าบ้าน (Mobile Application Design)](design/design.md)** - โครงสร้าง Components + Redux, สีสันธีม UI/UX และพฤติกรรมผู้ใช้
* **[การออกแบบโมบายแอปพลิเคชันโดยละเอียด (Detailed Mobile Design)](design/mobile.md)** - ขอบเขต เป้าหมาย หน้าจอ และโครงสร้างโฟลเดอร์ของ React Native
* **[การออกแบบสถาปัตยกรรมระบบหลังบ้าน (Backend & System Architecture)](design/server.md)** - โครงสร้าง Backend, ท่อประมวลผล AI Inference (FastAPI, PyTorch, ONNX), Database Schema และ API Specifications

---

## ซอร์สโค้ดและแอปพลิเคชัน (Source Code & Applications)

* **[แอปพลิเคชันมือถือ (Scam Image Mobile - Flutter)](scam_image_mobile/)** - ซอร์สโค้ดการพัฒนาแอปพลิเคชันด้วย Flutter
* **[ต้นแบบ (Prototype)](pototype/)** - ไฟล์และโฟลเดอร์ต้นแบบของระบบ

---

## ลิงก์พื้นที่ทำงานสำหรับการดำเนินงาน (Workspace Links)

* **[Discord Channel](https://discord.gg/WSEXfzrb)** - ช่องทางการสื่อสารของทีมงาน
* **[Miro Board](https://miro.com/welcomeonboard/QmZJV2lUMDZ0amlTbWtrRlBxQkM0WE82aEM5K1YyVFdYM0s2Z2J1U0w1cXYwQlorcDRSZk5oaFNaYXM3enozcXppUXdyK0xQNWE5aTZ0bm42anhNUWtHeEhvMWNmVHNWUUlMZGx1VU41WGdmK0g2eTdzQ1U2S3VCd2pqeTNBNEd0R2lncW1vRmFBVnlLcVJzTmdFdlNRPT0hdjE=?share_link_id=95378118618)** - พื้นที่ระดมสมองและวิเคราะห์ความต้องการเชิงระบบ
* **[Figma Design](https://www.figma.com/design/gFrjAWWl0ZmT7h7vzu9011/project-Mobile-App--Scam-Image-Detection?node-id=0-1&t=seKA8vjnzcKV9HMq-1)** - หน้าจอ UI/UX Design และ Prototype ของโมบายแอป
* **[Trello Board](https://trello.com/b/7QuuGSAL)** - กระดานติดตามสถานะการดำเนินงาน (Task Tracking)
* **[System Architecture Diagram (Google Drive)](https://drive.google.com/file/d/1I2ksLvZp0x3iNYt57_46cqnTDfPgWvzR/view?usp=sharing)** - ไฟล์สำรองไดอะแกรมภาพรวมระบบ