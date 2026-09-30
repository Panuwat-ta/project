# ScamGuard Mobile — Design / UX / UI / AI-Slop Audit

วันที่ตรวจ: 20 กันยายน 2026
ขอบเขต: `scam_image_mobile` (Flutter Android), เอกสารออกแบบ, และหน้าจอจริงบน RMX3370
สถานะ: Audit only — ยังไม่มีการแก้ UI จากรายงานฉบับนี้

## 1. Method

การตรวจใช้การเทียบหลักฐาน 4 ชั้น ไม่ยึดคำตอบจาก agent ใด agent หนึ่ง:

1. **Self review** — อ่าน source จริง, design docs, wiki และตรวจหน้าจอจริงจากเครื่อง Android
2. **Impeccable 4.1.3** — ใช้กรอบ `critique`, `audit.native`, `android`, `operate`
3. **agy Design/UX review** — independent review เน้น hierarchy, IA, UX, design specificity และ AI-slop
4. **agy Native audit** — independent review เน้น Android, accessibility, theming, adaptivity และ platform conformance

เอกสารอ้างอิงหลัก:
- `.agents/PRODUCT.md`
- `wiki/architecture/mobile-design.md`
- `design/mobile/design.md`
- `design/image/scam_guard_ui_ux_design/vigilance_mobile/DESIGN.md`
- `.agents/skills/impeccable/reference/critique.md`
- `.agents/skills/impeccable/reference/audit.native.md`
- `.agents/skills/impeccable/reference/android.md`
- `.agents/skills/impeccable/reference/operate.md`

หน้าจอจริงที่ตรวจจากอุปกรณ์ `RMX3370 (1080x2400)` ได้แก่ Home, History, Report และ Settings ใน Light mode รวมถึงหน้าจอ Result/Loading ที่ตรวจจาก runtime ก่อนหน้าในรอบเดียวกัน

ข้อจำกัด: การสั่ง `font_scale=1.3` ผ่าน ADB บนอุปกรณ์จริงถูก Android ปฏิเสธด้วย `WRITE_SETTINGS`; จึงประเมิน large text จาก source และจะต้องยืนยันซ้ำบน emulator/อุปกรณ์ที่อนุญาตในรอบ validation

## 2. Executive verdict

**Design specificity:** ปานกลาง — โครงสร้างผลิตภัณฑ์เริ่มมีความเฉพาะของ Scam/Image Forensics แต่ visual grammar ยังใกล้เคียง template ของ security/fintech utility มากเกินไป: โล่, cyan accent, rounded cards, icon-in-tinted-square, soft shadow และ pulse animation ถูกใช้เป็นภาษาหลักแทน “หลักฐานที่ตรวจพบจริง”

**ปัญหาใหญ่ที่สุดไม่ใช่ความสวย แต่คือความน่าเชื่อถือของข้อมูลใน UI.** มีอย่างน้อย 2 จุดที่ UI สร้าง evidence ที่ไม่ได้มาจาก backend ได้แก่ fallback Heatmap และแท็ก forensic ใน History ซึ่งไม่ควรเกิดในผลิตภัณฑ์ที่ตัดสินความเสี่ยงของการหลอกลวง

**ทิศทางที่เหมาะสม:** เปลี่ยนจาก “Cyber Security Dashboard” ไปเป็น **Calm Forensic Utility** — ลดของตกแต่ง, เพิ่มความชัดของ evidence, ใช้สี risk เฉพาะจุด, ทำให้ user เห็นว่า “ระบบพบอะไร / ไม่พบอะไร / ยังไม่มีข้อมูลอะไร” โดยไม่มีการเติมข้อมูลจำลอง

## 3. Runtime visual review

### Home
สิ่งที่ดี:
- CTA ตรวจรูปชัดและหาเจอเร็ว
- ลำดับ Greeting → Upload → Tips → Recent History เข้าใจง่าย
- Bottom navigation 4 จุดไม่ซับซ้อน

