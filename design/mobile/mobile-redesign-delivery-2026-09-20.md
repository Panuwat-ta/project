# ScamGuard Mobile — Redesign Delivery

วันที่: 20 กันยายน 2026
อ้างอิงแผน: `mobile-redesign-plan-2026-09-20.md`
อ้างอิง baseline: `mobile-design-ux-audit-2026-09-20.md`

## 1. สรุปขอบเขตที่ทำจริง

รอบนี้ปรับ Mobile ไปทาง Calm Forensic Utility โดยเน้นความถูกต้องของ evidence ก่อน visual polish และไม่ได้เปลี่ยน AI scoring algorithm หรือ backend schema

งานหลักที่เสร็จแล้ว:
- ลบ simulated heatmap fallback และ forensic tag ที่ derive จาก risk grade
- ลบ faux slider ใน Result และแยก finding / unavailable ให้ชัด
- scan name ไม่ block การเริ่มวิเคราะห์ และ scan error มี in-place recovery
- Report top-level route เลือก completed scan จาก History ก่อนเข้า form
- primary navigation ใช้ router authority เดียวผ่าน `MainNavigationShell`
- compact/medium ใช้ Material 3 `NavigationBar`; expanded `>=840px` ใช้ `NavigationRail`
- เพิ่ม `AdaptiveContent` และ max width สำหรับ Home, Settings, History, Result และ Report
- รวม semantic colors/radius/typography ให้ใช้ authority กลางมากขึ้น
- ปรับ localization TH/EN ของ non-auth presentation และ app-generated errors
- เพิ่ม semantics, reduced-motion test และ touch target 48×48 สำหรับ core consent interaction

## 2. Product integrity

ผลตรวจ source/test หลัง implementation:
- missing `heatmapUrl` ไม่สร้าง anomaly overlay จำลอง
- History ไม่สร้าง `pixel_edge`, `metadata_conflict`, `light_filter` หรือ evidence tag จาก grade
- Result ไม่แสดง control ที่ดูเหมือน slider แต่ลากไม่ได้
- source/visual/XAI ที่ backend ไม่ได้ส่ง ไม่ถูกอนุมานจากคะแนนฝั่ง UI
- summary ที่ไม่มี server/XAI content ไม่ถูกสร้างเป็นคำสรุปความเสี่ยงเอง
## 3. Design-system / navigation metrics เทียบ baseline

| Signal | Baseline audit | Final state | หมายเหตุ |
|---|---:|---:|---|
| raw `Color(0x...)` นอก theme | 179 | 0 ใน non-auth / 75 ใน `auth/**` | auth เป็น implementation deny scope รอบนี้ |
| numeric `BorderRadius.circular(...)` นอก theme | 120 | 8 ใน non-auth / 29 ใน `auth/**` | non-auth ต่ำกว่าเป้าหมาย `<20` |
| `Semantics(...)` | 0 | 8 ใน non-auth | เพิ่ม semantic coverage ให้ข้อมูลสำคัญ |
| `semanticLabel:` | 8 | 7 ใน non-auth + 1 ใน auth | ใช้ร่วมกับ Semantics |
| `MaterialTapTargetSize.shrinkWrap` | 6 | 0 ใน non-auth / 3 ใน auth | core consent target ปรับเป็น 48×48 |
| Material 3 `NavigationBar` | 0 | 1 | primary navigation compact/medium |
| `NavigationRail` | 0 | 1 | expanded layout |
| `BottomNavigationBar` | 1 | 0 | implementation เก่าถูก retire |

`SystemNavigator.pop()` ยังมี 1 occurrence ใน legacy `features/auth/presentation/screens/main_shell.dart`; active router ใช้ `ShellRoute -> MainNavigationShell` จาก `core/router/app_router.dart` และไม่ได้อ้าง legacy shell นี้

## 4. Adaptivity verification

