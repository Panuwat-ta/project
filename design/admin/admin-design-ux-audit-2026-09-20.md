# Admin Portal Design / UX/UI / AI-Slop Audit

วันที่ตรวจ: 2026-09-20
ขอบเขต: `/home/panuwat/project/admin-portal`
สถานะ: Audit only — รอบนี้ยังไม่แก้ source UI

## 1. วิธีตรวจ

ตรวจ 3 ชั้นตามคำสั่งผู้ใช้:

1. ใช้ Impeccable skill 4.1.3 โดยอ่านแนวทาง `critique`, `audit`, `shape`, `operate` และตรวจ source จริง
2. ตรวจซ้ำด้วยตนเองจาก React source, design tokens, runtime UI และ backend contract ที่เกี่ยวข้อง
3. สั่ง `agy` ทำ independent UX/UI + AI-slop audit แบบ plan-only แล้วเทียบ finding ทีละข้อ

หลักฐานหลักที่ใช้:
- `.agents/PRODUCT.md`
- `design/admin.md`
- `wiki/architecture/admin-portal.md`
- `admin-portal/README.md`
- `admin-portal/src/**`
- `server/app/schemas/admin.py` และ code ฝั่ง AI heatmap ที่เกี่ยวข้อง

หมายเหตุ: Impeccable context resolver ไม่พบ `PRODUCT.md` / `DESIGN.md` ในตำแหน่งมาตรฐานของ skill แม้ repository มี `.agents/PRODUCT.md` และ `design/admin.md`; จึงใช้เอกสารจริงเหล่านี้เป็น authority โดยไม่สร้างบริบทสมมติใหม่

## 2. Executive Summary

ภาพรวมปัจจุบันมีโครงสร้าง UI ที่แข็งแรงกว่างาน dashboard สำเร็จรูปทั่วไป: navigation จัดกลุ่มดี, semantic color tokens ครบ, Light/Dark theme ใช้ CSS variables กลาง, ตารางและตัวเลขอ่านเป็นระบบ, workflow ตรวจรายงานวาง action ใกล้หลักฐาน และ runtime responsive ที่ 390px ใช้งานได้จริง

อย่างไรก็ตาม ยังไม่ควรถือว่า design พร้อม final เพราะมีปัญหา Product Integrity ที่สำคัญ: บาง component เติมข้อมูลสมมติหรือแปลง “ไม่มีข้อมูล” ให้ดูเหมือน “ผลจริง” โดยเฉพาะ Heatmap, multi-layer analysis, health status, model dry-run telemetry, profile/session และ risk score ที่หายไป

ผลสรุป severity:
- P0: ไม่พบ
- P1: 7 กลุ่ม — ต้องแก้ก่อน polish visual
- P2: 8 กลุ่ม — accessibility, responsive interaction, workflow และ design-authority drift
- P3: visual/copy AI-slop และ polish หลายจุด

Impeccable deterministic detector คืน `[]` หรือ 0 antipatterns แต่ manual audit พบ semantic AI-slop หลายจุด แสดงว่า detector ผ่านด้านโครงสร้างไม่ได้รับประกันความถูกต้องของข้อมูลที่ UI สื่อ

## 3. คะแนนจากการตรวจเองตาม Impeccable Audit

| มิติ | คะแนน /4 | สรุป |
|---|---:|---|
| Accessibility | 2 | Modal/Tabs/focus ring ดี แต่ clickable non-semantic surfaces และ Heatmap ยังไม่ keyboard/touch complete |
| Performance | 3 | Route lazy-load, chart animation ปิด, build ดี; ยังมี effect/transition ที่เกินจำเป็นบางส่วน |
| Responsive | 3 | 390px runtime ผ่านโครงหลัก แต่ data table และ forensic controls ยังพึ่ง horizontal/mouse interaction |
| Theming | 4 | Semantic token authority และ Light/Dark implementation แข็งแรง |
| Implementation Integrity | 1 | มี fabricated/deceptive fallback หลายจุด |
| รวม | **13/20** | โครง UI ดี แต่ integrity ต้องแก้ก่อน redesign polish |

## 4. สิ่งที่ออกแบบได้ดีแล้ว

