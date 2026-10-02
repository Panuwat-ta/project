# Mobile Functional Test Cases

> ขอบเขต: manual test cases สำหรับฟังก์ชันที่ผู้ใช้เรียกผ่าน Mobile v1 และเส้นทางที่โค้ดปัจจุบันรองรับ ใช้ Requirement ID จาก SRS canonical เท่านั้น
> Test Data อ้าง SRS, ไฟล์ที่มีอยู่จริง, ID ที่ได้จาก API ระหว่างทดสอบ หรือ N/A สำหรับกรณีไม่มี input ภายนอก ห้ามใช้ข้อมูลผู้ใช้จริง
> ทุกแถวเริ่มที่ To Do จนกว่าจะรันทดสอบ manual และบันทึกผลจริง

## Automated test audit

- flutter test --coverage --branch-coverage --reporter=failures-only ล่าสุด: 422 passed, 0 failed, 0 skipped
- line coverage ล่าสุดจาก coverage/lcov.info: 4,087/5,678 = 71.98%; การรันล่าสุดไม่มี BRDA records จึงยังสรุป branch coverage ปัจจุบันไม่ได้
- ผล branch coverage ก่อนเพิ่ม screen widgets (417 tests): 920/1,546 = 59.51% ตามรายงานรอบ 01:16
- flutter analyze: No issues found
- Automated tests ครอบคลุม Auth, HomeScreen, ImageCropScreen, History, NotificationsCubit/Screen, Report, Result, ScanBloc, SettingsCubit, UserProfileScreen, PrivacyConsentScreen, network, router และ storage
- เพิ่ม screen-level widget tests สำหรับ HomeScreen, ImageCropScreen, NotificationsScreen, UserProfileScreen และ PrivacyConsentScreen
- ชุดนี้ครอบคลุม user-visible functions ไม่ได้อ้างว่าทุก private Dart method มี unit test ครบ

## Test cases

