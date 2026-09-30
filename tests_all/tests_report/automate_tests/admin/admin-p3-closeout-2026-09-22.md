# Automated Test Report — Admin P3 Close-out

วันที่ทดสอบ: 2026-09-22
Branch baseline: `b9b30c88`

## 1. RED — User Detail recent scan status
คำสั่ง: `node --test --test-concurrency=1 tests/admin-workflow-regressions.test.mjs`

ผล: **8 passed / 1 failed**

Failure: test `user detail renders recent scan execution status` ไม่พบ `<TableHead>สถานะ</TableHead>` ใน `UserDetail.jsx`

## 2. RED — Scan status localization
คำสั่ง: `node --test --test-concurrency=1 tests/component-state.test.mjs`

ผล: **6 passed / 1 failed**

Failure: `StatusBadge` render `processing_visual` เป็น raw string แทนข้อความ `กำลังวิเคราะห์ภาพ`

## 3. GREEN — Targeted frontend regression
คำสั่ง: `node --test --test-concurrency=1 tests/admin-workflow-regressions.test.mjs tests/component-state.test.mjs`

ผล: **16/16 PASS**
## 4. Full Admin Gate
คำสั่ง: `npm test && npm run lint && npm run build`

ผล:
- Node tests: **39/39 PASS**
- ESLint: **PASS**
- Vite production build: **PASS**
- Modules transformed: **2,485**
- Build time: **446 ms**

## 5. WebMCP Runtime Matrix
Target: `tests/runtime/admin-all-pages-webmcp-matrix.mjs`

Matrix = 10 routes × 2 viewport × 2 themes = **40 cases**

Attempt 1: 0/40 ตาม aggregate gate เพราะ Chrome instance ไม่มี `document.modelContext`; path/heading/layout ของ product โหลดได้และ User Detail เห็น status แต่ WebMCP prerequisite ไม่พร้อม จึงจัดเป็น harness setup failure

Attempt 2: เปิด Chrome ด้วย `--enable-webmcp-testing --enable-features=WebMCPTesting`

ผล: **40/40 PASS**

User Detail `/admin/users/1`:
- mobile dark/light: PASS, `scanStatusVisible=true`, overflow=false, consoleErrors=0
- desktop dark/light: PASS, `scanStatusVisible=true`, overflow=false, consoleErrors=0
