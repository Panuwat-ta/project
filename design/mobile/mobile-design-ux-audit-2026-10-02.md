# ScamGuard Mobile — Final Product Integrity, UX และ Localization Audit

วันที่ตรวจ: 2026-10-02
GitHub Issue: [#76](https://github.com/Panuwat-ta/project/issues/76)
Baseline: `mobile-design-ux-audit-2026-09-20.md`
Implementation reference: `mobile-redesign-delivery-2026-09-20.md`

## ขอบเขตและหลักฐาน

- ตรวจ source ปัจจุบันของ Result, Heatmap, History, Report, Auth, Onboarding, Profile, Privacy, Notifications และ Settings พร้อมเทียบ checklist และ baseline audit วันที่ 20 กันยายน
- เพิ่ม regression tests สำหรับผลภาพสามสถานะ, ป้ายหลักฐาน, label ของประวัติ และ localization ของ Auth/Onboarding
- ผลล่าสุดหลังแก้ independent-review findings: `flutter test --coverage --branch-coverage --reporter=failures-only` ผ่าน 522/522; line coverage 5,209/5,718 (91.10%); branch coverage 1,286/1,549 (83.02%)
- รัน `flutter analyze lib test`: ไม่พบ issue; `git -c core.whitespace=cr-at-eol diff --check` ผ่าน โดยคง CRLF เดิมของไฟล์ Splash
- อุปกรณ์ RMX3370 ที่เชื่อมต่อไม่มี ScamGuard ติดตั้งอยู่ จึงไม่มีการอ้างผล visual/runtime บนอุปกรณ์จากรอบนี้ และไม่ได้เปลี่ยนการตั้งค่าระบบ

## Before / After เทียบ baseline

| ประเด็นจาก baseline 20 ก.ย. | หลักฐานสถานะปัจจุบัน | ผล |
|---|---|---|
| Heatmap สร้าง overlay จำลองเมื่อไม่มีข้อมูล | `heatmap_viewer_screen.dart` แสดง unavailable state เมื่อไม่มี Heatmap; Result และ History แยกป้าย Heatmap / ภาพต้นฉบับ / ไม่มีภาพ จาก URL ที่มีจริง | แก้ false Heatmap badge เพิ่มในรอบนี้; ไม่มีการอนุมาน Heatmap จากภาพต้นฉบับ |
| History สร้าง forensic tags จาก risk grade | `history_screen.dart` ไม่สร้าง tags `pixel_edge`, `metadata_conflict`, `light_filter` จาก risk grade | แก้แล้วใน redesign ก่อนหน้า |
| Result มีแถบที่ดูเหมือน slider แต่ลากไม่ได้ | ไม่มี faux `FractionallySizedBox` slider ใน Result | แก้แล้วใน redesign ก่อนหน้า |
| สี Risk และ navigation ไม่เป็น authority เดียว | `RiskLevelHelper` เป็นตัว map Low/Medium/High/Unknown; Shell ใช้ Material 3 NavigationBar/Rail และ router | แก้แล้วใน redesign ก่อนหน้า |
| Scan name บังคับและ error พาผู้ใช้ออกจากบริบท | ชื่อสแกนเป็น optional; Analysis Loading มี retry/edit/history recovery | แก้แล้วใน redesign ก่อนหน้า |
| ประวัติแสดงคำอธิบายที่อ้างความหมายเกินข้อมูล | เปลี่ยน `Accuracy`, `First Detected`, `Recurring Reports` เป็น Text risk score, Analysis date และ Source verification details ทั้ง TH/EN | แก้ในรอบนี้ |
| Auth/Onboarding/Splash English มีข้อความไทยฝัง | AuthBloc ส่ง localization key; Login/Register แปล error ที่ UI; Onboarding และ Splash ใช้ dictionary TH/EN | แก้ในรอบนี้ |

## Findings ที่แก้ในรอบนี้

1. **ป้าย Heatmap ที่ไม่ตรงกับภาพจริง — ปิดแล้ว**
   Result และ History เคยติดป้าย `HEATMAP` แม้มีเพียง `imageUrl` หรือไม่มีภาพ ปัจจุบันเลือก URL ที่ไม่ว่างก่อน และแสดง `HEATMAP`, `Source image`/`ภาพต้นฉบับ` หรือ `No preview image available`/`ไม่มีภาพตัวอย่าง` ตามสถานะจริง ดู `analysis_result_screen.dart:596-780` และ `history_detail_screen.dart:525-649`.

2. **ชื่อข้อมูลประวัติไม่ตรงกับค่าที่นำมาแสดง — ปิดแล้ว**
   `textFactor.score` เป็น risk score ไม่ใช่ accuracy; `createdAt` เป็นวันวิเคราะห์ ไม่ใช่วันตรวจพบครั้งแรก; รายละเอียด source ไม่ใช่จำนวนรายงานซ้ำ เปลี่ยน label ทั้งไทยและอังกฤษใน `app_translations.dart`.

3. **English copy ใน Auth/Onboarding — ปิดแล้วในส่วนที่ตรวจพบ**
   AuthBloc ส่ง key สำหรับ credential, network, duplicate email และ generic error; Login/Register แปลก่อนแสดง SnackBar. ข้อความ Onboarding, consent และปุ่มเริ่มใช้ dictionary ที่มีทั้งสองภาษา.

## Impeccable native audit

ตรวจตาม native criteria ใน Impeccable: product status/evidence labels, interactive affordance, theme-aware surfaces, empty/error states, accessible component semantics, adaptive navigation, touch-target debt และ visual-token consistency. หลักฐานจาก current source/checklist: Material 3 NavigationBar/Rail อยู่ใน Shell, faux slider และ fake Heatmap ไม่อยู่ใน Result/Heatmap flow, unavailable state มี copy ชัด, core non-auth surfaces ใช้ semantic theme/risk helper, และ adaptive widgets รองรับ compact/expanded layout.

ผลตรวจรอบนี้เป็น source + widget-test audit ไม่ใช่ device visual certification. Native device QA, TalkBack, rotation และ text-scale matrix ยังเป็น checklist งานแยกใน §4. ไม่ใช้คะแนนตนเองเป็น verdict เดียว.

## Residual และเหตุผล

- **ยังไม่ได้ runtime QA บนอุปกรณ์จริงหรือ staging backend**: เครื่องที่เชื่อมต่อไม่มี app ติดตั้ง; ผล widget tests ไม่ยืนยัน native rendering, TalkBack หรือ end-to-end กับ production API. งานเหล่านี้อยู่ใน Issues #77 และ #79 และไม่ใช้ audit นี้เป็น production sign-off.

## Independent `agy` review และ disposition

สามรอบแรกหยุดเพราะกำหนด timeout 180s/45s/60s. รอบถัดไปใช้ `--print-timeout 0s --output-format stream-json`, model `gemini-3.8-flash-low`, mode `plan`, sandbox และได้ `SUCCESS` ใน 205.404684316 วินาที. Reviewer ตรวจ commit `bd98db73`; conversation `d2969b67-a3a8-48b9-837d-51aa87ab86dc`. ผล review เก็บที่ [mobile-independent-agy-review-2026-10-02.md](mobile-independent-agy-review-2026-10-02.md). ตารางนี้เป็นคำตัดสินหลังตรวจข้อเสนอของ reviewer กับ source จริง:

| Finding | ผลตรวจและการแก้ |
|---|---|
| คำสะกดผิด/ข้อความไทยใน flat result adapter | ยืนยัน; แก้คำว่า “ความมั่นใจ”, model เก็บ confidence เป็นตัวเลขแยกจาก narrative details และ UI แปล label ตามภาษา ไม่สร้างรายละเอียดภาษาไทยใน data layer |
| สี confidence อิง visual score อีกค่า | ยืนยัน; metric ใช้สีข้อความ neutral และ visual-risk score ใช้ risk helper ของตัวเอง; regression test confidence 10% + visual 85% ผ่าน |
| History Detail นิยาม risk colors ซ้ำ | ยืนยัน; `_getRiskColor` เรียก `RiskLevelHelper.toColor` รวมถึง Unknown |
| คีย์ Safe/accuracy/source ที่ไม่ใช้ | ยืนยันว่าไม่มี call site ด้วย `rg`; ลบ `safe`, `result_safe`, `result_ocr_accuracy`, `result_source_found`, `result_source_reports` ทั้ง TH/EN; dictionary parity test ผ่าน |
| Preview tap กับ Heatmap button ต่างกัน | ยอมรับเป็น interaction ปัจจุบัน: History มีปุ่มชัดเจนและ Viewer รองรับภาพต้นฉบับ/สถานะไม่มี Heatmap; ไม่มีการสร้าง overlay ปลอม จึงไม่จัดเป็น functional defect |
| TaskId/ScanId อาจต่างกัน | ยังเป็นสมมติฐาน; canonical `ScanResponse.id` เป็น UUID เดียวและ adapter map ทั้งสอง field จาก `id`; staging/API contract QA อยู่ Issue #79 |

ตรวจเพิ่มเองพบว่า Result visual card แสดง fallback `0%` เมื่อไม่มี visual factor; เปลี่ยนเป็น unavailable label และ neutral information icon. เมื่อมี confidence จะแสดง metric แบบ localized แยกจาก factor details. Regression tests ตรวจว่า absent factor ไม่แสดง `0%` และ confidence คงค่าจริง.

## ข้อสรุป

Source audit, independent review และ automated regression checks เสร็จแล้ว. Confirmed findings ที่แก้ได้ปิดแล้ว; hypotheses และ native/staging verification มีหลักฐานกับงานติดตามกำกับ. Test suite และ coverage gate ผ่าน จึงครบ acceptance ของ Issue #76 ในขอบเขต audit นี้.

GitHub Issue #76 ตรวจยืนยันเป็น CLOSED เมื่อ 2026-10-02 06:18 +07.
