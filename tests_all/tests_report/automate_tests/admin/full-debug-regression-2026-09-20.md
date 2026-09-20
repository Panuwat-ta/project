# Admin Full Debug Regression — 2026-09-20

## Defects fixed
- Dashboard TDZ/self-reference: `const dash = dash?.dashboard` -> `data?.dashboard`
- เพิ่ม ESLint `no-use-before-define` เพื่อจับ regression กลุ่มเดียวกัน
- ReportDetail error state เคยถูก skeleton branch บัง -> ให้ error branch มาก่อน
- WebSocket hook callback cycle ถูกจัดเป็น function declarations ให้ผ่าน lint โดย behavior เดิม

## Verification
- `npm run lint`: **PASS, 0 errors**
- `npm run build`: **PASS**
- Vite build: **2482 modules transformed**

## Notes
การเปลี่ยนแปลง query/heatmap shared utilities จาก architecture loop ยังคงผ่าน lint/build หลัง fixes รอบนี้
