## 2026-10-02 08:26 +07 - Splash startup และ async lifecycle regression

- Target: `SplashCubit.checkSession` และ mobile full suite
- Command: `flutter test --coverage --branch-coverage --concurrency=4 --reporter failures-only`
- Result: PASS
- Summary: Total737 | Passed737 | Failed0 | Skipped0 | Duration42.994s
- Coverage: line5,470/6,018 (90.89%); branch1,408/1,711 (82.29%); coveragegate>=80ผ่าน
- Worktree: `/tmp/scamguard-mobile-hardening`, branchrefactor-mobile; workspaceหลักdevelopไม่ถูกเปลี่ยน

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **Defaultstartup**: defaultdelayเป็น0 และ storagelookupเริ่มโดยไม่รอ3วินาที; onboardingfalseได้SplashConsentRequired
- **Concurrentchecks**: เรียกcheckSession2ครั้งขณะfuturepending มีstoragelookupเพียง1ครั้ง
- **Closeขณะasync**: lateonboarding/token/profileresponseหลังcloseไม่emitstateและfutureจบโดยไม่throw
- **Closeก่อนเริ่ม/ระหว่างcustomdelay**: ไม่เรียกrepositoryหลังclose; optionaldelayสำหรับcallerยังใช้ได้
- **Latefailure**: repositoryerrorที่กลับมาหลังcloseไม่ทำให้emitSplashFailureบนclosedcubit
- **Retry**: failureครั้งแรกตามด้วยcheckใหม่สำเร็จได้; guardไม่ค้างlocking
- **Behaviorเดิม**: onboardingrequired/noaccess token/authenticateduser/missinguser/storagefailureผ่านครบ; fullsuiteทุกmoduleผ่าน737กรณี
- Analyze0issuesและformatgateexit0; runtimecoverageวัดจริงเกิน80ทั้งline/branch

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed) ในรอบสุดท้าย.

ก่อนแก้ regressionrunผ่าน5/failed5: defaultDuration3sแทน0; concurrentlookup2แทน1; lateonboarding/token/profilecompletionหลังcloseทั้ง3กรณีthrow `Bad state: Cannot emit new states after calling close`. เพิ่มguard/ตัดdefaultdelayแล้วรันทั้งsuiteใหม่ผ่าน.

รอบกลางcompileไม่ผ่านเพราะใช้ `verifyNoInteractions` ซึ่งMocktailที่repoใช้อยู่ไม่มี; เปลี่ยนเป็นverifyNeverของแต่ละrepositorymethodแล้วrerun. ไม่ถือว่ารอบcompileerrorเป็นผลผ่าน.

ผลนี้ยืนยันfunctionalstartup/lifecycleและตัดartificialdelay ไม่ได้พิสูจน์nativecoldstart/frame/rendering/image-memory/fullsoak. #81ยังOPEN; ภาพ/metricsจากdevelopAPKก่อนพบbranchswitchไม่ใช่หลักฐานhardening.

## 2026-10-02 08:36 +07 — GitHub CI ของ startup fix

- Target: mobile full suite และ quality tools จาก source `ac5e8334097739539d143be0e2d91b004656bbd8`
- Command: workflow `mobile-quality.yml` (`flutter test --coverage --branch-coverage` และ Python quality-tool tests)
- Result: PASS — [GitHub Actions run 36951286426](https://github.com/Panuwat-ta/project/actions/runs/36951286426)
- Summary: Flutter Total737 | Passed737 | Failed0 | Skipped0 | runner duration74s; Python Passed8 | Failed0 | duration0.071s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- Full Flutter suite รวม Splash regression ผ่านบน GitHub runner; runner แสดง `01:14 +737: All tests passed!` ยืนยันว่าการเปลี่ยน default delay/concurrency/closed lifecycle ผ่านร่วมกับ tests เดิม
- Coverage gate อ่าน LCOV ได้ line5,470/6,018 (90.89%), branch1,408/1,711 (82.29%) สูงกว่าเกณฑ์80ทั้งสองค่า
- Python quality tools8กรณีผ่าน; analyzerไม่พบปัญหา, formatting และ locked dependency resolution ผ่าน
- Dependency audit ตรวจ230 Pub/Maven packages ได้0 findings ตามฐาน OSV ณเวลารัน ไม่ใช่คำรับรองว่าปลอดช่องโหว่ทุกประเภท

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed) ใน automated CI รอบนี้. Native frame/memory/soak ยังไม่ได้รัน จึงไม่มีผลผ่านสำหรับ acceptance criteria เหล่านั้น และ #81ยังOPEN.

Run metadata, coverage, audit และ runner summary อยู่ที่ `design/mobile/evidence/startup-2026-10-02/github-*`. ดาวน์โหลด unsigned quality APK และตรวจ SHA256 ตรงกับ artifact checksum; artifact เป็น compile-only fixture ไม่ใช่ signed production RC.
