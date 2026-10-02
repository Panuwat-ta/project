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