Automated viewport matrix ที่ผ่าน:
- 360×800, 390×844, 412×915
- 600×960
- 840×1180
- text scale 1.3 ครบ matrix
- 390×844 ที่ text scale 1.5 เพิ่มอีกเคส

Content width authority:
- Home / Settings: 720px
- History / Result: 840px
- Report selector / form: 600px

## 5. Final automated verification

- `flutter analyze` → `No issues found`
- `flutter test` → 368/368 passed
- `flutter test --coverage` → 368/368 passed (runner completion 00:19)
- final line coverage → **2908/5637 = 51.59%**
- `dart fix --dry-run` → `Nothing to fix!`
- `git diff --check` → PASS
- `git diff --cached --check` → PASS
- `flutter build apk --debug` → PASS, สร้าง `build/app/outputs/flutter-apk/app-debug.apk`

Coverage ของส่วน redesign สำคัญ:
- MainNavigationShell 90.00%
- AdaptiveContent 100.00%
- RiskBadge 100.00%
- AnalysisStepTile 87.14%
- Analysis Result 79.06%
- Heatmap Viewer 89.58%
- Report Screen 74.07%
- NotificationsCubit 97.92%

ข้อจำกัด: NFR-09 ใน wiki ระบุ branch coverage ≥80% บน CI แต่ผลที่วัดรอบนี้เป็น line coverage 51.59% จาก lcov จึงยังไม่ถือว่าผ่าน coverage target ของ NFR-09

## 6. Physical Android runtime gate

อุปกรณ์จริง: RMX3370, Android 13 (API 33)
- final debug APK ติดตั้งและเปิดผ่าน `flutter run`
- `flutter run` ถูกเปิดค้างไว้สำหรับ runtime log หลังส่งมอบ
- cold debug launch พบ skipped frames 166 และ 50 เฟรม; เป็นหลักฐานว่าควร profile startup เพิ่มใน profile/release mode ก่อนสรุป performance production
- runtime checks ก่อนหน้าไม่พบ `FlutterError`, `RenderFlex overflow`, `Unhandled Exception` หรือ `FATAL EXCEPTION`

## 7. Impeccable 4.1.3 native audit หลัง implementation

ใช้กรอบ `audit.native.md` + `android.md` ตรวจจาก source, automated tests และ physical-device evidence; ไม่ใช้ `detect.mjs` เป็นหลักฐานเพราะ Impeccable ระบุว่า web detector ไม่ใช้กับ native app

| Dimension | Baseline | Final self-audit | หลักฐาน final |
|---|---:|---:|---|
| Accessibility | 2/4 | 3/4 | เพิ่ม Semantics, 48dp core target, text-scale tests; ยังไม่ได้ manual TalkBack traversal |
| Performance | 3/4 | 2/4 | list/cache ใช้ได้ แต่ debug cold start พบ skipped frames; ยังไม่มี profile/release measurement |
| Appearance & Theming | 2/4 | 3/4 | non-auth raw hex = 0, radius drift = 8; `auth/**` ยังอยู่นอก scope |
| Platform Conformance | 2/4 | 3/4 | M3 NavigationBar/Rail + active router Back flow; manifest ยังมี predictive Back warning |
| Adaptivity | 1/4 | 3/4 | viewport matrix + NavigationRail; ยังไม่ได้ physical tablet/rotation/foldable gate |
| **รวม** | **10/20** | **14/20** | ใช้เป็น supporting audit ไม่ใช่ final product score |

การเปลี่ยนจาก baseline สะท้อน improvement ที่ตรวจสอบได้ แต่ไม่ได้ใช้คะแนนนี้แทน test/runtime evidence

## 8. Known release gaps / deferred items

1. **Security — debug Authorization header logging**
   - `core/network/dio_client.dart` ใช้ `LogInterceptor(request: false, responseBody: false)` แต่ runtime debug log ยังพิมพ์ request headers รวม Authorization
   - ไม่บันทึก token ค่าใดลงเอกสารนี้
   - ยังไม่แก้ในรอบนี้เพราะเป็น security-gated change ที่ต้องอนุมัติแยก