### 4.1 Information Architecture
- Sidebar แบ่ง `งานหลัก`, `โมเดล AI & ชุดข้อมูล`, `ความปลอดภัย & ระบบ` ชัดเจนและตรง mental model ของงาน admin
- Report queue, User management, Model operations, Dataset export และ Audit log ถูกแยกหน้าตาม responsibility ไม่ปะปนกัน
- Command Palette และ URL filter ของ Reports ช่วยผู้ใช้ power-user โดยไม่บังคับ workflow ใหม่

### 4.2 Design System / Theme
- `src/index.css` มี semantic tokens สำหรับ canvas, surface, border, status, risk, chart และ sidebar แยก Light/Dark
- Font ปัจจุบันคือ `Noto Sans Thai Variable` + `Geist Variable` ซึ่งอ่านภาษาไทยและตัวเลขได้ดีกว่าเอกสาร design เก่าที่ระบุ Inter/Sarabun
- Chart ใช้ `var(--chart-*)` จึงสลับ theme ได้จริง; agy ตรวจซ้ำและยืนยันว่า inline chart styles ไม่ใช่ dark-mode bug

### 4.3 Interaction ที่ดี
- `Modal.jsx` มี Escape, focus trap, focus restore, `role="dialog"`, `aria-modal`
- `Tabs.jsx` รองรับ ArrowLeft/Right, Home/End, roving tabindex และ `aria-selected`
- Workflow Report Detail รองรับ optimistic locking และ HTTP 409 เพื่อไม่ให้ผู้ดูแลหลายคนตัดสินข้อมูลเก่าทับกัน
- Recharts animation ถูกปิด เหมาะกับ Operate mode และลด motion ที่ไม่จำเป็น

### 4.4 Runtime responsive ที่ตรวจจริง
- 1440x1000: Dashboard และ Report queue ใช้พื้นที่ดี ตารางมี hierarchy ชัด
- 390x844: Sidebar ยุบเป็น drawer, KPI ลงแนวตั้ง, toolbar Reports เปลี่ยนเป็นแนวตั้งโดยไม่เกิด viewport overflow หลัก
- จุดอ่อนของ mobile table คือคอลัมน์สำคัญด้านขวาต้อง horizontal scroll และไม่มี cue ชัดว่ามีข้อมูลต่อด้านข้าง

## 5. Confirmed Findings — P1 Product Integrity

### P1-01 Heatmap fallback แสดงภาพต้นฉบับเป็นผลโมเดล
- `src/components/ui/HeatmapComparator.jsx:135,192,215`
- ใช้ `heatmapUrl || originalUrl` ใน view ที่ติด label ว่า “ผลตรวจของโมเดล/ฮีตแมป”
- เมื่อไม่มี Heatmap ผู้ใช้ยังเห็นภาพเหมือนมี artifact จากโมเดล เป็น deceptive evidence
- ต้องเปลี่ยนเป็น explicit unavailable state และปิด comparator mode ที่ต้องใช้ heatmap

### P1-02 Report Detail สร้างความหมายของ evidence ขึ้นเองเมื่อ field หาย
- `src/pages/ReportDetail.jsx:288` ใช้ overall risk score แทน visual anomaly score
- `:292` เติมข้อความ “ตรวจพบจุดรบกวน...” แม้ backend ไม่ส่ง summary
- `:303` textual score หายถูกแสดงเป็น `0%`
- `:325` source result หายถูกแสดงเป็น “ไม่พบภาพที่ตรงกัน”
- `:329` เติมข้อความเหมือนมีการค้นหาแหล่งที่มาแล้ว
- repository ฝั่ง server ปัจจุบันยังไม่พบ `source_status` implementation; จึงยิ่งต้องแยก unavailable จาก no-match ใน UI

### P1-03 Risk score ที่หายถูกตีความเป็น Low
- `src/components/ui/Badge.jsx:68` ใช้ `Number(score) || 0`
- `src/pages/UserDetail.jsx:264,268,271` ใช้ `?? 0` แล้วจัดระดับเป็น “ต่ำ”
- Unknown/missing ต้องไม่กลายเป็น Low เพราะ “ไม่มีหลักฐาน” ไม่เท่ากับ “ความเสี่ยงต่ำ”