### เริ่มต้นและ Authentication

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
|---|---|---|---|---|---|---|---|---|---|
| TC-MOB-01 | Splash คืน session และกัน protected screen | FR-AUTH-02, FR-AUTH-04 | ติดตั้งแอป; มี session ทดสอบที่ใช้ได้หรือถูกเพิกถอน | session จาก isolated test environment | ตรวจ route หลัง cold start | เปิดแอปทั้ง session ใช้ได้และใช้ไม่ได้ | session ใช้ได้ไป Home; ไม่มี/ใช้ไม่ได้ไป Login หรือ onboarding ตาม state; ไม่เปิด protected screen | To Do | High |
| TC-MOB-02 | Onboarding นำทางไปสมัครและ Login | NFR-06 | first run | N/A | ตรวจ entry navigation | ทำ onboarding แล้วเลือกสมัครและ Login | แต่ละ action เปิด route ที่ตรง; Back ไม่วนผิด route | To Do | Medium |
| TC-MOB-03 | Register สำเร็จพร้อม consent | FR-AUTH-01, FR-PDPA-01 | Register; isolated test DB | FR-AUTH-01 AC-1: bas test, new.user01@example.com, Test1234!; ตรวจ email ว่ายังไม่ซ้ำ | ตรวจ register flow | กรอกค่าตาม SRS; ยอมรับ system consent; สมัคร | สมัครสำเร็จ; response ไม่มี password/hash; UI แสดงผลตาม code | To Do | High |
| TC-MOB-04 | Register ปฏิเสธ email/password ผิดรูปแบบ | FR-AUTH-01 | Register | FR-AUTH-01 AC-3/4: test@, test.com และ password ต่ำกว่า 8 ตัวอักษร | ตรวจ validation ก่อนส่ง | ส่งแต่ละค่าที่ไม่ถูกต้อง | แจ้งช่องผิดและไม่ส่ง request | To Do | High |
| TC-MOB-05 | Register ปฏิเสธเมื่อไม่ยอมรับ system consent | FR-AUTH-01, FR-PDPA-01 | Register; isolated test DB | ข้อมูลตาม FR-AUTH-01 AC-1 โดย system_consent=false | ตรวจ consent บังคับ | กรอกข้อมูลถูกต้องแต่ไม่เลือก system consent แล้วส่ง | ไม่สร้างบัญชี; แจ้ง consent ที่ต้องยอมรับ | To Do | High |
| TC-MOB-06 | Register ปฏิเสธ email ซ้ำ | FR-AUTH-01 | user01@example.com มีอยู่ใน isolated test DB ตาม SRS | user01@example.com จาก FR-AUTH-01 AC-2 | ตรวจ duplicate error | สมัครด้วย email ที่มีอยู่ | แสดง error; ไม่แสดง success | To Do | High |
| TC-MOB-07 | Login สำเร็จและเก็บ session | FR-AUTH-02 | บัญชี active จาก SRS มีใน isolated test env | user01@example.com และ Test1234! จาก FR-AUTH-02 AC-1; credential ไม่ใส่ report | ตรวจ auth และ route | กรอกแล้ว Login | เข้า Home; token เก็บใน Secure Storage; token ไม่แสดงใน UI/log | To Do | High |
| TC-MOB-08 | Login ปฏิเสธรหัสผ่านผิด | FR-AUTH-02 | Login; backend test พร้อม | user01@example.com และ Wrong1234! จาก FR-AUTH-02 AC-2 | ตรวจ 401 handling | กรอก credential ผิดแล้ว Login | อยู่หน้า Login; ไม่มี protected access; แสดง localized error | To Do | High |
| TC-MOB-09 | Login validation และป้องกัน double submit | FR-AUTH-02 | Login | ค่าว่างและ email ผิดรูปแบบตาม SRS | ตรวจ validation/loading state | ส่งฟอร์มว่าง/ผิดรูปแบบ; แตะซ้ำระหว่าง request | ไม่ส่ง request เมื่อ invalid; ระหว่างโหลดป้องกัน submit ซ้ำ | To Do | High |
| TC-MOB-10 | Refresh token สำเร็จ | FR-AUTH-03 | session ทดสอบ; refresh token ยังใช้ได้ | refresh token จาก login ใน isolated test environment | ตรวจ 401 refresh flow | เรียก protected API หลัง access token หมดอายุ | refresh สำเร็จ; request เดิม retry ด้วย token ใหม่โดยไม่กลับ Login | To Do | High |
| TC-MOB-11 | Refresh ล้มเหลวและ fail closed | FR-AUTH-03, FR-AUTH-04 | refresh token ถูกเพิกถอน/หมดอายุ | token ที่ทำให้ใช้ไม่ได้ใน isolated test env | ตรวจ refresh failure | เรียก protected API แล้วให้ refresh ล้มเหลว | ล้าง local token; ไม่ refresh วน; กลับ Login | To Do | High |
| TC-MOB-12 | Logout ยกเลิกหรือยืนยัน | FR-AUTH-04 | authenticated; เปิด Settings | N/A | ตรวจ confirm/cancel | เปิด Logout dialog, Cancel; ทำซ้ำแล้ว Confirm | Cancel คง session; Confirm ล้าง sessionและกลับ Login; Back ไม่เปิด protected page | To Do | High |

