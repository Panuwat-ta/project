# ScamGuard Admin Portal — Implementation Design Authority

อัปเดต: 2026-09-21

เอกสารนี้เป็น source of truth สำหรับ UI ที่ implement อยู่ใน `admin-portal/src` และใช้ร่วมกับ `design/admin.md` ซึ่งเก็บ product/design intent ระดับสูง หากรายละเอียดขัดกัน ให้ยึดไฟล์นี้สำหรับ implementation ปัจจุบัน แล้วปรับเอกสารระดับสูงให้ตามภายหลัง

## 1. Product mode

Admin Portal เป็น **Operate surface**: ผู้ดูแลระบบเข้ามาตรวจคิวรายงาน, ดูหลักฐาน, จัดการผู้ใช้/โมเดล/ชุดข้อมูล และตรวจ audit trail ดังนั้นลำดับความสำคัญคือ:

1. ความถูกต้องของข้อมูลก่อนความสวยงาม
2. งานหลักและสถานะต้องอ่านได้ในไม่กี่วินาที
3. ความคุ้นเคยและ semantic controls สำคัญกว่าลูกเล่น
4. Missing / unavailable / error ต้องไม่ถูกตีความเป็นค่าปกติ
5. สีและ motion ใช้เพื่อสื่อ state ไม่ใช้เป็น decoration

## 2. Evidence integrity

- ห้ามสร้างตัวเลข, timestamp, IP, model version, health state หรือผลวิเคราะห์ใน client เพื่อเติม field ที่ backend ไม่ส่ง
- Risk score ที่ไม่มีข้อมูลแสดง `ไม่ทราบ`; ค่า `0` เป็นข้อมูลจริงและยังคงจัดเป็นระดับต่ำ
- Source verification ที่ยังไม่เชื่อม backend ใช้ EvidenceState `unavailable` และแสดง `ยังไม่พร้อมใช้งาน`; ห้ามสรุปว่า “ไม่พบภาพที่ตรงกัน”
- Heatmap ที่ไม่มีข้อมูลต้องแสดง unavailable state; ห้ามเอาภาพต้นฉบับมาแทน heatmap
- Model dry-run แสดง latency/memory เฉพาะเมื่อ response ส่งค่าจริง
- Dashboard health อ่านจาก `/admin/health`; field ที่หายใช้สถานะ `ไม่ทราบ`

Evidence state vocabulary ใช้ authority กลางใน `src/lib/display-state.js`:

- `unavailable` → `ยังไม่พร้อมใช้งาน`
- `not_checked` → `ยังไม่ได้ตรวจ`
- `checked_no_match` → `ตรวจแล้ว: ไม่พบภาพตรงกัน`
- `matches_found` → `ตรวจแล้ว: พบแหล่งที่มา`
- `error` → `ตรวจไม่สำเร็จ`
- missing/unknown → `ไม่ทราบ`

## 3. Typography

ใช้ family เดียวสำหรับ product UI เป็นหลัก:

- Thai/UI text: `Noto Sans Thai Variable`
- Latin fallback: `Geist Variable`
- Code/data only: system monospace via `font-mono`
- Page title: 20px / 700 (`text-xl font-bold`)
- Section title: 14–16px / 600
- Body and controls: 14px เป็นฐาน
- Supporting copy: 13px
- 12px ใช้เฉพาะ metadata, timestamp, dense table caption ที่เป็นข้อมูลรองจริง
- ตัวเลขตารางใช้ `tabular-nums`; monospace ไม่ใช้เป็น costume สำหรับข้อความทั่วไป

## 4. Color and state

Token authority อยู่ใน `src/index.css` ทั้ง Light/Dark mode:

- `primary`: current selection และ primary action
- `success`: confirmed healthy/success state
- `warning`: reviewing/degraded/needs-attention ที่ยังไม่เป็นอันตราย
- `danger`: high risk, destructive action, failure
- `info`: pending/informational state
- `muted`: unavailable, unknown, secondary information

ห้ามใช้สี semantic เป็น decoration หากไม่มี state ที่รองรับความหมายของสีนั้น

