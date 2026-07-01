# ScamGuard Mobile App — เอกสารอธิบายแอปพลิเคชัน

---

## 1. ภาพรวมของแอป

ScamGuard เป็นแอปพลิเคชัน Flutter สำหรับ Android และ iOS ที่ช่วยให้ผู้ใช้ทั่วไปสามารถตรวจสอบความน่าเชื่อถือของรูปภาพก่อนนำไปใช้ตัดสินใจ เช่น รูปสลิปโอนเงิน หลักฐานการชำระเงิน คิวอาร์โค้ด หรือเอกสารที่ส่งมาทางโซเชียลมีเดีย แอปส่งรูปภาพไปยัง Backend API เพื่อวิเคราะห์และแสดงผลระดับความเสี่ยงในรูปแบบที่เข้าใจง่าย

ชื่อแพ็กเกจ: `scam_image_mobile`
เวอร์ชัน: `1.0.0+1`
SDK Flutter: `^3.12.2`

---

## 2. สถาปัตยกรรมซอฟต์แวร์

### 2.1 Clean Architecture

แอปแบ่งโครงสร้างออกเป็น 3 ชั้นในแต่ละ feature:

- **Presentation layer** — Flutter widgets, BLoC/Cubit, Screens
- **Domain layer** — Entities, Repository interfaces, Use cases (pure Dart)
- **Data layer** — Repository implementations, Remote datasources, Models (JSON serialization)

ทิศทางของ dependency ไหลจาก Presentation เข้าหา Domain เท่านั้น Data layer implement interface ที่ Domain กำหนด ทำให้ domain logic ไม่ขึ้นกับ framework หรือ HTTP library ใด

### 2.2 โครงสร้างโฟลเดอร์

```
lib/
  core/
    constants/     app_colors.dart, app_typography.dart, app_spacing.dart
    di/            injection_container.dart (ServiceLocator)
    errors/        failures.dart, exceptions.dart
    network/       dio_client.dart, api_endpoints.dart
    router/        app_router.dart
    storage/       secure_storage.dart
    theme/         app_theme.dart
    utils/         risk_level_helper.dart
    widgets/       shared reusable widgets (barrel: widgets.dart)
  features/
    auth/
    history/
    notifications/
    report/
    result/
    scan/
    settings/
  main.dart
```

### 2.3 State Management

ใช้ `flutter_bloc` (BLoC pattern + Cubit) ทุก feature มี BLoC หรือ Cubit ของตัวเองที่ถูก provide ผ่าน `MultiBlocProvider` ใน `main.dart` ระดับ root ทำให้ทุกหน้าจอเข้าถึง state ได้โดยไม่ต้องส่งผ่าน constructor

---

## 3. Dependency Injection (ServiceLocator)

ไฟล์ `lib/core/di/injection_container.dart` ทำหน้าที่เป็น service locator อย่างง่าย ไม่ใช้ `get_it` แต่ใช้ static fields และ `init()` ที่เรียกก่อน `runApp` ใน `main.dart`

ลำดับการ initialize:

1. `SecureStorage` — wrapper ของ `flutter_secure_storage`
2. `Dio` — HTTP client ที่ configure ผ่าน `DioClient.createDio()`
3. Repository ทุกตัวในลำดับ: Auth, Scan, Result, History, Report, Settings

Base URL ของ API ถูกอ่านจาก compile-time environment variable `API_BASE_URL` ผ่าน `String.fromEnvironment()` ค่า default คือ `http://localhost:8000` สำหรับการพัฒนา

---

## 4. Network Layer

### 4.1 DioClient

`lib/core/network/dio_client.dart` สร้าง `Dio` instance พร้อม:

- `connectTimeout` และ `receiveTimeout` อย่างละ 30 วินาที
- Header `Content-Type: application/json` ทุก request
- Interceptors 2 ตัว: `AuthInterceptor` และ `LogInterceptor`

### 4.2 AuthInterceptor

`AuthInterceptor` ทำงาน 2 อย่าง:

1. ดึง access token จาก `SecureStorage` แนบเป็น `Authorization: Bearer {token}` ทุก request
2. เมื่อได้รับ HTTP 401 ให้ลอง refresh token โดยเรียก `POST /auth/refresh` ด้วย Dio ใหม่ (เพื่อป้องกัน interceptor loop) ถ้า refresh สำเร็จจะ retry request เดิมด้วย token ใหม่ ถ้าล้มเหลวจะ `deleteAll()` tokens และส่ง error ต่อเพื่อให้ app navigate ไป login

### 4.3 API Endpoints

ทุก path รวมอยู่ใน `ApiEndpoints` class เพื่อป้องกันการ hardcode string ซ้ำ