### Gallery, Crop และ Scan

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
|---|---|---|---|---|---|---|---|---|---|
| TC-MOB-13 | Home เปิด Gallery และเลือกรูป | FR-SCAN-01 | authenticated; อนุญาต image access | server/tests/test1.png | ตรวจ picker flow | เลือกภาพจาก Gallery | ไป Crop/Preview; path และขนาดมาจากไฟล์ที่เลือก | To Do | High |
| TC-MOB-14 | ยกเลิก Gallery picker | FR-SCAN-01 | อยู่ Home | N/A | ตรวจ picker cancel | เปิด Gallery แล้ว Cancel | กลับ Home; ไม่มี Crop หรือ Upload | To Do | Medium |
| TC-MOB-15 | ปฏิเสธ Gallery permission | FR-SCAN-01, NFR-08 | Android test device; permission ยังไม่อนุญาต | N/A | ตรวจ permission denied | ปฏิเสธ permission แล้วแตะเลือกรูป | แสดง permission guidance ตาม implementation; ไม่ crash/ไม่ upload | To Do | High |
| TC-MOB-16 | อนุญาต Gallery หลังปฏิเสธ | FR-SCAN-01, NFR-08 | เคยปฏิเสธ permission | server/tests/test1.png | ตรวจ permission recovery | อนุญาตผ่าน System Settings แล้วกลับมาเลือกรูป | เลือกภาพได้โดยไม่ติดตั้งใหม่ | To Do | Medium |
| TC-MOB-17 | ยืนยันภาพที่ครอบตัด | FR-SCAN-01 | เลือกรูปแล้วอยู่หน้า Crop | server/tests/test1.png | ตรวจ crop result | ปรับ crop area แล้วยืนยัน | Preview และ scan ใช้ path ภาพที่ crop แล้ว | To Do | High |
| TC-MOB-18 | ยกเลิก Cropper | FR-SCAN-01 | อยู่หน้า Crop | server/tests/test1.png | ตรวจ crop cancel | เปิด cropper แล้ว Cancel | ยังใช้ภาพก่อน crop; ไม่มี path ว่างหรือ crash | To Do | Medium |
| TC-MOB-19 | หมุนภาพจากหน้า Crop | FR-SCAN-01 | อยู่หน้า Crop; ภาพอ่านได้ | server/tests/test1.png | ตรวจ rotate transform | ใช้ control หมุนที่มีในหน้าจอ | ภาพหมุนจริงและ scan ใช้ไฟล์ที่หมุนแล้ว | To Do | Medium |
| TC-MOB-20 | Zoom และ Reset Preview | FR-SCAN-01 | อยู่หน้า Crop | server/tests/test1.png | ตรวจ zoom bounds/reset | กด zoom จนถึงขอบเขตแล้ว Reset | scale อยู่ในช่วง UI; Reset คืนขนาดปกติ | To Do | Low |
| TC-MOB-21 | เปลี่ยนภาพในหน้า Crop | FR-SCAN-01 | อยู่หน้า Crop; มีภาพใหม่ | server/tests/test1.png และ server/tests/test2.png | ตรวจ source image ใหม่ | เลือกภาพที่สอง | Preview ใช้ไฟล์ที่สอง; crop เก่าไม่ถูกนำมาใช้ | To Do | Medium |
| TC-MOB-22 | Back จาก Crop พร้อม confirmation | FR-SCAN-01 | อยู่หน้า Crop หลังเลือกรูป | server/tests/test1.png | ตรวจ discard dialog | กด Back แล้ว Cancel; ทำซ้ำแล้ว Confirm ออก | Cancel คงหน้าเดิม; Confirm ออก; ไม่เริ่ม scan | To Do | Medium |
| TC-MOB-23 | Scan โดยไม่ใส่ชื่อ | FR-SCAN-02 | authenticated; backend test พร้อม | server/tests/test1.png; scan name ว่าง | ตรวจ optional title | เริ่มวิเคราะห์โดยไม่กรอกชื่อ | ส่ง multipart file; ไม่ส่ง title ว่าง; ได้ scan ID จาก response จริง | To Do | High |
| TC-MOB-24 | Scan ด้วยชื่อที่กรอก | FR-SCAN-02 | authenticated; ภาพพร้อมส่ง | server/tests/test1.png; ชื่อที่กรอกใน test run | ตรวจ trim title | กรอกชื่อมีช่องว่างหัวท้ายแล้วเริ่ม scan | request ส่ง title หลัง trim; History ใช้ title จาก backend | To Do | Medium |
| TC-MOB-25 | Upload สำเร็จและเริ่ม polling | FR-SCAN-02, FR-SCAN-03 | backend/model test พร้อม | server/tests/test1.png; scan ID จาก API | ตรวจ multipart และสถานะแรก | เริ่ม scan แล้วดู Loading | multipart ถูกส่ง; ID จริงถูกใช้; queued/processing ตรง API | To Do | High |
| TC-MOB-26 | Upload network error | FR-SCAN-02 | ควบคุม network บนอุปกรณ์ทดสอบได้ | server/tests/test1.png | ตรวจ recovery | ตัด network ก่อนเริ่ม scan | แสดง localized error; ไม่มี success; คง context เมื่อ flow รองรับ retry | To Do | High |
| TC-MOB-27 | Upload ถูกปฏิเสธจาก server | FR-SCAN-02 | test backend คืน validation error | server/tests/test1.png; error response จาก test server | ตรวจ server error mapping | ส่งรูปใน test env ที่คืน error | แสดง error; ไม่สร้าง Scan ID/result ปลอม | To Do | High |
| TC-MOB-28 | Polling แสดง queued/processing และ progress | FR-SCAN-03 | มี scan ที่ยัง processing | scan ID จาก API ใน test environment | ตรวจ status mapping | เปิด Loading แล้วรอ polling | state/progress ตรง response; progress อยู่ในช่วง 0–100 | To Do | High |
| TC-MOB-29 | Polling recover หลัง transient network error | FR-SCAN-03 | scan processing; network ควบคุมได้ | scan ID จาก API | ตรวจ transient failure | ตัด network ชั่วคราวแล้วคืน network | polling ต่อและอ่าน status ใหม่; error ไม่ถูกตีเป็น completed | To Do | High |
| TC-MOB-30 | Scan completed เปิด Result | FR-SCAN-03, FR-ANALYSIS-04 | backend คืน completed | scan ID จาก API | ตรวจ completion navigation | รอ polling ได้ completed | เปิด Result ด้วย ID เดิม; data เทียบ API ได้ | To Do | High |
| TC-MOB-31 | Scan failed แสดง recovery | FR-SCAN-03 | มี task ที่ backend ระบุ failed | scan ID จาก test environment | ตรวจ terminal failure | รอ polling ได้ failed | แสดง failure/action; spinner หยุด; ไม่เปิด Result เป็น success | To Do | High |
| TC-MOB-32 | Scan timeout branch | FR-SCAN-03 | ใช้ automated test clock หรือ test backend; ไม่รอ timeout จริง | scam_image_mobile/test/features/scan/presentation/bloc/scan_bloc_test.dart | ตรวจ timeout/cleanup | เร่งเวลาใน test harness จน timeout | timer/active task ถูกหยุด; แสดง timeout recovery state | To Do | Medium |
| TC-MOB-33 | ยกเลิกการรอ scan | FR-SCAN-03 | มี task processing | scan ID จาก test environment | ตรวจ client-side cancel | เลือก Cancel และยืนยัน | แอปหยุด poll/ออกตาม UI; ไม่กล่าวว่า server ลบ task หากไม่มี API รองรับ | To Do | Medium |