จุดที่ควรปรับ:
- Upload card สูงและเด่นเกินความจำเป็น ทำให้ Recent History หลุด below-the-fold
- Safety tips เป็น card grid ที่ดูคล้าย template dashboard มากกว่าส่วนช่วยตัดสินใจ
- pulse animation บน CTA เป็น motion เชิงตกแต่ง ไม่ได้สื่อ state

### History
สิ่งที่ดี:
- รูปตัวอย่าง + risk score อ่านสถานการณ์ได้เร็ว
- search/filter อยู่ตำแหน่งที่คาดเดาได้

จุดที่ควรปรับ:
- card สูงมาก ในจอจริงเห็นเพียงประมาณ 1–2 รายการต่อ viewport
- score ซ้ำทั้ง badge และ title เช่น `f • 85%`
- forensic tags ที่เห็นบน card ไม่ได้มาจาก evidence จริง แต่ถูกสร้างจาก risk level
- Low risk ใช้สีไม่ตรงกันระหว่างหน้าต่าง ๆ

### Report
สิ่งที่ดี:
- Form hierarchy ชัด: ภาพ → ประเภท → platform → รายละเอียด
- spacing และ form controls สม่ำเสมอพอใช้

จุดที่ควรปรับ:
- เป็น Bottom-nav destination แต่ submit ใช้ไม่ได้ถ้าไม่มี `scanId`; IA จึงสัญญาว่าเป็นหน้าอิสระแต่ business flow ไม่ใช่
- placeholder image card ใช้พื้นที่มากทั้งที่ผู้ใช้จาก tab ยังไม่มีภาพ
- ควรเริ่มด้วย “เลือกรายการที่จะรายงาน” เมื่อเข้าจาก tab โดยไม่มี scan context

### Settings
สิ่งที่ดี:
- grouping อ่านง่าย
- language/theme/privacy/cache หาเจอง่าย

จุดที่ควรปรับ:
- ใช้ pattern rounded card + tinted icon square + chevron ซ้ำมากจนดู generic
- profile card มีทั้ง card ด้านบนและรายการ Account ด้านล่าง ทำให้ข้อมูลซ้ำ
- `v1.0.0` ถูก hard-code ใน UI (`settings_screen.dart:447`) ทำให้ความหมายของ version ไม่ชัดและเสี่ยง stale

## 4. Nielsen heuristic score — Self review

| # | Heuristic | Score | หลักฐานสำคัญ |
|---|---|---:|---|
| 1 | Visibility of system status | 2/4 | Loading มี stage/progress จริงแล้ว แต่ error/timeout แสดง SnackBar 1 วินาทีแล้วกลับ Home (`analysis_loading_screen.dart:405-422`) |
| 2 | Match system / real world | 2/4 | มีศัพท์/แท็ก forensic ที่ไม่อธิบายและบางแท็กเป็นข้อมูลสร้างเอง |
| 3 | User control and freedom | 2/4 | ชื่อ scan ถูกบังคับ (`image_crop_screen.dart:462-468`), Report tab ไม่มี scan แล้วไปต่อไม่ได้ |
| 4 | Consistency and standards | 1/4 | navigation 2 implementation, risk color 3 แบบ, token bypass จำนวนมาก |
| 5 | Error prevention | 2/4 | มี validation/confirm delete แต่ flow หลักยังสร้าง friction และ recovery ต่ำ |
| 6 | Recognition rather than recall | 2/4 | Result หลักแสดง Summary + Visual เท่านั้น ไม่เห็นภาพรวม 3-layer evidence (`analysis_result_screen.dart:143-149`) |
| 7 | Flexibility and efficiency | 2/4 | flow scan ต้องผ่าน crop+ตั้งชื่อ, report tab ไม่รองรับ contextual selection |
| 8 | Aesthetic and minimalist design | 3/4 | ภาพรวมสะอาด แต่ card/shield/pulse/decoration ซ้ำมากเกินผลิตภัณฑ์ประเภท utility |
| 9 | Error recovery | 1/4 | scan error ไม่มี in-place retry และพาผู้ใช้ออกจากบริบทอัตโนมัติ |
| 10 | Help and documentation | 3/4 | มี onboarding, tips, heatmap description แต่ยังอธิบาย risk/evidence ไม่พอ |
| **รวม** | | **20/40** | ใช้งานได้ แต่ยังมี systemic consistency + trust issues |

