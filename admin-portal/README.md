# ScamGuard — Cyber-Forensics & Fraud Intelligence Console

> ระบบคอนโซลส่วนกลางสำหรับผู้ดูแลระบบระดับสูง (Super Admin) ในการสืบสวน ตรวจสอบนิติวิทยาศาสตร์ดิจิทัล วิเคราะห์โมเดล AI และควบคุมความปลอดภัยของแพลตฟอร์ม ScamGuard

**Path:** `/home/panuwat/project/admin-portal`  
**สถานะ:** Production-Ready (Operate Mode Architecture)  
**สเกลความเสี่ยง:** 3 ระดับ (Low: 0-39, Medium: 40-69, High: 70-100) — ปราศจากระดับ Safe ตามข้อกำหนดระบบ

---

## ภาพรวมของระบบ (System Overview)

ScamGuard Admin Portal ออกแบบภายใต้แนวคิด **Operate Mode** เพื่อรองรับการทำงานของเจ้าหน้าที่นิติวิทยาศาสตร์และผู้ดูแลระบบในการตรวจจับรูปภาพต้องสงสัยจากการหลอกลวง (เช่น Romance Scams, สลิปโอนเงินปลอม, เอกสารราชการปลอม, ภาพสังเคราะห์จาก AI และความผิดปกติของพิกเซล) โดยผสานการทำงานร่วมกับโมเดลการเรียนรู้เชิงลึก **SegFormer MiT-B2** เพื่อสร้าง Heatmap ระบุตำแหน่งการดัดแปลงภาพ

### คุณสมบัติหลัก (Key Features)

1. **ศูนย์บัญชาการสถิติ (Real-time Forensic Dashboard)**
   - ตัวชี้วัดสำคัญ (KPIs): ยอดสแกนทั้งหมด, คิวรอดำเนินการ, เคสความเสี่ยงสูง, ความแม่นยำของ AI
   - กราฟแนวโน้มการสแกน (Area Chart) และสัดส่วนหมวดหมู่ภัยคุกคาม (Severity Donut / Category Bar)
   - แถบสถานะระบบ (System Health Bar): CPU, Memory, GPU VRAM, Latency
   - การสตรีมข้อมูลสด (Live Telemetry): อัปเดตคิวและสถิติผ่าน WebSocket อัตโนมัติ

2. **คิวสืบสวนและตรวจสอบรายงาน (Investigation Queue)**
   - กรองสถานะแบบแท็บ (ทั้งหมด, รอดำเนินการ, กำลังตรวจ, อนุมัติแล้ว, ปฏิเสธ)
   - ค้นหาแบบ Debounced Search พร้อมระบบแบ่งหน้า (Pagination)
   - ป้ายระดับความเสี่ยง (RiskBadge) 3 ระดับ พร้อมสีแสดงความรุนแรงตามมาตรฐาน

3. **โต๊ะทำงานนิติวิทยาศาสตร์ดิจิทัล (Forensic Workbench & Report Detail)**
   - หน้าต่างตรวจสอบแบบ Dual-Pane: ข้อมูลภาพหลักฐานทางซ้าย และแผงควบคุมการตัดสินใจทางขวา
   - เครื่องมือเปรียบเทียบพิกเซลผิดปกติ (**HeatmapComparator**):
     - โหมด **Split Slider**: รูดเปรียบเทียบภาพต้นฉบับกับภาพซ้อนทับ Heatmap
     - โหมด **Side-by-Side**: วางภาพเทียบกันสองฝั่ง
     - โหมด **Opacity Overlay**: ปรับความโปร่งใสของ Heatmap ได้อย่างละเอียด
   - วิเคราะห์เจาะลึกหลายมิติ (Multi-Layer XAI): Visual Anomaly, Metadata/EXIF, Text/OCR Inconsistency, Reverse Image Context
   - ระบบ **Optimistic Locking (`version`)**: ป้องกันผู้ดูแลระบบแก้ไขบันทึกซ้ำซ้อนกัน

4. **การบริหารจัดการผู้ใช้งาน (User Administration)**
   - ทะเบียนผู้ใช้งาน ค้นหาด้วยชื่อหรืออีเมล
   - ปรับสถานะบัญชีและระงับการใช้งาน (Ban/Unban) โดยบังคับระบุเหตุผลเพื่อใช้ตรวจสอบย้อนหลัง

5. **ทะเบียนและการจัดการโมเดล AI (AI Model Registry & Ops)**
   - รายการโมเดลตรวจจับ SegFormer และเวอร์ชันที่รองรับ
   - ตรวจสอบความถูกต้องของ Checksum และสถิติความแม่นยำ (mIoU, Precision, Recall)
   - โหมดทดสอบการอนุมานแห้ง (**Dry-Run Inference**) โดยไม่กระทบการทำงานจริง
   - การสลับรุ่นโมเดลและย้อนกลับ (**Deploy & Rollback**) พร้อมบันทึกประวัติการเปลี่ยนแปลง

