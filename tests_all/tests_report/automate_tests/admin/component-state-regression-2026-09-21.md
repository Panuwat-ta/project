# Admin Portal Component State Regression — 2026-09-21

- Target: `admin-portal/tests/component-state.test.mjs`
- Command: `cd admin-portal && npm test`
- Result: PASS
- Summary: Total: 4 | Passed: 4 | Failed: 0 | Skipped: 0 | Duration: 730.19 ms

## 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน

- **missing risk stays unknown while a real zero score stays low**
  - `RiskBadge(score=null)` render เป็น `ไม่ทราบ` และไม่ปรากฏคำว่า `ต่ำ`
  - `RiskBadge(score=0)` ยัง render เป็น `ต่ำ (0)` ยืนยันว่า missing data ไม่ถูกตีความเป็นความเสี่ยงต่ำ
- **operational unknown and degraded remain distinct from healthy**
  - `status=null` render เป็น `ไม่ทราบ` และไม่ปรากฏ `ปกติ`
  - `status="degraded"` render เป็น `มีข้อจำกัด`
- **missing Heatmap shows unavailable evidence without comparator controls**
  - เมื่อ `heatmapUrl=null` แสดง `ไม่มี Heatmap จากระบบ` และข้อความยืนยันว่าภาพที่เห็นเป็นภาพต้นฉบับเท่านั้น
  - ภาพต้นฉบับถูก render เพียง 1 ครั้ง และไม่มี `role="slider"` หรือข้อความที่ทำให้เข้าใจว่าเป็นผล Heatmap
- **available Heatmap renders model evidence and accessible comparator**
  - เมื่อมี `heatmapUrl` จริง จะ render URL ของ Heatmap, comparator `role="slider"` และ legend `ความน่าจะเป็นของความผิดปกติ`

## 2. ผ่านอย่างไร / ทำไมจึงผ่าน

ชุดทดสอบใช้ Node built-in `node:test` ร่วมกับ Vite SSR loader และ React `renderToStaticMarkup` ที่มีอยู่ใน dependency เดิมของโปรเจกต์ จึงโหลด JSX และ alias `@` จาก source จริงโดยไม่สร้าง mock behavior ใหม่หรือเพิ่ม test dependency ภายนอก

Assertion ตรวจทั้ง positive และ negative semantics โดยตรง เช่น Unknown ต้องไม่มีคำว่า Low และ Heatmap unavailable ต้องไม่มี comparator controls/ข้อความ model evidence จึงครอบคลุม regression ที่ audit เคยพบเรื่อง fabricated evidence และ missing-data semantics
## 3. รายการที่ไม่ผ่าน

ไม่มีข้อผิดพลาด (0 Failed) และไม่มี test ถูก skip/cancel/todo

## 4. ไม่ผ่านอย่างไร / สาเหตุ

ไม่มี failure จากการรันจริง จึงไม่มี Expected vs Actual ที่คลาดเคลื่อนหรือ stack trace ของ test failure

## Verification เพิ่มเติม

- `npm run lint`: PASS, 0 ESLint errors
- `npm run build`: PASS, Vite production build สำเร็จใน 412 ms
- `git diff --check`: PASS
- Independent `agy` review: `NO_CONFIRMED_P0_P2`

## หมายเหตุเรื่อง Loop

Attempt แรกทดลอง Vitest และผ่าน 3/3 แต่ rollback ทั้ง attempt เมื่อพบว่า `.agents/docs-safety.md` กำหนด dependency upgrade/addition เป็น human gate จากนั้น Attempt 2 ใช้ Node test runner + Vite/React ที่มีอยู่เดิมแทน จึงไม่เพิ่ม dependency ใหม่

## Re-run 07:58 +07 — เพิ่ม EvidenceState authority

- Command: `cd admin-portal && npm test`
- Result: PASS
- Summary: Total: 5 | Passed: 5 | Failed: 0 | Skipped: 0 | Duration: 736.70 ms
- เพิ่มเคส **evidence states keep unavailable, not checked, error, available, and unknown distinct**
  - `unavailable` → `ยังไม่พร้อมใช้งาน`
  - `not_checked` → `ยังไม่ได้ตรวจ`
  - `error` → `ตรวจไม่สำเร็จ`
  - `available` → `มีข้อมูล`
  - ค่า missing → `ไม่ทราบ`
- `ReportDetail` ใช้ `EvidenceState status="unavailable"` สำหรับ Source Verification ตาม implementation ปัจจุบันที่ Google Vision ยังไม่เชื่อมต่อและ admin response ยังไม่มี `source_status`
- Verification เพิ่มเติม: `npm run lint` PASS, `npm run build` PASS (373 ms), `git diff --check` PASS
- Independent `agy` scope แคบ: `NO_CONFIRMED_P0_P2` (รอบแรก timeout 3 นาทีจึงไม่นับเป็นผล review; รอบ retry สำเร็จ)

## Re-run 08:12 +07 — หลัง sync Design Authority / README

- Command: `cd admin-portal && npm test`
- Result: PASS
- Summary: Total: 5 | Passed: 5 | Failed: 0 | Skipped: 0 | Duration: 696.21 ms
- พฤติกรรม component state ทั้ง 5 เคสยังเหมือนเดิมหลังเอกสารประกาศ `EvidenceState` vocabulary และเพิ่ม `npm test` เป็น verification gate
- `npm run lint`: PASS
- `npm run build`: PASS (395 ms)
- `git diff --check`: PASS
- Independent `agy`: `NO_CONFIRMED_P0_P2`
- ไม่มี failure หรือ stack trace ใน rerun นี้

## Final acceptance re-run 08:16 +07

- Command: `cd admin-portal && npm test`
- Result: PASS
- Summary: Total: 5 | Passed: 5 | Failed: 0 | Skipped: 0 | Duration: 712.39 ms
- `npm run lint`: PASS
- `npm run build`: PASS (369 ms)
- `git diff --check`: PASS
- Fabricated fallback gate: CLEAN
- Semantic interaction gate: `transition-all=0`, clickable `<tr>=0`, clickable `<div>=0`, reduced-motion rule=1, Heatmap pointer handler=1, Heatmap slider semantics=1
- Impeccable mechanical detector: `[]`
- Independent `agy`: `NO_CONFIRMED_P0_P2`
- ไม่มี automated test failure ใน final acceptance re-run นี้

## Source Verification contract integration — 2026-09-21
- `ReportDetail` อ่าน `scan.source_status` จาก Backend แทน hardcode unavailable และไม่ infer จาก `source_score`
- EvidenceState แยก `unavailable`, `not_checked`, `checked_no_match`, `matches_found`, `error` ชัดเจน
- `npm test`: 5/5 PASS; `npm run lint`: PASS; `npm run build`: PASS (402 ms)
- Backend contract targeted 13/13 PASS และ broad server 54 passed / 1 skipped
- Mobile compatibility targeted 19/19 PASS
- Independent `agy`: `NO_CONFIRMED_P0_P2`
- ไม่มีการแก้ auth, `.env*`, migration หรือ DB data ในรอบนี้
