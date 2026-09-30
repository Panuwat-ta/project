# ScamGuard Mobile — Redesign Plan

วันที่: 20 กันยายน 2026
ฐานข้อมูล: `mobile-design-ux-audit-2026-09-20.md`
สถานะ: Plan only — ยังไม่เริ่มแก้ implementation

## 1. Redesign objective

ปรับ Mobile จาก visual language แบบ “generic cyber-security dashboard” ไปเป็น **Calm Forensic Utility** ที่:

- เชื่อถือได้เพราะแสดงเฉพาะ evidence จริง
- อ่านผลได้ภายในไม่กี่วินาทีในสถานการณ์ที่ผู้ใช้กำลังกังวล
- แยก “ระบบพบ”, “ระบบไม่พบ”, “ยังไม่มีข้อมูล” ออกจากกันชัดเจน
- ใช้ Material 3 และ Android behavior เป็นฐาน ไม่สร้าง interaction pattern ซ้ำเอง
- รองรับภาษาไทย, English, large text, light/dark และหน้าจอขนาดต่าง ๆ
- คง branding ScamGuard แต่ลด shield/cyan/card decoration ที่ไม่ช่วยตัดสินใจ

## 2. Design principles หลัง redesign

### P1 — Evidence before decoration
ข้อมูลจริงจาก scan ต้องมาก่อน icon, animation, gradient หรือ badge เสมอ

### P2 — No fabricated specificity
ห้ามสร้าง heatmap, forensic tag, confidence, source finding หรือข้อความ “ปลอดภัย” จาก heuristic ฝั่ง UI ถ้า backend ไม่ได้ส่งข้อมูลนั้น

### P3 — Calm, not alarming
Risk color ใช้เพื่อระบุระดับ ไม่ใช้ย้อมทั้งหน้าจอหรือสร้างความตื่นตระหนกโดยไม่จำเป็น

### P4 — One design authority
สี, typography, radius, spacing, navigation, risk badge และ card primitives ต้องมี authority กลาง

### P5 — Android-native interaction
System Back, touch target, navigation, feedback และ reduced motion ต้องเป็นไปตาม Material 3/Android expectations

### P6 — Thai-first readability
Body text ต้องอ่านได้จริงในภาษาไทย มี line height รองรับสระ/วรรณยุกต์และ scale ตามระบบ

## 3. Target visual direction — Calm Forensic Utility

### Keep
- Sarabun เป็น UI font
- neutral light/dark surfaces
- primary blue/teal เป็น brand/action color
- 3 risk levels Low/Medium/High
- evidence image เป็น visual anchor
- 4 primary areas: Home, History, Report, Settings

### Reduce
- shield icon ซ้ำทุก section
- decorative pulse/glow/gradient
- soft-shadow rounded card ทุกอย่าง
- tinted square icon ทุก row
- card-inside-card nesting
- duplicate score labels

### Increase
- whitespace ที่ใช้สร้าง hierarchy ไม่ใช่สร้าง card
- explanatory copy ใกล้กับ evidence
- source provenance และ unavailable state
- direct actions เช่น “ดูหลักฐาน”, “ตรวจภาพอื่น”, “รายงานรายการนี้”

## 4. Phase 0 — Product integrity gate

**Priority:** P0
**ทำก่อน redesign เชิงภาพทั้งหมด**

### 0.1 Remove fake Heatmap fallback
Target:
- `lib/features/result/presentation/screens/heatmap_viewer_screen.dart`

Change:
- ลบ `Demo heatmap overlay` / hard-coded `RadialGradient`
- ถ้าไม่มี `heatmapUrl` ให้แสดง explicit unavailable state
- base image ยังดูได้ แต่ต้องไม่มี anomaly overlay จำลอง

Acceptance:
- ไม่มีคำว่า `Demo heatmap overlay` ใน production source
- `heatmapUrl == null` ไม่สร้างสีแดง/ส้มบนภาพ
- copy ระบุว่าไม่มีข้อมูล heatmap ไม่ใช่ “ไม่พบความเสี่ยง” เว้น backend ยืนยัน

### 0.2 Remove fabricated History tags
Target:
- `lib/features/history/presentation/screens/history_screen.dart`
- history/result model ถ้าจำเป็น