6. **ระบบส่งออกชุดข้อมูลเพื่อการวิจัย (Dataset Export Pipeline)**
   - คัดกรองข้อมูลภาพตามเกณฑ์ความยินยอมทางกฎหมาย (PDPA Consent Filtering)
   - ประมวลผลแบบเบื้องหลัง (Asynchronous Background Job Queue) พร้อมแถบแสดงความคืบหน้า
   - สร้างไฟล์บีบอัด ZIP พร้อมไฟล์กำกับข้อมูลเมทาดาทา (Manifest Metadata)

7. **บันทึกการกระทำที่ไม่สามารถแก้ไขได้ (Immutable Audit Trail)**
   - บันทึกการกระทำของผู้ดูแลระบบแบบ Append-Only ห้ามลบหรือแก้ไข
   - แสดงผลต่างของการเปลี่ยนแปลงสถานะก่อนและหลัง (JSON Diff Snapshot)

8. **โปรไฟล์และความปลอดภัยของบัญชี (Profile & Security Settings)**
   - ข้อมูลผู้ดูแลระบบและการเปลี่ยนรหัสผ่านตามนโยบายความปลอดภัย
   - รายการเซสชันที่กำลังใช้งาน (Active Sessions) พร้อมปุ่มตัดการเชื่อมต่อทันที (One-Click Session Revocation)

9. **แถบค้นหาคำสั่งลัด (Command Palette)**
   - ใช้งานผ่านคีย์ลัด `Ctrl + K` หรือ `Cmd + K` เพื่อสลับหน้าและค้นหารายการได้อย่างรวดเร็ว

10. **ระบบสลับธีมคู่และความเปรียบต่างสูง (Dual-Theme & High Contrast)**
    - รองรับทั้ง **Dark Mode** (ศูนย์ปฏิบัติการความมั่นคงปลอดภัย Deep Slate `#090d16`) และ **Light Mode** (สไตล์องค์กรสะอาดตา Soft Slate `#f8fafc`)
    - สลับธีมได้ทันทีผ่านปุ่มบน TopBar พร้อมบันทึกสถานะลงใน LocalStorage
    - ตัวอักษรและป้ายกำกับปรับแต่งความเข้มและความเปรียบต่างตามเกณฑ์มาตรฐาน WCAG AA เพื่อให้อ่านข้อมูล ตัวเลขสถิติ และ Hash ได้อย่างคมชัดในทุกสภาพแสง

---

## สถาปัตยกรรมเทคโนโลยี (Tech Stack)

- **Frontend Core:** React 19 + Vite 8
- **Routing:** React Router DOM v7
- **Styling:** Tailwind CSS v4 (`@tailwindcss/vite`) + Modern CSS Design Tokens
- **Themes:** Dual-Theme Architecture (Dark Mode & Light Mode) พร้อมระบบจัดการคลาสระดับราก
- **Typography:** Geist Sans Variable + Monospace Tabular Figures (`tabular-nums font-mono`)
- **Icons:** Lucide React
- **Charts:** Recharts (ปรับแต่ง Zero-Delay Animation เพื่อการแสดงผลแบบเรียลไทม์ที่แม่นยำ)
- **Design System:** Impeccable Design Archetype (Operate Mode, Electric Cyan `#00e5ff`, Triad Risk Colors)
- **Notifications & Dialogs:** In-App Toast Provider และ Accessible Modal Dialogs (ปราศจาก native browser `alert()` หรือ `confirm()`)

---

## โครงสร้างโฟลเดอร์ (Directory Structure)