### P1-04 Dashboard แสดง health status แบบ hardcoded
- `src/pages/Dashboard.jsx:169-181`
- UI แสดง `ฐานข้อมูล ปกติ`, `โมเดล AI พร้อมใช้งาน` โดยไม่ map `health.database`, `health.models`
- active model มี fallback เป็น `SegFormer v1.0.0` หรือ `SegFormer-B2` เมื่อข้อมูลจริงไม่มี
- Backend `HealthStatus` มี field `database`, `storage`, `models`, `queue`, `last_check`; UI ควรใช้ข้อมูลเหล่านี้ตรง ๆ หรือแสดง Unknown

### P1-05 Model dry-run เติม telemetry สมมติ
- `src/pages/ModelsList.jsx:274`
- fallback `98ms` และ `235MB` ไม่มีหลักฐานจาก API
- `ModelDryRunResponse.details` เป็น optional จึงต้องใช้ `— / ไม่ได้รายงาน` ไม่ใช่ค่าตัวเลขสมมติ

### P1-06 Profile / Session เติมข้อมูลระบบสมมติ
- `src/pages/ProfileSettings.jsx:206` ไม่มี profile id แล้วแสดง `#1`
- `:214` ไม่มี `last_login_at` แล้วใช้เวลาปัจจุบัน
- `:331` ไม่มี IP แล้วแสดง `127.0.0.1`
- ทั้งสามค่าเป็นข้อมูล audit/security จึงห้าม fallback เป็นค่าที่ดูจริง

### P1-07 Heatmap legend สื่อความหมายผิด domain
- `src/components/ui/HeatmapComparator.jsx:248-259` แสดงสีเป็น Low 0–39 / Medium 40–69 / High 70–100
- แต่ backend `onnx_worker.py:36-55` สร้าง continuous colormap Green→Blue→Yellow→Red ที่ช่วง 85/170 ของ 255 ไม่ได้แบ่งตาม Overall Risk 40/70
- ควรใช้ legend “Forgery probability / anomaly intensity” ตาม probability map ไม่ใช่ Overall Risk tier

## 6. Confirmed Findings — P2 UX / Accessibility / Workflow

### P2-01 Clickable surfaces ไม่เป็น semantic control
- `Dashboard.jsx:212` KPI “รอตรวจ” เป็น Card/div ที่มี `onClick` แต่ keyboard focus ไม่ถึง
- `ReportsList.jsx:216`, `UsersList.jsx:162`, `AuditLogsList.jsx:168` ใช้ clickable table row โดยไม่มี keyboard equivalent
- ควรใช้ Link/Button จริง หรือเพิ่ม semantic + keyboard behavior โดยไม่ซ้อน interactive controls ผิดโครงสร้าง

### P2-02 Heatmap interaction ยัง mouse-first
- `HeatmapComparator.jsx:126-132` ใช้ `onMouseMove` สำหรับ divider
- ไม่มี Pointer Events, touch drag, `role="slider"`, `aria-valuenow`, keyboard arrows
- ปุ่ม Zoom/Reset มีพื้นที่เล็กและอาศัย `title` แทน accessible name ที่ชัดเจน

### P2-03 Login label association ไม่ครบ
- `Login.jsx:69-95` label ไม่มี `htmlFor` และ input ไม่มี `id`
- wrapper หน้า Login มี `select-none` ทำให้ copy error/help text ไม่ได้

### P2-04 Reduced motion ยังไม่มี authority
- ไม่พบ `prefers-reduced-motion` หรือ `motion-reduce` ใน `admin-portal/src`
- มี `animate-pulse`, modal zoom/fade, toast slide และ status pulse หลายจุด
- animation ส่วนสถานะควรคงได้เฉพาะเมื่อมีความหมาย แต่ต้องมี reduced-motion fallback

### P2-05 Mobile data table ยังใช้ desktop table เป็นหลัก
- Runtime 390x844 ของ Reports แสดงเพียงคอลัมน์ช่วงต้นใน viewport; Status, Date และ Action อยู่ด้านขวา
- `Table.jsx` มี `overflow-x-auto` จึงไม่ overflow หน้า แต่ไม่มี fade/label/cue ว่าเลื่อนได้
- สำหรับงาน admin บนจอเล็กควรเลือก priority columns หรือ stacked compact row แทนบังคับ horizontal scroll ทุกตาราง

