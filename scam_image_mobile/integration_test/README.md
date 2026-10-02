# Staging authentication/navigation E2E

ตรวจ login → Home → History → Settings → ยืนยัน logout ผ่าน backend จริง ยังไม่ได้ยืนยัน staging execution และไม่ครอบคลุม scan/result/report ทุก API

## Preconditions

ใช้เครื่อง/profile และ applicationId เฉพาะ staging ที่เจ้าของยืนยัน แยกจากข้อมูลส่วนตัว (`flutter test -d` จะติดตั้ง test APK). แอปต้อง signed out; หากมี session เข้า Home อยู่แล้ว test จะ fail โดยไม่ล้าง storage หรือ logout session เดิม

สร้าง `config/staging-e2e.local.json` ผ่านช่องทางปลอดภัย โดยใช้ keys:

| Key | ค่า |
|---|---|
| APP_ENV | staging |
| API_BASE_URL | HTTPS staging URL ที่ยืนยัน รวม API prefix |
| E2E_EMAIL | Email บัญชี fixture จริง |
| E2E_PASSWORD | Password บัญชี fixture จริง |
| E2E_ACCEPT_TERMS | true เฉพาะเมื่อเจ้าของบัญชีอนุญาต terms ใน onboarding; default false |

`config/*.local.json` ถูก gitignore แล้ว ห้ามใส่ credentials ใน command line/commit/report. Dart defines ถูก compile ลง test binary ได้ จึงห้ามเผยแพร่ test APK และต้องใช้บัญชีเฉพาะทดสอบ; ไม่ใช้ production credentials. Config validation ไม่ได้พิสูจน์ว่า endpoint เป็น staging จริง เจ้าของต้องยืนยัน

```bash
SCAMGUARD_APPLICATION_ID='<confirmed-staging-test-id>' flutter test \
  integration_test/app_test.dart --no-uninstall \
  -d '<confirmed-device-serial>' \
  --dart-define-from-file=config/staging-e2e.local.json
```

`<...>` คือข้อมูลที่ยังต้องรับจากเจ้าของ ไม่ใช่ command พร้อมรัน

## Assertions

- Config ต้องเป็น staging/HTTPS; ปฏิเสธ production/development, URL มี credentials/query/fragment, localhost/loopback/.invalid และไม่มีบัญชี ก่อน DI/app startup
- ไม่ใช้ `FlutterSecureStorage.deleteAll` และไม่เปิด research consent; terms ต้อง explicit opt-in
- ต้องพบทุก destination และ logout dialog จึงผ่าน ไม่มี optional navigation ที่ข้ามแล้วผ่าน
- รอ condition จริง deadline45วินาทีต่อขั้นตอน ไม่ใช้ pumpAndSettle กับ repeating animations และไม่ถือ fixed delay ว่า network สำเร็จ
- Logout ต้องกลับ Login, AuthBloc unauthenticated และ access token ไม่มีค่า; assertion ไม่พิมพ์ token
- History destination ผ่านไม่ได้ยืนยัน raw History API; #79 ยังต้อง scan/status/result/heatmap/history/report/error evidence

```bash
flutter test test/integration_support/staging_test_config_test.dart
flutter analyze --fatal-infos --fatal-warnings
```

Host regression นี้ตรวจ configuration guard ไม่ใช่ native/staging E2E. เก็บผล execution จริงตาม template ที่ tests_all/tests_report/automate_tests/mobile/ และอย่าเปลี่ยน manual cases เป็น Pass ก่อนรันจริง

## Signed-out native startup probe (#81)

สำหรับprofile/developmentบนเครื่องที่signedoutเท่านั้น ไม่ล้างstorageหรือทำconsent/login. ใช้FlutterFrameTimingของSDK; ไม่ใช่signedRCหรือauthenticatedsoak

```bash
SCAMGUARD_APPLICATION_ID='<dedicated-probe-id>' flutter drive --profile --no-dds --keep-app-running \
  --driver=test_driver/startup_profile_test.dart \
  --target=integration_test/startup_profile_test.dart \
  -d '<confirmed-device-serial>' \
  --dart-define=E2E_DEDICATED_INSTALL=true \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL='<confirmed-development-api-url>'
```

`--no-dds` จำเป็นในรอบRMX3370ที่ทดสอบเพื่อให้watchPerformanceเชื่อมVMtimelineบนdeviceได้. ผลJSONอยู่build/integration_response_data.json; จำนวนframesต้องมากกว่า0จึงผ่าน การผ่านprobeไม่ยืนยันว่าframebudgetผ่าน. หลังทดสอบติดตั้งแอปปกติคืนแทนtestAPK

Flutter drive ค่าเริ่มต้น stop และ uninstall app หลังจบทดสอบ (ตรวจจากSDKdrive_service.dart) จึงต้องใช้ dedicated applicationId แยกจากแอปปกติ และ --keep-app-running. E2E_DEDICATED_INSTALL เป็น explicit fixture flag; ไม่ได้ตรวจ package identity อัตโนมัติ ห้ามใส่ true เพื่อรันบน app ที่มีข้อมูลผู้ใช้.