2. **Predictive Back manifest warning**
   - Android runtime เคยเตือนว่า `android:enableOnBackInvokedCallback="true"` ยังไม่ได้เปิดใน application manifest
   - active Flutter navigation ไม่ intercept root Back แบบเก่าแล้ว แต่ manifest config ยังควรตรวจ/ทดสอบแยก
3. **Auth presentation scope**
   - `features/auth/**` ไม่ถูก polish/refactor ใน implementation loop นี้ จึงยังมี token/touch/back legacy debt บางส่วน
4. **Manual native QA ยังไม่ครบทุก mode**
   - ยังไม่ได้เปลี่ยน system font scale/TalkBack/rotation บนมือถือจริงของผู้ใช้ เพราะไม่ควรเปลี่ยน device settings โดยไม่ได้รับอนุญาต
   - physical tablet/foldable ไม่ได้ต่ออยู่ใน environment รอบนี้
5. **Coverage gap**
   - final line coverage 51.59%; ยังต่ำกว่า NFR-09 branch coverage target ≥80%
6. **Server capability gaps ที่ไม่ใช่ Mobile defect**
   - privacy export ยังไม่มี endpoint ที่รองรับ
   - delete usage data ยังไม่มี endpoint ที่รองรับ
   - forgot password และ social login ยังไม่มี backend flow
   - profile update / password update ยังไม่มี backend route ที่ Mobile เรียกได้
   - true server-side scan cancellation ยังไม่มี endpoint

## 9. Independent `agy` review

Independent `agy` ถูกเรียกแบบ read-only/sandbox หลัง implementation โดยสองรอบแรก timeout ระหว่าง review จึงไม่นำ partial output มาใช้เป็นผลสรุป

รอบที่จำกัดเฉพาะไฟล์ redesign หลักสำเร็จและรายงานว่า **ไม่มี Blocking** พร้อมชี้ 2 Important + 4 Minor ได้แก่ CTA “ตรวจภาพอื่น” ไป History, decorative Report placeholder, radius token, deprecated Heatmap zoom/safe-area, semantic danger token และ legacy translation keys

การตรวจและแก้ตาม finding:
- เปลี่ยน CTA “ตรวจภาพอื่น” ไป `/main/home`
- ลด Report placeholder เหลือ icon เดียว
- ใช้ `AppRadius` กับ filter sheet
- เปลี่ยน Heatmap zoom จาก deprecated `matrix.scale` และใช้ `SafeArea` แทน bottom padding คงที่
- ใช้ semantic danger token แทน `Colors.red`
- legacy heuristic tag keys ที่เลิกใช้ถูกลบแล้ว

Post-fix `agy` pass ยืนยันจุดข้างต้นถูกปิดและยังไม่มี Blocking แต่ชี้ residual semantic-surface usage, status comparison และ heatmap navigation เมื่อไม่มี artifact; ทั้งสามจุดที่ยืนยันจาก source ถูกแก้ต่อ ส่วนข้อเสนอให้ลบ `history_*` text keys ถูกตรวจพบว่าเป็น false positive เพราะ key เหล่านั้นยังถูกใช้ใน `history_detail_screen.dart` จึงไม่ลบ

ตาม bounded-review rule ไม่วน agent review เพิ่มหลัง residual patch; final correctness ยืนยันด้วย analyzer, full tests, coverage tests, build และ runtime gate แทน

## 10. Delivery state

Mobile redesign implementation หลักและ automated regression gates ผ่านตามหลักฐานข้างต้น แต่ยังไม่ควรเรียกว่า release-complete 100% จนกว่าจะปิด security logging, predictive Back config, manual accessibility/device gate และ coverage target ที่ค้างอยู่