## 5. Impeccable Native Audit — Self score

| Dimension | Score | เหตุผล |
|---|---:|---|
| Accessibility | 2/4 | ไม่มี `Semantics(...)`, semanticLabel 8 จุด, tooltip 6 จุด, มี shrink-wrap touch target 6 จุด และไม่ honor Reduce Motion |
| Performance | 3/4 | History หลักใช้ cached image และ list virtualization แต่ Heatmap ใช้ `Image.network` และมี animation loop หลายจุด |
| Appearance & Theming | 2/4 | มี Material 3 + light/dark ThemeData แต่ UI bypass token ด้วย raw color/radius/font size จำนวนมาก |
| Platform Conformance | 2/4 | ใช้ Material widgets เป็นฐาน แต่ MainShell สร้าง nav เองและ hijack Back ด้วย `PopScope(canPop:false)` |
| Adaptivity | 1/4 | ไม่มี `LayoutBuilder`/`NavigationRail`; tablet rule ใน design doc ยังไม่ถูก implement ยกเว้น Auth ที่มี max width |
| **รวม** | **10/20** | **Acceptable — significant work needed** |

หมายเหตุ: แอปไม่ได้ lock portrait ทั้งระบบตามที่ agy กล่าว; `screenOrientation="portrait"` อยู่เฉพาะ `UCropActivity` (`AndroidManifest.xml:35-38`) จึงไม่นับเป็น app-wide adaptivity defect

## 6. Deterministic source metrics — Self scan

ตรวจ `108` Dart files, `15,969` LOC:

| Signal | Count |
|---|---:|
| raw `Color(0x...)` นอก `core/theme` และ `risk_level_helper` | 179 |
| raw `fontSize` นอก `core/theme` | 59 |
| raw `BorderRadius.circular(number)` นอก `core/theme` | 120 |
| manual `isDark ?` branches | 203 |
| `Semantics(...)` | 0 |
| `semanticLabel:` | 8 |
| `tooltip:` | 6 |
| `MaterialTapTargetSize.shrinkWrap` | 6 |
| `LayoutBuilder` | 0 |
| `NavigationRail` | 0 |
| Material 3 `NavigationBar` | 0 |
| legacy `BottomNavigationBar` | 1 |
| user-visible Thai literal matches ใน presentation/core widgets | 93 |
| `.repeat(...)` animation calls | 6 |

`detect.mjs` ของ Impeccable ถูกลองกับ Flutter source และคืน `[]`; ตาม `audit.native.md` ตัว detector นี้ออกแบบสำหรับ web/markup จึง **ไม่นำ zero findings มาใช้เป็นหลักฐานว่า native UI สะอาด**

## 7. Confirmed priority findings

### P0 — Fabricated Heatmap fallback
**Location:** `features/result/presentation/screens/heatmap_viewer_screen.dart:87-103`

เมื่อไม่มี `heatmapUrl` หน้าจอวาด `RadialGradient` แดง/ส้มที่ตำแหน่งคงที่ทับภาพจริงและ comment ระบุ `Demo heatmap overlay` โดยตรง

ผลกระทบ: ผู้ใช้สามารถเข้าใจผิดว่าระบบตรวจพบความผิดปกติทั้งที่ไม่มี evidence จาก backend

แนวทาง: เมื่อไม่มี heatmap ให้แสดง explicit empty/unavailable state เท่านั้น ห้ามสร้าง visualization ทดแทน

### P0 — Fabricated forensic tags in History
**Location:** `features/history/presentation/screens/history_screen.dart:552-562`

`_getTags()` สร้าง `pixel_edge`, `metadata_conflict`, `light_filter`, `original_file` จาก risk level โดยตรง ไม่ได้มาจาก analysis result

ผลกระทบ: card ดูเฉพาะทางและน่าเชื่อถือขึ้น แต่เป็น specificity ที่ไม่ได้มาจากข้อมูลจริง

