# Mobile Hardening → Production Deploy Master To-do List

วันที่เริ่ม: 2026-09-20
โปรเจกต์: `/home/panuwat/project/scam_image_mobile`
เป้าหมาย: ทำ Mobile ให้พร้อม Production Deploy แบบตรวจสอบย้อนกลับได้

## GitHub Issues cross-check — 2026-10-02

ณ cross-check ล่าสุด 2026-10-02 Issues #71–#76 และ #82 ปิดแล้ว; #77–#81 และ #83–#88 ยังเปิด. ข้อความสถานะเวลา 01:53 ด้านล่างเป็นประวัติเดิมก่อนปิด Issues #71–#76. #88 เป็น roadmap หลักและอ้างอิง hardening gates ในรายการด้านล่าง:

| Issue | Checklist section |
|---|---|
| [#71](https://github.com/Panuwat-ta/project/issues/71) | §1.1 History Detail overflow |
| [#72](https://github.com/Panuwat-ta/project/issues/72) | §1.2 Notifications test harness |
| [#73](https://github.com/Panuwat-ta/project/issues/73) | §2.1 Presentation branch tests |
| [#74](https://github.com/Panuwat-ta/project/issues/74) | §2.2 Router/BLoC/data/shared branch tests |
| [#75](https://github.com/Panuwat-ta/project/issues/75) | §2.3 NFR-09 branch coverage gate |
| [#76](https://github.com/Panuwat-ta/project/issues/76) | §3 Final product integrity, UX, localization audit |
| [#77](https://github.com/Panuwat-ta/project/issues/77) | §4 Accessibility and Android native QA |
| [#78](https://github.com/Panuwat-ta/project/issues/78) | §5 Security, session, input and privacy |
| [#79](https://github.com/Panuwat-ta/project/issues/79) | §6 Production API contract and staging E2E |
| [#80](https://github.com/Panuwat-ta/project/issues/80) | §8 Offline, retry and async recovery |
| [#81](https://github.com/Panuwat-ta/project/issues/81) | §9 Performance and stability soak |
| [#82](https://github.com/Panuwat-ta/project/issues/82) | §10 Auth UI, accessibility and localization |
| [#83](https://github.com/Panuwat-ta/project/issues/83) | §11 Production configuration and release artifact |
| [#84](https://github.com/Panuwat-ta/project/issues/84) | §14 CI/CD and quality gates |
| [#85](https://github.com/Panuwat-ta/project/issues/85) | §15 Store/distribution readiness |
| [#86](https://github.com/Panuwat-ta/project/issues/86) | §18 Backend/Model production coordination |
| [#87](https://github.com/Panuwat-ta/project/issues/87) | §16 Release Candidate QA |
| [#88](https://github.com/Panuwat-ta/project/issues/88) | Master roadmap; references #71–#87 |

ตัวเลข coverage ใน §0.4 เป็นผลย้อนหลัง ณ 20 กันยายน 2026 ไม่ใช่ผลปัจจุบัน. ผลล่าสุด 2026-10-02 หลังปิด Issue #76: full suite ผ่าน 522 tests; LCOV line 5,209/5,718 (91.10%) และ branch 1,286/1,549 (83.02%). รายงานล่าสุดคือ `tests_all/tests_report/automate_tests/mobile/issue-76-integrity-localization-2026-10-02.md`; residual branches ของ Issues #74/#75 อยู่ในรายงานเดิม `issue-74-75-2026-10-02.md`.

## สัญลักษณ์สถานะ

- `[x]` ทำเสร็จและมีผลตรวจยืนยันแล้ว
- `[ ]` ยังต้องทำ
- `[!]` มีข้อจำกัด / blocked / ต้องเปลี่ยน approach ก่อนทำต่อ
- `[H]` ต้องให้คนอนุมัติหรือยืนยันก่อนทำ

## Production Definition of Done

แอปจะถือว่า Production-ready เมื่อผ่านทั้งหมด:
- ไม่มี fabricated evidence / fake forensic UI
- ไม่มี critical/high security finding ที่เปิดอยู่
- `flutter analyze` ผ่าน 0 issues
- full `flutter test` ผ่านทั้งหมด
- branch coverage ตาม NFR-09 `>= 80%`
- debug/release build ผ่าน และ release signing ถูกต้อง
- Android runtime QA ผ่านบนอุปกรณ์จริง
- accessibility / text scale / rotation / adaptive layout ผ่านเกณฑ์
- backend/API contract, auth, scan, result, history, report ทำงาน end-to-end
- production env ไม่มี localhost/dev IP/debug secret
- release artifact ติดตั้ง/เปิดได้จริงจาก clean install
- privacy/permission/store metadata พร้อมสำหรับช่องทาง deploy
- มี rollback plan, monitoring และ post-deploy verification

## 0. สถานะที่ทำเสร็จแล้ว

### 0.1 Product integrity / AI-slop cleanup
- [x] ลบ fake/demo Heatmap fallback
- [x] ลบ forensic tags ที่สร้างจาก risk level โดยไม่มี backend evidence
- [x] ลบ faux slider ใน Result
- [x] Result แสดง Visual / Text / Source evidence จากข้อมูลจริง
- [x] ไม่มี evidence ให้แสดง unavailable state แทนการเดา
- [x] Home ลด pulse/decorative hero ที่ไม่สื่อสถานะ
- [x] History เปลี่ยนเป็น compact evidence rows
- [x] Settings ลด card stacking และ tinted icon boxes
- [x] Material 3 NavigationBar / NavigationRail เป็น navigation authority หลัก
- [x] non-auth raw hex นอก theme = 0
- [x] non-auth numeric radius นอก authority เหลือ 8

### 0.2 Security / Android integration
- [x] ปิด request/response header และ body logging ใน Dio logger
- [x] regression test ป้องกัน Authorization/access token หลุดใน log
- [x] runtime logcat ยืนยัน `AUTH_HEADER_LEAK_NOT_FOUND`
- [x] เปิด `android:enableOnBackInvokedCallback="true"`
- [x] full rebuild/install หลังแก้ AndroidManifest
- [x] ส่ง Android Back event จริงและไม่พบ Predictive Back warning

### 0.3 Native/adaptive QA ที่มี automated evidence แล้ว
- [x] viewport 360x800, 390x844, 412x915, 600x960, 840x1180
- [x] landscape 844x390
- [x] expanded landscape 1180x840
- [x] text scale 1.3 matrix
- [x] 390x844 ที่ text scale 1.5
- [x] reduced-motion tests
- [x] Semantics สำหรับ RiskBadge / RiskGauge / AnalysisStepTile
- [x] non-auth touch target `shrinkWrap` = 0

### 0.4 Coverage hardening ที่ทำแล้ว
- [x] baseline branch coverage จริง `784/1526 = 51.38%`
- [x] full branch suite ล่าสุด `834/1527 = 54.62%`
- [x] full line coverage ล่าสุด `2986/5638 = 52.96%`
- [x] SettingsLocalDataSource branch `20.00% -> 87.10%`
- [x] ScanRemoteDataSource branch `54.55% -> 100%`
- [x] HistoryRemoteDataSource branch `63.16% -> 100%`
- [x] SettingsRepositoryImpl branch `36.36% -> 100%`
- [x] ResultRepositoryImpl branch `70.00% -> 100%`
- [x] DioClient branch `61.90% -> 85.71%`
- [x] SettingsScreen branch ประมาณ `2/68 -> 39/68 = 57.35%`

## 1. P0 — ปิด defect ที่รู้แล้วก่อนเพิ่ม feature/test
### 1.1 History Detail overflow — แก้แล้ว 2026-10-02
- [x] แก้ `RenderFlex overflow` ที่เกิดจาก OCR summary row และป้าย evidence unavailable ใน `history_detail_screen.dart`
- [x] รองรับข้อความ/หลักฐานยาวโดยไม่ล้นแนวนอน
- [x] ตรวจที่ 320x800 (dark mode) และ 800x360 (landscape + dark mode)
- [x] ตรวจ assertion คะแนนที่แสดงซ้ำ; ใช้ `findsWidgets` สำหรับคะแนน 88%, 20% และ 10% ที่อาจพบหลายตำแหน่ง
- [x] รัน `history_detail_screen_test.dart` ผ่านทั้งหมด และ Flutter suite ผ่าน 425 tests
- [x] วัด coverage จาก LCOV: History Detail line 339/385 (88.05%), branch 34/53 (64.15%); coverage ทั้งชุด branch 978/1,547 (63.22%)
- รายงานผล: `tests_all/tests_report/automate_tests/mobile/history-detail-overflow-2026-10-02.md`

### 1.2 Notifications Screen testability
- [x] แทน harness เดิมที่เคย BLOCKED ด้วย `MockBloc` + controlled stream; ไม่ใช้ repository async หรือ `pumpAndSettle()` รอ HistoryBloc
- [x] cover HistoryEmpty / HistoryDataLoaded / HistoryError
- [x] cover completed / high-risk / failed notification และไม่แสดง processing scan
- [x] cover today / yesterday / earlier grouping
- [x] cover mark-as-read / dismiss / clear-all
- [x] cover navigation เมื่อมี scanId และยืนยันว่าไม่มีการ navigate เมื่อไม่มี scanId
- [x] ไม่ retry approach เดิม; เพิ่ม test file แยก `notifications_screen_test.dart`
- ผลทดสอบ: 8 widget tests ผ่านซ้ำ 5 รอบ; full suite 432/432 และ analyzer ผ่าน. รายงาน: `tests_all/tests_report/automate_tests/mobile/notifications-screen-harness-2026-10-02.md`

### 1.3 Known runtime/performance warnings
- [ ] วิเคราะห์ skipped frames ตอน cold start ว่าเป็น debug-only หรือมี main-thread work จริง
- [ ] profile startup ใน profile/release mode ก่อนถือว่า performance ผ่าน
- [ ] ตรวจ memory growth ระหว่าง History/Result/Heatmap navigation หลายรอบ
- [ ] ตรวจ image cache และ large image handling ไม่ทำให้ OOM

## 2. P1 — Branch Coverage NFR-09 >= 80%
### 2.1 Presentation screens ที่ยังมี missed branches สูง
- [x] `settings_screen.dart` branch 62/68 (91.18%); ครอบคลุม logout cancel/confirm, language/theme/cache, current-user restore loading/success/null/error, system theme และ profile/privacy/notifications navigation; ยังมี defensive/repository branches
- [ ] `image_crop_screen.dart` branch 38/55 (69.09%); ครอบคลุม crop success/cancel/error, เปลี่ยนภาพ, notification, zoom/reset, discard cancel/confirm; rotate utility มี test แยกแต่ widget/file IO, mounted/transforming และ image-load error ยังไม่ครอบคลุม; native UI ยังไม่ทดสอบบนอุปกรณ์จริง
- [x] `history_detail_screen.dart` branch 44/53 (83.02%); ครอบคลุม unavailable evidence, report/heatmap/share navigation และ delete cancel/confirm/success/failure; external share chooser ยังไม่ได้ทดสอบแบบ native
- [x] `notifications_screen.dart` หลังเปลี่ยน harness: branch 45/51 (88.24%); line 193/204 (94.61%)
- [ ] `analysis_loading_screen.dart` branch 48/53 (90.57%); ครอบคลุม retry/timeout, polling progress และ backend status ทุกขั้น, cancel/resume/background, ScanCompleted ไปผลตรวจ, notification, แก้รูปและไป History; ยังเหลือ fallback/error-image/reduced-motion branches
- [x] `report_scam_screen.dart` branch 57/69 (82.61%); ครอบคลุม required fields, custom category/platform validation และ trimmed submission, research consent, canonical category, network error/success และ scan selector error/retry
- [x] `home_screen.dart` branch 31/36 (86.11%); ครอบคลุม permission denied/retry/error, history empty/recent และ result/history navigation
- [x] `user_profile_screen.dart` branch 32/36 (88.89%); ครอบคลุม authenticated/restored/fallback identity, unsupported action และ delete failure; แก้ controller lifecycle
- [x] `privacy_consent_screen.dart` branch 18/24 (75.00%); ครอบคลุม consent confirm/cancel, export success/unavailable และ delete confirm/unavailable
- [ ] `history_screen.dart` branch 42/50 (84.00%); ครอบคลุม empty/error/retry, notification/result navigation, risk filter ทั้งผลตรงและไม่มีรายการ, search debounce/clear, visible count และ confirm delete cancel/success; gesture ปัดจริงกับ refresh callback ยังไม่เสถียรใน widget harness
- [x] `analysis_result_screen.dart` branch 52/55 (94.55%); ครอบคลุม pending/unavailable XAI, missing/score-only/partial visual evidence, ResultError, report/detail/share/heatmap/notification navigation, previous/home navigation และ delete cancel/success/failure; network image error กับ disposed-context branch ยังไม่ครอบคลุม
- [x] `heatmap_viewer_screen.dart` branch 21/23 (91.30%); ครอบคลุม unavailable/toggle/intensity/zoom/reset; native image error ยังไม่จำลองใน widget test

ผล LCOV ล่าสุดของ Issue #73: suite branch 1,244/1,548 (80.36%), line 5,007/5,679 (88.17%); full suite 496 tests ผ่าน, analyzer ผ่าน. Issue #73 ปิดแล้วหลังแนบรายการ residual branches และเหตุผลไว้ใน issue comment.

### 2.2 Core/logic coverage ที่ยังควรเก็บ
- [x] `app_router.dart` ทดสอบ onboarding/auth guards และ deep-link redirect ผ่าน `GoRouter` จริง; branch 15/30 โดย route builder บางหน้ากับ extra mapping ยังเป็น residual ตามรายงาน
- [x] `scan_bloc.dart` ทดสอบ timer polling, duplicate/stale poll, upload/status errors, cancellation, timeout และ race; branch 36/36
- [x] `history_bloc.dart` ทดสอบ pagination, repeated page, delete, refresh/search retention และ failure ระหว่างโหลดหน้าถัดไป; branch 47/47
- [x] `report_bloc.dart` ทดสอบ success และ network/auth/generic failure mapping; branch 19/19
- [x] `database_helper.dart` ทดสอบ migration v1–v5, partial upgrade, column rename, nulling ค่าเดิม และ schema ที่ถูก rename แล้ว; branch 20/24 โดยเหลือ plugin init/defensive catch ตามรายงาน
- [x] `risk_progress_bar.dart` ทดสอบช่วงสี Low/Medium/High และ label; branch 10/11 โดย Unknown case เป็น defensive branch ที่ score mapping ปัจจุบันเข้าไม่ถึง
- [x] `loading_overlay.dart` ทดสอบ fullscreen/contained, optional message และ light/dark spinner; branch 4/4

### 2.3 Coverage gate
- [x] รัน full `flutter test --coverage --branch-coverage --reporter=failures-only`
- [x] คำนวณ branch hit จาก LCOV `BRDA` จริง: 1,283/1,548 (82.88%)
- [x] ตรวจ LCOV มี critical source files และไม่มี custom exclusion เพื่อยก coverage; line coverage รายงานแยก ไม่ใช้แทน branch coverage
- [x] branch coverage รวมเกิน NFR-09 gate 80%; Issue #75 ปิดตาม acceptance
## 3. P1 — Final UX/UI และ AI-slop audit

สถานะ 2026-10-02 06:18 +07: Issue #76 CLOSED; source/widget audit และ independent review เสร็จแล้ว; confirmed findings แก้และ verify แล้ว ตาม `mobile-design-ux-audit-2026-10-02.md`. Native runtime/staging QA ยังติดตามใน Issues #77/#79.

### 3.1 Product integrity
- [x] ตรวจ source ของ Mobile ว่าไม่มี fake evidence ใน flow ที่ตรวจ; unavailable/empty แสดง state แทนการสร้างหลักฐาน
- [x] ตรวจข้อความ Low/Medium/High/Unknown และ score/grade ใช้ backend authority กับ RiskLevelHelper
- [x] ตรวจ semantics ของ score, วันที่วิเคราะห์, source detail และ Heatmap/source image labels; แก้ label ที่อ้างข้อมูลเกินจริง
- [x] ตรวจ Heatmap ไม่มี fallback จำลอง anomaly; preview แยก Heatmap, ภาพต้นฉบับ และไม่มีภาพตาม URL

### 3.2 Visual quality / AI-slop
- [x] ทำ Impeccable native source audit; ผลและเกณฑ์ตรวจอยู่ใน audit report
- [x] independent `agy` review สำเร็จเมื่อใช้ `--print-timeout 0s`; รัน 205.404684316 วินาที มี report และ finding disposition; timeout 3 ครั้งก่อนหน้าเป็นประวัติการรัน
- [x] เทียบ before/after กับ baseline audit 2026-09-20 โดยแยกผลเดิมกับ defect ที่ยืนยันเพิ่มในรอบนี้
- [x] ตรวจ Profile / Privacy / Notifications / Auth และ design-token consistency จาก source/checklist; ไม่พบ fabricated evidence เพิ่มใน scope ที่ตรวจ
- [x] ตรวจ theme-aware surfaces, semantic risk colors, responsive navigation, spacing/radius และ interactive affordance จาก source
- [x] ตรวจ TH/EN dictionary parity และ English copy; เพิ่ม tests สำหรับ Auth, Onboarding, Splash และ evidence labels
- [!] dark-mode/native visual QA ครบทุกหน้าจอยังต้องทดสอบบนอุปกรณ์ตาม §4; widget/source audit ไม่ทดแทน device certification

### 3.3 User flows
- [x] source/widget tests ครอบคลุม image pick/crop/optional name/submit และ scan progress/error recovery
- [x] Result/History tests ครอบคลุม preview state, Heatmap navigation, report payload, history actions และ notification actions
- [x] Report tab เลือก scan ก่อนเข้า form; tests ตรวจ scanId/image payload และ submit behavior
- [x] Settings theme/language/cache/privacy/profile/logout และ notification actions มี widget coverage
- [!] onboarding-to-auth และ end-to-end flows ยังไม่ได้ยืนยันกับ staging backend/installed app ในรอบนี้

ผล test suite รอบสุดท้ายและ coverage: `tests_all/tests_report/automate_tests/mobile/issue-76-integrity-localization-2026-10-02.md`.

## 4. P1 — Accessibility / Native behavior

### 4.1 TalkBack
- [H] ขออนุญาตก่อนเปิด TalkBack บน RMX3370
- [ ] ตรวจ focus order Home / History / Result / Heatmap / Report / Settings
- [ ] ปุ่ม/ไอคอนสำคัญต้องมี label ที่มีความหมาย
- [ ] Risk level + score ต้องอ่านเป็นข้อมูลเดียวกันอย่างเข้าใจได้
- [ ] toggle/checkbox ต้องประกาศ role และ state
- [ ] decorative icon/image ต้องไม่ถูกอ่านซ้ำโดยไม่จำเป็น
- [ ] error/loading/live status ต้องประกาศเหมาะสม

### 4.2 Text scale / motion / contrast
- [ ] ตรวจ text scale 1.0 / 1.3 / 1.5 ทุกหน้าหลัก
- [ ] ไม่มี clipping/overflow ที่ 1.3 และ critical action ยังเข้าถึงได้ที่ 1.5
- [ ] Reduced Motion ปิด animation ที่วน/ไม่จำเป็น
- [ ] ตรวจ contrast Light/Dark ของ text, risk, disabled, borders
- [ ] touch target สำคัญ >= 48dp

### 4.3 Rotation / tablet / multi-window
- [H] ขออนุญาตก่อนเปลี่ยน rotation setting บนเครื่องจริง
- [ ] portrait <-> landscape แล้ว form/state ไม่หาย
- [ ] keyboard + rotation ไม่ทำให้ layout overflow
- [ ] >=840dp ใช้ NavigationRail และ content width ถูกต้อง
- [ ] ตรวจ tablet/emulator density/system-insets จริง
- [ ] ตรวจ split-screen / resize ถ้า Android target รองรับ

## 5. P1 — Security hardening ก่อน Production

### 5.1 Secrets / logging / transport
- [x] Authorization header ไม่ถูก print ใน debug log แล้ว
- [ ] grep source/logs ว่าไม่มี access token / refresh token / password logging อื่น
- [ ] release build ต้องปิด verbose network logger โดย design
- [ ] production API ต้องใช้ HTTPS เท่านั้น
- [ ] ตรวจ cleartext traffic policy ของ Android manifest/network config
- [ ] ตรวจ certificate/TLS failure handling ไม่ bypass validation
- [ ] ตรวจ `.env`/build config ไม่มี secret ฝังใน repository หรือ APK โดยไม่จำเป็น
- [ ] ตรวจ API key ที่เป็น public client key แยกจาก server secret ให้ชัด

### 5.2 Authentication/session
- [ ] access token expiry / refresh success / refresh failure / concurrent 401 ผ่าน tests
- [ ] logout ล้าง local credential จริง
- [ ] refresh failure fail closed และกลับ login อย่างปลอดภัย
- [ ] session restoration ไม่เปิด protected screen เมื่อ token/storage ใช้ไม่ได้
- [ ] deep link protected routes ผ่าน auth guard
- [ ] ตรวจ secure storage บนอุปกรณ์จริงหลัง logout/reinstall ตาม requirement

### 5.3 Input/file security
- [ ] validate image type/size ก่อน upload ตาม backend contract
- [ ] corrupt/non-image file ให้ error ที่ recover ได้
- [ ] ไม่เชื่อ filename/MIME จาก client เพียงอย่างเดียว
- [ ] ตรวจ file URI/path handling ไม่เปิด arbitrary file access
- [ ] ตรวจ report form/user text validation ไม่เกิด injection ฝั่ง client/server
- [ ] dependency vulnerability audit สำหรับ Flutter/Android dependencies ก่อน release

## 6. P1 — Backend/API contract และ End-to-End

### 6.1 Production API compatibility
- [ ] ระบุ production API base URL ชัดเจน แยกจาก dev LAN URL
- [ ] production API version ตรงกับ Mobile contract
- [ ] `/auth/login`, `/auth/refresh`, `/auth/me` contract ผ่าน
- [ ] scan submit/status/result endpoints ผ่าน
- [ ] History list/search/delete contract ผ่าน
- [ ] Report submit contract ผ่าน
- [ ] Settings/privacy endpoints ที่มีจริงต้องตรงกับ UI
- [ ] endpoint ที่ backend ยังไม่มีต้อง disable/แสดง unsupported อย่างตรงไปตรงมา
- [ ] ตรวจ HTTP 400/401/403/404/409/422/429/500/503 mapping
- [ ] ตรวจ timeout/retry policy ไม่ยิงซ้ำ operation ที่ไม่ idempotent แบบอันตราย

### 6.2 End-to-End staging test
- [ ] ใช้ staging backend/model configuration ใกล้ production
- [ ] login ด้วย test account จริง
- [ ] upload image จริงอย่างน้อย Low / Medium / High หรือ fixtures ที่ backend รองรับ
- [ ] ตรวจ scan progress status ทุกช่วงที่ backendส่งได้
- [ ] Result values ตรง raw API response ที่สำคัญ
- [ ] Heatmap/image URLs เปิดได้จริง
- [ ] History หลัง scan แสดงข้อมูลเดียวกับ Result
- [ ] Report อ้าง scan canonical ID ถูกต้อง
- [ ] logout/login ใหม่แล้วยัง restore history ตาม server policy

## 7. P1 — Data integrity / Privacy / PDPA
### 7.1 Consent / user data
- [ ] consent processing/history/research ต้องสะท้อน behavior จริง
- [ ] consent default และ persisted value ผ่าน tests
- [ ] ถ้าปิด consent ที่จำเป็น ต้องบอกผลกระทบก่อนดำเนินการ
- [ ] Privacy screen ไม่มีปุ่มที่ทำเหมือนสำเร็จทั้งที่ backend ไม่รองรับ
- [ ] Account deletion flow มี confirmation และ error recovery
- [ ] Export data ระบุ unsupported จน backend มี endpoint จริง
- [ ] ระบุ retention policy ของ scan image/result/history ในเอกสารผู้ใช้
- [ ] ระบุว่า image/metadata ใดถูก upload และเก็บนานเท่าไร
- [ ] ตรวจ permission ที่ขอจาก Android ว่าจำเป็นทุก permission
- [ ] ไม่ขอ broad storage permission ถ้า Android picker/API ใหม่ทำได้

### 7.2 Local data
- [ ] SQLite/cache schema migration ผ่านจาก supported versions
- [ ] malformed cache ไม่ crash และ fallback ถูกต้อง
- [ ] clear cache ลบเฉพาะ cache ไม่ลบ history/account ผิด scope
- [ ] logout/account deletion เคลียร์ local data ตาม policy
- [ ] sensitive local data อยู่ใน secure storage เมื่อเหมาะสม

## 8. P1 — Reliability / Offline / Error recovery

- [ ] airplane/offline จริงบนเครื่องต้อง native QA (#77); automated network/cache recovery ผ่านแล้ว
- [x] network หายระหว่าง upload/scan polling recover ได้
- [x] scan timeout ไม่ auto-redirect ทำ context หาย
- [x] Retry ไม่สร้าง duplicate task โดยไม่ตั้งใจ
- [x] stale async response ไม่เขียนทับ scan ใหม่
- [x] concurrent polling ถูกจำกัดและไม่ leak timer
- [x] History remote fail -> cache fallback ตาม contract
- [x] authoritative server error ไม่ถูกแทนด้วย stale cache แบบทำให้เข้าใจผิด
- [x] malformed JSON/partial response ไม่ crash
- [x] empty/missing evidence มี explicit state
- [x] delete/report/account action failure ไม่แสดง success ก่อน server confirm
- [x] Flutter binding paused/resumed ระหว่าง scan ไม่เปลี่ยน task; physical recreation/soak อยู่ #81

หลักฐาน: [Async recovery](mobile-async-recovery-2026-10-02.md); full suite 684/684, branch 83.13%, focused Scan รวม lifecycle 20/20

## 9. P1 — Performance / Resource usage

### 9.1 Startup/rendering
- [ ] วัด startup ใน `--profile` หรือ release build ไม่ใช้ debug skipped-frame เป็น final metric
- [ ] ตรวจ frame jank Home / History scroll / Result / Heatmap
- [ ] ตรวจ animation ไม่ทำงานเมื่อ offscreen หรือ reduced-motion
- [ ] ลด rebuild ที่ไม่จำเป็นใน BLoC/widget tree ถ้าพบจาก profiler

### 9.2 Images/network/cache
- [ ] thumbnail ใช้ขนาดเหมาะสม ไม่ decode full-resolution โดยไม่จำเป็น
- [ ] large scan image ไม่ทำ memory spike/OOM
- [ ] CachedNetworkImage eviction/cache policy เหมาะสม
- [ ] Heatmap zoom/pan ไม่เกิด memory leak
- [ ] timeout/connectTimeout/receiveTimeout เหมาะกับ production network
- [ ] ตรวจ API request duplication จาก screen rebuild/navigation

### 9.3 Stability soak
- [ ] เปิด/ปิด History Detail/Result/Heatmap ซ้ำหลายรอบ
- [ ] scan หลายงานต่อเนื่องและตรวจ memory/timer/socket
- [ ] background/foreground app หลายรอบ
- [ ] ทดสอบ low-memory/process recreation เท่าที่ Android tooling รองรับ

## 10. P1 — Auth/UI scope ที่เคยถูก loop deny
- [x] ผู้ใช้อนุมัติทำ Issues ต่อทั้งหมด; ทำ Auth scope ตาม #82 แล้ว
- [x] ตรวจ Login/Register/Onboarding/Splash visual consistency กับ redesign
- [x] ตรวจ touch target/semantics ของ auth forms
- [x] reduced-motion สำหรับ Splash/Onboarding animation
- [x] localization auth copy ไทย/อังกฤษให้ครบ
- [x] validation email/password/display name ชัดเจนและสม่ำเสมอ
- [x] loading state ป้องกัน double submit
- [x] auth error ไม่เผย raw server/internal detail ที่ไม่ควรให้ผู้ใช้เห็น
- [x] legacy `main_shell.dart`/navigation code ที่ไม่ใช้แล้วต้องลบหรือยืนยันว่า dead code
- [x] ลด raw colors/radius ใน auth scope ให้ใช้ design authority เดียวกับแอป

หลักฐาน: [Auth hardening](mobile-auth-hardening-2026-10-02.md), full suite 670/670 และ branch 83.49%; native QA ยังคงอยู่ #77

## 11. P1 — Release configuration

### 11.1 Environment / build mode
- [ ] แยก dev / staging / production configuration อย่างชัดเจน
- [ ] Production `API_BASE_URL` เป็น HTTPS public endpoint ไม่ใช่ LAN IP
- [ ] ไม่มี `.env` development value ติด release artifact
- [ ] ตรวจ feature flags/debug flags ทุกตัวก่อน release
- [ ] ปิด debug banner/debug-only UI/loggers ใน release
- [ ] ตรวจ app display name / package name / applicationId สำหรับ production
- [ ] ตรวจ version `versionName` / `versionCode` ก่อนทุก release
- [ ] UI version ต้องอ่านจาก package metadata ไม่ hard-code

### 11.2 Android SDK/manifest
- [ ] ตรวจ compileSdk / targetSdk / minSdk ตาม policy ช่องทาง deploy ปัจจุบัน
- [ ] ตรวจ Android permissions ทีละรายการ
- [ ] ตรวจ exported activity/service/receiver/provider ทุกตัว
- [ ] Predictive Back flag ผ่านแล้วและต้องอยู่ใน production manifest
- [ ] ตรวจ cleartext/network security config
- [ ] ตรวจ backup/data extraction policy ตาม sensitivity ของข้อมูล
- [ ] ตรวจ icon / adaptive icon / splash / theme resources ครบ Light/Dark
- [ ] ตรวจ UCrop portrait lock แยกจาก MainActivity และไม่ลบโดยไม่ทดสอบ

## 12. P1 — Release signing / artifact integrity

- [H] เตรียม production keystore/upload key ผ่านช่องทางปลอดภัย
- [ ] ห้าม commit keystore/password/signing secret ลง Git
- [ ] ตั้ง release signing config จาก environment/secure secret source
- [ ] build `flutter build appbundle --release` ผ่าน
- [ ] build release APK ถ้าช่องทาง deploy ต้องใช้
- [ ] ตรวจ artifact ใช้ production applicationId/version
- [ ] ตรวจ APK/AAB signature และ certificate fingerprint
- [ ] เก็บ SHA-256 checksum ของ release artifact
- [ ] clean install release artifact บนอุปกรณ์จริง
- [ ] upgrade install จาก version ก่อนหน้าโดยข้อมูลที่ควรอยู่ยังอยู่
- [ ] uninstall/reinstall behavior ตรง data policy
- [ ] เปิด release build และทำ smoke test โดยไม่พึ่ง Flutter debugger

## 13. P1 — Production build optimization

- [ ] ตรวจ tree shaking/icon/font assets
- [ ] ตรวจ app bundle size และ largest assets/dependencies
- [ ] ลบ unused demo/test assets ออกจาก release bundle
- [ ] พิจารณา `--obfuscate --split-debug-info` ถ้า release policy ต้องการ
- [ ] ถ้าใช้ obfuscation ต้องเก็บ symbol/debug-info artifact อย่างปลอดภัย
- [ ] ทดสอบ crash stack trace mapping ก่อนเปิด production rollout
- [ ] ตรวจ ProGuard/R8/plugin compatibility ใน release build
- [ ] release build ต้องไม่มี debug network/body logging
## 14. P1 — CI/CD และ Quality Gates

- [ ] CI ใช้ Flutter/Dart version ที่ pin/บันทึกไว้ชัดเจน
- [ ] CI รัน `flutter pub get`
- [ ] CI รัน `dart format --output=none --set-exit-if-changed` เฉพาะ scope ที่กำหนด หรือ normalize legacy ก่อนบังคับทั้ง repo
- [ ] CI รัน `flutter analyze`
- [ ] CI รัน full `flutter test`
- [ ] CI รัน `flutter test --branch-coverage`
- [ ] CI fail ถ้า branch coverage ต่ำกว่า 80% เมื่อ NFR-09 พร้อมบังคับใช้
- [ ] CI build release/AAB จาก production config โดยไม่เผย secret
- [ ] dependency/security audit เป็น release gate
- [ ] เก็บ test/coverage/build artifacts ของแต่ละ release
- [ ] ห้าม auto-deploy production เมื่อ final gate fail
- [ ] production deploy ต้องมี human approval

## 15. P1 — Store/Distribution readiness

### 15.1 Product metadata
- [ ] ชื่อแอป คำอธิบาย short/full description พร้อม
- [ ] icon / feature graphic / screenshots อัปเดตตาม UI ล่าสุด
- [ ] screenshot ต้องไม่แสดงข้อมูลผู้ใช้จริง/token/test credential
- [ ] Privacy Policy URL ใช้งานได้จริง
- [ ] Terms/consent text ตรงกับ behavior จริงของแอป/Backend
- [ ] support/contact channel ระบุชัดเจน
- [ ] release notes/version notes พร้อม

### 15.2 Store compliance
- [ ] กรอก Data Safety / privacy disclosure ให้ตรงกับข้อมูลที่ app/backend เก็บจริง
- [ ] ตรวจ content rating / target audience / ads declaration ตามจริง
- [ ] ตรวจ permission declaration และเหตุผลการใช้ permission
- [ ] ตรวจ account deletion requirement ถ้าช่องทาง deploy กำหนด
- [ ] ตรวจ testing track/internal testing requirements ก่อน production
- [ ] ถ้าไม่ได้ deploy ผ่าน Play Store ให้กำหนด trusted distribution/signing/update policy แทน

## 16. P1 — Release Candidate QA

### 16.1 Clean-state QA
- [ ] ล้าง build/cache ที่เหมาะสมและ build RC ใหม่
- [ ] clean install RC บน RMX3370
- [ ] ทดสอบ first launch / onboarding / permission flow
- [ ] login/register/logout/session restore
- [ ] scan image จริง end-to-end
- [ ] retry offline/timeout flow
- [ ] Result / Heatmap / History / Report / Settings
- [ ] dark/light/system theme
- [ ] ไทย/English
- [ ] Android Back / predictive back
- [ ] background -> resume
- [ ] kill app -> reopen

### 16.2 Upgrade QA
- [ ] ติดตั้ง version ก่อนหน้าแล้วสร้าง local state/history/cache
- [ ] upgrade เป็น RC โดยไม่ uninstall
- [ ] SQLite migration ผ่าน
- [ ] auth/session behavior หลัง upgrade ถูกต้อง
- [ ] settings/theme/language/consent ไม่เสียหาย
- [ ] ไม่มี crash จาก stale cache/schema

## 17. P1 — Observability / Production Monitoring
- [ ] เลือก crash/error reporting ที่สอดคล้อง privacy policy ถ้าจะใช้
- [ ] ห้ามส่ง token/password/raw sensitive payload เข้า crash logs
- [ ] บันทึก app version/build number กับ error event
- [ ] monitor crash-free sessions / ANR / startup failures
- [ ] monitor API error rates ที่สัมพันธ์กับ Mobile version
- [ ] monitor scan timeout/failure rate
- [ ] monitor auth refresh failure ที่ไม่เผย credential
- [ ] กำหนด alert threshold สำหรับ critical regression
- [ ] มีช่องทางรับ user-reported bug พร้อม version/device info

## 18. P1 — Backend/Model production coordination

- [ ] ยืนยัน production model version ที่ Mobile จะใช้งานผ่าน backend
- [ ] model/backend health check ก่อน release
- [ ] API schema/version frozen สำหรับ Mobile release candidate
- [ ] database migrations production ผ่าน staging rehearsal
- [ ] upload/storage URLs และ permissions พร้อม production load
- [ ] server rate limit รองรับ Mobile retry behavior
- [ ] CORS ไม่เกี่ยวกับ native clientโดยตรง แต่ API auth/security policy ต้องถูกต้อง
- [ ] model timeout/error ต้อง map เป็น status ที่ Mobile handle ได้
- [ ] source/text/visual evidence fields ที่ optional ต้อง documented
- [ ] ห้ามเปลี่ยน risk semantic contract ระหว่าง rollout โดยไม่ version API
- [ ] เตรียม backend rollback ถ้า Mobile release พบ contract regression

## 19. Production Deployment Plan

### 19.1 Pre-deploy freeze
- [ ] freeze release candidate commit/tag หลัง final tests
- [ ] review diff ว่าไม่มี dev endpoint/secret/debug hack
- [ ] `git diff --check` ผ่าน
- [ ] `git diff --cached --check` ผ่าน
- [ ] `git status --short` ตรวจ scope ชัดเจน
- [ ] final report/test evidence ตรงกับ source state เดียวกับ release
- [ ] release version/tag/changelog พร้อม
- [H] ผู้รับผิดชอบ release อนุมัติ Production Deploy

### 19.2 Internal/Staging distribution
- [ ] upload AAB/APK ไป internal testing channel ก่อน production
- [ ] install artifact จาก distribution channel จริง ไม่ใช้เฉพาะ local build
- [ ] smoke test account/auth/scan/result/report บน artifact ที่แจกจริง
- [ ] ตรวจ app update path จาก internal version เดิม
- [ ] เก็บ tester feedback และปิด blocker ทั้งหมด
- [ ] RC ต้องไม่มี P0/P1 blocker ก่อน promote

### 19.3 Production rollout
- [ ] เริ่ม staged/canary rollout ถ้าช่องทาง deploy รองรับ
- [ ] หลีกเลี่ยง 100% rollout ทันทีถ้าเป็น release ใหญ่
- [ ] monitor crash/API/scan failure หลังปล่อยช่วงแรก
- [ ] ตรวจ install/update/login/scan จาก production artifact จริง
- [ ] เพิ่ม rollout ทีละระดับเมื่อ metrics ปกติ
- [ ] หยุด rollout ทันทีถ้า crash/auth/contract failure เกิน threshold
- [ ] บันทึก release time/version/artifact checksum/commit/tag

## 20. Rollback / Incident Plan

- [ ] กำหนด trigger ชัดเจนสำหรับ rollback
- [ ] มี previous stable Mobile artifact/version พร้อม
- [ ] backend API ยังรองรับ previous stable Mobile ระหว่าง rollout
- [ ] database migration ต้อง backward-compatible หรือมี recovery plan
- [ ] model/backend rollback ไม่ทำให้ Mobile schema แตก
- [ ] ถ้า store rollback binary ไม่ทัน ให้มี server-side mitigation/feature flag ตามที่ระบบรองรับ
- [ ] เตรียมข้อความ incident/status และผู้รับผิดชอบตัดสินใจ rollback
- [ ] หลัง rollback ต้อง verify auth/scan/result/history/report อีกครั้ง
- [ ] ทำ postmortem สำหรับ incident production ที่มี user impact

## 21. Post-deploy Verification

### ภายในชั่วโมงแรก
- [ ] production install/update สำเร็จ
- [ ] login/session restore สำเร็จ
- [ ] scan end-to-end สำเร็จ
- [ ] Result/Heatmap/History/Report ใช้งานได้
- [ ] ไม่มี spike ของ crash/ANR/auth failures
- [ ] ไม่มี token/sensitive data ใน production logs

### ภายใน 24 ชั่วโมง
- [ ] monitor crash-free rate / API errors / scan failures
- [ ] ตรวจ user feedback/review/support issue
- [ ] ตรวจ device/Android version ที่มี failure ผิดปกติ
- [ ] ตรวจ performance/startup regression
- [ ] ตัดสินใจเพิ่ม rollout / hold / rollback จากข้อมูลจริง

### หลัง release stable
- [ ] ปิด release checklist พร้อม evidence
- [ ] archive AAB/APK/checksum/symbols/test report/release notes
- [ ] อัปเดต known issues/backlog สำหรับ release ถัดไป
- [ ] ทบทวน NFR/monitoring threshold จาก production metrics

## 22. Final Automated Gates — ห้ามข้าม
- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter test --branch-coverage`
- [ ] branch coverage รวม `>= 80%`
- [ ] ตรวจ critical files ไม่ได้ผ่านเพราะ exclude/ignore แบบหลบ requirement
- [ ] `dart fix --dry-run` ไม่มี fix สำคัญค้าง
- [ ] `flutter build apk --debug` ผ่านสำหรับ debug verification
- [ ] `flutter build appbundle --release` ผ่านสำหรับ production candidate
- [ ] clean install release artifact บนอุปกรณ์จริง
- [ ] runtime log scan ไม่มี Flutter exception/FATAL/RenderFlex overflow ใน flows ที่ทดสอบ
- [ ] runtime log scan ไม่มี Authorization/access/refresh token
- [ ] Predictive Back warning ไม่กลับมา
- [ ] `git diff --check`
- [ ] `git diff --cached --check`
- [ ] final `git status --short` ตรวจ scope

## 23. Final Manual QA Matrix

| Area | Cases ที่ต้องผ่าน |
|---|---|
| Language | Thai / English |
| Theme | Light / Dark / System |
| Text scale | 1.0 / 1.3 / 1.5 |
| Phone widths | 360 / 390 / 412 |
| Medium | 600 |
| Expanded | >=840 / NavigationRail |
| Orientation | Portrait / Landscape |
| Network | Online / Offline / Timeout / Recovery |
| Auth | Fresh login / Restore / Refresh / Logout / Expired session |
| Scan | Pick / Crop / Optional name / Upload / Poll / Retry / Timeout |
| Result | Complete / Partial / Missing evidence / Unknown risk |
| History | Load / Search / Filter / Refresh / Delete / Offline cache |
| Heatmap | Available / Missing / Toggle / Opacity / Zoom / Back |
| Report | Selector / Form / Validation / Submit success/failure |
| Settings | Theme / Language / Cache / Privacy / Profile / Logout |
| Accessibility | TalkBack / focus order / labels / reduced motion |
| Lifecycle | Background / Resume / Process restart / Upgrade |

## 24. Documentation / Evidence ก่อนปิด Release

- [ ] อัปเดต `design/mobile/mobile-redesign-delivery-2026-09-20.md`
- [ ] อัปเดต `design/mobile/mobile-design-ux-audit-2026-09-20.md` ด้วย final post-audit
- [ ] อัปเดต automated report ใน `tests_all/tests_report/automate_tests/mobile/`
- [ ] บันทึก final test count / branch coverage / build commands / artifact
- [ ] บันทึก manual QA device/Android version/result
- [ ] บันทึก agy/Impeccable findings และ false positives ที่ตรวจ source แล้ว
- [ ] append `.agents/log.md` ตามผลจริง
- [ ] อัปเดต README/runbook สำหรับ production build ถ้ายังไม่มี
- [ ] อัปเดต API/environment deployment notes โดยไม่ใส่ secret
- [ ] บันทึก known limitations ที่ยอมรับใน release อย่างชัดเจน

## 25. Git / Release governance

- [ ] ไม่ reset/overwrite unrelated user changes
- [ ] stage เฉพาะไฟล์ที่เกี่ยวกับ release scope
- [ ] ตรวจ staged diff ก่อน commit
- [H] ห้าม commit/tag/push/deploy จนผู้ใช้หรือ release owner อนุมัติ
- [ ] หลัง commit ต้องผูก commit/tag กับ artifact/test report เดียวกัน
- [ ] release branch/main merge ต้องผ่าน repository guardrails

## 26. ลำดับการทำงานจากสถานะปัจจุบัน

1. แก้ History Detail RenderFlex overflow ที่ test ตรวจพบ
2. ทำ History Detail test suite ให้เขียวและวัด branch coverage
3. เพิ่ม presentation behavior coverage ตาม missed-branch impact
4. เปลี่ยน NotificationsScreen test harness ก่อน retry
5. รัน full branch coverage และวนจน NFR-09 >=80% หรือมี blocker ที่ต้องตัดสินใจ
6. ปิด auth-scope/deferred visual-accessibility work หลังได้รับ approval
7. Final Impeccable + agy + deterministic AI-slop/product-integrity audit
8. Manual Native QA: TalkBack / rotation / real-device critical flows
9. Security/dependency/env/API production audit
10. Profile/release performance + stability soak
11. Release config + signing + AAB release build
12. Staging/internal distribution และ clean/upgrade QA
13. Final automated/manual release gates
14. Human production approval
15. Staged production rollout + monitoring
16. Post-deploy verification + archive evidence

## 27. Current blockers / ยังห้ามประกาศ Production-ready

- [!] History Detail มี RenderFlex overflow ที่ regression test ใหม่ตรวจพบ
- [!] branch coverage ล่าสุด 54.62% ยังต่ำกว่า NFR-09 80%
- [!] NotificationsScreen widget harness ต้องเปลี่ยน approach หลังครบ 3 attempts
- [!] Manual TalkBack ยังไม่ได้ทดสอบบนเครื่องจริง
- [!] Manual rotation ยังไม่ได้ทดสอบบนเครื่องจริง
- [!] Auth visual/accessibility cleanup ยังติด loop deny scope เดิมจนกว่าจะอนุมัติ
- [!] Production environment/API endpoint ยังต้อง final verify
- [!] Production signing/AAB/internal distribution ยังไม่ทำ
- [!] Final release-mode performance/security QA ยังไม่ทำ
- [!] Production rollout/monitoring/rollback rehearsal ยังไม่ทำ

## 28. Production Sign-off Gate

ห้ามเปลี่ยนสถานะเอกสารเป็น `Production-ready` จนกว่าจะยืนยันครบว่า:

- [ ] ไม่มี P0/P1 blocker ที่ยังเปิดอยู่
- [ ] product evidence ทุกจุด trace กลับ backend/real analysis ได้
- [ ] AI-slop final audit ไม่มี deceptive/fabricated UI
- [ ] branch coverage >=80% ตาม NFR-09
- [ ] security/privacy release gates ผ่าน
- [ ] automated + manual QA ผ่านตาม matrix
- [ ] release AAB signed/build/install ผ่าน
- [ ] staging/internal rollout ผ่านจาก artifact เดียวกับ candidate
- [ ] production backend/model/API พร้อมและ contract frozen
- [ ] monitoring/rollback/incident procedure พร้อมใช้งาน
- [ ] final reports/logs/checksums/version/tag ตรงกับ source state เดียวกัน
- [ ] ผู้รับผิดชอบ release อนุมัติ deploy

เมื่อ checklist ด้านบนผ่านครบ จึงเปลี่ยนสถานะเอกสารเป็น `Production-ready` และดำเนินการ staged production deployment ได้

## กฎการทำงาน

- ทำตาม loop-engineering: one fix/run, verify ก่อนขยับ item
- ไม่ปิด/skip test เพื่อให้ gate ผ่าน
- item ที่ fail ครบ 3 attempts ต้อง mark BLOCKED และเปลี่ยน approach
- ไม่ fabricate test/audit/deploy result
- ไม่ commit, tag, push หรือ deploy โดยไม่มีคำสั่ง/approval