### Result และ Heatmap

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
|---|---|---|---|---|---|---|---|---|---|
| TC-MOB-34 | Result แสดงค่าจาก API | FR-ANALYSIS-04, FR-XAI-01 | มี scan completed | scan ID จาก backend test environment | ตรวจ field mapping | เปิด Result แล้วเทียบ score/grade/breakdown กับ response | ค่าตรง API; ไม่มี evidence ที่ UI อนุมานเอง | To Do | High |
| TC-MOB-35 | Risk Grade Low boundaries 0 และ 39 | FR-ANALYSIS-04 | มี response fixture ควบคุม score | score 0 และ 39 ตาม FR-ANALYSIS-04 AC | ตรวจ Low boundaries | เปิด Result ของแต่ละ score | ทั้งสองแสดง Low ตาม risk authority กลาง | To Do | High |
| TC-MOB-36 | Risk Grade Medium boundaries 40 และ 69 | FR-ANALYSIS-04 | มี response fixture ควบคุม score | score 40 และ 69 ตาม FR-ANALYSIS-04 AC | ตรวจ Medium boundaries | เปิด Result ของแต่ละ score | ทั้งสองแสดง Medium ตาม risk authority กลาง | To Do | High |
| TC-MOB-37 | Risk Grade High boundaries 70 และ 100 | FR-ANALYSIS-04 | มี response fixture ควบคุม score | score 70 และ 100 ตาม FR-ANALYSIS-04 AC | ตรวจ High boundaries | เปิด Result ของแต่ละ score | ทั้งสองแสดง High ตาม risk authority กลาง | To Do | High |
| TC-MOB-38 | Partial evidence แสดง unavailable/ไม่มีข้อมูล | FR-ANALYSIS-01, FR-ANALYSIS-02, FR-ANALYSIS-03, FR-XAI-01 | response มี analysis field ว่างหรือ unavailable | response fixture ใน scam_image_mobile/test/features/result/presentation/screens/analysis_result_screen_test.dart | ตรวจสถานะ evidence | เปิด Result | แยก unavailable/ไม่พบ/ไม่มีข้อมูลตาม response; ไม่สร้าง score/tag | To Do | High |
| TC-MOB-39 | Source unavailable ไม่สรุปว่าปลอดภัย | FR-ANALYSIS-03 | source_status=unavailable | response fixture หรือ API response จาก test env | ตรวจ source fallback | เปิด Result เมื่อ source service ไม่พร้อม | แจ้ง unavailable; ไม่ตีความว่าไม่พบ source หรือปลอดภัย | To Do | High |
| TC-MOB-40 | แสดง manipulation_confidence ตามความหมาย | FR-ANALYSIS-02 | response มี manipulation_confidence | response จาก API/test fixture | ตรวจ copy/ค่า | เปิด visual analysis detail | สื่อความมั่นใจเรื่องการดัดแปลง; ไม่เรียก AI-generation probability | To Do | High |
| TC-MOB-41 | XAI pending แล้วรับ summary ภายหลัง | FR-XAI-01 | response แรก processing/summary ว่าง; response ถัดไปมี summary | scan ID จริงหรือ test fixture | ตรวจ Result polling | เปิด Result ขณะ pending แล้วรอ poll ถัดไป | แสดงกำลังสร้างโดยไม่กระพริบ loading; แสดง server summary เมื่อพร้อม | To Do | High |
| TC-MOB-42 | XAI summary ว่างเมื่อ terminal | FR-XAI-01 | status completed/failed และ summary ว่าง | fixture ใน scam_image_mobile/test/features/result/data/models/analysis_result_model_test.dart หรือ API response | ตรวจ terminal unavailable state | เปิด Result | แสดง unavailable; ไม่สร้างคำอธิบายจาก score | To Do | High |
| TC-MOB-43 | Result network error และ retry/back | FR-ANALYSIS-04 | มี scan ID; ควบคุม network ได้ | scan ID จาก API | ตรวจ error recovery | ตัด network ระหว่างโหลดแล้วใช้ action retry/back ที่ UI มี | แสดง error; retry สะท้อน response ใหม่หรือคง error ชัด; Back กลับต้นทาง | To Do | Medium |
| TC-MOB-44 | Heatmap URL จริง toggle/opacity/pan/zoom | FR-XAI-01 | heatmap URL เปิดได้ | heatmap_url จาก response จริง | ตรวจ overlay controls | เปิด Heatmap; toggle; ปรับ opacity; pan/zoom | ภาพมาจาก URL จริง; controls เปลี่ยน overlay และใช้งานได้ | To Do | High |
| TC-MOB-45 | Heatmap ไม่มี URL | FR-XAI-01 | ไม่มี heatmap_url หรือ asset เปิดไม่ได้ | scan ID ที่ API คืน | ตรวจ no-fabrication fallback | เปิด Heatmap | แสดง unavailable/error; ไม่มี overlay จำลอง | To Do | High |