```text
admin-portal/
├── public/                     # ไฟล์สาธารณะและ Favicon
├── src/
│   ├── components/
│   │   ├── ui/                 # คลัง UI Primitives ตามมาตรฐาน Design System
│   │   │   ├── Badge.jsx       # ป้ายกำกับทั่วไป, StatusBadge, และ RiskBadge
│   │   │   ├── Button.jsx      # ปุ่มกดพร้อม Variants และ Loading State
│   │   │   ├── Card.jsx        # โครงสร้างการ์ดและแผงควบคุม
│   │   │   ├── CommandPalette.jsx # เมนูค้นหาและคำสั่งลัดด่วน (Ctrl+K)
│   │   │   ├── HeatmapComparator.jsx # เครื่องมือเปรียบเทียบภาพนิติวิทยาศาสตร์
│   │   │   ├── Input.jsx       # กล่องข้อความ, SearchInput, Select, Textarea
│   │   │   ├── Modal.jsx       # กล่องโต้ตอบ Focus-Trapped พร้อมปุ่ม ESC
│   │   │   ├── Skeleton.jsx    # โครงสร้างโหลดข้อมูลแบบ Shimmer
│   │   │   ├── Table.jsx       # ตารางแสดงผลความหนาแน่นสูงและ Pagination
│   │   │   ├── Tabs.jsx        # แท็บกรองสถานะและโหมดการทำงาน
│   │   │   └── ToastContext.jsx # ระบบแจ้งเตือนลอยพร้อมตัวจัดการคิว
│   │   ├── AppSidebar.jsx      # เมนูด้านข้างพร้อมป้ายเตือนคิวค้าง
│   │   └── TopBar.jsx          # แถบบนแสดง Breadcrumb, Live Indicator และ Profile
│   ├── layouts/
│   │   └── AdminLayout.jsx     # โครงร่างหน้าหลัก รองรับ Responsive & Mobile Drawer
│   ├── lib/
│   │   ├── api.js              # เลเยอร์เชื่อมต่อ API, จัดการ Token, และ WebSocket Helper
│   │   └── utils.js            # ยูทิลิตี้ cn, ตัวจัดรูปแบบตัวเลข, วันที่, และสีความเสี่ยง
│   ├── pages/                  # หน้าจอระบบครบทั้ง 10 หน้า
│   │   ├── AuditLogsList.jsx   # บันทึก Audit Log
│   │   ├── Dashboard.jsx       # แดชบอร์ดศูนย์บัญชาการ
│   │   ├── DatasetExport.jsx   # ส่งออกชุดข้อมูล
│   │   ├── Login.jsx           # เข้าสู่ระบบผู้ดูแล
│   │   ├── ModelsList.jsx      # จัดการโมเดล AI
│   │   ├── ProfileSettings.jsx # ตั้งค่าโปรไฟล์และเซสชัน
│   │   ├── ReportDetail.jsx    # โต๊ะตรวจสอบรายงานและ Heatmap
│   │   ├── ReportsList.jsx     # คิวสืบสวนรายงานสแกน
│   │   ├── UserDetail.jsx      # รายละเอียดและประวัติผู้ใช้งาน
│   │   └── UsersList.jsx       # ทะเบียนผู้ใช้งาน
│   ├── App.jsx                 # ทางเข้าหลัก แอปพลิเคชันและ Route Provider
│   ├── index.css               # Design Tokens, โทนสี และสไตล์ระดับฐาน
│   └── main.jsx                # จุดเริ่มต้นการ Render ของ React DOM
├── .env.example                # แม่แบบตัวแปรสภาพแวดล้อม
├── DESIGN.md                   # เอกสารระบุข้อกำหนด Design Tokens & Primitives
├── package.json                # ข้อมูลโมดูลและสคริปต์
├── run.sh                      # สคริปต์รันระบบแบบขั้นตอนเดียว
└── vite.config.js              # คอนฟิก Vite พร้อม Proxy และ WebSocket Support
```

---

## ตัวแปรสภาพแวดล้อม (Environment Variables)

ระบบอ่านค่าคอนฟิกจากไฟล์ `.env` ที่อยู่ในโฟลเดอร์นี้ โดยมีตัวแปรสำคัญที่รองรับดังนี้:

| ตัวแปร | ค่าเริ่มต้น | คำอธิบาย |
| :--- | :--- | :--- |
| `VITE_APP_NAME` | `"ScamGuard Cyber-Forensics Console"` | ชื่อแอปพลิเคชันที่แสดงบนแถบหัวเรื่องและเมนูด้านข้าง |
| `VITE_APP_ENV` | `development` | สภาพแวดล้อมการทำงาน (`development`, `staging`, `production`) |
| `VITE_APP_VERSION` | `1.0.0` | เวอร์ชันของแอปพลิเคชัน |
| `VITE_BACKEND_TARGET` | `http://127.0.0.1:8000` | ปลายทางของ FastAPI Backend สำหรับ Vite Dev Proxy |
| `VITE_API_BASE_URL` | `/api/v1` | เส้นทางหลักของ API (เรียกผ่าน Proxy หรือ Domain หลัก) |
| `VITE_WS_URL` | *(ค่าว่าง)* | WebSocket URL สำหรับ Live Telemetry (หากเว้นว่างจะคำนวณจากโฮสต์อัตโนมัติ) |
| `VITE_STORAGE_URL` | `/uploads` | เส้นทางสำหรับดาวน์โหลดและเปิดดูไฟล์ภาพหลักฐานและ Heatmap |
| `VITE_REFRESH_LEEWAY_SECONDS` | `10` | ระยะเวลาสำรอง (วินาที) สำหรับ Silent Refresh ก่อน Token หมดอายุ |
| `VITE_SESSION_TIMEOUT_MINUTES` | `60` | ขีดจำกัดเวลาเซสชันก่อนแจ้งเตือนผู้ดูแลระบบ |
| `VITE_ENABLE_AUDIT_LOGGING` | `true` | บังคับส่งบันทึกการกระทำทุกอย่างเข้าสู่ระบบ Immutable Audit Log |
| `VITE_ENABLE_MOCK_FALLBACK` | `false` | ปิดการจำลองข้อมูลอย่างเด็ดขาด เพื่อบังคับเชื่อมต่อ Real Backend |
| `VITE_DEFAULT_ADMIN_USERNAME` | `admin@gmail.local` | บัญชีผู้ดูแลระบบเริ่มต้นสำหรับเติมในแบบฟอร์มอัตโนมัติ (Dev Mode) |