แนวทาง: แสดงเฉพาะ factor/evidence ที่ backend ส่งจริง หรือไม่แสดง tags เลย

### P1 — Misleading static slider affordance
**Location:** `analysis_result_screen.dart:602-652`

แถบที่มี eye/layers ถูกวาดด้วย `FractionallySizedBox` และหน้าตาเหมือน opacity slider แต่ไม่มี interaction

ผลกระทบ: user คาดว่าจะลากได้และสับสนกับ slider จริงใน HeatmapViewer

แนวทาง: เปลี่ยนเป็น semantic progress bar พร้อม label เช่น “Visual anomaly score” หรือทำให้เป็น control จริงถ้าจำเป็น

### P1 — Risk semantics ไม่เป็นระบบเดียว
- `risk_level_helper.dart:38-43` → Low = amber/tertiary
- `risk_badge.dart:19-24` → Low = green
- `history_screen.dart:518-520` → Low = cyan

ผลกระทบ: สีเดียวกันไม่สื่อความหมายเดิมระหว่างหน้าจอ ผู้ใช้ต้องเรียนรู้ใหม่ทุก surface

แนวทาง: กำหนด authority เดียว: Low=success/green, Medium=warning/amber, High=danger/red, Unknown=neutral

### P1 — Scan name ถูกบังคับทั้งที่ contract บอก optional
- UI block: `image_crop_screen.dart:462-468`
- Wiki: `wiki/architecture/mobile-design.md:834` ระบุ `title` optional

ผลกระทบ: เพิ่มขั้นตอนก่อน action หลักโดยไม่มีประโยชน์ต่อการวิเคราะห์

แนวทาง: ชื่อเป็น optional; ถ้าว่างใช้ชื่อไฟล์/วันที่สำหรับ display เท่านั้น

### P1 — Error recovery ทำลาย context
**Location:** `analysis_loading_screen.dart:405-422`

Error/timeout แสดงข้อความชั่วครู่แล้ว `context.go('/main/home')`

ผลกระทบ: ผู้ใช้เสียบริบท, ต้องเลือกรูปและเริ่ม flow ใหม่, และมีเวลาอ่านข้อความ error น้อย

แนวทาง: แสดง in-place failure state + Retry + Back/Keep in history

### P1 — Report destination กับ business rule ขัดกัน
**Location:** `report_scam_screen.dart:78-87`

Report เป็น top-level bottom-nav tab แต่ submit ต้องมี `scanId`

แนวทางที่ไม่ต้องเปลี่ยน backend: เมื่อเข้าจาก tab ให้หน้าแรกเป็น “เลือกรายการจากประวัติที่จะรายงาน”; เมื่อเข้าจาก Result ให้เปิด form พร้อม scan/image ทันที

### P1 — Navigation system แตกเป็นหลายชุด
- `MainShell` ใช้ custom `Container + GestureDetector + _NavItem`
- `AppBottomNavigation` ใช้ `BottomNavigationBar`
- `AnalysisResultScreen` เป็น standalone route แต่ใส่ bottom nav เอง (`analysis_result_screen.dart:98-106`)

ผลกระทบ: interaction, semantics, selected state และ hierarchy ไม่เป็นระบบเดียว

แนวทาง: ให้ MainShell เป็น navigation authority เพียงจุดเดียว ใช้ Material 3 `NavigationBar`; detail/result ใช้ back hierarchy

### P1 — Android Back ถูก hijack
**Location:** `main_shell.dart:40-82`

`PopScope(canPop:false)` ดัก Back แล้วเปิด dialog “ออกจากแอป” ก่อน `SystemNavigator.pop()`

ผลกระทบ: ขัด Android predictive Back และสร้าง friction ที่ Android user ไม่คาดหวัง

แนวทาง: ปล่อย system Back ทำงานตาม Android; ห้ามมี exit confirmation ที่ root เว้นมี unsaved destructive state

