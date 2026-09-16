# PRODUCT.md — ScamGuard Admin Portal

> ที่มาของเอกสารนี้: Implementation Brief (ผู้ใช้, 2026-09-16) + backend source of truth
> (`server/app/api/v1/admin.py`, `server/app/schemas/admin.py`, `server/app/api/v1/ws.py`).
> ข้อสมมติถูกติดป้าย [ASSUMPTION] — นอกนั้นคือ contract ที่ตรวจจากโค้ดจริงแล้ว

## 1. ผลิตภัณฑ์คืออะไร

ScamGuard Admin Portal คือเครื่องมือภายในสำหรับทีมตรวจสอบรายงาน (moderators) และ
ผู้วิเคราะห์ความเสี่ยง (risk analysts) ใช้จัดลำดับ รับเคส และตัดสินรายงานภาพ
ต้องสงสัย (สแกมหลายรูปแบบ — ไม่ใช่แค่สลิปปลอม) ไม่ใช่แดชบอร์ดสถิติทั่วไป

## 2. ผู้ใช้และงานหลัก

- ผู้ดูแล (admin, role เดียว — backend ใช้ `require_super_admin` ทุก route):
  ตรวจคิว → รับเคส (review) → ตัดสิน (approve/reject) → บันทึกเหตุผล
- งานรอง: จัดการผู้ใช้ (ban/unban), deploy/dry-run โมเดล, สร้าง dataset export,
  อ่าน audit log, จัดการโปรไฟล์/sessions ของตัวเอง

## 3. Backend contracts (ตรวจจาก source แล้ว)

Base: `VITE_API_BASE_URL` (เดิม `/api/v1`) + prefix `/admin`.
Auth: `Authorization: Bearer <access-token>` ทุก request + `credentials: include`.
Access token อยู่ใน memory เท่านั้น. Refresh token อยู่ใน HttpOnly cookie
`admin_refresh_token` (path `/api/v1/admin/`, SameSite lax, rotation ทุกครั้งที่ refresh).

| Method & Path | Body / Query | หมายเหตุ |
|---|---|---|
| POST /admin/login | form-urlencoded `username`, `password` | 401 generic, 403 บัญชีถูกปิด; rate limit 5/min |
| POST /admin/refresh | cookie | single-flight; 401/403 → logout |
| POST /admin/logout | — | ต้อง auth; ล้าง token + query cache ฝั่ง client เสมอ |
| GET /admin/me | — | โปรไฟล์ |
| PATCH /admin/me | `full_name?`, `current_password?`, `new_password?` | เปลี่ยนรหัสต้องยืนยันรหัสเดิม; ใหม่ ≥ 8 ตัว (400 ถ้าผิด) |
| GET /admin/sessions | — | `is_current` บอก session ปัจจุบัน |
| POST /admin/sessions/:id/revoke | — | session ปัจจุบันใช้ logout แทน |
| GET /admin/dashboard | — | overview, risk_distribution, reports, category_breakdown, model, scan_trend |
| GET /admin/health | — | database, storage, models, queue, last_check |
| GET /admin/search?q= | — | items: {id, type, title, subtitle?, url} — validate internal path ก่อน navigate |
| GET /admin/reports | page≥1, limit 1–100 (default 20), status?, category?, search? | ตอบเพิ่ม `total_pages` (extra ที่อนุญาต) |
| GET /admin/reports/:id | — | scan เป็น object เต็ม (defensive render) |
| POST /admin/reports/:id/review | `{version}` (400 ถ้าขาด) | "รับเคส" — เปิด detail เฉย ๆ ห้ามเรียก |
| PATCH /admin/reports/:id | `{status, version, admin_note?}` | 409 = optimistic-lock conflict → refetch, ห้าม retry อัตโนมัติ |
| GET /admin/users | page, limit, search? | ไม่มี status filter ฝั่ง server — filter สถานะทำ client-side [ASSUMPTION] |
| GET /admin/users/:id | — | recent_scans/recent_reports เป็น dicts — render แบบ defensive |
| PATCH /admin/users/:id | `{is_active, reason}` (reason บังคับ) | confirm dialog ทุกครั้ง |
| GET /admin/models | — | metrics เป็น Optional — null แสดง em dash + label "ไม่มีข้อมูล" |
| POST /admin/models/:id/deploy | `{reason}` | confirm + reason; broadcast refresh_dashboard |
| POST /admin/models/:id/dry-run | — (ไม่มี body) | ตอบ {success, message, details?} |
| POST /admin/dataset/export-jobs | categories?, from_date?, to_date?, include_metadata=true, format=zip | — |
| GET /admin/dataset/export-jobs | page, limit | เรียง created_at desc |
| GET /admin/dataset/export-jobs/:id | — | poll ทุก 2s เฉพาะ job ที่ active + tab visible |
| POST /admin/dataset/export-jobs/:id/cancel | — | cancel ได้เฉพาะ queued/running; server ตอบ status `canceled` (สะกดด้วย L ตัวเดียว) |
| GET /admin/dataset/export-jobs/:id/download | — | FileResponse + filename; อ่านชื่อจาก Content-Disposition ถ้ามี |
| GET /admin/audit-logs | page, limit (default 50), search?, action?, entity_type? | read-only; filter state ใน URL |
| WS /api/v1/ws/admin/dashboard?token= | event `{"type":"refresh_dashboard"}` | invalidate dashboard/health/queue/counts; reconnect 1/2/4/8s สูงสุด 30s |

Risk scoring: 3 ระดับ low 0–39 / medium 40–69 / high 70–100 (ไม่มีระดับ Safe แล้ว).
`risk_distribution` keys มาจาก backend — normalize case-insensitive ฝั่ง client.

## 4. งานที่ห้ามทำ

ห้ามแก้ backend/schemas/DB, ห้ามเปลี่ยน route URLs และชื่อ env vars,
ห้าม mock fallback ใน production, ห้าม TypeScript/Recharts/component framework,
ห้าม emoji/Unicode glyph เป็น icon (Lucide เท่านั้น),
ห้ามคำนวณ metric ที่ backend ไม่ได้ให้ (เช่น % เปรียบเทียบช่วงก่อนหน้า),
ห้าม optimistic update กับการตัดสินรายงานและ deploy โมเดล.

## 5. ภาษาและโทน

UI ภาษาไทยเป็นหลัก. อัตลักษณ์ ScamGuard: แม่นยำ สุขุม งานตรวจสอบหลักฐาน —
แยกสถานะความเสี่ยงชัดเจน (emerald/amber/rose + label + icon; cyan สงวนให้ action/focus).
Light theme เป็นค่าเริ่มต้น + dark theme เต็มรูปแบบ (`localStorage["scamguard-admin-theme"]`).

## 6. เกณฑ์สำเร็จ

Routes เดิมครบ, auth/refresh/logout เชื่อม backend จริง, dashboard เป็น
Queue-forward ตาม comp ที่ผู้ใช้เลือก, desktop table + mobile cards,
lint/tests/build ผ่าน, Impeccable detector + finish reviewer ผ่าน.
