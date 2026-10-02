## 2026-10-02 10:59 +07 — Physical profile startup probe

- Target: `integration_test/startup_profile_test.dart`; RMX3370 Android13,1080x2400,density480,fontscale1.0
- Command: `flutter drive --profile --no-dds --no-pub --driver=test_driver/startup_profile_test.dart --target=integration_test/startup_profile_test.dart -d f9a12239 --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://127.0.0.1:18080/api/v1`
- Result: PASS (functional probe เท่านั้น)
- Summary: startup probe1 | Passed1 | Failed0 | Skipped0 | runner durationประมาณ4s; frameworkมีtearDownAllเพิ่มในcounter

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- ใช้profile/development configจริง; อ่านsecurestorageก่อนเริ่มและยืนยันไม่มีaccess token โดยไม่พิมพ์token/ไม่deleteAll
- เริ่มServiceLocatorและScamGuardAppจริง; พบLoginหรือOnboardingภายในdeadline45s,ไม่มีFlutterexceptionในstartup และFlutterFrameTimingมี3frames มากกว่า0ตามassertion
- DIเริ่มจนพบsigned-out route406ms ในtest harness; ไม่รวมOSprocesslaunch/driver startupและwatchPerformanceflushdelay
- ผลframe data: buildเวลา44.014/23.642/6.842ms; raster10.961/4.263/19.919ms; SDKsummarizerนับbuildbudgetmiss2/rasterbudgetmiss1. การผ่านtestหมายถึงเก็บข้อมูลได้ ไม่ใช่performancebudgetผ่าน
- newgenGC4/oldgenGC0ในหน้าต่างที่เก็บ; ไม่ใช่memorysoak/leakproof. Native pluginรายงานalgorithm migrationสำเร็จ0itemsในinstallationนี้; ไม่ได้ทดสอบmigrationบัญชีที่มีข้อมูล

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed) ในรอบสุดท้าย. รอบแรกไม่ได้ใส่ `--no-dds`: watchPerformanceเรียกVMtimelineแล้วconnectionrefusedบนlocalhostของdevice, runnerรายงานprobeFailed1. SDKแนะนำปิดDDS; reruncommandข้างบนแล้วเก็บtimingsสำเร็จ.

ยังมีperformancefinding: 2/3buildframesและ1/3rasterframesเกินbudgetที่SDKใช้; sample3framesไม่เพียงพออ้างp90/p99หรือทั้งแอปพร้อมproduction. #81คงOPENเพราะHome/History/Result/Heatmap authenticatedframes/image-memory/soak/processrecreationยังไม่ครบ. localhost8000ไม่ทำงานในenvironmentนี้; ไม่ใช่stagingexecutionหรือsignedRC.

Rawsanitizedmetrics: `design/mobile/evidence/native-2026-10-02/flutter-startup-profile.json`. หลังทดสอบbuild/installprofileแอปปกติคืน; ไม่เผยแพร่testAPK.


ข้อจำกัดเพิ่มเติม: commandรอบแรกใช้flutterdrivedefaultcleanupซึ่งSDKstop/uninstallapp; reinstallregularprofileสำเร็จแต่พบOnboardingแทนLogin. ไม่มีaccess tokenก่อนprobe ไม่ได้พิสูจน์localsettings/cacheคงอยู่. เพิ่มexplicitdedicatedinstallguardและรันแยกapplicationIdในรอบต่อไป; ไม่ถือผลนี้เป็น upgradepreservesdataผ่าน.

## Dedicated applicationId rerun — PASS

- Command: `SCAMGUARD_APPLICATION_ID=com.example.scam_image_mobile.hardening_probe flutter drive --profile --no-dds --keep-app-running --no-pub --driver=test_driver/startup_profile_test.dart --target=integration_test/startup_profile_test.dart -d f9a12239 --dart-define=E2E_DEDICATED_INSTALL=true --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://127.0.0.1:18080/api/v1`
- Result: PASS; probe1/1, runnerประมาณ4s. Analyzer0(2.0s), format189files0changed.
- ผ่าน: configexplicitdedicatedinstall/profile/dev,ไม่มีaccess tokenบนtestinstallใหม่,พบsignedoutroute,Fluttertimings3frames. Driverยืนยัน `Leaving the application running.` ไม่uninstallแอปปกติ; หลังเก็บข้อมูลforce-stopเฉพาะprobeและกลับแอปปกติ
- Metric: DI→signedoutroute382ms; build29.173/12.138/6.119ms, raster8.913/3.359/28.019ms, buildmiss1/rastermiss1, newgenGC4/oldgenGC0. ตัวอย่างยัง3framesจึงไม่ถือperformanceพร้อมproduction และไม่เทียบbefore/afterกับรอบแรกที่route/artifactต่างกัน
- ไม่มีข้อผิดพลาด (0 Failed) ในรอบdedicated; ยังมีoverbudgetfindingและข้อจำกัดauthenticated/staging/fullsoakเหมือนเดิม
- Evidence: flutter-startup-profile-dedicated.json และ dedicated-probe-artifact.json ใน design/mobile/evidence/native-2026-10-02/