Change:
- ลบ `_getTags(riskLevel)` ที่ derive forensic finding จาก grade
- แสดง tag เฉพาะ field ที่ backend ส่งจริง
- ถ้ารายการ summary ไม่มี evidence detail ให้ไม่แสดง tags

Acceptance:
- HIGH/MEDIUM/LOW อย่างเดียวไม่สามารถสร้าง `pixel_edge`, `metadata_conflict`, `light_filter`, `original_file`
- card ที่ไม่มี evidence จริงยังสมบูรณ์และอ่านง่าย

### 0.3 Replace faux slider in Result
Target:
- `analysis_result_screen.dart`

Change:
- เปลี่ยน eye/layers static slider เป็น labeled score bar เช่น `Visual anomaly 85/100`
- หรือเอาออกและใช้ CTA “ดู Heatmap” เป็น interaction เดียว

Acceptance:
- ไม่มี component ที่หน้าตาเหมือน slider แต่ลากไม่ได้
- interactive element ทุกชิ้นมี action/semantic role ที่ตรงกับหน้าตา

### 0.4 Integrity regression tests
Add tests asserting:
- missing heatmap does not render simulated heatmap
- history tag rendering cannot derive evidence from risk level
- result score visualization is non-interactive progress semantics หรือ real control ตาม design ที่เลือก

## 5. Phase 1 — Core UX and information architecture

**Priority:** P1

### 1.1 Make scan name optional
Target:
- `image_crop_screen.dart`
- localization
- widget tests

Change:
- ไม่ block Start Analysis เมื่อชื่อว่าง
- hint เป็น “ตั้งชื่อเพื่อค้นหาภายหลัง (ไม่บังคับ)”
- ส่ง `title=null/empty` ตาม repository contract หรือสร้าง display fallback ฝั่ง server/UI เท่านั้น

Acceptance:
- user เลือกรูปและเริ่มวิเคราะห์ได้โดยไม่พิมพ์ชื่อ
- ถ้าตั้งชื่อ History search ยังหาได้จากชื่อนั้น

### 1.2 In-place scan error recovery
Target:
- `analysis_loading_screen.dart`
- `scan_bloc.dart` ถ้าต้องมี Retry event/state

Change:
- ยกเลิก auto redirect หลัง 1 วินาที
- Error state อยู่ในหน้าเดิม
- actions: `ลองใหม่`, `กลับไปแก้ไขรูป`, `ไปประวัติ` ตามสถานะจริง
- network/transient error ไม่ทำให้ user สูญเสีย context

Acceptance:
- error text อ่านได้จน user เลือก action
- ไม่มี delayed navigation จาก `ScanError`/`ScanTimeout`
- retry ไม่ต้องเลือกรูปใหม่ถ้า local file ยังอยู่

### 1.3 Fix Report top-level IA
Target:
- `report_scam_screen.dart`
- `app_router.dart`
- History selection component/repository reuse

Chosen design:
- ถ้าเข้าจาก Result/History detail พร้อม `scanId` → เปิด Report form พร้อมภาพทันที
- ถ้าเข้าจาก Bottom Nav โดยไม่มี `scanId` → แสดง **Select a scan to report** จาก History ก่อน
- ไม่สร้าง standalone raw upload flow ในรอบนี้ เพื่อไม่ขยาย backend contract

Acceptance:
- Bottom-nav Report ไม่มี dead-end
- user เข้า tab แล้วสามารถเลือก scan และไป form ได้ภายใน 2 taps
- ไม่มี submit button ที่รู้ล่วงหน้าว่าจะ fail เพราะไม่มี `scanId`

### 1.4 Redesign Result as evidence summary
Target:
- `analysis_result_screen.dart`
- shared evidence components

Above-the-fold hierarchy:
1. Risk level + score + short interpretation
2. “สิ่งที่ระบบพบ” summary
3. actions: ดูหลักฐาน / รายงาน / ตรวจภาพอื่น

Evidence section:
- Visual
- Text/OCR
- Source/metadata

แต่ละ layer มี 4 states:
- finding
- no finding
- unavailable
- processing/not ready (ถ้า route รองรับ)

Acceptance:
- user เห็นว่าคะแนนสูงเพราะ factor ใดโดยไม่ต้องเดา
- ไม่มี “ปลอดภัย” ถ้า grade เป็น unknown/unavailable
- source/text layer ที่ไม่มีข้อมูลต้องระบุ unavailable อย่างตรงไปตรงมา