### P2-06 Design documentation drift
- `design/admin.md:76-86` ระบุ Inter/Sarabun แต่ source ใช้ Noto Sans Thai + Geist
- `design/admin.md:174` ระบุไม่มี Global Search แต่ source มี Command Palette + `/admin/search`
- `design/admin.md:216` ระบุ KPI 7 ใบ แต่ Dashboard ปัจจุบันมี 4 KPI หลัก
- `design/admin.md:551-576` ระบุ Upload Model flow แต่ source ปัจจุบันไม่มี upload UI
- `admin-portal/README.md:20` ระบุ System Health Bar เป็น CPU/Memory/GPU/Latency แต่ implementation แสดง Database/AI model/active model
- README อ้าง `admin-portal/DESIGN.md` แต่ไฟล์ดังกล่าวไม่มีอยู่จริง

### P2-07 agy พบ route-state issue ใน Report Detail
- `ReportDetail.jsx:53-59` ใช้ `noteSynced.current` แล้วไม่ reset เมื่อ `id` เปลี่ยน
- หาก component instance ถูก reuse ระหว่าง `/reports/:id` ค่า note ของเคสก่อนอาจไม่ sync กับ report ใหม่
- ควร reset ref/note เมื่อ `id` เปลี่ยน หรือ derive state จาก report identity อย่างชัดเจน

### P2-08 Rollback model target ไม่ชัดเจน
- `ModelsList.jsx:313` เลือก `models.find((m) => m.id !== model.id)` เป็นเป้าหมาย rollback
- เป็น “first non-active model” ไม่ใช่ explicit previous stable version
- UX ควรให้เลือก target version พร้อม comparison + reason ก่อนดำเนินการ

## 7. AI-Slop / Visual Polish — P3

ตัวเลข deterministic จาก `admin-portal/src`:
- `<Card>` 28 จุด
- `text-xs` / 11–13px 153 จุด
- rounded icon-tile pattern อย่างน้อย 14 จุด
- `transition-all` 19 จุด
- `animate-pulse` 16 จุด
- `rounded-full` 22 จุด

ประเด็นที่เห็นเป็น pattern มากกว่าบั๊ก:

1. Login ใช้สูตรสำเร็จ “cyber security”: shield-in-rounded-square + cyan ambient glow + dark glass card + shadow ใหญ่ (`Login.jsx:40-48`) ดูเป็น AI-generated security landing/login มากกว่าหน้า operate ที่นิ่งและจริงจัง
2. หลายหน้าใช้ card + colored icon square + metric ซ้ำ เช่น User Detail, Dataset Export, Profile และ Models ทำให้ hierarchy ทุกส่วนมีน้ำหนักใกล้กัน
3. ข้อความ 12px จำนวนมากเหมาะกับ metadata บางส่วน แต่ถูกใช้เป็น body/supporting copy กว้างเกินไป โดยเฉพาะภาษาไทย
4. `transition-all` และ pulse ถูกใช้ใน control หลายจุด ทั้งที่ `transition-colors` หรือ no-motion เพียงพอ
5. status pill / dot / icon box ถูกใช้บ่อยจน semantic signal อ่อนลง เพราะทั้งข้อมูลสำคัญและข้อมูลทั่วไปมี treatment คล้ายกัน

ระดับ AI-slop โดยรวม:
- Visual trope: ปานกลาง
- Template/card repetition: ปานกลาง
- Copy buzzword/slop: ต่ำถึงปานกลาง
- Fabricated evidence / semantic slop: สูง และเป็นประเด็นที่ต้องแก้ก่อน visual redesign

## 8. เปรียบเทียบผล: Impeccable vs ตรวจเอง vs agy