### History

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
|---|---|---|---|---|---|---|---|---|---|
| TC-MOB-46 | Home recent history และ See All | FR-HISTORY-01 | มี history บน backend | รายการ scan ของบัญชีทดสอบใน staging | ตรวจ recent items | เปิด Home; แตะรายการและ See All | ข้อมูลมาจาก HistoryBloc; เปิด scan เดิม; See All ไป History | To Do | Medium |
| TC-MOB-47 | History loading และเรียงล่าสุดก่อน | FR-HISTORY-01 | authenticated; มีหลายรายการ | history จริงของบัญชีทดสอบ | ตรวจ order/thumbnail | เปิด History | loading แล้วรายการล่าสุดก่อน; thumbnail หรือ error placeholder | To Do | High |
| TC-MOB-48 | History empty และ error state | FR-HISTORY-01 | มีบัญชีว่างและ backend test ที่คืน error | บัญชีทดสอบไม่มี scans; error response จาก test env | แยก empty/error | เปิด History ในแต่ละเงื่อนไข | empty แสดง empty state; error แสดง recovery; สถานะไม่ปะปน | To Do | Medium |
| TC-MOB-49 | Refresh History | FR-HISTORY-01 | backend test พร้อม; มี scan ใหม่ | scan record จาก flow ก่อนหน้า | ตรวจ pull-to-refresh | refresh หลัง scan ใหม่ | รายการใหม่แสดงจาก server; indicator จบ | To Do | Medium |
| TC-MOB-50 | ค้นหาชื่อบางส่วนและไม่พบผล | FR-HISTORY-01 | มี scan ชื่อและไม่มีชื่อ | ชื่อจาก History จริงใน test env | ตรวจ search/local fallback | ค้นบางส่วนแล้วค้นคำที่ไม่มี | แสดง match เท่านั้น; no-match เป็น empty state; ไม่มี error | To Do | Medium |
| TC-MOB-51 | เปิด scan จาก History | FR-HISTORY-01 | มี scan completed | scan ID จากรายการจริง | ตรวจ navigation/data identity | แตะรายการ | เปิด route ที่กำหนดด้วย scan ID เดิม | To Do | High |
| TC-MOB-52 | ยกเลิกการลบ scan | FR-HISTORY-01 | มี scan ของบัญชีทดสอบ | scan ID จากรายการจริง | ตรวจ confirm cancel | แตะ Delete แล้ว Cancel | รายการยังอยู่; ไม่มี delete สำเร็จ | To Do | Medium |
| TC-MOB-53 | ลบ scan สำเร็จหลัง server ยืนยัน | FR-HISTORY-01 | มี disposable scan ใน isolated test env | scan ID จากรายการจริง | ตรวจ confirmed delete | ยืนยันลบแล้วเปิด History ใหม่ | รายการหายหลัง server ยืนยันและไม่กลับมา | To Do | High |
| TC-MOB-54 | Delete scan server error | FR-HISTORY-01 | test backend คืน error ตอน DELETE | scan ID จากรายการจริง | ป้องกัน optimistic success | จำลอง error แล้ว confirm delete | แสดง error; ไม่แสดง success/ลบถาวรจาก state | To Do | High |