### 1.5 Navigation hierarchy
Target:
- `main_shell.dart`
- `app_bottom_navigation.dart`
- `analysis_result_screen.dart`
- router

Change:
- MainShell เป็นเจ้าของ primary navigation เพียงจุดเดียว
- ใช้ Material 3 `NavigationBar`
- Result/Heatmap/Detail/Crop/Loading เป็น task/detail routes ไม่มี bottom nav ซ้ำ
- back จาก Result กลับ context ที่เหมาะสม: History ถ้ามาจาก History, Home/task flow ถ้ามาจาก scan

Acceptance:
- ไม่มี bottom-nav implementation มากกว่า 1 ชุด
- selected tab state มาจาก router authority เดียว
- detail route ไม่แสดง tab bar ปลอมเป็น shell

### 1.6 Android Back
Target:
- `main_shell.dart`

Change:
- ลบ root exit confirmation ที่ intercept ทุก Back
- honor predictive Back
- ใช้ confirmation เฉพาะหน้าที่มี unsaved state จริง เช่น form/report/crop edits

Acceptance:
- Android Back ที่ root ทำงานตาม platform expectation
- ไม่มี `SystemNavigator.pop()` ใน normal navigation path

## 6. Phase 2 — Design system consolidation

**Priority:** P1/P2

### 2.1 Establish color authority
Target:
- `core/theme/app_colors.dart`
- `light_theme.dart`
- `dark_theme.dart`
- all presentation screens

Proposed semantic mapping:
- `primary` = `#006685` ตาม design authority
- `primaryContainer/accent` = brighter cyan family เช่น `#00A6D6`
- Low = Success green
- Medium = Warning amber
- High = Danger red
- Unknown = neutral outline/onSurfaceVariant

Rule:
- screen-level UI ใช้ `Theme.of(context).colorScheme` ก่อน `AppColors`
- raw hex อนุญาตเฉพาะ evidence visualization ที่มี documented reason

Acceptance:
- Low risk ใช้ semantic family เดียวทุก screen
- raw hex outside theme ลดจาก baseline 179 เหลือ <25 และทุกข้อที่เหลือมี comment/reason
- dark/light ไม่ต้องเขียน `isDark ?` สำหรับ text/surface ทั่วไป

### 2.2 Restore typography scale for Thai
Target:
- `app_typography.dart`
- ThemeData TextTheme

Proposed scale aligned with design doc:
- page headline 24
- title 20–22
- section 18
- body 16
- button 16
- caption/supporting 13–14
- nav labels >=12

Add:
- explicit line height suitable for Thai (`height` ประมาณ 1.35–1.5 ตาม role)
- tabular figures for risk score where appropriate

Acceptance:
- ไม่มี core body copy 12px
- labels ไม่ตัดวรรณยุกต์ที่ text scale 1.3
- screen titles/section/body มี hierarchy เดียวกันทั้ง app

### 2.3 Radius / shape tokens
Create:
- `core/theme/app_radius.dart` หรือ ThemeData shape authority

Suggested:
- xs 4
- sm 8
- md 12
- lg 16
- pill 999

Acceptance:
- raw `BorderRadius.circular(number)` outside theme/shared component ลดจาก 120 เหลือ <20
- same component category uses same shape

### 2.4 Shared component consolidation
Unify:
- `RiskGauge` / Result gauge
- `RiskBadge` / History badge / factor badge
- `HistoryListItem` / History card variants
- `AppTopBar`
- primary navigation
- evidence state card
- empty/error states

Acceptance:
- ไม่มี private component ที่ duplicate shared component โดยไม่มี documented variant reason
- component variants เป็น parameter/API ไม่ใช่ copy-paste screen implementation

## 7. Phase 3 — Screen-level visual redesign

### 3.1 Home: task-first, denser
New hierarchy:
- Greeting compact
- Scan CTA card สูงลดลงประมาณ 25–35%
- Primary action คงเต็มความกว้างบน compact phone
- Safety tips เปลี่ยนเป็น compact 3-row tips หรือ horizontal supporting section
- Recent History ต้องเริ่มเห็นอย่างน้อย 1 item บน common phone viewport โดยไม่ต้อง scroll มาก