### P2 — Design token fragmentation
Design authority ระบุ primary `#006685`, แต่ `AppColors.primary` ปัจจุบันคือ `#00A6D6` (`app_colors.dart:19`). Typography spec 24/22/18/16/16/13 แต่ implementation ลดเป็น 22/18/16/14/15/12 (`app_typography.dart:20-68`).

ผลกระทบ: Figma/docs กับ production drift และแก้ theme ยาก

แนวทาง: ทำ semantic token authority เดียว, เพิ่ม `AppRadius`, และห้าม screen-level raw color/radius เว้น evidence visualization ที่มีเหตุผล

### P2 — Thai/English localization leakage
พบ user-visible Thai literals ใน presentation/core widgets จำนวนมาก เช่น Home greeting, History filters/empty states, Onboarding, Permission view, RiskBadge, errors และ Report validators

ผลกระทบ: English mode ไม่เป็นภาษาหนึ่งเดียวและ copy ไม่ได้ควบคุมจาก content system

แนวทาง: ย้ายข้อความ user-facing ทั้งหมดเข้า localization keys; exception เฉพาะ proper nouns/data จาก server

### P2 — Accessibility semantics / touch target / motion coverage ต่ำ
- `Semantics(...)` = 0
- `semanticLabel` = 8
- `tooltip` = 6
- shrink-wrap tap target = 6
- animation `.repeat` = 6 และไม่พบ `MediaQuery.disableAnimations`

แนวทาง: เพิ่ม semantics สำหรับ risk/evidence/status, ทำ hit area >=48dp, และหยุด decorative/repeating motion เมื่อ `disableAnimations` เป็น true

### P2 — Tablet/adaptive strategy ยังไม่เกิดขึ้นจริง
Design ระบุ >600px ควร cap content 540px แต่ app core screens ไม่มี `LayoutBuilder` และไม่มี `NavigationRail`; มี max-width strategy ชัดเจนเฉพาะ Login/Register

แนวทาง: compact/medium/expanded layout policy, max-width content, rail บน expanded และทดสอบ landscape/foldable

### P3 — Generic security visual clichés
Shield + cyan + rounded card + tinted icon square + soft shadow + pulse ปรากฏซ้ำหลาย surface โดยไม่ได้เพิ่มข้อมูลใหม่

สิ่งนี้ **ไม่พิสูจน์ว่า AI เป็นผู้เขียน** แต่เข้าข่าย AI-slop-like visual pattern เพราะ category-interchangeable และใช้ decoration แทน product evidence

แนวทาง: ลด shield/decorative icon, ลด shadow/gradient, ให้ภาพหลักฐานและ factor explanation เป็นเอกลักษณ์หลักของแบรนด์

## 8. AI-slop classification

### Confirmed AI-slop-like / product-slop patterns
1. **Fake Heatmap fallback** — mock visualization อยู่ใน production path
2. **Fake History evidence tags** — forensic labels สร้างจาก risk grade ไม่ใช่ evidence
3. **Fake slider affordance** — หน้าตาเหมือน control แต่เป็น static score bar
4. **Component reinvention** — มี `RiskGauge` แต่ Result สร้าง `_ArcPainter`; มี `AppBottomNavigation` แต่ MainShell สร้าง nav อีกชุด

คำว่า “confirmed” ในส่วนนี้หมายถึง **ยืนยัน pattern จาก code** ไม่ได้หมายถึงยืนยันว่าถูกสร้างโดย AI

### Suspected / generic patterns
- shield/cyan/security-card visual grammar ที่ใช้ได้กับ antivirus, VPN, fintech fraud หรือ password manager โดยแทบไม่ต้องเปลี่ยน layout
- rounded cards 16px + icon tile + chevron ซ้ำใน Settings
- decorative pulse/scan-line/dots animation หลายจุด
- “coming soon” affordances ที่กดได้ในฟังก์ชันสำคัญ

