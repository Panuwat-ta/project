# แผนการทดสอบ: พอร์ทัลผู้ดูแลระบบ (Admin Portal Test Plan)

- **System / Component**: ScamGuard Admin Portal & Forensic Console
- **Architecture**: Single Page Application (SPA), Real-time WebSocket Client, Forensic Dashboard
- **Tech Stack**: React 18, Vite, TypeScript, Tailwind CSS, Lucide React, Axios / Native WebSocket
- **Target Browsers**: Chrome (v110+), Firefox (v110+), Edge (v110+), Safari (v16+)
- **Document Version**: 1.0.0
- **Status**: Approved

---

## 1. ขอบเขตการทดสอบ (Scope of Testing)

### 1.1 สิ่งที่อยู่ในขอบเขต (In-Scope)
1. **Admin Authentication & Role Separation**:
   - การลงชื่อเข้าใช้ผ่านฟอร์มเฉพาะแอดมิน โดยตรวจสอบข้อมูลจากตาราง `admins` เท่านั้น
   - การปฏิเสธบัญชีผู้ใช้ทั่วไปจากตาราง `users` ด้วยข้อความแจ้งเตือนที่ชัดเจนและ HTTP 403
   - การตัด Session เมื่อ Token หมดอายุหรือถูกเพิกถอน
2. **Dashboard Overview & WebSocket Telemetry**:
   - การแสดงตัวเลขชี้วัดหลัก (Total Scans, High Risk Incidents, Pending Reports, System Health)
   - การเชื่อมต่อ WebSocket (`/api/v1/ws/telemetry`) แสดงผลกราฟ CPU, GPU, Memory และปริมาณคำขอแบบเรียลไทม์
   - กลไก Auto-reconnect เมื่อการเชื่อมต่อ WebSocket ขาดหาย
3. **AI Model Management**:
   - การแสดงรายการโมเดลใน Model Registry โดยต้องนำโมเดลสถานะ ACTIVE มาปักหมุดไว้ที่อันดับแรกเสมอ
   - การทดสอบสุขภาพโมเดลล่วงหน้า (Dry-run Health Check) ก่อนกด Deploy
   - การปรับเปลี่ยนสถานะโมเดล (Deploy / Rollback) ภายใต้การควบคุม Row Lock
4. **Report Review & Forensic Console**:
   - ตารางรายการข้อร้องเรียนจากผู้ใช้ พร้อมตัวกรองตามสถานะ (PENDING, RESOLVED, REJECTED)
   - การเปิดดูภาพต้นฉบับเปรียบเทียบกับ Heatmap ซ้อนทับ พร้อมข้อมูลคะแนน 3 มิติ
   - การอนุมัติหรือปฏิเสธรายงาน พร้อมการควบคุม Concurrency (Optimistic Locking ด้วยคอลัมน์ `version`)
5. **User Management**:
   - การค้นหาบัญชีผู้ใช้ ตรวจสอบประวัติ และการสั่งระงับบัญชี (Ban User) โดยต้องมี Modal บังคับระบุเหตุผลเสมอ
6. **Audit Logs & Security Tracing**:
   - การตรวจสอบบันทึกการกระทำของผู้ดูแลระบบทั้งหมด พร้อมการแสดงผล JSON Diff เปรียบเทียบข้อมูลก่อนและหลังแก้ไข
   - การแสดงเวลาในรูปแบบ UTC+7 (เวลาประเทศไทย)
7. **Accessibility & Responsive Design**:
   - การสลับธีม Dark Mode / Light Mode โดยมีค่าความเปรียบต่างสี (Contrast Ratio) >= 4.5:1 ตามมาตรฐาน WCAG 2.1 AA

### 1.2 สิ่งที่อยู่นอกขอบเขต (Out-of-Scope)
1. การเข้าถึงระดับ Cloud Infrastructure Console (AWS/GCP Console)
2. การปรับแต่งฐานข้อมูลแบบ Direct SQL Query ผ่านหน้าเว็บ

---

## 2. กลยุทธ์และวิธีการทดสอบ (Testing Strategy)

### 2.1 สภาพแวดล้อมการทดสอบ (Test Environment)
- **Node.js Environment**: Node.js v18+ พร้อม Vite Dev Server (`http://localhost:5173`)
- **Backend API Server**: Local FastAPI Backend พร้อม Proxy บน Vite (`/api/v1 -> http://localhost:8000`)
- **Mock / Real Data**: ใช้ฐานข้อมูล PostgreSQL และ Redis ของจริง 100% ปราศจากการ Mock ข้อมูล

### 2.2 ระดับและประเภทการทดสอบ (Test Levels & Types)
1. **Component & State Testing**: ตรวจสอบการ Render ของคอมโพเนนต์, Theme Provider, และ Error Boundaries
2. **WebSocket Integration Testing**: ยิงข้อมูลจำลองผ่านช่องทาง WebSocket เพื่อทดสอบการอัปเดตกราฟแบบทันทีโดยไม่เกิด Memory Leak
3. **Optimistic Locking Conflict Testing**: เปิดเบราว์เซอร์ 2 หน้าต่างพร้อมกัน และกดแก้ไขสถานะ Report รายการเดียวกัน เพื่อยืนยันว่าระบบตรวจจับ Version Mismatch ได้ถูกต้อง
4. **Automated Accessibility Testing**: ใช้เครื่องมือ Lighthouse และ Axe Core เพื่อตรวจจับการละเมิดเกณฑ์ความเปรียบต่างสี

---

## 3. เกณฑ์การตรวจรับ (Entry & Exit Criteria)

### 3.1 เกณฑ์การเริ่มต้นทดสอบ (Entry Criteria)
- โปรเจกต์ผ่านการคอมไพล์ด้วยคำสั่ง `npm run build` โดยไม่มีข้อผิดพลาดด้าน TypeScript หรือ Lint
- Backend API และ WebSocket Endpoint เปิดให้บริการปกติ

### 3.2 เกณฑ์การสิ้นสุดการทดสอบ (Exit Criteria)
- กรณีทดสอบใน `tests_all/manual_tests/test_cases_admin.md` ผ่าน 100%
- คะแนนการเข้าถึง (Lighthouse Accessibility Score) บนทุกหน้าจอหลักต้องไม่ต่ำกว่า 95 คะแนน
- การสลับธีม Dark/Light Mode ทำงานได้เรียบเนียนโดยไม่มีอาการ Flash of unstyled content (FOUC)
- ระบบปฏิเสธการระงับผู้ใช้หากไม่ระบุเหตุผลในทุกกรณี

---

## 4. ความเชื่อมโยงไปยังชุดกรณีทดสอบจริง
- **เอกสารกรณีทดสอบละเอียด**: `tests_all/manual_tests/test_cases_admin.md`
- **ตารางความสอดคล้องความต้องการ**: `tests_all/rtm.md` (หมวดหมู่ FR-ADM-01 ถึง FR-ADM-06, NFR-A11Y-01)