| Method | Path | หน้าที่ |
|--------|------|---------|
| POST | /auth/login | เข้าสู่ระบบ |
| POST | /auth/register | สมัครสมาชิก |
| POST | /auth/refresh | refresh token |
| POST | /auth/logout | ออกจากระบบ |
| GET | /auth/me | ดึงข้อมูลผู้ใช้ปัจจุบัน |
| POST | /scans | ส่งภาพเพื่อวิเคราะห์ (multipart) |
| GET | /scans/{taskId} | ตรวจสอบสถานะการวิเคราะห์ |
| GET | /scans/{taskId}/result | ดึงผลการวิเคราะห์ |
| DELETE | /scans/{taskId} | ยกเลิก/ลบงาน |
| GET | /history | ดึงประวัติการสแกน (pagination) |
| GET | /history/{scanId} | ดึงรายละเอียดประวัติ |
| DELETE | /history/{scanId} | ลบรายการประวัติ |
| POST | /reports | ส่งรายงาน |
| GET | /reports/categories | ดึงประเภทการรายงาน |
| GET | /consents/me | ดึงสถานะ consent |
| PUT | /consents/me | อัปเดต consent |
| POST | /privacy/export | ส่งออกข้อมูลส่วนตัว |
| DELETE | /privacy/account | ลบบัญชี |

---

## 5. Design System

### 5.1 สี (AppColors)

แอปใช้ Dark Mode เป็นธีมหลัก ทุกสีกำหนดเป็น const ใน `AppColors` class

**พื้นหลัง (Dark Mode)**

| Token | Hex | ใช้งาน |
|-------|-----|--------|
| bgDark | #0F1720 | พื้นหลังหลักทุกหน้า |
| surfaceDark | #162230 | Card, Bottom nav, AppBar |
| inverseSurface | #27313C | Input fill, secondary surface |

**พื้นหลัง (Light Mode)**

| Token | Hex | ใช้งาน |
|-------|-----|--------|
| bgLight | #F6F8FB | พื้นหลังในโหมดสว่าง |
| surfaceLight | #FFFFFF | Card ในโหมดสว่าง |

**Primary**

| Token | Hex | ใช้งาน |
|-------|-----|--------|
| primary | #006685 | ปุ่มและ accent ใน light mode |
| primaryFixedDim | #6CD2FF | ปุ่มและ accent ใน dark mode |
| primaryContainer | #00A6D6 | Container สี |

**Risk / Status**

| Token | Hex | ใช้งาน |
|-------|-----|--------|
| danger | #DC2626 | ความเสี่ยงสูง (สูง) |
| error | #BA1A1A | Error state |
| warning | #D68900 | ความเสี่ยงปานกลาง |
| success | #006E2D | ความเสี่ยงต่ำ / ปลอดภัย |

### 5.2 Typography (AppTypography)

ใช้ `google_fonts` package โหลด font จาก Google Fonts

- **Sarabun** — ใช้กับข้อความ UI ทั้งหมด รองรับภาษาไทยและอังกฤษ
- **Inter** — ใช้กับตัวเลขและข้อมูล (risk score, เปอร์เซ็นต์, วันที่)

| Style | ขนาด | Weight | ใช้งาน |
|-------|------|--------|--------|
| headlineLgMobile | 24sp | 700 | หัวข้อหลักของหน้า |
| titleMd | 22sp | 700 | หัวข้อ card / section |
| sectionHeader | 18sp | 600 | หัวข้อ section |
| bodyBase | 16sp | 400 | เนื้อหาทั่วไป |
| buttonLabel | 16sp | 600 | ข้อความบนปุ่ม |
| caption | 13sp | 400 | ข้อความช่วย / helper text |
| codeData | 14sp | 500 | ตัวเลข risk score (Inter) |

### 5.3 Spacing (AppSpacing)

ใช้ grid 4 point ทุกค่า spacing เป็น multiple ของ 4

| Constant | ค่า | ใช้งาน |
|----------|-----|--------|
| xs | 4.0 | gap เล็กมาก, icon padding |
| sm | 8.0 | gap เล็ก |
| gutter | 12.0 | padding แน่น |
| md | 16.0 | padding ทั่วไป (default) |
| safeMargin | 20.0 | horizontal margin ขอบจอ |
| lg | 24.0 | gap ใหญ่ |
| xl | 32.0 | gap ใหญ่มาก |
| xxl | 48.0 | gap ใหญ่พิเศษ |

### 5.4 Theme (AppTheme)

`AppTheme.dark` และ `AppTheme.light` สร้าง `ThemeData` ครบถ้วนโดยใช้ `ColorScheme` Material 3 ครอบคลุม: AppBar, BottomNavigationBar, Card, ElevatedButton, OutlinedButton, InputDecoration, Divider, Checkbox, Switch

`main.dart` ตั้ง `themeMode: ThemeMode.dark` เป็น default

---

## 6. Navigation (AppRouter)

ใช้ `go_router` package รวม route ทั้งหมดใน `AppRouter.router` ซึ่งเป็น static field

### 6.1 โครงสร้าง Route

```
/splash                    SplashScreen (จุดเริ่มต้น)
/onboarding                OnboardingScreen
/login                     LoginScreen
/register                  RegisterScreen

/main/home                 HomeScreen          (ShellRoute - bottom nav)
/main/history              HistoryScreen       (ShellRoute)
/main/history/:id          HistoryDetailScreen (ShellRoute - sub-route)
/main/report               ReportScamScreen    (ShellRoute)
/main/settings             SettingsScreen      (ShellRoute)
/main/settings/profile     UserProfileScreen   (ShellRoute - sub-route)
/main/settings/privacy     PrivacyConsentScreen(ShellRoute - sub-route)

/crop                      ImageCropScreen     (standalone, รับ filePath ผ่าน extra)
/loading                   AnalysisLoadingScreen (standalone, รับ filePath ผ่าน extra)
/result/:scanId            AnalysisResultScreen
/heatmap/:scanId           HeatmapViewerScreen (รับ imageUrl, heatmapUrl ผ่าน extra)
/notifications             NotificationsScreen
```

