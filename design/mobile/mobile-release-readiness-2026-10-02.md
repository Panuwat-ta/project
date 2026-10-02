# Mobile release readiness — 2026-10-02

สถานะ: เตรียมงานที่ทำได้จาก source แล้ว; ยังไม่อนุมัติ production/Release Candidate. เอกสารนี้เป็น checklist และ metadata draft ไม่ใช่ผลทดสอบหรือข้อมูลเผยแพร่จริง.

## Issue ที่เหลือและ dependency

| Issue | สิ่งที่เตรียมได้แล้ว | สิ่งที่ยังขาด |
|---|---|---|
| #77 Native accessibility | widget/semantics/adaptive tests และ manual cases เดิม | RMX3370ปลดล็อกแล้ว; Login/keyboard scroll/Back baselineตรวจแล้ว; TalkBack/rotation/font settings และทุกหน้าที่เหลือยังต้องตรวจ |
| #79 Production/staging | endpoint constants, response/error/retry tests, explicit URL config; RMX3370 เรียก dev `/health` ได้ HTTP 200 โดยไม่มี ADB reverse | HTTPS staging URL/version, test account/fixtures; authenticated E2E เทียบ raw API กับ Result/History/Report |
| #81 Performance/soak | correct-source profileAPKติดตั้งแล้ว; Android cold launch5รอบ515–576ms; polling/dispose guardsมีtests | actual unlocked device/profile frames, cold/warm timing, memory/soak/process recreation; gfxinfo0framesเดิมใช้อ้าง performance ไม่ได้ |
| #83 Signed production | config/environment signing guard; unsigned compile gate | production applicationId/version, secure key source, signed AAB/APK/fingerprint, actual clean/upgrade install |
| #84 CI — CLOSED | GitHub run36963858748 completed/success หลัง pin Node24; follow-up run36969781386 ใน PR #90 ผ่านเช่นกัน: 749/749, branch82.35%, audit230 packages/0 advisories และ APK ไม่มี `.env` | signedproduction/native/stagingอยู่gatesอื่น |
| #85 Distribution | metadata draft และ disclosure inventory ด้านล่าง | ช่องทางจำหน่าย, Privacy Policy/Terms/support URLs ที่ใช้ได้, approved policy, screenshotsของ signed/staging build |
| #86 Operations | rehearsal/rollback evidence checklist ด้านล่าง | endpoint/model/migration freeze, owner/monitoring thresholds, previous stable artifact และ rehearsal จริง |
| #87 RC QA | evidence checklist และ manual88casesเดิม | signed same-commit RC, native/staging/install/soak/CI evidence ครบ, owner sign-off |
| #88 Roadmap | checkbox sync ตาม GitHub actual states | ทุก gateปิดจริงก่อน production approval |

## #79 Contract rehearsal

อ้าง `scam_image_mobile/lib/core/network/api_endpoints.dart`, `server/app/api/v1/`, `wiki/architecture/backend-api.md` และ `tests_all/manual_tests/test_cases_mobile.md`.

1. ใช้ staging ที่ผู้ใช้ยืนยัน มี HTTPS และ API prefix `/api/v1`; ไม่ใช้ `example.invalid`/dev LAN เป็นหลักฐาน staging
2. ใช้ test account ผ่านช่องทางปลอดภัย; ห้ามบันทึก password/token/raw personal data ใน screenshot/log/report
3. ตรวจ register/login/refresh/me/logout, scan POST/status/result, History list/search/delete, Report submit/categories, DELETE users/me; บันทึก HTTP status + field/type ที่จำเป็นโดย redactข้อมูล
4. แยก task ID/canonical scan ID ตาม raw response; retry known task เป็น GET status ไม่ POST scan ใหม่; POST report/scan ไม่ auto-retry
5. ใช้ภาพจริงที่อ้างใน manual cases; บันทึก score/risk/evidence ตาม backend response ไม่สร้าง Low/Medium/High fixture result ขึ้นเอง
6. เปิด original/heatmap URL จริง, เทียบ ResultกับHistory; logout/login restoreข้อมูลตามserver; delete/account error ไม่ successก่อนserverยืนยัน
7. Privacy preferences เป็น local-only; export/delete-all usage ยังไม่รองรับ; account deleteเป็นsoft-delete ไม่เทียบเท่าลบserverข้อมูลทั้งหมด

## #85 Metadata draft รอเจ้าของผลิตภัณฑ์ตรวจ

- ชื่อ: **ScamGuard** (ตรง Android label ปัจจุบัน)
- คำอธิบายสั้นฉบับร่าง: **วิเคราะห์ความเสี่ยงของภาพต้องสงสัย พร้อมหลักฐานที่ระบบตรวจพบ**
- คำอธิบายฉบับร่าง: **ScamGuard ส่งภาพที่คุณเลือกไปวิเคราะห์บนเซิร์ฟเวอร์และแสดงระดับความเสี่ยง Low, Medium หรือ High พร้อมรายละเอียดและ heatmap เมื่อมีข้อมูล รองรับภาพที่อาจเกี่ยวข้องกับ romance scam ภาพตัดต่อ เอกสารปลอม ภาพสังเคราะห์ และสกรีนช็อตหรือสลิปปลอม คุณสามารถดูประวัติและส่งรายงานภาพต้องสงสัย ผลวิเคราะห์ใช้ประกอบการพิจารณาและไม่ได้ยืนยันว่าภาพเป็นการหลอกลวงทุกกรณี**
- ไอคอน: `scam_image_mobile/assets/icons/scamguard_app_icon.png`; launcher resourcesมีแล้ว; ยังต้องตรวจ adaptive/store rendition ตามช่องทางที่เลือก
- Release notes ฉบับร่าง: ปรับ layout/TH-EN/error recovery; ป้องกัน submit/pollingซ้ำ; แยก session/cache; ตรวจไฟล์ก่อนupload; disclosure privacyตามimplementation
- ยังไม่มี confirmed Privacy Policy URL, Terms URL, support/contact หรือ distribution channel; ไม่ใส่ URL/ชื่อผู้รับผิดชอบที่แต่งขึ้น
- Screenshots ต้องมาจาก actual approved build; ใช้ข้อมูลทดสอบจริงที่ไม่มีข้อมูลส่วนบุคคล/token; ไม่ใช้ภาพ widget matrix แทน screenshotบนเครื่องโดยไม่ระบุที่มา

