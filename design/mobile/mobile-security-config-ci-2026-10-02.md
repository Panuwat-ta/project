# Mobile security, configuration และ CI — 2026-10-02

## ขอบเขตและสถานะ

งาน #78: แก้ security/session/input/privacy ฝั่ง Mobile พร้อม regression tests และบันทึกข้อจำกัด backend/product ด้านล่าง งานนี้ไม่ใช่การรับรอง production readiness.
งาน #83: เตรียม config/signing แบบ fail closed แต่ยังไม่มี production identity/key/endpoint และ signed RC.
งาน #84: GitHub clean-checkout run 36963858748 หลัง pin action Node 24 ผ่านทุก gate; follow-up PR #90 รัน CI ซ้ำบน source ที่เพิ่ม development API runner แล้ว (run 36969781386) และผ่านทุก gate ทั้งคู่เป็น quality/compile evidence ไม่ใช่ signed RC หรือ production sign-off.

## สิ่งที่แก้และหลักฐาน

- ยกเลิก Dio network logger ทุก build; ค้น `print`, `debugPrint`, `LogInterceptor`, `badCertificateCallback` ใน `lib/` ไม่พบการใช้งาน
- `AppConfig` ไม่มี URL fallback; release ห้าม development, staging/production บังคับ HTTPS; URL ห้าม userinfo/query/fragment; URL เป็น public config ห้ามใส่ secrets
- ไม่ load/bundle `.env`; ถอน `flutter_dotenv`; models รับ base URL จาก Dio ที่กำหนดจริง
- Main manifest ปิด cleartext และ backup; debug/profile อนุญาต HTTP development; ไม่มี TLS bypass; badCertificate เป็น authoritative error ไม่เปิด offline cache
- Refresh แชร์คำขอเฉพาะ session เดียว, retry ได้ครั้งเดียว, เก่าไม่ restore/ล้าง credentials ของ session ใหม่; batch secure-storage writes เรียงกับ logout
- SecureStorage แจ้ง session invalidation ให้ AuthBloc/router; protected routes fail closed; clear account cache ใน login/register/logout; responses/cache writes/deletions ของ session เก่าถูกตัดทิ้ง
- History/Result/Report/Notifications state ถูก reset เมื่อ session สิ้นสุด; completions เก่าไม่เปลี่ยน state ใหม่
- ตรวจ absolute regular file, ไม่รับ URI/symlink/directory, limit 20 MB และ 100 MP ตาม backend defaults; decode JPEG/PNG/WebP จาก content ใน isolate ไม่เชื่อ extension; corrupt/non-image/error recover ได้
- Report validation ยังคง form tests เดิม; ไม่อ้างว่าฝั่ง client ป้องกัน server injection ได้เอง
- Account deletion ใช้ข้อความเฉพาะ soft-delete ตาม user_service: ปิดบัญชี ไม่อ้างว่าลบ server image/result/report ทันที; focused widget tests12/12
- Privacy แจ้งว่า preferences อยู่บนอุปกรณ์และไม่เปลี่ยน server consent; ลบคำรับรอง PDPA/security/third-party sharing ที่ไม่มีหลักฐาน; unsupported export/delete usage ไม่แสดง success
- OSV query ของ resolved Pub/Maven 230 packages: 0 advisories ณเวลาที่บันทึกใน JSON; SDK packages แยก excluded ไม่อ้างว่าปลอดภัยทุก dependency/SDK หรือ future advisories

หลักฐาน automated: `tests_all/tests_report/automate_tests/mobile/issue-78-security-2026-10-02.md` และ `evidence/security-2026-10-02/`.

## Signing และ compile artifact

Gradle อ่าน identity/key จาก environment; release packaging ไม่มี identity/key ต้องหยุด ไม่ fallback debug key. ตรวจ task graph เพื่อครอบคลุม aggregate build. `SCAMGUARD_ALLOW_UNSIGNED_QUALITY_BUILD=true` เป็น compile-only override และ signingConfig=null แม้มี key environment.