## 5. Surfaces and layout

- Main content จำกัดที่ `max-w-[1600px]` และใช้ page padding 16/24/32px ตาม breakpoint
- Sidebar 256px desktop; mobile ใช้ drawer + backdrop
- Card ใช้กับ section boundary ที่มีเหตุผล ไม่ใช้สร้าง card ซ้ำสำหรับ metric ทุกค่า
- Metric ที่เป็นกลุ่มเดียวกันควรรวมเป็น strip เดียวและแบ่งด้วย border
- Desktop tables เหมาะกับข้อมูล dense; mobile ต้องจัด primary fields/action ใหม่ ไม่บังคับ horizontal scroll เพื่อทำงานหลัก

## 6. Interaction and accessibility

- ใช้ `<button>` สำหรับ action และ `<a>/<Link>` สำหรับ navigation; ห้ามทำ `<div>` หรือทั้ง `<tr>` clickable โดยไม่มี semantics
- ทุก icon-only control ต้องมี accessible name
- Form label ต้องผูกกับ control ด้วย `htmlFor`/`id`
- Table header ใช้ `scope="col"`
- Dialog ต้อง trap focus, ปิดด้วย Escape และคืน focus เมื่อปิด
- Heatmap comparator รองรับ pointer/touch และ keyboard: Arrow ±1, PageUp/PageDown ±10, Home/End
- `prefers-reduced-motion: reduce` ต้องตัด animation/transition ที่ไม่จำเป็น
- Focus ring ต้องมองเห็นชัดทั้ง Light/Dark

## 7. Motion

- Product motion ใช้เพื่อ state feedback เท่านั้น
- ระยะทั่วไป 150–250ms
- ห้ามใช้ `transition-all`; ระบุ property ที่เปลี่ยน
- Skeleton pulse ใช้ได้ใน loading state และถูกลด motion ตาม media query
- ไม่มี decorative page-load choreography หรือ continuous status pulse

## 8. Heatmap semantics

Backend heatmap ใช้ probability colormap แบบต่อเนื่อง **Green → Blue → Yellow → Red** จาก 0–100% ดังนั้น legend ของ heatmap ต้องเป็น continuous probability scale

Risk grade ของรายงานเป็นอีก domain หนึ่ง: Low 0–39, Medium 40–69, High 70–100 และต้องไม่ถูกใช้เป็น legend ของ heatmap probability

## 9. Responsive priorities

- Target QA: 390px, 768px, 1440px
- Reports mobile: thumbnail, report ID, category, risk, status และปุ่มตรวจสอบต้องเห็นโดยไม่ scroll แนวนอน
- Users mobile: identity, status, role, scan count และ profile/status action ต้องเข้าถึงได้ทันที
- Audit mobile: event summary + explicit expand control; payload เปิดแบบ progressive disclosure
- Sessions mobile: device, state, IP/time และ revoke action อยู่ใน stacked record
- Models: desktop ใช้ comparison list; mobile แสดง core metrics ก่อน metadata

## 10. Verification gate

ก่อนส่งมอบ UI change:

1. `npm test`
2. `npm run lint`
3. `npm run build`
4. ตรวจ fabricated fallback gate (`98ms`, `235MB`, loopback fallback, fake model version, original-as-heatmap, missing-risk-as-zero)
5. Runtime visual QA ทั้ง Dark/Light/System และ breakpoint 390/768/1440
6. Keyboard-only flow สำหรับ navigation, modal, filters และ heatmap
7. ตรวจ empty/error/loading/unavailable states ที่เปลี่ยน
8. รัน Impeccable mechanical detector หลัง implementation เสร็จเพียงรอบเดียว
9. independent review เปรียบเทียบกับ audit/plan และแก้เฉพาะ finding ที่ยืนยันจาก source/runtime

เอกสารที่เกี่ยวข้อง:

- `../design/admin/admin-design-ux-audit-2026-09-20.md`
- `../design/admin/admin-redesign-plan-2026-09-20.md`
- `../design/admin.md`