### Not slop / false positives
- ไม่มี emoji: เป็น product policy ไม่ใช่ความจืดของ design
- Safety Tips แบบ Bento: มีอยู่ใน design spec โดยตรง
- `ConstrainedBox(maxWidth: ...)` บน Auth: เป็น adaptive practice ที่เหมาะสม
- Heatmap Viewer **มี opacity `Slider` จริง** (`heatmap_viewer_screen.dart:241-258`); agy Design review ที่บอกว่าไม่มี slider เป็น false positive
- App **ไม่ได้ล็อก portrait ทั้งระบบ**; portrait lock อยู่เฉพาะ UCrop activity
- Dark Android launch theme **มี** `values-night/styles.xml`; claim เรื่องไม่มี dark launch theme ถูกตัดทิ้ง
- History delete **มี confirm dialog**; claim ว่าไม่มี confirmation ถูกตัดทิ้ง
- Risk model จริงมี 3 ระดับ + `unknown`, ไม่มี `critical`; claim 4 risk levels จาก agy ถูกตัดทิ้ง

## 9. Self vs agy reconciliation

| Finding | Self | agy Design | agy Native | Final |
|---|---|---|---|---|
| Fake fallback heatmap | พบ | พบ | พบ | Confirmed P0 |
| Fake History forensic tags | พบ | พบ | ไม่เน้น | Confirmed P0 |
| Static faux slider | พบ | พบ | ไม่เน้น | Confirmed P1 |
| Token/component fragmentation | พบ | พบ | พบ | Confirmed |
| Mandatory scan name vs optional contract | พบ | พบ | ไม่เน้น | Confirmed P1 |
| Scan error auto-redirect | พบ | พบ | ไม่เน้น | Confirmed P1 |
| Predictive Back conflict | พบ | ไม่เน้น | พบ | Confirmed P1 |
| Accessibility semantics gap | พบ | บางส่วน | พบ | Confirmed P2 |
| App-wide portrait lock | ไม่พบ | - | พบ | **Rejected** — only UCrop activity |
| Missing dark launch theme | ไม่พบ | - | พบ | **Rejected** — values-night exists |
| Heatmap opacity slider missing | ไม่พบ | พบ | - | **Rejected** — real Slider exists |
| 4 risk levels incl. critical | ไม่พบ | พบ | - | **Rejected** — 3 + unknown |
| No delete confirmation | ไม่พบ | พบ | - | **Rejected** — confirmation exists |

### Reliability conclusion
`agy` เหมาะสำหรับใช้เป็น independent hypothesis generator แต่ต้องอ่าน source ยืนยันทุก finding ก่อนนำไปใช้ คะแนนดิบของ agy (Design 15/40 และ Native 6/20) **ไม่ถูกนำมาใช้เป็น final score** เพราะอิง false positives บางส่วน

## 10. Positive findings to preserve

1. Main task flow เลือกรูป → crop → analyze → result มีโครงสร้างชัดและ BLoC state แยกดี
2. Home CTA เด่นและใช้ภาษาคนทั่วไปมากกว่าศัพท์โมเดล
3. History ใช้รูป preview จริงและ cached network image ใน main list
4. Light/Dark ThemeData มีอยู่จริง ไม่ใช่ theme แบบ invert อย่างเดียว
5. Delete flow มี confirmation และรอ backend success ก่อนนำรายการออก
6. Heatmap viewer มี pan/zoom และ opacity slider จริง
7. 4-tab IA เข้าใจง่าย ถ้าแก้ semantic ของ Report tab และรวม navigation implementation ให้เหลือจุดเดียว
8. Design docs, Figma references และ token files มีฐานดีพอสำหรับทำ redesign โดยไม่ต้องเริ่มใหม่ทั้งหมด

## 11. Final priorities

- **P0:** ลบ fabricated evidence ทั้งหมดก่อนแตะ cosmetic redesign
- **P1:** แก้ report IA, scan-name friction, error recovery, navigation authority และ Android Back
- **P2:** รวม design system, risk semantics, typography, localization, accessibility และ adaptivity
- **P3:** ลด generic cyber visual clichés และ polish density/motion

รายละเอียด implementation sequence และ acceptance criteria อยู่ใน `design/mobile/mobile-redesign-plan-2026-09-20.md`
