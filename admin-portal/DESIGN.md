# DESIGN.md — ScamGuard Admin Portal (as built)

> เขียนจาก implementation จริงหลัง detector ผ่าน (2026-09-16).
> Direction: Incident Assignment Desk · Mode Operate · Topology Queue-forward
> Comp ที่อนุมัติ: C — Signal Map · Roll key `70b5aaec`

## 1. Spatial contract (comp C)

Dashboard เรียง: PageHeader (eyebrow `ศูนย์ปฏิบัติการ` + H1 `คิวตรวจสอบความเสี่ยง`)
→ KPI strip 4 cards → แผนที่สัญญาณ full-width (สถิติสรุป + ปุ่มวันแบบ focus ได้ +
ตาราง sr-only) → grid 12: คิว 8 cols + rail 4 cols (risk distribution, health,
active model). Mobile: table → priority cards, rail stack, drawer แทน sidebar.

## 2. Visual tokens (ใช้จริงใน `src/styles/index.css`)

- Font: Geist Variable + system fallback; metrics ใช้ tabular-nums; mono เฉพาะ IDs/versions
- Light (default): app #F4F7F6, surface #FFFFFF/#EDF2F0/#F9FBFA, line #D7E0DD/#BAC8C3,
  ink #16201D/#5D6B66/#7B8883, action #0E7490→#155E75, focus #06B6D4,
  ok #047857, warn #B45309, bad #BE123C
- Dark (`.dark` + `localStorage["scamguard-admin-theme"]`): app #0B1211,
  surface #101A18/#16221F/#1B2925, line #293A35/#3A4D47, ink #EDF5F2/#A9BBB5/#7F938C,
  action #22A7C6→#38B8D4, focus #67E8F9, ok #34D399, warn #FBBF24, bad #FB7185
- เสี่ยง: emerald/amber/rose + label + icon ทุกจุด; cyan สงวนให้ action/focus
- Layout: content max 1600px, padding 28–32/20–24/16, radius 12, controls ≥40px,
  touch ≥44px (icon-button 40px + padding รอบใน mobile cards กว้างเต็ม)
- Motion: hover/focus 160ms, dialog/drawer 200–240ms (CSS transition),
  ease-out, prefers-reduced-motion ตัดเหลือ opacity; ไม่มี stagger/count-up/entrance

## 3. Component inventory (ของจริง)

- `components/ui`: Button (primary/secondary/ghost/danger, sm/md, loading คงความกว้าง),
  IconButton (บังคับ label), Input/Select/Textarea (label/desc/error/disabled reason),
  Badge (5 tones), MetricCard, PageHeader, StatePanel (7 states),
  Dialog (focus trap/Escape/คืน focus) + ConfirmDialog (reason field),
  Drawer, Toast (aria-live), ResponsiveCollection (table↔cards),
  Pagination, Skeleton, VisuallyHidden, RouteFallback
- `components/layout`: Sidebar 244px (drawer <900px, ไม่ใช่ icon rail), TopBar 64px
  (search trigger, Live badge, theme toggle, avatar), AppShell (skip link + Ctrl+K),
  Theme (light default)
- `components/navigation`: CommandPalette (nav ทันที, search ≥2 ตัวอักษร debounce
  250ms + abort, validate internal path, keyboard ครบ)
- `features/*`: auth (memory token, single-flight refresh, bootstrap skeleton),
  dashboard (comp C), reports (list/filter URL + detail 8/4 + heatmap comparator
  clip-path + decision rail), users (ban/unban + reason), models (active card +
  dry-run + deploy + reason), exports (form + 2s poll + blob download + cancel),
  audit (URL filters + details drawer + copy), profile (3 sections + ARIA live)

## 4. Behavior ที่ตรวจแล้ว

- Auth จริงกับ backend (login 200, refresh rotation, logout ล้าง cache)
- Zod schemas 10 ตัว validate ผ่านกับ response จริงทุก endpoint
- Queue sort: score desc → created เก่าก่อน → ไม่มี scan ท้ายสุด, แสดง 5 แรก
- 409 conflict: refetch + banner, ไม่ retry อัตโนมัติ
- Chunk สูงสุด 304 kB (manualChunks แบบ function ตาม Rolldown/Vite 8)
- Detector: ไม่พบปัญหา; tests 24/24; lint 0 errors; build ผ่าน

## 5. ข้อจำกัดที่เหลือ (ไม่ปกปิด)

- Dark theme ตรวจแบบ code-level (tokens + topology เดียวกัน) ยังไม่ screenshot
  ครบทุกหน้า (browser อัตโนมัติใช้ profile จริงไม่ได้เพราะ Brave ล็อก)
- QA 200% zoom / 320×568 / keyboard walkthrough ทั้งแอปยังเป็นงาน manual
- `npm run lint` มี react-refresh warnings 6 จุด (context/hook exports — ไม่มีผล runtime)
- เพิ่ม `eslint-plugin-react` (dev-only) นอก list ใน brief เพราะ core rule ของ
  ESLint 9.39 ไม่นับ JSX usage; ไม่มีผลต่อ production bundle