### Disclosure inventory ที่ต้องยืนยันก่อนเผยแพร่

| ข้อมูล/การทำงาน | Code evidence | ข้อที่ต้องยืนยัน |
|---|---|---|
| Email/password/profile/auth | Auth remote/local; tokenอยู่SecureStorage | controller/contact/security handlingจริง, server retention |
| ภาพและผลวิเคราะห์/History | Scan upload, Result/History cache; backend scans/files | retention/deployed purge schedule, backup/CDN/research sharing |
| Report text/reference scan | Report repository + server report API | การใช้งาน/retention/ผู้เข้าถึง |
| Consent | registerส่งsystem/research; Settings localpreferences | server update/revocation และผลต่อprocessing/research |
| Delete account | user_serviceปิดis_activeและanonymizeconsent metadata | scan/reportยังคงอยู่; approveddeletionpolicyและช่องทางติดตาม |
| Local data | SQLite/cache/temp + securestorage | device lifecycle/backup/cleanup tests |

Backend มี `server/scripts/purge_old_scans.py` default90วัน และ `archive_old_logs.py` default365วัน. การมี script ไม่ยืนยัน cron/deployment หรือการลบ archivedข้อมูล; ต้องตรวจ deployment จริงก่อนสัญญา retention ระยะดังกล่าวกับผู้ใช้. Wiki mobile เก่าระบุไม่เก็บภาพบนอุปกรณ์ แต่ code มี image/cache/temp behavior จึงยึด code และยังต้องปรับ approvedpolicyให้ตรง.

Store/Data Safety/content rating/target audience/ads/testing-track requirements ยังไม่กรอกหรือส่งจริง; ตรวจตามช่องทางและข้อกำหนดปัจจุบันเมื่อเลือก distribution แล้ว.

## #86 Rehearsal และ rollback checklist

- Freeze Mobile commit, backend/API schema/version, active model version, migration head, storage URL และ compatibility ที่ใช้จริง; เก็บ identifiersโดยไม่เก็บsecrets
- `/health` ของ codeปัจจุบันมี status/version/database/redis; ไม่พิสูจน์ model inferenceเพียงendpointนี้ ต้อง scan fixtureและเปิดimage/heatmapด้วย
- Owner ของ release, incident, backend/model และ alerts: **ยังไม่มีการยืนยัน**; ห้ามเรียก owner-specific action ว่าพร้อมก่อนมีผู้รับผิดชอบ
- เก็บ metrics crash/auth failure/scan failure/timeout/API error/latency แบบไม่มีpayloads/token; thresholdและobservation windowต้องตกลงจากbaseline/rehearsalจริง ไม่แต่งตัวเลข
- Previous stable signed artifact + certificate/hash/versionCode: **ยังไม่ได้รับ**; ต้องตรวจ compatibilityกับbackend และวิธีrestoreก่อนrollout
- Canary/rollback rehearsal: คนอนุมัติเริ่มจากstaging/internaldistribution; หยุดและสอบสวนเมื่อgate/security/contract critical failure; rolloutpercentage/triggerตัวเลขรอยืนยัน
- Android installupgradeต้องversionCodeเพิ่ม; การ downgradeกลับbinaryเก่าอาจต้องuninstallและทำให้localdataหาย จึงไม่ถือว่าเก็บAPKเก่าไว้เท่ากับrollbackผ่าน ต้องทดสอบแผนด้วยsignedkeyเดียวกัน
- ไม่รันmigration/productiondeploy/modelswitch/purgeหรือaccountdeleteproductionจากเอกสารนี้

### Evidence ที่ต้องเก็บหลัง deploy (ยังไม่ได้ execute)

| ช่วงเวลา | Evidence | ผู้รับผิดชอบ |
|---|---|---|
| ชั่วโมงแรก | deployed hash/version/config, health DB/Redis, login/scan/result/history/report smoke, sanitized crash/API/scan/auth metrics และ decision log | รอยืนยัน |
| 24ชั่วโมง | error/latency/scan success/crash trends, storage URLs, alertdelivery, support incidents และ rollback decision | รอยืนยัน |
| หลังstable | finalsignoff, artifact/symbol/retention records, compatibilityและpreviousstablehandover | รอยืนยัน |

## #87 RC evidence bundle

RC ต้องเป็น signed artifact จาก commitเดียวที่มี test/CI evidence. เก็บ commit/tag, APP_ENV/HTTPSpublicURLโดยไม่มีsecrets, applicationId/versionCode/versionName, SDK/mergedmanifest, SHA-256/certfingerprint, buildlog/symbolsตามpolicy, nativeclean/upgradeผลจริง, TH/EN/light/dark/textscale/rotation/keyboard/TalkBack, realstagingflows, offline/resume/processkill/soak, residualdefectseverity/ownerdecision.

Manual87casesใน `tests_all/manual_tests/test_cases_mobile.md` ยังเป็น To Do จนมี actual execution; ห้าม bulkเปลี่ยนเป็นPassจากwidget/unit tests. Humanproductionapprovalและdeployเป็นขั้นแยกหลังbundleครบ.