---

## การติดตั้งและเริ่มต้นใช้งาน (Getting Started)

### ความต้องการของระบบ (Prerequisites)

- **Node.js**: เวอร์ชัน LTS (รองรับ Node.js 20 หรือใหม่กว่า)
- **npm**: เวอร์ชัน 10 ขึ้นไป
- **FastAPI Backend**: รันอยู่ที่พอร์ต `8000` (ตรวจสอบผ่าน `curl http://127.0.0.1:8000/api/v1/health`)

### บัญชีผู้ดูแลระบบสำหรับโหมดพัฒนา (Default Credentials)

- **URL เข้าใช้งาน:** `http://localhost:5173/admin/dashboard`
- **Username:** `admin@gmail.local`
- **Password:** กำหนดค่าผ่านไฟล์ `.env` ส่วนตัว (หรือดูบัญชีเริ่มต้นใน `server/scripts/admin.sh`)

*(ในโหมดพัฒนา หากมีการกำหนดค่าใน `.env` ระบบจะดึงมากรอกในหน้า Login ให้อัตโนมัติ)*

### ขั้นตอนการรันระบบ

1. **เตรียมไฟล์คอนฟิก:**
   ```bash
   cd /home/panuwat/project/admin-portal
   cp .env.example .env
   ```

2. **ติดตั้ง Dependencies:**
   ```bash
   npm install
   ```

3. **รัน Development Server:**
   ```bash
   npm run dev
   ```
   หรือใช้สคริปต์ขั้นตอนเดียว:
   ```bash
   ./run.sh
   ```
   เปิดเบราว์เซอร์และเข้าไปที่ `http://localhost:5173`

4. **การตรวจสอบและ Build สำหรับ Production:**
   ```bash
   # ตรวจสอบความถูกต้องของโค้ดด้วย ESLint
   npm run lint

   # คอมไพล์ Production Bundle
   npm run build

   # พรีวิวผลลัพธ์ Production Build
   npm run preview
   ```

---

## การทดสอบและประกันคุณภาพ (Testing & Quality Assurance)

ระบบผ่านการตรวจสอบคุณภาพและความถูกต้องตามระเบียบวิธีของโครงการ:

1. **การทดสอบความถูกต้องผ่าน Chrome DevTools MCP:**
   - ทดสอบโฟลว์การเข้าสู่ระบบ (Login) การจัดการเซสชัน JWT และการเชื่อมต่อ Real Backend ผ่านเครือข่ายจำลอง
   - ทดสอบการสลับธีมทั้ง Dark Mode และ Light Mode อย่างสมบูรณ์
   - ตรวจสอบ Console Messages: ไม่พบข้อผิดพลาดหรือคำเตือนในรันไทม์ (0 errors, 0 warnings)

2. **การตรวจสอบ UX/UI ด้วย Impeccable Design Standards:**
   - รันสคริปต์ตรวจจับอัตโนมัติ `node .agents/skills/impeccable/scripts/detect.mjs --json admin-portal` ผลลัพธ์: 0 Anti-patterns
   - ปรับแต่งความเข้มของตัวอักษรและความเปรียบต่าง (Typography Contrast) ตามมาตรฐานสากล WCAG AA ทั้งสองธีม
---

## ความปลอดภัยและการเชื่อมต่อ (Security & Communication)

1. **การพิสูจน์ตัวตน (Authentication):**
   - เข้าสู่ระบบผ่าน `POST /api/v1/admin/login`
   - จัดเก็บ Access Token ใน Memory เท่านั้นเพื่อป้องกันการโจมตีผ่าน XSS
   - ระบบรีเฟรชโทเค็นอัตโนมัติ (Silent Refresh) ผ่าน HttpOnly Cookie ที่ `POST /api/v1/admin/refresh`
   - ออกจากระบบและตัดเซสชันผ่าน `POST /api/v1/admin/logout`

2. **การป้องกันข้อผิดพลาด:**
   - ใช้โมดอลยืนยันพร้อมระบุเหตุผล (Mandatory Audit Reason) สำหรับการแบนผู้ใช้และการ Deploy/Rollback โมเดล
   - ระบบแจ้งเตือนในตัว (Custom Toast Provider) ป้องกันการขัดจังหวะการทำงานของเบราว์เซอร์
