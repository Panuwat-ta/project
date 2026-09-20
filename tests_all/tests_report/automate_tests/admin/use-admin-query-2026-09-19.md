## 2026-09-19 05:10 +07 - [Admin useAdminQuery Migration / lint+build]

- Target: admin-portal/src (7 หน้า + hooks ใหม่)
- Command: `npm run lint` + `npm run build` (workdir: `admin-portal/`)
- Result: PASS (admin ไม่มี test suite — lint+build คือ gate ดีที่สุดที่มี)
- Summary: lint 0 errors 0 warnings | build สำเร็จ

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **[ESLint]**:
  - พฤติกรรมที่ผ่าน: 0 errors 0 warnings รวมไฟล์ใหม่ `use-admin-query.js` + `use-debounced-value.js` และ 7 หน้าที่ migrate (ระหว่างทางเจอ 3 errors: import ไม่ใช้, setDebouncedSearch ตกค้าง, effect deps — แก้ครบก่อนเขียว)
- **[Vite build]**:
  - พฤติกรรมที่ผ่าน: build สำเร็จทุก route (Dashboard chunk แยก) ยืนยันว่า 7 หน้า + hook ใหม่ compose กันได้จริง
- **Behavior preserved (ตรวจด้วย code review ไม่ใช่ test)**:
  - ModelsList/DatasetExport ตอน error คง stale data (resetOnError: false) เหมือนเดิม, ReportDetail quiet poll ไม่ทับโน้ตที่พิมพ์ (note sync เฉพาะ visible load + mutations), DatasetExport 3s poll ยังหยุดเองเมื่อไม่มี active job

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed; ไม่มี test suite ให้ fail — บันทึกเป็นข้อจำกัด)
