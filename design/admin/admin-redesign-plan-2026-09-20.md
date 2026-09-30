# Admin Portal Redesign Plan

วันที่: 2026-09-20
อ้างอิง Audit: `design/admin/admin-design-ux-audit-2026-09-20.md`
ขอบเขต: `admin-portal/` และ contract/documentation ที่จำเป็นต่อความถูกต้องของ UI
สถานะ: Plan only — ยังไม่ implement source UI ในเอกสารนี้

## 1. เป้าหมายการออกแบบใหม่

ปรับ Admin Portal จากแนว “Cyber-Forensics Dashboard” ที่ยังมี decorative/template pattern ให้เป็น **ScamGuard Operations Console** ที่เน้น:

1. Evidence first — ทุกคะแนน สถานะ และ forensic artifact ต้อง trace กลับข้อมูลจริงได้
2. Task first — สิ่งที่ผู้ดูแลต้องตัดสินใจอยู่ก่อน decoration
3. Clear hierarchy — แยก primary action, operational status, evidence และ metadata ชัดเจน
4. Accessible by default — keyboard, screen reader, touch, reduced motion
5. Responsive by information priority — ไม่ใช่แค่ย่อ desktop layout
6. One design authority — token, typography, copy state และ component behavior มีแหล่งเดียว

## 2. Non-negotiable Design Rules

- ห้ามสร้างคะแนน, status, latency, memory, IP, timestamp, model version, heatmap หรือ analysis summary เมื่อ backend ไม่ส่ง
- `Unknown`, `Unavailable`, `Not checked`, `No match found` ต้องเป็นคนละสถานะ
- ห้ามใช้ Overall Risk แทน score ของ analysis layer ใด layer หนึ่ง
- Risk color ใช้เฉพาะ risk semantics; Heatmap ใช้ anomaly-probability semantics แยกกัน
- การกระทำ destructive/production-impacting ต้องมี explicit target + confirmation + reason เมื่อเหมาะสม
- Visual decoration ต้องมีหน้าที่ต่อ task; ถ้าไม่มีให้ตัดออก

## 3. Phase 0 — Product Integrity Gate (P1, ทำก่อน visual polish)

### 3.1 สร้าง state authority สำหรับข้อมูลที่อาจหาย
- เพิ่ม shared display helpers เช่น `formatOptionalMetric`, `formatOptionalDate`, `formatOptionalIdentifier`
- เพิ่ม `UnknownBadge` / neutral unavailable treatment ที่ไม่ใช้สีเขียว
- แก้ `RiskBadge` ให้รับ missing score แล้วแสดง `ไม่ทราบ` แทน `ต่ำ (0)`
- แก้ User Detail recent scans ให้ score/grade missing เป็น Unknown

### 3.2 แก้ Report Detail ให้ evidence-based 100%
- Visual score: แสดงเฉพาะ `visual_anomaly.score`; ห้าม fallback Overall Risk
- Visual/Text summary: ถ้า backend ไม่มี ให้ใช้ข้อความสถานะ “ไม่มีคำอธิบายจากระบบ” ไม่ใช่สรุปวิเคราะห์แทน
- Text score missing: Unknown ไม่ใช่ 0%
- Source verification: แยก `unavailable`, `not_checked`, `checked_no_match`, `matches_found`
- ถ้า backend ยังไม่มี `source_status` ให้ UI ระบุ “ยังไม่มีข้อมูลการตรวจสอบแหล่งที่มา” จน contract พร้อม

### 3.3 Heatmap integrity
- ถ้าไม่มี `heatmapUrl` ให้แสดง dedicated unavailable panel
- ไม่ render comparator/overlay ด้วย `originalUrl` แทน Heatmap
- เปลี่ยน legend จาก Risk tier เป็น continuous anomaly/forgery probability legend
- document ความหมายสีให้ตรงกับ colormap implementation จริง

### 3.4 Dashboard health ต้องผูก backend จริง
- map `health.database`, `health.storage`, `health.models`, `health.queue`, `health.last_check`
- ใช้ status mapping กลาง: ok / degraded / unavailable / unknown
- Active model แสดงเฉพาะ `dashboard.model.active_version`; ไม่มีค่าให้แสดง `ไม่ทราบ`
- ห้าม fallback เป็น `v1.0.0` หรือ `SegFormer-B2`

### 3.5 Model operation integrity
- Dry-run ไม่มี latency/memory ให้แสดง `ไม่ได้รายงาน`
- Architecture/file/dataset metadata ที่ไม่มีให้แสดง `ไม่ระบุ` เท่านั้น
- Rollback ต้องเปิด selector ของ version เป้าหมาย พร้อม current → target comparison
- ระบุ model ID/version/checksum ใน confirmation ให้ครบก่อน deploy/rollback

