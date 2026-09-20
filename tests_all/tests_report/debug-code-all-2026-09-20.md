# ScamGuard Code Debug & Regression Report — 2026-09-20

## Executive summary
รอบนี้แก้ findings จาก code review เดิมทั้งหมด และไล่ debug ต่อจนเจอปัญหาเพิ่มเติมใน Admin, Server tests, Mobile analyzer และ runtime services จากนั้น rerun quality gates ที่เกี่ยวข้อง

### สถานะสุดท้ายที่ยืนยันแล้ว
| Area | Result |
|---|---|
| Admin ESLint | PASS — 0 errors |
| Admin production build | PASS |
| Mobile analyze | PASS — No issues found |
| Mobile tests | PASS — 240/240 |
| Server deterministic broad suite | PASS — 53 passed, 1 skipped |
| Server Python compile | PASS |
| Model evaluation core | PASS — 3/3 |
| Model ONNX contract | PASS — 3/3 |
| Git whitespace checks | PASS |
| Runtime health | PASS — DB ok, Redis ok |

## Main fixes
1. Admin Dashboard self-reference/TDZ crash และเพิ่ม ESLint guard
2. ReportDetail failure state ไม่ถูก skeleton บังอีกต่อไป
3. ONNX worker import ใช้ได้ทั้ง package context และ worker execution
4. ONNX runner รับมือ empty/malformed worker stdout โดยไม่ throw JSONDecodeError
5. inference/admin callers ตรวจ parsed payload ก่อน `.get()`
6. tiling parity tests เรียก worker wrappers จริง
7. scan orchestration tests ครอบคลุม cache hit/miss + heatmap/cache behavior
8. admin global search ใช้ canonical Scan fields แทน attributes ที่ไม่มีจริง
9. ซ่อม root tests ที่อ้าง DB API/function ที่ถูกลบไปแล้ว
10. เปลี่ยน DB script ที่ pytest มองไม่เห็นเป็น integration test จริง
11. Mobile analyzer issues 12 จุดถูกแก้จนเหลือ 0
12. Redis runtime ถูกกู้กลับจาก stopped state และ health endpoint กลับมา ok

## Remaining non-code risks
- Redis แจ้ง `vm.overcommit_memory = 0`; ควรตั้งเป็น 1 ที่ระดับ OS สำหรับ production reliability แต่ไม่ได้แก้ system sysctl ในงาน source-code รอบนี้
- live/GPU inference tests ไม่รวมใน deterministic broad suite เพื่อไม่ให้ผลปนกับ VRAM/model-runtime constraints
- third-party deprecation warnings: Surya/Pydantic class config และ Hugging Face `resume_download`

## Repository state
ไม่มี commit ใหม่ถูกสร้างในรอบนี้ งานยังอยู่ใน index/staging ตาม workflow ก่อนหน้า
