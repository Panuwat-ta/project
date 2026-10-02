> ผล independent review จาก `agy`, model `gemini-3.8-flash-low`, commit ที่ตรวจ `bd98db73`.
> Conversation: `d2969b67-a3a8-48b9-837d-51aa87ab86dc`; เวลารัน 205.404684316 วินาที; ใช้ `--print-timeout 0s`.
> เนื้อหาด้านล่างเป็นผล reviewer ก่อนแก้ findings; คำตัดสินและ disposition อยู่ใน `mobile-design-ux-audit-2026-10-02.md`.

# การตรวจสอบอิสระแบบอ่านอย่างเดียว (Independent Read-Only Review) สำหรับ ScamGuard Mobile Issue #76

การตรวจสอบนี้ดำเนินการตามกฎของระบบ (ห้ามแก้ไขไฟล์, ไม่ใช้อิโมจิ, ยึดหลักฐานจริงจากโค้ด, แยกข้อเท็จจริงที่ยืนยันแล้วออกจากสมมติฐาน) ครอบคลุม 5 จุดหลักตามคำสั่ง:
1. [`analysis_result_screen.dart`](file:///home/panuwat/project/scam_image_mobile/lib/features/result/presentation/screens/analysis_result_screen.dart)
2. [`history_detail_screen.dart`](file:///home/panuwat/project/scam_image_mobile/lib/features/history/presentation/screens/history_detail_screen.dart)
3. [`heatmap_viewer_screen.dart`](file:///home/panuwat/project/scam_image_mobile/lib/features/result/presentation/screens/heatmap_viewer_screen.dart)
4. [`app_translations.dart`](file:///home/panuwat/project/scam_image_mobile/lib/core/localization/app_translations.dart)
5. `lib/features/auth/presentation`

---

## 1. ข้อเท็จจริงที่ยืนยันแล้วพร้อมตำแหน่งไฟล์และบรรทัด (Confirmed Findings)

### 1.1 คำสะกดผิดในพจนานุกรมภาษาไทย (Typo Defect)
- **ไฟล์และบรรทัด**: [`lib/core/localization/app_translations.dart:351`](file:///home/panuwat/project/scam_image_mobile/lib/core/localization/app_translations.dart#L351) และ [`lib/features/result/data/models/analysis_result_model.dart:78`](file:///home/panuwat/project/scam_image_mobile/lib/features/result/data/models/analysis_result_model.dart#L78)
- **พฤติกรรมจริง**:
  - ใน `app_translations.dart` บรรทัดที่ 351: `'result_ai_generated_probability': 'ความม่ันใจว่าถูกดัดแปลง',` (สระอั่ ใช้ไม้เอกบนสระอะ/สระอำ หรือ Unicode ordering `\u0e21\u0e48\u0e31\u0e19` ซึ่งสลับวรรณยุกต์กับสระ หรือพิมพ์ผิดจาก "ความมั่นใจ")
  - ใน `analysis_result_model.dart` บรรทัดที่ 78: `'ความม่ันใจว่าถูกดัดแปลง: ${((json[\'manipulation_confidence\'] as num) * 100).round()}%',` มีการสะกดผิดแบบเดียวกัน และเป็นข้อความภาษาไทยฮาร์ดโค้ดใน Model โดยไม่ได้เรียกผ่าน localization key
- **ผลกระทบ**: หน้าจอ `HistoryDetailScreen` (บรรทัดที่ 658) ที่เรียก `'result_ai_generated_probability'.tr(context)` จะแสดงผลข้อความสะกดผิดบนหน้าจอผู้ใช้

---

### 1.2 ป้ายกำกับข้อมูลเสี่ยงที่ยังค้างข้อความและคีย์ที่ไม่ตรงกับสเปกโดเมน (Product Integrity & Misleading Labels)
- **ไฟล์และบรรทัด**: [`lib/features/history/presentation/screens/history_detail_screen.dart:657-679`](file:///home/panuwat/project/scam_image_mobile/lib/features/history/presentation/screens/history_detail_screen.dart#L657-L679)
- **พฤติกรรมจริง**:
  - ตัวแปรในโมเดลคือ `result.manipulationConfidence` ซึ่งมาจาก SegFormer / AI Anomaly Detection pipeline (ตรวจจับการตัดต่อพิกเซล/ดัดแปลงภาพ)
  - อย่างไรก็ตาม คีย์ที่หน้าจอเรียกใช้เพื่อแสดงหัวข้อคือ `'result_ai_generated_probability'`
  - แม้ว่าในภาษาไทยจะมีการปรับแก้ข้อความในพจนานุกรมเป็น `'ความม่ันใจว่าถูกดัดแปลง'` และภาษาอังกฤษเป็น `'Manipulation confidence'` แต่การตั้งชื่อคีย์เดิมยังผูกกับคำว่า "AI Generated"
  - ยิ่งไปกว่านั้น ในบรรทัดที่ 670–675 มีการคำนวณ fallback สี (color thresholding) ข้ามประเภทข้อมูล:
    ```dart
    color: (result.manipulationConfidence != null &&
            result.manipulationConfidence! >= 0.7) ||
        visualFactor.score >= 70
        ? AppColors.danger
        : ...
    ```
    หาก `manipulationConfidence` มีค่า 0.1 (ต่ำมาก) แต่ `visualFactor.score` เป็น 75 สีของค่า Manipulation Confidence จะกลายเป็นสีแดง (`AppColors.danger`) ซึ่งทำให้เกิดความเข้าใจผิดทางสายตา (Visual Misleading) ว่าค่า Confidence นั้นอยู่ในระดับอันตราย ทั้งที่ตัวเลขที่แสดงอาจเป็น 10%

---

### 1.3 ความไม่สอดคล้องของการนำทาง Heatmap ระหว่างสองหน้าจอ (Interaction & State Affordance Inconsistency)
- **ไฟล์และบรรทัด**:
  - [`lib/features/result/presentation/screens/analysis_result_screen.dart:686-698`](file:///home/panuwat/project/scam_image_mobile/lib/features/result/presentation/screens/analysis_result_screen.dart#L686-L698)
  - [`lib/features/history/presentation/screens/history_detail_screen.dart:590-651`](file:///home/panuwat/project/scam_image_mobile/lib/features/history/presentation/screens/history_detail_screen.dart#L590-L651) และ [`767-775`](file:///home/panuwat/project/scam_image_mobile/lib/features/history/presentation/screens/history_detail_screen.dart#L767-L775)
- **พฤติกรรมจริง**:
  - ใน `AnalysisResultScreen`: รูปพรีวิวมี `GestureDetector(onTap: previewUrl != null ? ... : null)` ซึ่งผู้ใช้สามารถกดที่รูปเพื่อเปิด Heatmap Viewer ได้
  - ใน `HistoryDetailScreen`: รูปพรีวิว (บรรทัดที่ 592–650) เป็น `Container` และ `Stack` ธรรมดา **ไม่มี `GestureDetector` หรือ `InkWell`** ผู้ใช้กดที่รูปภาพไม่ได้
  - ในขณะเดียวกัน ปุ่ม Action Button ด้านล่าง (บรรทัดที่ 767) ของ `HistoryDetailScreen` มีปุ่ม `'result_view_heatmap'` ซึ่งกดเปิด `/heatmap/${result.taskId}` ได้ตลอดเวลา แม้ว่ารายการสแกนนั้นจะไม่มี Heatmap (`heatmapUrl == null`) ก็ตาม (เปิดเข้าไปเจอสถานะ Unavailable ใน HeatmapViewerScreen)

---

### 1.4 การจัดการสี Risk Level ใน History Detail ไม่ผ่าน Authority กลาง (Architecture & Consistency Defect)
- **ไฟล์และบรรทัด**: [`lib/features/history/presentation/screens/history_detail_screen.dart:734-745`](file:///home/panuwat/project/scam_image_mobile/lib/features/history/presentation/screens/history_detail_screen.dart#L734-L745)
- **พฤติกรรมจริง**:
  - ใน `HistoryDetailScreen` มีฟังก์ชันส่วนตัว `_getRiskColor(RiskLevel level)` ที่ฮาร์ดโค้ดส่งค่าสีกลับเอง:
    ```dart
    Color _getRiskColor(RiskLevel level) {
      switch (level) {
        case RiskLevel.high: return AppColors.danger;
        case RiskLevel.medium: return AppColors.warning;
        case RiskLevel.low: return AppColors.success;
        case RiskLevel.unknown: return Colors.grey;
      }
    }
    ```
  - ขณะที่ระบบมี `RiskLevelHelper.toColor(level)` (ใน [`lib/core/utils/risk_level_helper.dart:36-47`](file:///home/panuwat/project/scam_image_mobile/lib/core/utils/risk_level_helper.dart#L36-L47)) ซึ่งเป็น Single Authority สำหรับแมปสี Risk ทั่วทั้งแอป (และ `unknown` ใน Helper จะได้ `AppColors.outline`) แต่หน้าจอนี้กลับนิยามเองและใช้ `Colors.grey`

---

### 1.5 คีย์แปลภาษาที่ซ้ำซ้อนและไม่ได้ใช้งาน (Dead / Redundant Translation Keys)
- **ไฟล์และบรรทัด**:
  - [`lib/core/localization/app_translations.dart:96, 98, 99`](file:///home/panuwat/project/scam_image_mobile/lib/core/localization/app_translations.dart#L96) (ภาษาไทย)
  - [`lib/core/localization/app_translations.dart:500, 502, 503`](file:///home/panuwat/project/scam_image_mobile/lib/core/localization/app_translations.dart#L500) (ภาษาอังกฤษ)
  - [`lib/core/localization/app_translations.dart:363-367, 769-773`](file:///home/panuwat/project/scam_image_mobile/lib/core/localization/app_translations.dart#L363-L367)
- **พฤติกรรมจริง**:
  - คีย์ `result_ocr_accuracy`, `result_source_found`, `result_source_reports` ยังคงอยู่ในบล็อกผลการวิเคราะห์ส่วนบน แม้ว่าในโค้ดหน้าจอจริงจะเปลี่ยนไปใช้ `result_accuracy`, `result_first_detected`, `result_recurring` แล้ว
  - มีคีย์ `result_safe: 'Safe'` หลงเหลืออยู่ในพจนานุกรม ทั้งที่ตาม Domain Guardrail ระบุชัดเจนว่า Risk Scale มี 3 ระดับ (Low, Medium, High) ไม่มี Safe level

---

## 2. สิ่งที่ได้รับการยืนยันว่าทำงานถูกต้องแล้วตามสเปก (Verified Intact Features)

1. **การป้องกัน Fake Evidence บนภาพพรีวิว**:
   - ทั้ง `analysis_result_screen.dart` (L598-604, L777-780) และ `history_detail_screen.dart` (L526-532, L640-647) ตรวจสอบ URL จริงอย่างรัดกุม โดยจะแสดงป้าย `HEATMAP` เฉพาะเมื่อมี `heatmapUrl` จริงเท่านั้น หากมีเฉพาะภาพต้นฉบับจะแสดงป้าย `ภาพต้นฉบับ` / `Source image` และหากไม่มีทั้งสองอย่างจะแสดง `ไม่มีภาพตัวอย่าง` โดยไม่สร้าง overlay จำลอง
2. **หน้าจอ Heatmap Viewer ป้องกันการสร้าง Heatmap ปลอม**:
   - `heatmap_viewer_screen.dart` (L80-91, L118-148, L178-185) แสดงสถานะ `heatmap_unavailable_desc` เมื่อไม่มี URL และปิด toggle / overlay เมื่อไม่มีข้อมูลจริง ไม่มีการสุ่มสีหรือวาดจุดหลอก
3. **การแปลภาษาในโมดูล Auth/Onboarding**:
   - `login_screen.dart`, `register_screen.dart`, `onboarding_screen.dart`, และ `splash_screen.dart` ไม่มีข้อความภาษาไทยฮาร์ดโค้ดในตัวโค้ดแล้ว ทุกจุดเรียกผ่าน `.tr(context)` และ `AuthBloc` ส่งรหัส error key ให้ UI แปลภาษาตาม Locale ที่เลือก

---

## 3. ข้อสมมติฐานและประเด็นที่ต้องตรวจสอบเพิ่มเติม (Hypotheses)

1. **สมมติฐานเรื่องการเปิดใช้งาน Heatmap Viewer เมื่อไม่มี Heatmap**:
   - *สมมติฐาน*: ใน `HistoryDetailScreen` บรรทัดที่ 766 ปุ่ม `result_view_heatmap` อาจควรถูก disable หรือเปลี่ยนเป็น secondary state เมื่อ `result.heatmapUrl == null` เพื่อไม่ให้ผู้ใช้กดเข้าไปแล้วพบหน้าจอที่ไม่มี Heatmap ให้ดู
   - *หลักฐานที่ต้องรอการยืนยัน*: พฤติกรรมปัจจุบันออกแบบให้ `HeatmapViewerScreen` มี unavailable banner และยังสามารถดูภาพต้นฉบับพร้อมระบบ Zoom/Pan ได้ จึงยังไม่จัดว่าเป็นบั๊กฟังก์ชันร้ายแรง แต่อาจเป็นจุดปรับปรุง UX
2. **สมมติฐานเรื่องการส่ง TaskId และ ScanId ข้าม Route**:
   - *สมมติฐาน*: ใน `HistoryDetailScreen` ใช้ `widget.scanId` ส่งไปให้ `ResultBloc(ResultLoadRequested(widget.scanId))` ขณะที่ใน entity `AnalysisResult` มีทั้ง `scanId` และ `taskId`
   - *หลักฐาน*: หากฝั่ง Backend API ในบาง endpoint คาดหวัง UUID ของ task แต่อีก endpoint คาดหวัง scan ID อาจเกิดเคส 404 ได้หากสองค่านี้ไม่เหมือนกัน (ปัจจุบันในโค้ดมี fallback `scanId.isNotEmpty ? scanId : taskId` ในหลายจุด)

---

## สรุปผลการตรวจสอบ

- **สถานะไฟล์โค้ด**: ไม่มีการแก้ไขไฟล์ใดๆ โค้ดคงสภาพเดิมทั้งหมด
- **ข้อค้นพบสำคัญที่ต้องแก้ไขในการทำงานรอบถัดไป**:
  1. แก้ไขคำสะกดผิด `'ความม่ันใจว่าถูกดัดแปลง'` -> `'ความมั่นใจว่าถูกดัดแปลง'` ใน [`app_translations.dart:351`](file:///home/panuwat/project/scam_image_mobile/lib/core/localization/app_translations.dart#L351) และ [`analysis_result_model.dart:78`](file:///home/panuwat/project/scam_image_mobile/lib/features/result/data/models/analysis_result_model.dart#L78)
  2. แยกเงื่อนไขการให้สีของ `manipulationConfidence` ออกจาก `visualFactor.score` ใน [`history_detail_screen.dart:669-677`](file:///home/panuwat/project/scam_image_mobile/lib/features/history/presentation/screens/history_detail_screen.dart#L669-L677) เพื่อป้องกันการแสดงสีระดับอันตรายที่ขัดแย้งกับตัวเลขจริง
  3. ปรับ `_getRiskColor` ใน `history_detail_screen.dart` ให้เรียกใช้ `RiskLevelHelper.toColor` เพื่อความเป็น Single Authority
