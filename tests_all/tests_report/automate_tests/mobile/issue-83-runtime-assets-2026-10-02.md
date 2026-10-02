## 2026-10-02 07:52 +07 - Runtime asset regression และ full suite

- Target: `test/core/assets/app_assets_test.dart` และ mobile full suite
- Command: `flutter test --coverage --branch-coverage --concurrency=2 --reporter failures-only`
- Result: PASS
- Summary: Total728 | Passed728 | Failed0 | Skipped0 | Duration: ไม่บันทึก
- Coverage: line5,456/6,010 (90.78%); branch1,394/1,703 (81.86%); gate>=80ผ่าน

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

AssetManifest assertionมีgoogle/github/facebookSVGและonboardingheroครบ และไม่มีlauncherต้นฉบับPNGเป็นFlutterasset; โหลดSVGทั้ง3จริงได้. Fullsuiteเดิมพร้อมassettestใหม่ผ่าน728กรณี. APKzipassertionไม่มีlauncherPNGซ้ำ/no.envและมีSVGครบ3; buildunsignedreleaseผ่าน49.0s ขนาด63,447,112bytes ลด1,009,923bytesจากfixtureเดิม64,457,035bytes. Androidmipmaplauncherresourcesไม่ได้แก้; sourcePNGยังอยู่.

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed) ในรอบสุดท้าย.

รอบก่อนถูกinterrupt: runnerถึง611Passedแต่เกิด5loadingerrors/SIGTERMและbuildexit143 จึงไม่ถือว่าผ่าน. หลังเปลี่ยนpermission profile Flutterต้องเขียนSDKcacheนอกworkspace; sandboxattemptexit1 แล้วรันใหม่ด้วยapprovedescalationจน728ผ่าน. ไม่ยืนยันสาเหตุผู้ส่งSIGTERMจากlogเพียงอย่างเดียว. Buildรอบสุดท้ายมีInvaliddepfilewarningจากinterruptedbuildแต่compileจบsuccess; analyzer0issues. ผลcoverageรอบล่าสุดใช้ค่าที่วัดจริงจากconcurrency2 ไม่ใช้ตัวเลขรอบก่อนแทน.

Artifactยังเป็นunsignedHTTPSexample.invalidcompilefixture; signing/production/nativeinstallยังไม่ผ่าน #83.

## 2026-10-02 - Unsigned AAB compile/container gate

- Target: `app-release.aab` ของcommitac5e833
- Command: `SCAMGUARD_ALLOW_UNSIGNED_QUALITY_BUILD=true flutter build appbundle --release --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://example.invalid/api/v1` ตามด้วยjarsignerและPythonzip/assertions
- Result: PASS สำหรับcompile/containergate; signingstatusเป็นunsignedตามที่ตั้งใจ
- Summary: Build67.2s | Assertions6Passed | Failed0

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- ReleaseAABcompileสำเร็จขนาด61,361,753bytes; ไม่มี.envทุกentryและไม่มีlauncherPNGซ้ำในFlutterassets
- google/github/facebookSVGมีครบในbaseassetsจริงทั้ง3assertions
- jarsigneroutputระบุjarunsigned และassertตรงกับunsignedqualitybuild ไม่ใช้debugsigningfallback
- ExactSHA256/ABIs/sourcecommit/configเก็บใน `design/mobile/evidence/startup-2026-10-02/unsigned-aab.json`

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed) ในcompile/containergate. ไม่ใช่productionidentity/signatureacceptanceหรือphysicalclean-upgradeinstall; ไม่ปิด #83 จากunsignedartifactนี้.