รอบ compile ก่อนแก้ race เพิ่มเติม: `flutter build apk --release` ใช้ staging HTTPS `https://example.invalid/api/v1` ที่เป็น test fixture ไม่ใช่ staging server, explicit unsigned override; build ผ่าน 68.0s, 64,457,035 bytes, SHA-256 `d167c77bbe4f7ceb2c00f56057809cf222f65518da7ea0c065304dad98ea3b5e`.

ตรวจ APK: ไม่มี `.env`; allowBackup=false, usesCleartextTraffic=false, ไม่มี debuggable=true; minSdk24/targetSdk36/compileSdk36; label ScamGuard, identity `com.example.scam_image_mobile`, version1.0.0+1. apksigner verify fail `Missing META-INF/MANIFEST.MF` ตรงกับ unsigned artifact. Artifact นี้ห้ามแจกจ่ายและไม่ใช่ final source/RC. ต้อง build final snapshot ใหม่.

ตรวจ negative build หลังปรับ task-graph guard: ไม่มี production applicationId → exit1 `Release requires a confirmed SCAMGUARD_APPLICATION_ID`; เป็น expected rejection.

## CI ที่เพิ่ม

`.github/workflows/mobile-quality.yml` pin Flutter3.47.2/Dart3.13.2 และ action commit SHAs; pub lockfile/format/analyze/full branch tests/line+branch>=80/OSV audit/unsigned release compile/check .env/checksum/artifacts. Normalize Dart legacy format ใน mobile เพื่อให้ gate ใช้ scope `lib test integration_test` ได้. ไม่มี production secrets หรือ deploy/publish step. Production signing/distribution ต้องเป็นขั้นตอนแยกที่คนอนุมัติ.

`tool/check_coverage.py` fail เมื่อ coverage หาย/ผิดรูป/ต่ำกว่า80. `tool/audit_dependencies.py` fail เมื่อ resolution/API response ผิดหรือมี advisory และรองรับ pagination. API อ้างอิง: https://google.github.io/osv.dev/post-v1-querybatch/.

## ข้อจำกัดที่ยังต้องทำ

