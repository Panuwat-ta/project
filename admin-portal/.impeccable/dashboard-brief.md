# Surface Brief — Dashboard (คิวตรวจสอบความเสี่ยง)

> Direction contract สำหรับ production implementation. Comp ที่ผู้ใช้อนุมัติ
> คือ spatial contract; behavior ทั้งหมดยึด PRODUCT.md + Implementation Brief.

- Mode: Operate
- Direction: Incident Assignment Desk
- Dashboard topology: Queue-forward (Pending Queue คือเนื้อหาหลัก ไม่ใช่กราฟสถิติ)
- Theme: Light-first + complete dark theme
- Language: Thai-first
- Icons: Lucide only (ห้าม emoji / Unicode glyph เป็น icon)
- Motion: restrained and purposeful (hover/focus 160ms, drawer/dialog 200–240ms,
  queue feedback 180–220ms, ease-out สุขุม; รองรับ prefers-reduced-motion;
  ห้าม stagger/count-up/chart entrance)
- Roll key: `70b5aaec`

## ลำดับเนื้อหา (บน→ล่าง)

1. Page header — eyebrow `ศูนย์ปฏิบัติการ`, H1 `คิวตรวจสอบความเสี่ยง`,
   คำอธิบายสั้น, เวลาอัปเดตล่าสุด, สถานะ WebSocket, actions (Refresh icon-button +
   `ดูรายงานทั้งหมด` secondary + ArrowUpRight)
2. KPI strip — 4 cards บาง: รอตรวจสอบ (reports.pending), กำลังตรวจสอบ
   (reports.reviewing), สแกนวันนี้ (overview.scans_today), ความเสี่ยงสูง
   (normalize key ใน risk_distribution; ไม่มี = 0 + ระบุที่มา). ห้าม % เปรียบเทียบ
3. Main queue (8/12) + right rail (4/12):
   - Queue: pending สูงสุด 100, เรียง scan.total_risk_score มาก→น้อย,
     เท่ากันเอา created_at เก่าก่อน, ไม่มี scan อยู่ท้าย; แสดง 5 แรก + link ดูทั้งหมด.
     Columns: priority/risk, report+submitter, category/platform, waiting time,
     status, actions (เปิดรายละเอียด / รับเคส). Row click เปิด detail แต่ไม่เริ่ม review.
   - Rail: Risk distribution (จำนวน + สัดส่วน), System health, Active model.
     ห้าม recent activity feed (ไม่มี endpoint)
4. Activity visualization — scan_trend แบบ compact matrix / bar sequence ด้วย
   SVG+CSS (ห้าม canvas), มีสรุป text + accessible table, tooltip ผ่าน hover/focus,
   keyboard-operable, ไม่ animate ตอน refetch

## Responsive

- Desktop: table; Mobile (<900px drawer, table→priority cards, ปุ่มรับเคสกว้างเต็ม)
- ห้าม horizontal table scroll เป็นหน้าหลัก; ห้าม icon-only sidebar rail
- ตารางอ้างอิง QA: 1440×900, 1024×768, 390×844, 360×800, 320×568, zoom 200%

## Comps (รอผู้ใช้เลือก — ห้ามเริ่ม production UI ก่อน)

- [ ] A: Dispatch Board — queue เด่นสุด, rail กะทัดรัด
- [ ] B: Evidence Ledger — density สูง, metadata เด่น
- [ ] C: Signal Map — activity เด่นขึ้น แต่ queue ยัง primary
- เลือกแล้ว: C — Signal Map (วันที่: 2026-09-16)
