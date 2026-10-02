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