| ประเด็น | Impeccable detector | ตรวจเอง | agy | ข้อสรุป |
|---|---|---|---|---|
| Hardcoded Dashboard health | ไม่พบ | พบ | พบ | Confirmed |
| Model dry-run 98ms / 235MB | ไม่พบ | พบ | พบ | Confirmed |
| Profile last-login fallback = now | ไม่พบ | พบ | พบ | Confirmed |
| Heatmap mouse-only | ไม่พบ | พบ | พบ | Confirmed |
| Interactive Card keyboard | ไม่พบ | พบ | พบ | Confirmed |
| Heatmap original-as-heatmap fallback | ไม่พบ | พบ | ไม่รายงาน | Confirmed จาก source โดยตรง |
| Source unavailable -> no-match | ไม่พบ | พบ | ไม่รายงาน | Confirmed จาก UI + server search |
| Missing risk -> Low | ไม่พบ | พบ | ไม่รายงาน | Confirmed จาก Badge/UserDetail |
| Profile ID/IP fabricated fallback | ไม่พบ | พบ | ไม่รายงาน | Confirmed |
| Heatmap legend vs colormap semantics | ไม่พบ | พบ | ชม threshold consistency | Confirmed semantic mismatch; threshold consistency ไม่ได้แก้ meaning mismatch |
| Report note state leakage | ไม่พบ | ไม่พบรอบแรก | พบ | ตรวจ source ซ้ำแล้วรับเป็น P2 |
| Dashboard partial-shape crash risk | ไม่พบ | ไม่จัดเป็น design finding | พบ | รับเป็น implementation robustness issue |
| Model rollback target | ไม่พบ | พบภายหลัง | พบ | Confirmed |
| Dark Recharts theme bug | ไม่พบ | ไม่พบ | ระบุเป็น false positive | เห็นตรงกันว่าไม่ใช่ปัญหา |

ข้อสังเกตสำคัญ: deterministic detector เหมาะกับ anti-pattern เชิงรูปแบบ แต่ไม่ตรวจความจริงของข้อมูลที่ UI สื่อ จึงต้องมี product-integrity audit แยกต่างหากสำหรับระบบ forensic/admin

## 9. False Positives ที่ตัดออก

- Inline style ของ Recharts ไม่ได้ทำให้ Dark Mode พัง เพราะใช้ CSS variables จริง
- Pagination ซ่อนเมื่อมีหน้าเดียวเป็น intended decluttering ไม่ใช่ bug
- การมี `SegFormer-B2` ใน ternary ไม่ใช่ syntax bug; ปัญหาคือ fallback นั้นไม่ควรถูกนำเสนอเป็นสถานะจริงเมื่อ API ไม่มีค่า
- String ภาษาไทยใน Profile ที่เคยปรากฏเป็นตัวอักษรเสียในผล grep รอบหนึ่งไม่พบใน full file read จึงไม่นับเป็น finding

## 10. Verification ที่รันจริง

- Impeccable context script: รัน 1 ครั้ง; พบ path-context drift ตามที่ระบุ
- Impeccable detector: `[]` (0 deterministic findings)
- Runtime visual check ผ่าน Headless Chrome:
  - Login 1440x1000
  - Dashboard 1440x1000 และ 390x844
  - Reports 1440x1000 และ 390x844
- `npm run lint`: PASS, 0 ESLint errors
- `npm run build`: PASS, Vite production build สำเร็จใน 561ms
- `agy`: independent audit สำเร็จ และผลถูกเทียบกับ source จริงก่อนนำมาใช้

## 11. ข้อสรุป

Admin Portal ไม่ได้มีปัญหา “หน้าตาแย่” เป็นหลัก โครงสร้าง visual system และ responsive foundation อยู่ในระดับดีแล้ว จุดที่ควรแก้ก่อนคือความน่าเชื่อถือของข้อมูลและ semantics ของ forensic/admin UI

ทิศทาง redesign ที่เหมาะสมคือ Operate Mode ที่นิ่งกว่าเดิม: ลด cyber decoration, ลด card/icon-box repetition, เพิ่ม data hierarchy, ใช้ Unknown/Unavailable อย่างตรงความหมาย, ทำ Heatmap เป็น forensic tool ที่ accessible จริง และเปลี่ยน responsive data-heavy pages จาก desktop-table shrink ให้เป็น information-priority layout

แผนการปรับใหม่อยู่ที่ `design/admin/admin-redesign-plan-2026-09-20.md`