### Scam Report

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
|---|---|---|---|---|---|---|---|---|---|
| TC-MOB-55 | Report tab เลือก scan ก่อนเปิด form | FR-HISTORY-02 | มี scan completed ใน History | scan ID/image URL จาก History จริง | ตรวจ top-level selector | เปิด Report tab; เลือก scan | form เปิดหลังเลือกและผูก ID/image เดียวกัน | To Do | High |
| TC-MOB-56 | เปิด Report จาก History/Result | FR-HISTORY-02 | เปิด scan ผ่าน History หรือ Result | scan ID จาก route จริง | ตรวจ context handoff | เลือก action Report | form เลือก scan ปัจจุบันไว้ | To Do | High |
| TC-MOB-57 | เปลี่ยน scan ใน Report | FR-HISTORY-02 | อยู่ form; มี scan อื่น | scan IDs จาก History จริง | ตรวจ change scan | เปลี่ยนแล้วเลือกอีกรายการ | image preview และ reference เปลี่ยนตาม scan ใหม่ | To Do | Medium |
| TC-MOB-58 | Submit Report โดยไม่มี scan | FR-HISTORY-02 | เปิด top-level Report ยังไม่เลือก scan | N/A | ตรวจ required scan gate | ลอง submit | คงอยู่ selector; ไม่มี request | To Do | High |
| TC-MOB-59 | Report validation ของ Other/details | FR-HISTORY-02 | เลือก scan แล้วเปิด form | scan ID จริง; category ที่ UI แสดง | ตรวจ required custom fields/details | ละ field ที่จำเป็นแล้ว submit; เติมค่าตาม form แล้วลองใหม่ | แสดง validation; ส่ง request เฉพาะเมื่อผ่านจริง | To Do | High |
| TC-MOB-60 | ส่ง Scam Report สำเร็จ | FR-HISTORY-02 | scan เป็นของ user เดียวกัน; backend test พร้อม | scan ID จริง; input ตาม FR-HISTORY-02 AC-1 | ตรวจ success state | กรอก form แล้ว submit | success หลัง server ตอบรับ; report ผูก scan ID เดิม | To Do | High |
| TC-MOB-61 | Report network/auth/server error | FR-HISTORY-02 | test backend คืน network/401/5xx | scan ID จริง; input จาก form | ตรวจ error mapping | submit แล้วรับ error | ไม่มี success; แจ้ง error; รักษาข้อมูลให้แก้หรือส่งใหม่ | To Do | High |