Remove:
- pulse animation ถาวร
- unnecessary gradient/shadow stack

### 3.2 History: evidence-aware compact list
New card anatomy:
- thumbnail 88–112px หรือ compact media row
- title ที่ user ตั้งเป็น primary label
- date/time secondary
- risk badge 1 จุด
- optional evidence summary จากข้อมูลจริงสูงสุด 1–2 items

Remove:
- risk score ซ้ำใน title
- fabricated tags
- image height 160 แบบ full-width ทุก record ถ้าไม่จำเป็น

Goal:
- common phone viewport เห็น 2.5–4 records แทนประมาณ 1–2

### 3.3 Result: verdict + evidence + action
Top section:
- `Risk level` เป็นข้อความหลัก
- score เป็น supporting metric ไม่ใช่ hero เดี่ยว
- short explanation จาก XAI/server

Second section:
- 3 evidence rows/cards
- status icon + score + one-line explanation
- expand for details

Third:
- image/heatmap comparison CTA

Fourth:
- next actions / report / share / delete

### 3.4 Heatmap: comparison tool, not decoration
- Original/Heatmap toggle จริง
- opacity slider จริง (ของเดิมคงไว้และปรับ semantics)
- no fake overlay
- unavailable state
- pan/zoom controls 48dp + semantic labels

### 3.5 Settings: reduce card stacking
Direction:
- profile header compact
- one or two grouped list surfaces แทน card ทุกหมวด
- Account entry ไม่ซ้ำกับ entire profile card ถ้ากดไปที่เดียวกัน
- app version อ่านจาก package metadata ไม่ hard-code
- destructive Logout แยกชัดแต่ไม่ใช้ oversized empty card

## 8. Phase 4 — Accessibility and native Android pass

**Priority:** P1/P2

### 4.1 Semantics
Add explicit semantics to:
- risk score/gauge
- risk badges when color communicates meaning
- analysis progress/status
- heatmap controls
- navigation destinations
- image result/thumbnail when meaningful
- loading state of buttons

### 4.2 Touch targets
Remove unnecessary `MaterialTapTargetSize.shrinkWrap` and guarantee >=48x48dp for:
- Forgot password
- Login/Register cross-links
- See all
- Change image
- icon-only custom crop controls
- all custom gesture surfaces

### 4.3 Reduced motion
Gate repeating animations with:
- `MediaQuery.disableAnimations`

Affected:
- Home upload pulse
- Splash pulse
- loading scan line/dots
- AnalysisStepTile spinner (replace by static active state if animations disabled)

### 4.4 Contrast
Validate WCAG AA for normal text in both themes, especially:
- captions
- disabled/pending states
- unknown risk
- placeholder/hint text

### 4.5 Back / focus / IME
- predictive Back
- keyboard action/field order
- focus restoration after dialogs
- form error focus to first invalid field where useful

## 9. Phase 5 — Localization and content design

Move all user-visible literals to localization:
- Home greeting/empty/recent labels
- History filter/empty/date strings
- RiskBadge labels
- onboarding copy
- permission view
- Report “other” validators
- bloc error messages via UI mapping/localized failure types

Content principles:
- avoid technical term alone; pair with user meaning
- distinguish `ไม่พบ`, `ตรวจไม่ได้`, `ยังไม่มีข้อมูล`
- do not use “ปลอดภัย” as synonym for Low unless product language explicitly approves it
- explain that risk score is an assessment, not legal certainty

Acceptance:
- English mode has no Thai UI literals except user/server data/proper nouns
- Thai mode avoids unnecessary English technical text unless followed by explanation

## 10. Phase 6 — Adaptivity

Window strategy:
- Compact `<600`: phone single-column + `NavigationBar`
- Medium `600–839`: centered content/max width + optional two-column evidence
- Expanded `>=840`: `NavigationRail` + content max widths

Rules:
- Form content max width 540–600
- Result evidence max width around 720–840 depending layout
- History can become two-column only when card readability remains high
- no unbounded full-width CTA on tablet

Do not remove `UCropActivity` portrait lock blindly; it is third-party crop activity and must be tested separately. Main Flutter activity is currently not portrait-locked.

## 11. Phase 7 — Validation and regression gate

