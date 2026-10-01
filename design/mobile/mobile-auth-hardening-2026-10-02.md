# Auth hardening — Issues #77 / #82

## ขอบเขตที่แก้

- Login/Register ใช้ semantic colors จาก Theme และ radius จาก AppRadius; typography สืบทอด text theme ที่ใช้ Sarabun
- ปุ่มแสดง/ซ่อนรหัสผ่านมี tooltip ไทย/อังกฤษ และพื้นที่กดอย่างน้อย 48dp
- เพิ่ม accessible label ของช่องกรอกและ checkbox consent; ข้อความเงื่อนไขรองรับ text scale
- Login label/forgot-password ใช้ Wrap; Register ลบ badge END-TO-END ENCRYPTED ที่ไม่มีหลักฐานรองรับ
- Onboarding เลื่อนได้เมื่อหน้าจอเตี้ยหรือขยายข้อความ, ปุ่มยืนยันไม่ส่งซ้ำ, persistence ล้มเหลวไม่ประกาศสำเร็จและลองใหม่ได้
- Splash ใช้ typography/semantic colors ของแอป, เลื่อนได้, loading เป็น live region และไม่แสดง animation เมื่อระบบขอลด motion
- AuthBloc ปฏิเสธ Login/Register ซ้ำหรือข้าม operation ระหว่างรอผล และยังลองใหม่หลัง failure ได้
- ลบ MainShell เก่า: `rg 'MainShell|main_shell.dart' scam_image_mobile` พบเฉพาะ declaration ในไฟล์ดังกล่าวก่อนลบ; routing จริงใช้ core/widgets/main_navigation_shell.dart

## หลักฐานอัตโนมัติ

`auth_accessibility_test.dart`: 144 combinations ของ Login/Register/Onboarding/Splash × 390×844, 844×390, 1024×768 × text scale 1.0/1.3/1.5 × Light/Dark × TH/EN; landscape จำลอง keyboard inset 120dp และทุกกรณีปิด animation

ตรวจไม่มี Flutter layout exception และปุ่มแสดงรหัสผ่านมี tooltip พร้อมขนาดอย่างน้อย 48×48dp ไม่ถือผล widget tests เป็นหลักฐาน TalkBack บนเครื่องจริง

`onboarding_screen_test.dart`: success และ persistence failure/retry ตรวจไม่เขียนซ้ำขณะรอ, ไม่ mark onboarding เมื่อบันทึกล้มเหลว และเข้า Login เมื่อสำเร็จจริง

## ขอบเขตที่ยังต้องตรวจใน #77

TalkBack focus order/เสียงประกาศจริง, Android back/predictive back, rotation/multi-window และ system settings จริงบน RMX3370 ยังต้อง native execution; matrix ข้างต้นจำลอง viewport และ MediaQuery เท่านั้น