### 3.6 Profile / session integrity
- ไม่มี profile id ให้แสดง `—`
- ไม่มี last login ให้แสดง `ไม่มีข้อมูล`
- ไม่มี session IP ให้แสดง `ไม่ทราบ` ไม่ใช่ loopback address
- สิทธิ์ผู้ดูแลต้องอ้าง field/role จริงจาก API; ห้าม hardcode “สิทธิ์ทั้งหมด” หาก contract ไม่รับรอง

### Exit Criteria Phase 0
- grep ไม่พบ fabricated numeric/system fallbacks ที่ระบุใน audit
- ไม่มี missing evidence state ใดกลายเป็น success/low/normal
- manual API-response matrix: complete / partial / null / unavailable แสดงความหมายถูกต้อง

## 4. Phase 1 — Information Hierarchy & Operate Mode

### 4.1 Global shell
- คง Sidebar grouping ปัจจุบัน เพราะ IA ดีแล้ว
- ลด TopBar จาก “title ซ้ำกับ page header” ให้เป็น global utilities: command search, connection state, theme, account
- Page header เป็น authority ของชื่อหน้า, context, summary และ primary action
- Realtime indicator ใช้ pulse เฉพาะตอน meaningful; static state เป็น default

### 4.2 Dashboard
- คง KPI หลัก 4 ใบ ไม่ย้อนกลับไป 7 ใบตาม design เก่า
- Health เปลี่ยนเป็น compact operational status strip ที่อ่านค่า backend จริง
- High-risk KPI ใช้ danger semantic เฉพาะเมื่อเป็น alert/actionable ไม่ใช้ warning แบบคลุมเครือ
- จัด chart ตามคำถามของผู้ดูแล: volume trend, risk distribution, report categories
- ไม่เพิ่ม card เพียงเพื่อ “เติม dashboard”

### 4.3 Report Queue
- ให้ filter/search เป็น toolbar หลักติดกับ table
- Desktop: ตาราง dense แต่ readable
- Mobile: แสดง thumbnail + report id + category + risk + status ก่อน; date/action เข้า secondary row/menu
- ทำ row navigation เป็น semantic Link หรือ dedicated primary cell link

### 4.4 Report Detail
- Evidence area เป็น primary surface; metadata เป็น secondary
- Workflow state (`pending/reviewing/approved/rejected`) อยู่ใกล้ action header
- Multi-layer analysis ใช้ 3 evidence rows ไม่ต้องเป็น mini-card ซ้อน card ถ้าไม่มีข้อมูลมากพอ
- unavailable layer ใช้ neutral state พร้อมเหตุผล ไม่ใช้ score 0 หรือข้อความเหมือนผลตรวจ

## 5. Phase 2 — ลด Visual AI-Slop และจัด Design Language ใหม่

### 5.1 Login
- ตัด ambient cyan blobs และ `backdrop-blur` ที่ไม่มีหน้าที่
- ลด shield-in-box จาก hero decoration เป็น brand mark ขนาดเล็ก
- ใช้ plain secure sign-in surface: heading, explanation สั้น, form, security notice
- คง dark/light theme แต่ให้ contrast และ focus เป็นจุดเด่นแทน glow/shadow

### 5.2 Card strategy
- กำหนด 3 surface levels เท่านั้น: page canvas, section surface, elevated modal/popover
- ใช้ Card เมื่อ section ต้องมี boundary จริง ไม่ครอบทุก metric/list
- metric ที่สัมพันธ์กันใช้ summary strip/grid เดียว แทน icon-card แยกหลายใบ
- ลด colored icon square ใน User Detail, Dataset Export, Profile และ Models

### 5.3 Status treatment
- จำกัด pill/badge ให้ status, risk, workflow state, deployment state
- ข้อมูลทั่วไป เช่น count, architecture, timestamp ไม่ต้องทำเป็น pill
- danger/success color ใช้เฉพาะ semantic outcome ไม่ใช้เป็น decoration

### 5.4 Motion
- แทน `transition-all` ด้วย `transition-colors`, `transition-opacity` หรือ property เฉพาะ
- pulse ใช้เฉพาะ live/connecting state ที่มีความหมาย
- เพิ่ม global `prefers-reduced-motion: reduce` rule สำหรับ animation/transition ที่ไม่จำเป็น

## 6. Phase 3 — Typography, Density, Spacing