### 6.2 ShellRoute (Bottom Navigation)

Route ที่อยู่ใต้ `/main` ถูกห่อด้วย `ShellRoute` ซึ่ง render `MainShell` widget ที่มี `AppBottomNavigation` 4 tabs ถาวร:
1. หน้าหลัก (`/main/home`)
2. ประวัติ (`/main/history`)
3. แจ้งรายงาน (`/main/report`)
4. ตั้งค่า (`/main/settings`)

### 6.3 Extra Parameters

Route ที่ต้องส่ง parameter นอกเหนือจาก path ใช้ `state.extra` เป็น `Map<String, dynamic>`:
- `/crop` รับ `filePath`
- `/loading` รับ `filePath`
- `/heatmap/:scanId` รับ `imageUrl` และ `heatmapUrl`
- `/main/report` รับ `scanId` (optional)

---

## 7. Shared Core Widgets

ทุก widget อยู่ใน `lib/core/widgets/` และ export รวมผ่าน `widgets.dart`

### PrimaryButton
Full-width `ElevatedButton` ขนาด 52px สูง รูปทรง `StadiumBorder` รองรับ:
- `isLoading: true` — แสดง `CircularProgressIndicator` แทน label
- `enabled: false` — ปุ่ม disabled ด้วย opacity ลด
- `leadingIcon` — icon ก่อน label (optional)

### SecondaryButton
`OutlinedButton` สไตล์เดียวกับ `PrimaryButton` แต่ outlined