### Settings, Profile และ Privacy

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
|---|---|---|---|---|---|---|---|---|---|
| TC-MOB-62 | เปลี่ยน theme และตรวจหลัง restart | NFR-06 | Settings; local storage ใช้ได้ | N/A | ตรวจ Light/Dark/System persistence | เปลี่ยน mode แล้วปิดเปิดแอป | theme เปลี่ยนและคืนค่าที่บันทึก | To Do | Medium |
| TC-MOB-63 | เปลี่ยน Thai/English และตรวจหลัง restart | NFR-06 | Settings; storage ใช้ได้ | N/A | ตรวจ localization persistence | เปลี่ยนภาษาไปกลับแล้ว restart | app-generated copy เปลี่ยนภาษาและค่าคงอยู่ | To Do | Medium |
| TC-MOB-64 | Settings load failure ใช้ fallback | NFR-06 | ทำให้ local preference read fail ใน test harness | fixture ใน scam_image_mobile/test/features/settings/data/datasources/settings_local_datasource_test.dart | ตรวจ fallback | โหลด Settings เมื่อ storage error | ใช้ state เริ่มต้นตาม code; ไม่ crash | To Do | Low |
| TC-MOB-65 | Clear Cache แล้วยกเลิก | NFR-06 | มี cache บนอุปกรณ์ทดสอบ | ขนาด cache ที่แอปรายงานจริง | ตรวจ cancel | เปิด dialog แล้ว Cancel | cache ไม่ถูกลบและขนาดไม่เปลี่ยน | To Do | Medium |
| TC-MOB-66 | Clear Cache ไม่ลบ server History | FR-HISTORY-01, NFR-06 | มี cache และ server history | History จริงจาก test account | ตรวจขอบเขต clear | ยืนยัน clear cache แล้ว reload History | cache size refresh; server history ยังอยู่และโหลดกลับได้ | To Do | High |
| TC-MOB-67 | Profile แสดงข้อมูล Auth/API จริง | FR-AUTH-02 | authenticated; current-user endpoint พร้อม | profile จากบัญชีทดสอบจริงใน staging | ตรวจ name/email/avatar/fallback | เปิด Profile | แสดงค่าจาก API; fallback เฉพาะ field ว่าง | To Do | Medium |
| TC-MOB-68 | Profile action ที่ยังไม่รองรับ | NFR-06 | เปิด Profile | N/A | ตรวจ unsupported feedback | แตะ action ที่ code ระบุ coming soon | แจ้ง unavailable; ไม่แสดง success หรือเปลี่ยนข้อมูลเอง | To Do | Medium |
| TC-MOB-69 | ยกเลิก Delete Account | FR-AUTH-04 | authenticated; เปิด Profile | N/A | ตรวจ cancel destructive action | เปิด confirmation แล้ว Cancel | บัญชี/session คงอยู่; ไม่มี delete request | To Do | High |
| TC-MOB-70 | Delete Account ถูกปฏิเสธ | FR-AUTH-04 | บัญชีทดสอบ; backend ปฏิเสธคำขอ | credential จาก secret store; ห้ามบันทึกใน report | ตรวจ failure state | ส่ง password ที่ test env ตั้งให้ไม่ผ่าน | แสดง error; ไม่แสดง deletion success | To Do | High |
| TC-MOB-71 | Delete Account สำเร็จ | FR-AUTH-04 | disposable user ใน isolated environment เท่านั้น | บัญชี disposable ที่สร้างตาม FR-AUTH-01 | ตรวจ end state | ยืนยัน deletion ด้วย password ถูกต้อง | server ยืนยันก่อนล้าง session/กลับ Login; user นี้ login ไม่ได้ | To Do | High |
| TC-MOB-72 | Privacy screen โหลด consent | FR-PDPA-01 | authenticated; consent มีใน test env | consent จากบัญชีทดสอบจริง | ตรวจ loading/success/error | เปิด Privacy & Consent | แสดงค่าจริง; error/fallback ไม่เดาค่า consent | To Do | High |
| TC-MOB-73 | เปลี่ยน Research Consent | FR-PDPA-01 | research consent control ใช้ได้ | บัญชีและค่าปัจจุบันจาก test environment | ตรวจ opt-in/opt-out | เปลี่ยนค่าแล้วเปิดหน้าเดิมอีกครั้ง | แสดงค่าที่ repository/server ยืนยัน; system consent ไม่ถูกปิดเงียบ | To Do | High |
| TC-MOB-74 | Privacy Export แจ้ง unavailable | FR-PDPA-01 | ใช้ backend/config ที่ export endpoint ยังไม่รองรับ | N/A | ป้องกัน success เท็จ | แตะ Export Data | แจ้ง unavailable; ไม่มีไฟล์หรือ success ปลอม | To Do | High |
| TC-MOB-75 | Delete Usage Data ไม่ลบบัญชีแทน | FR-PDPA-01 | เปิด Privacy screen | N/A | ตรวจ confirm/cancel | Cancel; ทำซ้ำแล้ว Confirm | Cancel ไม่เปลี่ยน state; Confirm แจ้ง unavailable; account ไม่ถูกลบ | To Do | High |

