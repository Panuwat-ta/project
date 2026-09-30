## 2026-09-19 05:10 +07 - [Mobile Shared Mappers / full suite]

- Target: scam_image_mobile/test/ ทั้งชุด (เน้น shared_mappers_test ใหม่)
- Command: `flutter test` + `flutter analyze` (workdir: `scam_image_mobile/`)
- Result: FAIL (เฉพาะ 2 เคสเดิม scan_bloc — ของเดิมบน clean tree)
- Summary: Total: 240 | Passed: 238 | Failed: 2 | Skipped: 0 | Duration: ~10 วินาที

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **[shared_mappers_test 8 เคส (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: timeouts/connection → NetworkException, 401/403 + message → AuthException, detail key + String body honored, cancel → Network, resolveUploadUrl ผ่านทุกเคส (null/absolute/relative/backslash) และ throw ตอน baseUrl หาย
- **[232 เคสเดิมรวม risk/model/history]**:
  - พฤติกรรมที่ผ่าน: ผ่านครบ ยืนยันว่า delegate ไป mapper/resolver กลางไม่เปลี่ยน behavior (parseUrl เดิมกับ resolver ให้ผลเดียวกันทุกเคสใน model tests)
- **[flutter analyze]**:
  - พฤติกรรมที่ผ่าน: ไม่มี error ใหม่ในไฟล์ที่แตะ (ลบ unused imports 5 ไฟล์ที่ mapper กลางทำให้เกิน)

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- **[scan_bloc_test 2 เคส]**:
  - สาเหตุที่ไม่ผ่าน: ของเดิมบน clean tree (verify ไว้รอบก่อน) เกี่ยวกับ cancelScan/polling ไม่เกี่ยวกับงานนี้