1. Secure-storage/backup/uninstall behavior บนอุปกรณ์จริงยังไม่ได้ทดสอบรอบนี้; RMX3370 ล็อก/Dozing — เก็บใน native/RC QA #77/#83/#87
2. Consent settings ปัจจุบันเป็น local preferences; ไม่มี server update contract. Registration ส่ง system/research consent จริง; retention, research use และ policy ต้องยืนยันจาก backend/product ก่อน production (#79/#85/#86)
3. Backend ไม่มี privacy export/delete-all usage endpoints; account deletion เป็นคนละ operation. ห้ามอ้างว่าการ logout/cache purge ลบข้อมูลบนเซิร์ฟเวอร์
4. Cache cleanup ของ image/temp manager อาจข้ามไฟล์ที่ลบไม่ได้; ไม่ได้พิสูจน์ forensic erasure หรือ encryption ของ SQLite/cache. Production retention/storage policy ยังต้อง sign-off
5. OSV เป็น advisory snapshot ไม่ใช่ penetration test; actual TLS/production network และ staging E2E ยังไม่ผ่าน #79
6. ยังไม่มี signed AAB, clean/upgrade install จาก RC, store metadata หรือ production monitoring sign-off; GitHub CI ยืนยันเฉพาะ quality/compile gates

## Clean source verification รอบแรก

Export commit `849e52d` ด้วย git archive ไป directory ใหม่ (ไม่มี `.env`/build/.dart_tool): locked pub get, format, analyzer, tool tests8/8, full Flutter727/727 ผ่าน (45.183s), coverage gateผ่าน. แต่ Android graph เริ่มไม่ได้เพราะ `gradlew` ไม่ tracked ใน repo และต้องให้ Flutter build bootstrap ก่อน. จึงย้าย unsigned release compile ไปก่อน dependency graph ใน workflow; ยังไม่ถือว่ารอบนี้ผ่านทุก gate.

## Clean source verification รอบสุดท้าย

Export commit718c8d4ไปdirectoryใหม่และรันgatesตามworkflowลำดับที่แก้: ทุกgateผ่าน; full727/727 (44.677s), tooltests8/8, format/analyzer0, coverage>=80, unsignedcompile59.88s, graph/audit230packages0advisories, no.env. JSONหลักฐานใน `evidence/ci-2026-10-02/`; artifact SHA-256 `f451fa6ff214b58f001db27bda58e18ee4b1f8e381b4d58eef43e766312fbf76` เป็น unsignedfixture ไม่ใช่RC.

พบbranchremoteมีcommit718c8d4แล้วจากread-only ls-remote; GitHub Actions run https://github.com/Panuwat-ta/project/actions/runs/36946512530 กำลังรัน. ยังไม่สรุปremoteCIpassจนruncompleted.

## GitHub CI ยืนยันแล้ว

Run36946512530 ของ718c8d4 completed/success ทุกstep; remotebranchcoverage82.27%, dependency230รายการ0advisories, qualityartifactuploadและdownloadchecksummatch. หลักฐานgithub-*ในevidence/ci-2026-10-02และreportissue84. งานCIgateผ่าน ไม่ใช่productiondeployment/sign-off.

## Asset optimization #83

PNGต้นฉบับlauncherไม่ได้มีcallerในFlutterlib จึงเปลี่ยนpubspecจากiconsfolderเป็น3SVGที่ใช้จริง. PNGต้นฉบับและAndroidmipmapsยังอยู่. AssetManifesttestใหม่+fullsuite728ผ่าน; analyzer0; unsignedbuild49.0s ขนาด63,447,112bytes ลด1,009,923bytes; SHA256`7c9c0004c43e9b0a491270b61bf6a38cdcf5c3e7f2b7a951c05968e9db657360`. No.env/noPNGduplicate/SVG3ครบ. ยังไม่ได้signedAABหรือactualclean-upgradeinstall.

## CI action runtime maintenance

Run36962909262 (af9f9a0) completed/success:749/749,tools8/8,analyzer0,line90.91%/branch82.35%,OSV230packages0findings. แต่มีannotationNode20และsetup-javav4deprecated. ตรวจofficialrepos/tagcommit/action.yml/READMEแล้วปรับpins:

| Action | Version | Verified commit |
|---|---|---|
| actions/checkout | v7.0.1 | 3d3c42e5aac5ba805825da76410c181273ba90b1 |
| actions/setup-java | v6.0.1 | de7274f081f381c8f8158605e0321c36c376e2e6 |
| actions/setup-python | v7.0.0 | 5fda3b95a4ea91299a34e894583c3862153e4b97 |
| actions/upload-artifact | v7.0.1 | 043fb46d1a93c77aae656e7c1c64a875d1fc6a0a |

ทั้ง4action.ymlใช้node24;officialtagชี้commitSHAตรงกับpin. Runnerรอบก่อน2.337.0สูงกว่าminimum2.327.1ที่READMEกำหนด. Evidence/sourceURLsใน `evidence/ci-2026-10-02/node24-action-pins.json`. GitHub run 36963858748 ของ commit 7d30cc1 completed/success หลัง pin update; annotations 0. รายละเอียด coverage, audit, checksum และ APK assertions อยู่ใน `evidence/ci-2026-10-02/github-node24-artifact-verification.json`.

ตรวจrepo-levelGitHubvariables/secretsได้รายการว่าง;environmentsมีcopilotและgithub-pages ไม่พบstaging/productionenvironmentในrepositoryนี้. ไม่ได้อ่านsecretvaluesและไม่ถือว่ามีproductionconfigพร้อมจากunsignedcompilefixture.

## Follow-up CI — development API runner (PR #90)

GitHub run 36969781386 (`6c1f8a3e`) completed/success: `flutter analyze` พบ 0 issues, quality-tool tests 18/18, Flutter tests 749/749, line coverage 5,471/6,018 (90.91%), branch coverage 1,409/1,711 (82.35%). Dependency audit ตรวจ 230 packages และรายงาน 0 advisories. Unsigned APK ขนาด 63,447,112 bytes, SHA-256 `addbba05d1155f9dcc0d9d72042b8a915686ee72230656e15709d30714ce3ff2`; ตรวจ artifact แล้วไม่พบ `.env` หรือ signature files. สรุปเครื่องอ่านได้อยู่ที่ `evidence/ci-2026-10-02/github-run-36969781386-summary.json`. ผลนี้ไม่ใช่ signed RC, staging E2E หรือ production sign-off.
