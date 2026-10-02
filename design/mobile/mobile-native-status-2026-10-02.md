# Native QA / startup — 2026-10-02

## Source freeze และข้อจำกัด

- Workspaceหลักถูกเปลี่ยนจากrefactor-mobileไปdevelopc3bc7223ระหว่างงาน จึงสร้างworktree `/tmp/scamguard-mobile-hardening` บนrefactor-mobilecab54411 เพื่อรักษาbranch/workของผู้ใช้
- ProfileAPKที่build/installบนRMX3370ก่อนตรวจพบbranch switchเป็นdevelopc3bc7223 แม้amstartCOLDTotalTime1334ms/WaitTime1342ms แต่ **ไม่นับเป็นhardening performance evidence**
- gfxinfoในรอบนั้นมีเพียง2HWUIframes/1janky; ไม่ได้วัดFlutterpipelineครบและไม่นำpercentilesไปอ้างperformanceผ่าน
- หลังworktreefreezeที่ถูกต้อง buildprofilecab54411ผ่าน44.4s/92.2MBด้วยexplicitdevelopmentAPI`http://127.0.0.1:18080/api/v1`; ยังไม่ได้ติดตั้ง/วัดบนอุปกรณ์จากartifactนี้
- RMX3370เคยunlock/fontscale1.0/noaccessibilityserviceenabled แต่ถูกถอดก่อนcorrect-sourceinstall; Adbreversetcp18080->8000ล้มเหลวdevice-not-found จึงยังไม่มีreverseforwardที่ยืนยันสำเร็จ
- พบI2405serial10AF682JX1001YKต่ออยู่; ขอผู้ใช้ยืนยันก่อนติดตั้งทดสอบบนเครื่องนี้ ยังไม่เปลี่ยนTalkBack/rotation/fontsettings

## Backend availability ในรอบนี้

LANdevURLเดิม10.93.144.70timeout. localhost8000healthเคยdegraded(database/rediserror) ขณะcontainersup; independentvenvSELECT1และRedisPINGผ่าน และตรวจhealthใหม่08:14ได้statusok/databaseok/redisok. ไม่ได้restartsharedserver และยังไม่พิสูจน์สาเหตุtransientfailure. URL/healthนี้เป็นlocaldevelopmentไม่ใช่production/stagingcontractproof.

## Startup finding #81

SplashCubitdefaultหน่วง3วินาทีก่อนอ่านsessionทุกครั้ง. Regressionสร้างผลfailจริง5กรณี: delaydefault3sแทน0, concurrentstoragecalls2แทน1, lateonboarding/token/profilecompletionหลังcloseทำให้Badstate. แก้defaultdelay0, guardconcurrentlookup, stopaftercloseทุกawaitและallowretryafterfailure. Full-suite737/737 (42.994s), analyzer0, formatgateผ่าน, line90.89%/branch82.29%; รายงาน `tests_all/tests_report/automate_tests/mobile/issue-81-splash-startup-2026-10-02.md`.

การตัดexplicitdelayไม่ได้ยืนยันnativecoldstart/frame/memory/soakผ่าน; #81คงOPENจนมีprofile/releasehardwaremetricsและauthenticatedscan/history/result/heatmap/reportsoak/processrecreationครบ. #77ยังต้องactualTalkBack/scale/rotation/keyboard/insets/Back และ#83/#87ต้องsignedsame-sourceartifact/cleanupgradeinstall.

## Compile artifacts ของ startupfixac5e833

ProfileAPKcompileผ่าน33.8s(117.5MB) แต่ยังไม่ได้ติดตั้งcorrectsourceหลังstartupfixบนอุปกรณ์. UnsignedAABcompileผ่าน67.2s(61.4MB); zipassertionsไม่มี.env/ไม่มีlauncherPNGซ้ำ/SVG3ครบ; jarsignerยืนยันunsigned. Exactbytes/SHA256/ABIsในevidence/startup-2026-10-02/unsigned-aab.json. ทั้งคู่ไม่ใช่productionRC; productionidentity/key/signature/clean-upgradeinstallยังต้อง #83.

## Remote CI ของ source ac5e833