### In-app Notifications

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
|---|---|---|---|---|---|---|---|---|---|
| TC-MOB-76 | สร้าง notification จาก terminal scan history | FR-SCAN-03, NFR-06 | History มี completed, failed และ non-terminal scans | scan IDs/statuses จาก test account จริง | ตรวจ in-app source ไม่ใช่ FCM | เปิด Notifications หลัง History load | แสดง completed/failed ตาม logic; ไม่อ้างว่าเป็น push notification | To Do | Medium |
| TC-MOB-77 | จัดกลุ่ม notification ตามวัน | NFR-06 | มี records จากหลายวันใน test env | created_at จาก server records จริง | ตรวจ grouping | เปิด Notifications | Today/Yesterday/earlier ตรง timestamp; future time ไม่เกินเวลาปัจจุบัน | To Do | Low |
| TC-MOB-78 | Mark as read และ unread count | NFR-06 | มี notification unread | notification ID จากรายการจริง | ตรวจ read state | แตะรายการแล้วดู count | รายการถูกอ่านและ unread count ลดตามจริง | To Do | Medium |
| TC-MOB-79 | Dismiss แล้ว sync History ซ้ำ | NFR-06 | มี notification จาก history | notification ID/scan ID จริง | ตรวจ dismiss ใน session | dismiss แล้ว trigger history sync | รายการที่ dismiss ไม่กลับมาใน session; รายการอื่นคงอยู่ | To Do | Low |
| TC-MOB-80 | Clear All ไม่ลบ scan history | NFR-06, FR-HISTORY-01 | มี notifications จาก History | scan IDs จริง | ตรวจ clear scope | กด Clear All แล้วเปิด History | notifications ว่าง; scans ยังอยู่ | To Do | Medium |
| TC-MOB-81 | Notifications empty state และเปิดรายการ | NFR-06, FR-HISTORY-01 | เตรียมบัญชีว่างและบัญชีที่มีรายการ | บัญชีทดสอบว่าง; scan ID จริงสำหรับกรณีมีรายการ | ตรวจ empty/back/tap | เปิดทั้งสองสถานะ; แตะ notification ที่มี scanId | empty state เมื่อว่าง; Back ไป Home; tap เปิด scan ID เดิม | To Do | Medium |

### Routing, Adaptivity และ Accessibility

| Test Case ID | Test Case name | Requirement ID | Preconditions | Test Data | Description | Test Steps | Expected Results | Actual Result / Status | Priority |
|---|---|---|---|---|---|---|---|---|---|
| TC-MOB-82 | Auth guard ของ protected route | FR-AUTH-02, NFR-08 | ไม่มี valid session | route จาก scam_image_mobile/lib/core/router/app_router.dart | ตรวจ redirect | เปิด protected route โดยตรงใน test | redirect ไป Login/onboarding ตาม state; ไม่เห็นข้อมูล protected | To Do | High |
| TC-MOB-83 | Back ใน Crop/Loading/Result/Heatmap/Detail | NFR-08 | เข้าแต่ละหน้าผ่าน flow จริง | server/tests/test1.png; scan ID จาก API | ตรวจ route stack | ใช้ Android Back/toolbar Back | กลับหน้าต้นทางตาม stack; ไม่มีหน้าว่างหรือ bypass auth | To Do | Medium |
| TC-MOB-84 | NavigationBar/Rail ตาม width | NFR-08 | emulator/widget viewport matrix | 390x844 และ 840x1180 จาก redesign matrix | ตรวจ responsive shell | เปิด Main shell ในแต่ละ viewport | compact ใช้ NavigationBar; expanded ใช้ NavigationRail; ไม่ล้นแนวนอน | To Do | Medium |
| TC-MOB-85 | ภาษาและ theme บนหน้าหลัก | NFR-06, NFR-08 | Settings ใช้งานได้ | N/A | ตรวจ Home/History/Result/Report/Settings | วน Thai/English และ Light/Dark/System | copy เปลี่ยนตามภาษา; risk colors/labels มีความหมายเดิมข้าม theme | To Do | Medium |
| TC-MOB-86 | Text scale และ TalkBack ใน key flows | NFR-06, NFR-08 | Android device; TalkBack เปิดโดยผู้ทดสอบ | text scale 1.0, 1.3, 1.5; viewport 390x844 | ตรวจ semantics/focus/overflow | ไล่ Home, History, Result, Heatmap, Report, Settings ด้วย TalkBack | controls มี label/state; critical content ไม่ถูกตัดที่ 1.3; actions เข้าถึงได้ที่ 1.5 | To Do | High |
| TC-MOB-87 | Reduced Motion และ touch targets | NFR-06, NFR-08 | Android device หรือ widget environment | MediaQuery.disableAnimations=true; controls ที่หน้าจอแสดง | ตรวจ motion/touch | ปิด animation แล้วลอง controls สำคัญ | animation ซ้ำลดตาม code; critical targets อย่างน้อย 48dp | To Do | Medium |