### Required viewport matrix
- phone 360x800
- phone 390x844
- phone 412x915
- tablet 600x960
- tablet/expanded 840x1180

### Required modes
- Thai / English
- Light / Dark / System
- text scale 1.0 / 1.3 / 1.5
- animations enabled / disabled

### Required workflows
1. onboarding/login
2. pick image → crop → scan with no name
3. scan success
4. scan network failure + retry
5. Result → Heatmap
6. Result → Report
7. Bottom Report → select History item → form
8. History search/filter/delete
9. Settings language/theme/privacy/logout

### Automated gates
- `flutter analyze`
- full `flutter test`
- widget tests for overflow at 390px and text scale 1.3
- golden/screenshot tests for key screens in light/dark where stable
- regression tests for no fabricated heatmap/tags

### Manual Android gate
- TalkBack traversal
- system Back / predictive Back
- keyboard/IME
- rotation/large screen where supported
- physical-device screenshot comparison

## 12. Suggested implementation order

1. Phase 0 Product Integrity
2. Phase 1 Core UX/IA
3. Phase 2 Design system foundation
4. Phase 3 Home + History
5. Phase 3 Result + Heatmap + Report
6. Phase 3 Settings/Auth/Onboarding polish
7. Phase 4 Accessibility/native
8. Phase 5 Localization
9. Phase 6 Adaptivity
10. Phase 7 Verification

เหตุผล: ห้าม polish visual บน interaction/data ที่ผิด เพราะจะทำให้ mock/fabricated behavior ดูน่าเชื่อถือขึ้นแทนที่จะทำให้ product ถูกต้องขึ้น

## 13. Proposed file impact map

### Core
- `core/theme/app_colors.dart`
- `core/theme/app_typography.dart`
- `core/theme/light_theme.dart`
- `core/theme/dark_theme.dart`
- new radius/shape token file if selected
- `core/widgets/app_top_bar.dart`
- `core/widgets/app_bottom_navigation.dart` → retire/replace with one M3 navigation implementation
- `core/widgets/risk_badge.dart`
- `core/widgets/risk_gauge.dart`
- `core/widgets/history_list_item.dart`
- localization

### Auth / Shell
- `features/auth/presentation/screens/main_shell.dart`
- Login/Register/Onboarding/Splash for typography, localization, motion and touch targets

### Scan
- `home_screen.dart`
- `image_crop_screen.dart`
- `analysis_loading_screen.dart`
- Scan BLoC only where Retry state requires it

### Result
- `analysis_result_screen.dart`
- `heatmap_viewer_screen.dart`
- shared evidence widgets/models as needed

### History
- `history_screen.dart`
- `history_detail_screen.dart`

### Report
- `report_scam_screen.dart`
- selection step/component

### Settings
- `settings_screen.dart`
- `user_profile_screen.dart`
- `privacy_consent_screen.dart`

## 14. Out of scope for redesign pass

- เปลี่ยน AI model / scoring algorithm
- เปลี่ยน backend report schema โดยไม่จำเป็น
- เพิ่ม social login / forgot password backend
- เพิ่ม video analysis
- เปลี่ยน branding/logo ใหม่ทั้งหมด
- เปลี่ยน Flutter architecture/BLoC เป็น framework อื่น

## 15. Definition of Done

Redesign ถือว่าเสร็จเมื่อ:

1. production UI ไม่มี fabricated evidence หรือ mock visualization
2. Main workflows ไม่มี dead-end และ error มี recovery
3. navigation authority เหลือชุดเดียวและ Android Back ถูกต้อง
4. risk semantic color เหมือนกันทั้งระบบ
5. design token drift ถูกลดจน screens ไม่ต้องประกาศ visual primitives เองเป็นหลัก
6. Thai/English และ light/dark ไม่มี mixed copy สำคัญ
7. core interactive target >=48dp และ critical information มี semantics
8. text scale 1.3 ไม่มี overflow ใน key screens
9. compact + tablet layout ผ่าน viewport matrix
10. `flutter analyze` และ full tests ผ่าน พร้อม screenshot/manual audit หลังแก้

หลัง implementation ต้องรัน Impeccable audit และ independent agy review ซ้ำ แล้วเปรียบเทียบกับ baseline ฉบับวันที่ 2026-09-20 โดยไม่ใช้คะแนน agent ดิบเป็น final verdict