### RiskBadge
Pill-shaped badge แสดงระดับความเสี่ยงเป็น enum `RiskLevel`:
- `low` — พื้นสีเขียว (#006E2D) / ข้อความ "ต่ำ"
- `medium` — พื้นสีเหลือง (#D68900) / ข้อความ "ปานกลาง"
- `high` — พื้นสีแดง (#DC2626) / ข้อความ "สูง"
- `safe` — พื้นสีเขียว (#006E2D) / ข้อความ "ปลอดภัย"

มี static method `levelFromString(String)` สำหรับแปลง string จาก API

### RiskProgressBar
Horizontal progress bar แสดง risk score 0-100 สีเปลี่ยนตามระดับ (เขียว/เหลือง/แดง)

### RiskGauge
SVG semicircle gauge วาดด้วย `CustomPainter` แสดงคะแนนแบบ half-circle gauge

### AppTopBar
`PreferredSizeWidget` ที่ใช้เป็น AppBar มาตรฐานของแอป แสดง shield icon + "ScamGuard" title รองรับ custom actions

### AppBottomNavigation
`BottomNavigationBar` 4 tabs พร้อม active state styling ใช้ใน `MainShell`

### GlassCard
`Container` กึ่งโปร่งใส (`rgba(22,34,48,0.8)`) พร้อม border radius 16px ใช้เป็น form card บนหน้า Login/Register

### ConsentCheckboxTile
Row ที่มี `Checkbox` + label + optional description ทั้ง row tap ได้เพื่อ toggle

### AnalysisStepTile
แสดงขั้นตอนการวิเคราะห์ 3 สถานะ: done (check icon เขียว), active (spinner สีหลัก), pending (opacity 40%)

### EmptyStateView
Icon + title + subtitle สำหรับ list ที่ว่างเปล่า

### ErrorStateView
Icon + message + retry button สำหรับ error state

### LoadingOverlay
Full-screen loading overlay

### PermissionRequestView
แสดงเหตุผลและปุ่ม "เปิดการตั้งค่า" เมื่อ permission ถูกปฏิเสธ

### HistoryListItem
Card สำหรับแสดงรายการประวัติ: thumbnail 80x80, title, วันที่, `RiskProgressBar`, `RiskBadge`

---

## 8. Domain Entities

### User
```
id           String
email        String
displayName  String
avatarUrl    String? (optional)
```

### AnalysisResult
```
scanId       String
taskId       String
status       String ("completed" | "failed")
riskScore    int (0-100)
riskLevel    RiskLevel (enum: low, medium, high)
summary      String (คำอธิบายผลเป็นภาษาธรรมดา)
imageUrl     String? (URL รูปต้นฉบับ)
heatmapUrl   String? (URL รูป heatmap)
createdAt    DateTime
factors      List<RiskFactor>
```

### RiskFactor
```
type         String ("textual" | "source" | "visual")
score        int
title        String
details      List<String>
```

### ScanHistoryItem
```
scanId       String
thumbnailUrl String?
riskScore    int
riskLevel    RiskLevel
status       String
createdAt    DateTime
title        String?
```

### ConsentSetting
```
processingConsent  bool (บังคับ)
historyConsent     bool
researchConsent    bool
```

### RiskLevelHelper
Utility class แปลง numeric score เป็น enum:
- 0-39: `RiskLevel.low`
- 40-69: `RiskLevel.medium`
- 70-100: `RiskLevel.high`

และ `toThaiLabel()` แปลง enum เป็นข้อความภาษาไทย (ต่ำ / ปานกลาง / สูง)

---

## 9. BLoC / Cubit ทั้งหมด

### SplashCubit
ตรวจสอบ session เมื่อแอปเปิด
- States: `SplashInitial`, `CheckingSession`, `Authenticated`, `Unauthenticated`, `ConsentRequired`, `Failure`
- ตรวจ access token -> ถ้าหมดอายุลอง refresh -> ถ้าไม่มี consent นำไป onboarding

### AuthBloc
Events: `LoginRequested`, `RegisterRequested`, `LogoutRequested`
States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(User)`, `AuthUnauthenticated`, `AuthError(message)`
- Login/Register ผ่าน `AuthRepository`
- แปลง exception เป็นข้อความภาษาไทยที่เป็นมิตร

### ConsentCubit
จัดการสถานะ checkbox ในหน้า Onboarding
- `toggleTerms()` / `toggleResearch()`
- บันทึก consent state ก่อน navigate ไป login

### ScanBloc
Events: `ImageSelected`, `CropConfirmed`, `AnalysisStarted`, `AnalysisPollTick`, `AnalysisCompleted`
States: `ScanInitial`, `ImagePicked`, `ImageCropped`, `Uploading`, `Polling(progress, step)`, `AnalysisDone`, `ScanError`
- Polling `GET /scans/{taskId}` ทุก 3 วินาทีด้วย `Timer.periodic`
- Timeout หลัง 120 วินาที
- เมื่อ status = "completed" fetch result แล้ว navigate ไป `/result/:scanId`

### ResultBloc
Events: `ResultRequested(taskId)`
States: `ResultInitial`, `ResultLoading`, `ResultLoaded(AnalysisResult)`, `ResultError`

### HistoryBloc
Events: `HistoryLoaded`, `HistoryRefreshed`, `HistorySearched`, `HistoryItemDeleted`
States: `HistoryInitial`, `HistoryLoading`, `HistoryDataLoaded(items)`, `HistoryEmpty`, `HistoryError`
- Search ใช้ debounce 400ms ก่อนส่งไป API

### ReportBloc
Events: `ReportSubmitted(data)`
States: `ReportInitial`, `ReportSubmitting`, `ReportSuccess`, `ReportError`

### SettingsCubit
Events/Methods: `toggleTheme()`, `clearCache()`, `logout()`
States: `SettingsState(themeMode, language)`

### NotificationsCubit
States: `NotificationsState(items, unreadCount)`
- `loadNotifications()` เรียกตอน init

---

## 10. หน้าจอทั้งหมด (16 หน้าจอ)

### 10.1 SplashScreen (`/splash`)

จุดเริ่มต้นของแอป แสดงผลก่อนตรวจ session

Layout: full screen gradient เข้มจาก `#0F1720` ไปยัง `#162230`
- บรรยากาศ blur circles สี primary ด้านบนขวาและสีเขียวด้านล่างซ้าย
- ตรงกลาง: glass card มีไอคอน shield (80px) + ไอคอน search overlay
- ชื่อแอป "Scam Image Detection" (headlineLgMobile)
- คำบรรยาย "ตรวจจับรูปภาพหลอกลวง"
- ด้านล่าง: วงแหวน loading หมุน + ข้อความสถานะ cycling 4 ข้อความ
- `SplashCubit` ทำงานเบื้องหลัง navigate ไปหน้าที่เหมาะสมหลัง check เสร็จ

Requirement: REQ-001

### 10.2 OnboardingScreen (`/onboarding`)

แสดงครั้งแรกที่ผู้ใช้ยังไม่ได้ยอมรับ consent

- Shield icon + หัวข้อ "ยินดีต้อนรับสู่ ScamGuard"
- คำอธิบายวัตถุประสงค์ของแอป
- Disclaimer: "ผลการประเมินเป็นเพียงการประเมินความเสี่ยง ไม่ใช่คำตัดสินทางกฎหมาย"
- `ConsentCheckboxTile` 2 ตัว:
  1. ยอมรับเงื่อนไขการใช้งาน (บังคับ)
  2. ยินยอมให้ใช้ข้อมูลปรับปรุงโมเดล (ไม่บังคับ)
- ปุ่ม "ดำเนินการต่อ" disabled จนกว่าจะยอมรับข้อ 1

Requirement: REQ-002

### 10.3 LoginScreen (`/login`)

- พื้นหลัง `bgDark` พร้อม atmospheric blur background
- `GlassCard` ครอบ form ทั้งหมด
- ส่วน brand: shield icon + "ScamGuard" + คำบรรยาย
- Email field พร้อม mail icon, validate: ไม่ว่าง + มี @
- Password field พร้อม lock icon + toggle visibility
- Link "ลืมรหัสผ่าน" ด้านขวา
- Checkbox "จดจำการใช้งานของฉัน"
- ปุ่ม "เข้าสู่ระบบ" (PrimaryButton) — loading ขณะรอ API
- Divider "หรือ"
- ปุ่ม Google Login (outlined พร้อม Google logo)
- Link "สมัครสมาชิก" ไปยัง `/register`
- `BlocListener` navigate ไป `/main/home` เมื่อ `AuthAuthenticated`

Requirement: REQ-003

### 10.4 RegisterScreen (`/register`)

- Display Name, Email, Password, Confirm Password fields
- Inline validation: Password ขั้นต่ำ 8 ตัวอักษร, ต้องตรงกัน
- Checkbox ยอมรับเงื่อนไข
- ปุ่ม "สมัครสมาชิก"
- Link กลับไป login

Requirement: REQ-004

### 10.5 HomeScreen (`/main/home`)

หน้าหลักภายใน bottom nav shell

- `AppTopBar` พร้อม notifications icon (dot badge แสดงเมื่อมีแจ้งเตือนที่ยังไม่ได้อ่าน)
- Greeting section: "สวัสดี, [displayName]" + subtitle
- Upload Card (gradient `#162230` -> `#0F1720`):
  - วงกลม upload icon 80px
  - คำอธิบาย + hint ประเภทไฟล์ที่รองรับ
  - ปุ่ม "อัปโหลดรูปภาพ" พร้อม pulse animation
  - รองรับ jpg, jpeg, png, webp ขนาดสูงสุด 10MB
- Safety Tips Bento Grid (2 คอลัมน์):
  - verified_user icon card
  - link_off icon card
  - Full-width report card
- Recent History section: รายการล่าสุด 3-5 รายการ + link "ดูทั้งหมด"
- เมื่อเลือกไฟล์สำเร็จ navigate ไป `/crop`
- `PermissionRequestView` เมื่อ permission ถูกปฏิเสธ

Requirement: REQ-005

---

### 10.6 ImageCropScreen (`/crop`)

รับ `filePath` ผ่าน route extra

- Full screen dark background
- `image_cropper` package แสดงรูปพร้อม crop overlay
- Bottom controls: ปุ่มหมุนภาพ, ปุ่มเปลี่ยนรูป
- ปุ่ม "เริ่มวิเคราะห์" (PrimaryButton) ด้านล่าง
- เมื่อกด back หลัง crop แล้ว — แสดง `AlertDialog` ยืนยันก่อนยกเลิก
- เมื่อยืนยัน navigate ไป `/loading` พร้อม filePath

Requirement: REQ-006

### 10.7 AnalysisLoadingScreen (`/loading`)

รับ `filePath` ผ่าน route extra

- `AppTopBar`
- Circular progress SVG วาดด้วย `CustomPainter` (radius 84):
  - Track สีเข้ม `#27313C`
  - Arc สีหลัก animated ตาม progress %
  - ตรงกลาง: thumbnail รูปที่เลือก พร้อม scanning line animation
  - Badge % ลอยอยู่ด้านล่าง circle
- Heading "กำลังวิเคราะห์ความปลอดภัย" + dots wave animation
- Step Checklist Card (surfaceDark):
  - Step 1 (OCR): done — check icon สีเขียว
  - Step 2 (Source Check): active — spinner + search icon
  - Step 3 (Visual Analysis): pending — opacity 40%
- Privacy badge: "การวิเคราะห์แบบเข้ารหัส"
- `ScanBloc` poll `GET /scans/{taskId}` ทุก 3 วินาที ด้วย `Timer.periodic`
- Timeout 120 วินาที แสดง `ErrorStateView` พร้อมปุ่ม retry
- เมื่อสำเร็จ navigate ไป `/result/:scanId`

Requirement: REQ-007

### 10.8 AnalysisResultScreen (`/result/:scanId`)

รับ `taskId` จาก path parameter

- `AppTopBar`
- Risk Gauge Section:
  - SVG semicircle gauge วาดด้วย `CustomPainter` (viewBox 200x100)
  - ตัวเลข risk score ขนาดใหญ่ (สีตามระดับ)
  - `RiskBadge` แสดงระดับ
- Summary Card (surfaceDark): analytics icon + ข้อความอธิบายผล
- Analysis Bento Grid (2 คอลัมน์):
  - Contact info card
  - Transaction card
  - Full-width: Heatmap preview card พร้อม image background overlay
- Action Buttons (2 แถว):
  - แถว 1: "ดูรายละเอียด" (primary), "ดู Heatmap" (primary-container)
  - แถว 2: "รายงานภาพต้องสงสัย" (outlined danger), "แชร์ผลลัพธ์" (outlined cyan)
- Multi-layer detail sections (expandable): Textual, Source, Visual

Requirement: REQ-008

### 10.9 HeatmapViewerScreen (`/heatmap/:scanId`)

รับ `taskId`, `imageUrl`, `heatmapUrl` จาก path + extra

- Full screen dark background
- `InteractiveViewer` รองรับ zoom/pan ด้วยนิ้ว
- Stack: รูปต้นฉบับ + heatmap overlay ที่ปรับ opacity ได้
- Toggle bar: "ต้นฉบับ" / "Heatmap"
- Opacity `Slider` (0.0 ถึง 1.0) ปรับความชัดของ heatmap
- ปุ่ม download/save รูป
- คำอธิบาย: สีร้อน (แดง) = ส่วนที่มีความเสี่ยงสูงที่สุด

Requirement: REQ-009

### 10.10 HistoryScreen (`/main/history`)

- `AppTopBar` + notifications button
- Row: "ประวัติการตรวจสอบ" + badge จำนวนรายการ
- Search bar (rounded-xl, search icon) + Filter button
- `HistoryBloc` dispatch `HistoryLoaded` เมื่อ init
- Search ใช้ debounce 400ms dispatch `HistorySearched`
- แต่ละรายการ: `_HistoryCard`
  - Thumbnail 80x80 (`CachedNetworkImage`)
  - Title + วันที่ (calendar icon)
  - `RiskProgressBar` + score %
  - `RiskBadge` มุมบนขวา
  - Swipe left ลบ (`Dismissible` widget ด้วย `DismissDirection.endToStart`)
- `RefreshIndicator` pull-to-refresh
- `HistoryEmpty` state: `EmptyStateView` "ยังไม่มีประวัติการตรวจสอบ"
- Pagination: load more เมื่อ scroll ถึงท้าย list

Requirement: REQ-010

### 10.11 HistoryDetailScreen (`/main/history/:id`)

รับ `scanId` จาก path parameter

- Layout เหมือน `AnalysisResultScreen`
- แสดงข้อมูล metadata + คะแนน แม้ไม่มีรูปต้นฉบับ
- แสดงหมายเหตุเมื่อรูปต้นฉบับถูกลบแล้ว
- ปุ่ม "สแกนภาพใหม่" navigate กลับไป home

Requirement: REQ-011

---

### 10.12 ReportScamScreen (`/main/report`)

รับ `scanId` ผ่าน route extra (optional — สามารถเปิดจาก result screen หรือ bottom nav)

- AppBar "รายงานภาพต้องสงสัย"
- Image preview card (จาก scanId หรือรูปปัจจุบัน)
- Category picker (FilterChip grid):
  - Romance Scam
  - ซื้อขายออนไลน์
  - สลิปปลอม
  - ลงทุน
  - ปลอมแปลงตัวตน
  - AI/Deepfake
  - อื่นๆ
- Detail TextField (multiline, validate ขั้นต่ำ 10 ตัวอักษร)
- Platform picker: Facebook, LINE, Instagram, Marketplace, Website
- Reference URL / account field
- `ConsentCheckboxTile` ยินยอมใช้ข้อมูลเพื่อวิจัย
- ปุ่ม "ส่งรายงาน" พร้อม loading state + success feedback

Requirement: REQ-012

### 10.13 NotificationsScreen (`/notifications`)

- `AppTopBar`
- รายการแจ้งเตือน 3 ประเภทพร้อม icon:
  - analytics icon — งานวิเคราะห์เสร็จ
  - warning icon — งานล้มเหลว
  - campaign icon — Scam Alert ทั่วไป
- แตะ notification งานวิเคราะห์ navigate ไป `/result/:scanId`
- ปุ่ม "ล้างทั้งหมด" ด้านบนขวา
- `Dismissible` swipe เพื่อลบรายการ
- `EmptyStateView` เมื่อไม่มีแจ้งเตือน (notifications_off icon)

Requirement: REQ-013

### 10.14 SettingsScreen (`/main/settings`)

- User info header: avatar placeholder + displayName + email
- ListTile sections:
  - โปรไฟล์ — navigate ไป `/main/settings/profile`
  - ความปลอดภัยของบัญชี
  - การแจ้งเตือน
  - ภาษา
  - รูปแบบ (theme toggle switch Light/Dark)
  - ความเป็นส่วนตัวและ Consent — navigate ไป `/main/settings/privacy`
  - ล้าง Cache — confirmation snackbar
  - ออกจากระบบ (สีแดง danger) — `AlertDialog` ยืนยัน -> ลบ token + cache -> navigate ไป `/login`

Requirement: REQ-014

### 10.15 UserProfileScreen (`/main/settings/profile`)

- `CircleAvatar` 80px + edit icon overlay
- Display Name TextField (แก้ไขได้)
- Email TextField (read-only)
- ปุ่ม "บันทึก" (PrimaryButton)

Requirement: REQ-015

### 10.16 PrivacyConsentScreen (`/main/settings/privacy`)

- Section "การจัดการความยินยอม"
- `SwitchListTile` 3 ตัว:
  1. ประมวลผลรูปภาพ (required — ปิดไม่ได้)
  2. เก็บประวัติการสแกน
  3. ใช้ข้อมูลเพื่อการวิจัย
- ปุ่ม "ส่งออกข้อมูลของฉัน" เรียก `POST /privacy/export`
- ปุ่ม "ลบบัญชี" (สีแดง danger) — 2-step confirmation dialog ก่อนเรียก `DELETE /privacy/account`
- ถอน research consent ได้โดยไม่กระทบการใช้งานพื้นฐาน

Requirement: REQ-016

---

## 11. Security

| มาตรการ | รายละเอียด |
|---------|-----------|
| Token storage | Access token และ refresh token เก็บใน `flutter_secure_storage` เท่านั้น ไม่เก็บใน SharedPreferences หรือ plain storage |
| HTTPS | ทุก API call ใช้ HTTPS ห้ามใช้ HTTP ใน production |
| Token lifecycle | ลบ token ทุกครั้งที่ logout หรือ refresh ล้มเหลว |
| Auto refresh | `AuthInterceptor` จัดการ 401 โดยอัตโนมัติ ไม่ต้องให้ผู้ใช้ login ใหม่ทันที |
| Error messages | ไม่แสดง stack trace หรือข้อความ technical error ต่อผู้ใช้ แปลงเป็นภาษาไทยที่เข้าใจง่าย |
| Image upload | ตรวจสอบ format (jpg/jpeg/png/webp) และขนาด (<= 10MB) ก่อน upload |
| clientRequestId | ทุก scan request ส่ง UUID เพื่อป้องกัน duplicate submission |

---

## 12. Performance

| เงื่อนไข | เป้าหมาย |
|---------|---------|
| เปิดแอปถึงหน้าแรก | ภายใน 3 วินาที |
| เลือกไฟล์เข้า preview | ภายใน 1 วินาที |
| Image compression | บีบอัดอัตโนมัติเมื่อไฟล์ > 10MB โดยใช้ image_picker quality parameter |
| Network timeout | 30 วินาทีต่อ request |
| Analysis timeout | 120 วินาทีรวม polling ทั้งหมด |
| Polling interval | 3 วินาที |
| Search debounce | 400 milliseconds |

---

## 13. Accessibility

- ปุ่มทุกปุ่มมีพื้นที่แตะอย่างน้อย 44x44 px
- ทุก icon button มี `tooltip` หรือ Semantic Label
- สีสถานะทุกสีมีข้อความประกอบเสมอ (ไม่ใช้สีอย่างเดียว)
- รองรับ dynamic font size เท่าที่ layout ยังรับได้
- `ConsentCheckboxTile` ทั้ง row tap ได้ ไม่จำกัดให้แตะที่ checkbox เท่านั้น

---

## 14. Error Handling Pattern

ทุกหน้าที่เรียก API ต้องมีครบ 3 states:

1. **Loading state** — แสดง `CircularProgressIndicator` หรือ `LoadingOverlay`
2. **Error state** — แสดง `ErrorStateView` พร้อมปุ่ม retry / open settings
3. **Empty state** — แสดง `EmptyStateView` เมื่อ result ว่างเปล่า

---

## 15. Dependencies

### Runtime dependencies

| Package | Version | หน้าที่ |
|---------|---------|--------|
| flutter_bloc | ^9.1.1 | State management (BLoC pattern) |
| equatable | ^2.0.7 | Value equality สำหรับ entities และ states |
| go_router | ^15.1.2 | Declarative routing |
| dio | ^5.8.0+1 | HTTP client |
| flutter_secure_storage | ^9.2.4 | เก็บ token อย่างปลอดภัย |
| image_picker | ^1.1.2 | เลือกรูปจาก gallery/camera |
| image_cropper | ^9.0.0 | crop และ rotate รูป |
| cached_network_image | ^3.4.1 | แสดงรูปจาก URL พร้อม cache |
| google_fonts | ^6.2.1 | Sarabun + Inter fonts |
| uuid | ^4.5.1 | สร้าง clientRequestId |
| intl | ^0.20.2 | date formatting |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| share_plus | ^10.1.4 | share ผลลัพธ์ผ่านแอปอื่น |

### Dev dependencies

| Package | Version | หน้าที่ |
|---------|---------|--------|
| flutter_test | SDK | Flutter widget testing framework |
| flutter_lints | ^6.0.0 | Lint rules |
| bloc_test | ^10.0.0 | Testing helpers สำหรับ BLoC |
| mocktail | ^1.0.4 | Mock objects สำหรับ unit test |

---

## 16. Testing

### โครงสร้าง test files

```
test/
  widget_test.dart                          smoke test ของ ScamGuardApp
  core/
    utils/
      risk_level_helper_test.dart           unit test boundary conditions
    widgets/
      risk_badge_test.dart                  widget test สี + ข้อความ 4 ระดับ
      consent_checkbox_tile_test.dart       widget test checkbox + button integration
  features/
    auth/
      presentation/
        bloc/
          auth_bloc_test.dart               BLoC test login/register
        screens/
          login_screen_test.dart            widget test form validation
    scan/
      presentation/
        bloc/
          scan_bloc_test.dart               BLoC test polling state
    history/
      presentation/
        screens/
          history_screen_test.dart          widget test empty/loading/error/data states
```

### สิ่งที่ครอบคลุม

- **Unit tests** — `RiskLevelHelper` boundary conditions (0, 39, 40, 69, 70, 100)
- **BLoC tests** — `AuthBloc` (login success/failure), `ScanBloc` (polling transitions)
- **Widget tests**:
  - `RiskBadge` — ตรวจสี background และข้อความ Thai ทุก 4 ระดับ
  - `ConsentCheckboxTile` — label, description, value toggle, onChanged callback
  - `LoginScreen` — email empty, email invalid format, password empty, password visibility toggle
  - `HistoryScreen` — HistoryEmpty, HistoryLoading, HistoryDataLoaded, HistoryError states

### Test utilities

- `GoogleFonts.config.allowRuntimeFetching = false` ใน `setUpAll` เพื่อป้องกัน network call
- `MockHistoryRepository` extends `Mock implements HistoryRepository` (mocktail)
- `_MockHistoryBloc` extends `MockBloc` (bloc_test) สำหรับ control state โดยตรง
- ทุก widget test wrap ใน `MaterialApp` dark theme เพื่อป้องกัน Directionality error
- Screen ที่ใช้ go_router wrap ใน `MaterialApp.router` พร้อม `GoRouter` minimal routes

---

## 17. Flow การทำงานหลักของแอป

### 17.1 Flow แรกเข้าแอป

```
เปิดแอป
  -> SplashScreen (แสดง logo + loading)
     -> SplashCubit.checkSession()
        -> มี token ที่ยังใช้ได้     -> /main/home
        -> token หมดอายุ             -> refresh token
              -> refresh สำเร็จ      -> /main/home
              -> refresh ล้มเหลว     -> /login
        -> ไม่มี token               -> /login
        -> ไม่มี consent             -> /onboarding
```

### 17.2 Flow Onboarding

```
/onboarding
  -> ยอมรับ terms (บังคับ) + optional research consent
  -> ปุ่ม "ดำเนินการต่อ" เปิด
  -> บันทึก consent state
  -> /login
```

### 17.3 Flow การสแกนภาพ

```
/main/home
  -> แตะ "อัปโหลดรูปภาพ"
  -> image_picker เปิด file picker
  -> เลือกไฟล์สำเร็จ
  -> /crop (พร้อม filePath)
     -> ผู้ใช้ crop/rotate รูป
     -> แตะ "เริ่มวิเคราะห์"
     -> /loading (พร้อม filePath)
        -> ScanBloc POST /scans (multipart)
        -> ได้ taskId
        -> poll GET /scans/{taskId} ทุก 3 วินาที
        -> status = "completed"
        -> GET /scans/{taskId}/result
        -> /result/:scanId
           -> แสดง risk gauge, badge, summary, factors
           -> ปุ่ม "ดู Heatmap" -> /heatmap/:scanId
           -> ปุ่ม "รายงาน" -> /main/report?scanId=...
           -> ปุ่ม "แชร์" -> share_plus
```

### 17.4 Flow การดูประวัติ

```
/main/history
  -> HistoryBloc load GET /history
  -> รายการ scan items
  -> แตะรายการ -> /main/history/:id
     -> แสดงผล analysis เดิม
     -> "สแกนภาพใหม่" -> /main/home
  -> Swipe left -> delete item
  -> Pull to refresh -> reload
  -> Search -> debounce 400ms -> GET /history?keyword=...
```

### 17.5 Flow การรายงาน

```
/main/report (จาก bottom nav หรือ result screen)
  -> เลือก category (FilterChip)
  -> กรอกรายละเอียด (ขั้นต่ำ 10 ตัวอักษร)
  -> เลือก platform
  -> กรอก URL/account (optional)
  -> ยินยอม consent
  -> "ส่งรายงาน" -> POST /reports
  -> success feedback
```

### 17.6 Flow Logout

```
/main/settings
  -> "ออกจากระบบ" (สีแดง)
  -> AlertDialog "ยืนยันการออกจากระบบ?"
  -> ยืนยัน
  -> ลบ access token + refresh token จาก SecureStorage
  -> ล้าง cache
  -> navigate ไป /login
```

---

## 18. Environment Configuration

แอปรับ configuration ผ่าน compile-time environment variable:

| Variable | Default | คำอธิบาย |
|----------|---------|---------|
| API_BASE_URL | `http://localhost:8000` | Base URL ของ Backend API |

วิธีตั้งค่าเมื่อ build:
```
flutter run --dart-define=API_BASE_URL=https://api.example.com
flutter build apk --dart-define=API_BASE_URL=https://api.example.com
```

---

## 19. สรุปรายการไฟล์หลัก

| ไฟล์ | หน้าที่ |
|------|--------|
| `lib/main.dart` | Entry point, MultiBlocProvider, MaterialApp.router |
| `lib/core/di/injection_container.dart` | ServiceLocator, wire up ทุก dependency |
| `lib/core/router/app_router.dart` | Route definitions ทั้งหมด (go_router) |
| `lib/core/theme/app_theme.dart` | Dark + Light ThemeData |
| `lib/core/constants/app_colors.dart` | Color tokens ทั้งหมด |
| `lib/core/constants/app_typography.dart` | Text styles (Sarabun + Inter) |
| `lib/core/constants/app_spacing.dart` | Spacing constants (4-point grid) |
| `lib/core/network/dio_client.dart` | Dio factory + AuthInterceptor |
| `lib/core/network/api_endpoints.dart` | API path constants |
| `lib/core/storage/secure_storage.dart` | flutter_secure_storage wrapper |
| `lib/core/utils/risk_level_helper.dart` | Score -> RiskLevel + Thai label |
| `lib/core/widgets/widgets.dart` | Barrel export ทุก shared widget |