### 6.1 Typography authority
- ใช้ `Noto Sans Thai Variable` เป็น primary UI font สำหรับข้อความไทย
- ใช้ `Geist Variable` สำหรับ Latin/ตัวเลขตามความเหมาะสม โดยไม่สลับจน typography แตก
- body หลักเป้าหมาย 14px; supporting text 13px; 12px จำกัดไว้ metadata/caption ที่ไม่ critical
- table body ใช้ 13–14px ตามความหนาแน่น; primary values และ action ไม่ต่ำกว่า 13px
- ตัวเลข KPI ใช้ tabular numerals และ mono เฉพาะจุดที่ต้อง compare column alignment

### 6.2 Spacing / radius
- คง token radius ปัจจุบัน 4/6/8/12px เป็นฐาน
- page spacing ใช้ scale เดียว เช่น 8/12/16/24/32
- ลด nested `p-4` + card + inner rounded panel ที่สร้างหลายชั้นโดยไม่เพิ่ม hierarchy
- section gap ต้องสะท้อน grouping มากกว่าการกระจาย card เท่ากันทุกจุด

### 6.3 Copy hierarchy
- Page title 20–24px
- Section title 14–16px
- Supporting copy 13–14px
- Metadata 12–13px
- หลีกเลี่ยง technical buzzword ใน UI ถ้าไม่ช่วยตัดสินใจ; เก็บชื่อ model/framework/checksum ใน forensic metadata ตามความจำเป็น

## 7. Phase 4 — Accessibility & Input Methods

### 7.1 Semantic interaction
- clickable KPI ใช้ Link/Button จริง
- clickable table row เปลี่ยนเป็น primary link/action ที่ keyboard เข้าได้ หรือทำ row interaction ตาม ARIA pattern อย่างครบถ้วน
- icon-only button ทุกจุดต้องมี accessible name; `title` อย่างเดียวไม่พอ
- `TableHead` กำหนด `scope="col"` เป็น default สำหรับ simple data table

### 7.2 Forms
- Login และ custom inputs ต้องมี `id` + `htmlFor`
- error text เชื่อม `aria-describedby` และ `aria-invalid`
- ยกเลิก `select-none` ในบริเวณที่มีข้อความ error/help/copyable metadata

### 7.3 Heatmap forensic control
- ใช้ Pointer Events รองรับ mouse, touch, pen
- comparator divider ใช้ keyboard arrows/Home/End และประกาศค่า position
- opacity range มี label programmatic และ value text
- Zoom controls เพิ่ม hit area และ aria-label
- เมื่อ artifact unavailable focus ต้องไม่ตกไปยัง controls ที่ใช้งานไม่ได้

### 7.4 Motion / focus
- เพิ่ม `prefers-reduced-motion`
- ทดสอบ visible focus ใน Light/Dark
- modal/command palette ตรวจ focus return และ screen reader announcement

## 8. Phase 5 — Responsive Information Priority

### 8.1 Breakpoint targets
- 360–430px: compact admin fallback, primary tasks usable
- 768px: tablet/medium
- 1024px: desktop operations
- 1440px และ 1600px: wide operations workspace

### 8.2 Tables
- Reports: mobile compact rows แสดง ID, thumbnail, category, risk, status; secondary data expand/action menu
- Users: name/email/status/scans เป็น priority; registration date เป็น secondary
- Audit: mobile ใช้ event row + expandable detail แทนบีบ JSON/table หลายคอลัมน์
- Sessions: device/current-state/action อยู่ก่อน raw user-agent/IP
- ถ้ายังใช้ horizontal scroll ต้องมี visual cue และ sticky identity column ตามความเหมาะสม

### 8.3 Models
- Desktop เปลี่ยนจาก card grid จำนวนมากเป็น version comparison table/list
- Active model ใช้ summary banner/row เดียวที่เด่นพอ ไม่ต้อง card style ต่างทุก version
- Dry-run detail เปิด inline disclosure หรือ side panel
- Mobile แสดง version/status/core metrics ก่อน metadata/checksum

### 8.4 Heatmap
- mobile toolbar ลดเหลือ mode selector + essential zoom; advanced controlsอยู่ disclosure
- side-by-side บนจอแคบเปลี่ยนเป็น vertical stack
- comparator drag ต้องทำงานผ่าน touch จริง ไม่ใช่ mouse simulation

## 9. Phase 6 — Component Architecture สำหรับ Design Authority

สร้าง/ปรับ reusable primitives เฉพาะที่ลดความไม่สอดคล้องจริง:

- `PageHeader` — title, description, primary/secondary actions
- `OperationalStatus` — ok/degraded/unavailable/unknown จาก API จริง
- `OptionalMetric` — number/value + unavailable handling
- `EvidenceState` — available/unavailable/not-checked/error โดยไม่สร้าง evidence
- `DataTable` conventions — header scope, semantic row action, responsive priority
- `MetricStrip` — ใช้แทน card zoo สำหรับ metric ที่สัมพันธ์กัน
- `ModelVersionRow` / comparison pattern