[Run36951286426](https://github.com/Panuwat-ta/project/actions/runs/36951286426) completed/success เวลา01:36:57UTC (08:36:57+07). Flutter737/737, Python tools8/8, analyzer0, line90.89%/branch82.29%, OSV230packages0findings. ดาวน์โหลด unsigned quality APK63,447,112bytes และตรวจ SHA256ตรง `addbba05d1155f9dcc0d9d72042b8a915686ee72230656e15709d30714ce3ff2`; ไม่พบ.env/launcherPNGซ้ำในAPK. Metadataอยู่evidence/startup-2026-10-02/github-*. ผลCIไม่ใช่nativeQAหรือsignedRC; #81/#83ยังOPEN.

## Native execution เพิ่มเติม — worktreeถาวร

หลังสลับenvironment /tmpworktreeเดิมหาย เหลือgitworktreemetadata; สร้าง `/home/panuwat/project-mobile-hardening` บนrefactor-mobileจาก7ab28fbโดยไม่เปลี่ยนdevelop. กู้stagingharnessและรัน749/749/analyzer0; commitf393c86และCI36961640199completed/success.

RMX3370กลับมาเชื่อม/unlocked; ติดตั้งcorrect-sourceprofileAPK (appsourceac5e833,checkout7ab28fb,tests-onlychanges) สำเร็จ. InitialAMcoldTotalTime1168ms; อีก5รอบ576/515/531/523/535ms,WaitTime580/521/537/532/540ms. AMไม่ใช่Flutterreadytime; snapshotหลังรอบสุดท้ายPSS215874kB/RSS317616kB ไม่ใช่soak. Exactartifacthash/metadataในevidence/native-2026-10-02/profile-startup.json.

ตรวจLoginTH/light/font1.0portraitจริง: fields/forgotpassword/passwordtoggle/loginbuttonปรากฏ; focusemailเปิดkeyboard, scrollทำให้loginbuttonขึ้นเหนือkeyboard [144,882][936,1044]; Backปิดkeyboard(mInputShown=false). Loginbuttonheight162px/density3=54dp, passwordtoggleและforgotpassword144px=48dp. ภาพและsanitizednodeboundsในevidence/native-2026-10-02/. ไม่เปลี่ยนTalkBack/textscale/rotation; ไม่ถือsemanticsdumpแทนactualspokenlabels/focusorder. ยังไม่ตรวจทุกหน้าหรือทุกconfiguration จึง #77OPEN.

Profileintegrationstartupprobeผ่านจริง1กรณี; DI→signedoutroute406ms,Flutter3frames,buildbudgetmiss2/rastermiss1. Sample3framesจำกัดมาก; ไม่สรุปp90/p99หรือperformanceพร้อมproduction. รอบแรกDDSVMconnectionrefused แล้วrerun--no-ddsผ่าน. รายงานtests_all/tests_report/automate_tests/mobile/issue-81-native-startup-probe-2026-10-02.md. Authenticatedflows/staging/fullsoakยังไม่มีเพราะconfirmedstaging/accountไม่ครบและlocalhost8000down; #79/#81OPEN. คืนregularprofileappหลังprobe.

หลังคืนregularprofileAPKinstallSuccessและOnboardingปรากฏ: AMcoldTotalTime1826ms/WaitTime1831ms. ค่านี้สูงกว่ารอบrepeatedlaunch515–576ms จึงห้ามเลือกเฉพาะค่าต่ำเพื่อสรุปstartupผ่าน; disk/OS/appcacheและpostinstallต่างกัน. Exactrestoredartifactmetadataเพิ่มในprofile-startup.json.


ข้อค้นพบจากtool lifecycle: flutterdriveเริ่มต้นstop+uninstallเมื่อtestจบ (SDKdrive_service.dart280–287). หลังคืนregularAPKพบOnboarding ไม่ใช่Login; localstateไม่ได้ยืนยันpreserved แม้ไม่มีaccess tokenก่อนprobe และ testcodeไม่ได้deleteAll. ไม่กล่าวอ้างcleanupgradepreservesdata. แก้คู่มือ/probeให้explicitdedicatedinstallและใช้applicationIdสำหรับtestใหม่ `com.example.scam_image_mobile.hardening_probe` พร้อม--keep-app-running; เป็นtestidentifierที่เลือกเฉพาะงานนี้ ไม่ใช่confirmedproductionidentity. ไม่เปลี่ยนconsent/onboardingโดยพลการในแอปปกติเพื่อกลบผลที่พบ.

DedicatedprobeapplicationIdcom.example.scam_image_mobile.hardening_probeรันใหม่ผ่าน1/1ด้วยprofile/no-dds/keep-app-running/explicitfixtureflag; DI→signedoutroute382ms,Flutter3framesbuildmiss1/rastermiss1. ไม่เทียบเป็นbefore/afterกับรอบแรก; retainrawJSON2รอบเพื่อไม่เลือกผลที่ดีกว่าอย่างเดียว. หลังรันstopเฉพาะprobeและกลับแอปปกติที่Onboarding; ไม่รับterms/researchconsentเอง. #77/#79/#81/#83/#85/#86/#87/#88ยังOPEN.


## ทดสอบ API development บนอุปกรณ์ — 2026-10-02

- ใช้ `develop` commit `c74167b3` ซึ่ง mobile source รวม hardening commit `7d30cc17`; อ่านเฉพาะ `API_BASE_URL` จาก `.env` ที่ผู้ใช้มีอยู่ โดยไม่คัดลอกหรือเก็บค่าในหลักฐาน
- สร้าง Profile APK ขนาด 92,155,887 bytes ด้วย `APP_ENV=development` และ URL ดังกล่าวเป็น Dart define; ติดตั้งทับด้วย `adb install -r` และเปิด `MainActivity` สำเร็จ
- ตรวจ APK ก่อนติดตั้ง: ไม่มี `.env`/`.env.example` assets และพบค่า API URL ที่กำหนดอยู่ใน Flutter native library
- จาก RMX3370 / Android 13 ส่ง `GET /health` ผ่าน Wi-Fi หลังยืนยัน `adb reverse --list` ว่าง; ได้ HTTP 200 และ JSON `status=ok`, `database=ok`, `redis=ok` (`version=0.1.0`). หลักฐานที่ `evidence/native-2026-10-02/mobile-development-api-health.json`
- ยืนยันเฉพาะ device-to-development-API transport และ build configuration; ไม่ได้ส่ง credential, ทดสอบ login snackbar, scan หรือ staging flow จึงยังไม่ปิด #79 และไม่ใช่ production network proof
