## 2026-10-02 07:26 +07 - Mobile security/session/input regression suite

- Target: `scam_image_mobile/test/` ทุกไฟล์
- Command: `flutter test --coverage --branch-coverage --reporter failures-only`
- Result: PASS
- Summary: Total: 727 | Passed: 727 | Failed: 0 | Skipped: 0 | Duration: ไม่บันทึก elapsed ใน runner รอบนี้
- Coverage: line 5,462/6,010 (90.88%); branch 1,399/1,703 (82.15%) จาก LCOV

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **AppConfig**: reject missing/invalid URL, credentials/query/fragment, unknown environment, development release และ HTTP staging/production; normalize trailing slash ตาม assertions
- **Dio/AuthInterceptor**: loopback HTTP server ตรวจไม่ print credential, public auth ไม่ส่ง stale Bearer, concurrent401 แชร์ refresh, retry401 จบไม่วน, multipart clone ส่งซ้ำได้; refresh เก่าทั้ง success/failure ไม่เขียนทับหรือล้าง new login; stale retry ถูก cancel ก่อนส่งคำขอ
- **SecureStorage/Auth repository/BLoC/router**: credential mutation เรียงกับ logout, stale writes ถูกปฏิเสธ, expiry เก่าถูกลบ, onboarding retained; login เก่าไม่คืน authenticated หลัง logout; storage invalidation ทำให้ logout; protected deep links/session restore มี auth guard ตาม router tests
- **SQLite/cache/session isolation**: purge History+Result ใน transaction; invalidated cache writes/deletion/clear ไม่แก้ข้อมูล session ปัจจุบัน; stale repository response โยน AuthException; History/Result/Report late completions ไม่เปลี่ยน state หลัง session clear; Notifications reset ล้าง read/dismiss state
- **ScanImageValidator**: ภาพ JPEG/PNG จริงผ่านแม้ extension เปลี่ยน; empty/text/truncated/oversize/path URI/symlink/directory ถูกปฏิเสธ; sparse oversize file ไม่ต้อง decode เต็ม; repository validate ก่อน POST
- **TLS mapping**: badCertificate เป็น ServerException และไม่เป็น NetworkException จึงไม่เข้า offline fallback
- **Privacy และ presentation เดิม**: unsupported export/delete usage แสดง error, account deletion confirmation/error flow, local consent persistence ผ่าน; confirmation copy เตือนถูกต้องว่า local preference ไม่หยุด server processing
- **Regression ทั้งแอป**: Auth, Scan, Result, History, Report, Settings, Notifications, models/data sources/shared widgets และ adaptive/localization matrix ผ่านทั้งหมด

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed) ในรอบสุดท้าย.

รอบก่อนหน้า: 722 Passed/1 Failed เพราะ `Privacy processing consent requires confirmation before revoke` ยัง assert ข้อความเก่าว่าแอปจะหยุดวิเคราะห์ ซึ่ง implementation ไม่ได้บังคับ. ปรับ copy และ assertion ให้ตรง local-only behavior แล้วรันทั้ง suite ใหม่ได้ 727/727. Analyzer รอบก่อนพบ 3 curly-brace infos ใน guards ใหม่; เพิ่ม braces แล้ว analyzer สุดท้าย 0 issues.

ผลนี้เป็น automated unit/widget/loopback/SQLite tests ไม่ใช่ staging E2E, TalkBack, actual secure-storage inspection หรือ production acceptance.

## 2026-10-02 07:26 +07 - Quality gate tools

- Target: `scam_image_mobile/tool/tests/test_quality_gates.py`
- Command: `python3 -m unittest discover -s tool/tests -v`
- Result: PASS
- Summary: Total: 8 | Passed: 8 | Failed: 0 | Skipped: 0 | Duration: 0.194s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- LCOV นับ executed/unexecuted branches ถูก; malformed/missing data โยน ValueError; subprocess coverage gate exit nonzero เมื่อ branch50% หรือไม่มีBRDA และ exit0 เมื่อ line80%/branch100%
- Pub lockfile parser อ่าน hosted version และแยก SDK; reject unsupported/unresolved source
- Maven graph ใช้ resolved version/deduplicate และ reject FAILED/ไม่มี packages
- OSV query รักษา package identity รวม pagination และ reject malformed/incomplete/repeated page token

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed).

## 2026-10-02 - Live dependency advisory gate

- Target: resolved Pub/Maven dependency graph
- Command: `python3 tool/audit_dependencies.py --gradle-report /tmp/scamguard-android-dependencies-fixed.txt --output /tmp/scamguard-mobile-dependency-audit.json`
- Result: PASS
- Summary: ตรวจ 230 packages | Advisory findings: 0 | SDK exclusions ดู JSON | Duration: ไม่บันทึก

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

Gradle resolve ผ่าน; API ส่งครบตาม batch/pagination ที่ parser ตรวจ; advisory list ว่าง ทำให้ gate exit0. Public package names/versions เท่านั้นถูกส่ง; เก็บ snapshot ใน `design/mobile/evidence/security-2026-10-02/dependency-audit.json`.

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed) ในรอบนี้. รอบก่อน graph ไม่มี packages เพราะ signing guard จับ configuration name `releaseRuntimeClasspath` เป็น packaging task; แก้ให้ตรวจ task graph จริงแล้ว resolve/audit ผ่าน. ไม่อ้างว่าผลนี้รับรอง SDK/production security ทั้งระบบ.

## 2026-10-02 07:33 +07 - Account soft-delete disclosure regression

- Target: `test/features/screens/widget_screen_smoke_test.dart`
- Command: `flutter test test/features/screens/widget_screen_smoke_test.dart --reporter failures-only`
- Result: PASS
- Summary: Total: 12 | Passed: 12 | Failed: 0 | Skipped: 0 | Duration: ไม่บันทึก

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

Profile deletion confirmation แสดงว่าปิดบัญชีและไม่ได้ลบ server images/results/reports ทันทีตาม `server/app/services/user_service.py`; assert ข้อความ “ลบข้อมูลการใช้งานทั้งหมด” ไม่ปรากฏใน dialog นี้; password confirmation, cancel และ server failure recovery ผ่าน. Home/Crop/Notifications/Privacy tests ในไฟล์เดียวกันผ่านทั้งหมด.

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed).