กฎ component:
- อย่าสร้าง wrapper ใหม่ถ้าเป็นเพียง div + class เดียว
- data state และ visual state ต้องแยกจากกัน
- primitive ไม่ควรตัดสิน domain เช่นเปลี่ยน null เป็น score 0
- domain mapping เช่น Risk level ต้องมี authority กลางและรองรับ Unknown

## 10. Phase 7 — Design Documentation Sync

- สร้าง `admin-portal/DESIGN.md` ให้เป็น implementation-facing design authority ตามที่ README อ้างถึง
- ปรับ `design/admin.md` ให้เป็น high-level design/reference และชี้ไป `admin-portal/DESIGN.md`
- แก้ typography จาก Inter/Sarabun เป็น implementation ปัจจุบันหากยืนยันจะใช้ต่อ
- แก้ Global Search, KPI count, Model operations, Health Bar ให้ตรง code/contract จริง
- ระบุ semantic rules ของ Unknown/Unavailable/No Match และ Heatmap probability
- อัปเดต README เฉพาะเมื่อ implementation ใหม่เสร็จ ไม่เขียน future behavior เป็น current behavior

## 11. Phase 8 — Verification Matrix

### Automated / deterministic
- `npm run lint`
- `npm run build`
- Impeccable detector
- grep gate สำหรับ fabricated fallback ที่ audit ระบุ
- เพิ่ม component tests สำหรับ RiskBadge Unknown, EvidenceState, OperationalStatus และ Heatmap unavailable

### Runtime visual matrix
- Theme: Light / Dark / System
- Width: 360 / 390 / 768 / 1024 / 1440 / 1600
- Pages: Login, Dashboard, Reports, Report Detail, Users, User Detail, Models, Export, Audit, Profile
- State: loading / success / empty / partial / unavailable / error
- Data density: 0 rows / 3 rows / 10+ rows / long text / long identifiers

### Accessibility
- Keyboard-only full flow
- focus order + visible focus
- screen-reader labels สำหรับ forms, icon controls, modal, tables
- touch/pointer test Heatmap
- reduced motion
- contrast Light/Dark ของ text, status, focus, disabled

### Operational flows
- Report pending -> reviewing -> approve/reject
- Optimistic conflict 409
- Model dry-run -> deploy -> explicit rollback target
- Export create -> running -> cancel/download
- Session revoke
- API partial/missing field โดย UI ไม่สร้างข้อมูลแทน

## 12. Acceptance Criteria สำหรับ Redesign

ถือว่า redesign ผ่านเมื่อ:

- ไม่มี fabricated evidence/system metric จาก client fallback
- Missing risk ไม่ถูกแสดงเป็น Low
- Source unavailable ไม่ถูกแสดงเป็น No Match
- Heatmap unavailable ไม่แสดง original image เป็นผลโมเดล
- Heatmap legend ตรงกับ probability/colormap จริง
- Dashboard health ทุก field มาจาก backend หรือ Unknown
- Dry-run telemetry ที่ API ไม่ส่งแสดง unavailable ไม่ใช่ตัวเลขสมมติ
- Keyboard ใช้งาน primary admin flows ได้ครบ
- Heatmap ใช้ mouse/touch/keyboard ได้
- ไม่มี critical interaction ที่พึ่ง `title` เพียงอย่างเดียวเป็น accessible name
- reduced motion มีผลกับ pulse/zoom/fade ที่ไม่จำเป็น
- 390px ไม่บังคับ horizontal scroll เพื่อเข้าถึง primary action
- design tokens เป็น authority เดียว และ docs ตรง implementation
- Light/Dark/System ผ่าน visual regression รอบสุดท้าย
- `npm run lint` และ `npm run build` ผ่าน

## 13. ลำดับ Implement ที่แนะนำ

1. Phase 0 Product Integrity
2. Phase 4 Accessibility semantics ที่เกี่ยวกับ evidence controls
3. Phase 1 hierarchy / shell / page structure
4. Phase 2 visual AI-slop cleanup
5. Phase 3 typography / spacing / density
6. Phase 5 responsive information priority
7. Phase 6 component authority
8. Phase 7 documentation sync
9. Phase 8 full verification

ห้ามเริ่มจากเปลี่ยนสี, เพิ่ม animation หรือสร้าง card ใหม่ก่อน Phase 0 เพราะจะเป็นการ polish UI ที่ยังสื่อข้อมูลผิดความหมาย
