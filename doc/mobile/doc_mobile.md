# ScamGuard Mobile App — เอกสารอธิบายแอปพลิเคชัน

---

## 1. ภาพรวมของแอป

ScamGuard เป็นแอปพลิเคชัน Flutter สำหรับ Android และ iOS ที่ช่วยให้ผู้ใช้ทั่วไปสามารถตรวจสอบความน่าเชื่อถือของรูปภาพก่อนนำไปใช้ตัดสินใจ เช่น รูปสลิปโอนเงิน หลักฐานการชำระเงิน คิวอาร์โค้ด หรือเอกสารที่ส่งมาทางโซเชียลมีเดีย แอปส่งรูปภาพไปยัง ระบบหลังบ้าน (Backend) API เพื่อวิเคราะห์และแสดงผลระดับความเสี่ยงในรูปแบบที่เข้าใจง่าย

ชื่อแพ็กเกจ: `scam_image_mobile`
เวอร์ชัน: `1.0.0+1`
SDK Flutter: `^3.12.2`

---

## 2. สถาปัตยกรรมซอฟต์แวร์

### 2.1 Clean Architecture

แอปแบ่งโครงสร้างออกเป็น 3 ชั้นในแต่ละ ฟีเจอร์ (feature):

- **ชั้นการแสดงผล (Presentation layer)** — Flutter widgets, BLoC/Cubit, Screens
- **ชั้นโดเมน (Domain layer)** — Entities, Repository interfaces, Use cases (pure Dart)
- **ชั้นข้อมูล (Data layer)** — Repository implementations, Remote datasources, Models (JSON serialization)

ทิศทางของ การพึ่งพา (dependency) ไหลจาก Presentation เข้าหา Domain เท่านั้น ชั้นข้อมูล (Data layer) ใช้งาน (implement) อินเทอร์เฟซ (interface) ที่ Domain กำหนด ทำให้ domain ตรรกะ (logic) ไม่ขึ้นกับ เฟรมเวิร์ก (framework) หรือ HTTP library ใด

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

### 2.3 สถานะ (state) Management

ใช้ `flutter_bloc` (BLoC pattern + Cubit) ทุก ฟีเจอร์ (feature) มี BLoC หรือ Cubit ของตัวเองที่ถูก ให้บริการ (provide) ผ่าน `MultiBlocProvider` ใน `main.dart` ระดับ root ทำให้ทุกหน้าจอเข้าถึง สถานะ (state) ได้โดยไม่ต้องส่งผ่าน คอนสตรัคเตอร์ (constructor)

---

## 3. การพึ่งพา (dependency) Injection (ServiceLocator)

ไฟล์ `lib/core/di/injection_container.dart` ทำหน้าที่เป็น service locator อย่างง่าย ไม่ใช้ `get_it` แต่ใช้ static fields และ `init()` ที่เรียกก่อน `runApp` ใน `main.dart`

ลำดับการ initialize:

1. `SecureStorage` — ตัวครอบ (wrapper) ของ `flutter_secure_storage`
2. `Dio` — HTTP client ที่ ตั้งค่า (configure) ผ่าน `DioClient.createDio()`
3. Repository ทุกตัวในลำดับ: Auth, Scan, Result, History, Report, Settings

Base URL ของ API ถูกอ่านจาก ตัวแปรสภาพแวดล้อมตอนคอมไพล์ (compile-time environment variable) `API_BASE_URL` ผ่าน `ข้อความ (string).fromEnvironment()` ค่า ค่าเริ่มต้น (default) คือ `http://localhost:8000` สำหรับการพัฒนา

---

## 4. Network Layer

### 4.1 DioClient

`lib/core/network/dio_client.dart` สร้าง `Dio` instance พร้อม:

- `connectTimeout` และ `receiveTimeout` อย่างละ 30 วินาที
- Header `Content-Type: application/json` ทุก คำขอ (request)
- Interceptors 2 ตัว: `AuthInterceptor` และ `LogInterceptor`

### 4.2 AuthInterceptor

`AuthInterceptor` ทำงาน 2 อย่าง:

1. ดึง access โทเคน (token) จาก `SecureStorage` แนบเป็น `Authorization: Bearer {โทเคน (token)}` ทุก คำขอ (request)
2. เมื่อได้รับ HTTP 401 ให้ลอง ต่ออายุ (refresh) โทเคน (token) โดยเรียก `POST /auth/ต่ออายุ (refresh)` ด้วย Dio ใหม่ (เพื่อป้องกัน interceptor loop) ถ้า ต่ออายุ (refresh) สำเร็จจะ ลองใหม่ (retry) คำขอ (request) เดิมด้วย โทเคน (token) ใหม่ ถ้าล้มเหลวจะ `deleteAll()` tokens และส่ง ข้อผิดพลาด (error) ต่อเพื่อให้ app เปลี่ยนหน้า (navigate) ไป login

### 4.3 API Endpoints

ทุก เส้นทาง (path) รวมอยู่ใน `ApiEndpoints` class เพื่อป้องกันการ ฝังค่าในโค้ด (hardcode) ข้อความ (string) ซ้ำ

| เมธอด (method) | เส้นทาง (path) | หน้าที่ |
|--------|------|---------|
| POST | /auth/login | เข้าสู่ระบบ |
| POST | /auth/register | สมัครสมาชิก |
| POST | /auth/ต่ออายุ (refresh) | ต่ออายุ (refresh) โทเคน (token) |
| POST | /auth/logout | ออกจากระบบ |
| GET | /auth/me | ดึงข้อมูลผู้ใช้ปัจจุบัน |
| POST | /scans | ส่งภาพเพื่อวิเคราะห์ (หลายส่วน (multipart)) |
| GET | /scans/{taskId} | ตรวจสอบสถานะการวิเคราะห์ |
| GET | /scans/{taskId}/result | ดึงผลการวิเคราะห์ |
| DELETE | /scans/{taskId} | ยกเลิก/ลบงาน |
| GET | /history | ดึงประวัติการสแกน (การแบ่งหน้า (pagination)) |
| GET | /history/{scanId} | ดึงรายละเอียดประวัติ |
| DELETE | /history/{scanId} | ลบรายการประวัติ |
| POST | /reports | ส่งรายงาน |
| GET | /reports/categories | ดึงประเภทการรายงาน |
| GET | /consents/me | ดึงสถานะ ความยินยอม (consent) |
| PUT | /consents/me | อัปเดต ความยินยอม (consent) |
| POST | /privacy/export | ส่งออกข้อมูลส่วนตัว |
| DELETE | /privacy/account | ลบบัญชี |

---

## 5. Design System

### 5.1 สี (AppColors)

แอปใช้ Dark Mode เป็นธีมหลัก ทุกสีกำหนดเป็น ค่าคงที่ (const) ใน `AppColors` class

**พื้นหลัง (Dark Mode)**

| โทเคน (token) | Hex | ใช้งาน |
|-------|-----|--------|
| bgDark | #0F1720 | พื้นหลังหลักทุกหน้า |
| surfaceDark | #162230 | การ์ด (card), Bottom nav, AppBar |
| inverseSurface | #27313C | Input fill, secondary surface |

**พื้นหลัง (Light Mode)**

| โทเคน (token) | Hex | ใช้งาน |
|-------|-----|--------|
| bgLight | #F6F8FB | พื้นหลังในโหมดสว่าง |
| surfaceLight | #FFFFFF | การ์ด (card) ในโหมดสว่าง |

**Primary**

| โทเคน (token) | Hex | ใช้งาน |
|-------|-----|--------|
| primary | #006685 | ปุ่มและ accent ใน light mode |
| primaryFixedDim | #6CD2FF | ปุ่มและ accent ใน dark mode |
| primaryContainer | #00A6D6 | Container สี |

**Risk / Status**

| โทเคน (token) | Hex | ใช้งาน |
|-------|-----|--------|
| danger | #DC2626 | ความเสี่ยงสูง (สูง) |
| ข้อผิดพลาด (error) | #BA1A1A | ข้อผิดพลาด (error) สถานะ (state) |
| warning | #D68900 | ความเสี่ยงปานกลาง |
| สำเร็จ (success) | #006E2D | ความเสี่ยงต่ำ / ปลอดภัย |

### 5.2 Typography (AppTypography)

ใช้ `google_fonts` package โหลด แบบอักษร (font) จาก Google Fonts

- **Sarabun** — ใช้กับข้อความ UI ทั้งหมด รองรับภาษาไทยและอังกฤษ
- **Inter** — ใช้กับตัวเลขและข้อมูล (risk score, เปอร์เซ็นต์, วันที่)

| Style | ขนาด | Weight | ใช้งาน |
|-------|------|--------|--------|
| headlineLgMobile | 24sp | 700 | หัวข้อหลักของหน้า |
| titleMd | 22sp | 700 | หัวข้อ การ์ด (card) / section |
| sectionHeader | 18sp | 600 | หัวข้อ section |
| bodyBase | 16sp | 400 | เนื้อหาทั่วไป |
| buttonLabel | 16sp | 600 | ข้อความบนปุ่ม |
| caption | 13sp | 400 | ข้อความช่วย / helper text |
| codeData | 14sp | 500 | ตัวเลข risk score (Inter) |

### 5.3 Spacing (AppSpacing)

ใช้ grid 4 point ทุกค่า spacing เป็น multiple ของ 4

| Constant | ค่า | ใช้งาน |
|----------|-----|--------|
| xs | 4.0 | gap เล็กมาก, ไอคอน (icon) padding |
| sm | 8.0 | gap เล็ก |
| gutter | 12.0 | padding แน่น |
| md | 16.0 | padding ทั่วไป (ค่าเริ่มต้น (default)) |
| safeMargin | 20.0 | horizontal margin ขอบจอ |
| lg | 24.0 | gap ใหญ่ |
| xl | 32.0 | gap ใหญ่มาก |
| xxl | 48.0 | gap ใหญ่พิเศษ |

### 5.4 Theme (AppTheme)

`AppTheme.dark` และ `AppTheme.light` สร้าง `ThemeData` ครบถ้วนโดยใช้ `ColorScheme` Material 3 ครอบคลุม: AppBar, BottomNavigationBar, การ์ด (card), ElevatedButton, OutlinedButton, InputDecoration, Divider, Checkbox, Switch

`main.dart` ตั้ง `themeMode: ThemeMode.dark` เป็น ค่าเริ่มต้น (default)

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
/กำลังโหลด (loading)                   AnalysisLoadingScreen (standalone, รับ filePath ผ่าน extra)
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

Route ที่ต้องส่ง พารามิเตอร์ (parameter) นอกเหนือจาก เส้นทาง (path) ใช้ `สถานะ (state).extra` เป็น `Map<ข้อความ (string), dynamic>`:
- `/crop` รับ `filePath`
- `/กำลังโหลด (loading)` รับ `filePath`
- `/heatmap/:scanId` รับ `imageUrl` และ `heatmapUrl`
- `/main/report` รับ `scanId` (optional)

---

## 7. Shared Core Widgets

ทุก widget อยู่ใน `lib/core/widgets/` และ export รวมผ่าน `widgets.dart`

### PrimaryButton
Full-width `ElevatedButton` ขนาด 52px สูง รูปทรง `StadiumBorder` รองรับ:
- `isLoading: true` — แสดง `CircularProgressIndicator` แทน label
- `enabled: false` — ปุ่ม ถูกปิดใช้งาน (disabled) ด้วย opacity ลด
- `leadingIcon` — ไอคอน (icon) ก่อน label (optional)

### SecondaryButton
`OutlinedButton` สไตล์เดียวกับ `PrimaryButton` แต่ outlined

### RiskBadge
Pill-shaped ป้ายกำกับ (badge) แสดงระดับความเสี่ยงเป็น enum `RiskLevel`:
- `low` — พื้นสีเขียว (#006E2D) / ข้อความ "ต่ำ"
- `medium` — พื้นสีเหลือง (#D68900) / ข้อความ "ปานกลาง"
- `high` — พื้นสีแดง (#DC2626) / ข้อความ "สูง"
- `safe` — พื้นสีเขียว (#006E2D) / ข้อความ "ปลอดภัย"

มี static เมธอด (method) `levelFromString(ข้อความ (string))` สำหรับแปลง ข้อความ (string) จาก API

### RiskProgressBar
Horizontal progress bar แสดง risk score 0-100 สีเปลี่ยนตามระดับ (เขียว/เหลือง/แดง)

### RiskGauge
SVG semicircle gauge วาดด้วย `CustomPainter` แสดงคะแนนแบบ half-circle gauge

### AppTopBar
`PreferredSizeWidget` ที่ใช้เป็น AppBar มาตรฐานของแอป แสดง shield ไอคอน (icon) + "ScamGuard" title รองรับ custom actions

### AppBottomNavigation
`BottomNavigationBar` 4 tabs พร้อม active สถานะ (state) styling ใช้ใน `MainShell`

### GlassCard
`Container` กึ่งโปร่งใส (`rgba(22,34,48,0.8)`) พร้อม border radius 16px ใช้เป็น form การ์ด (card) บนหน้า Login/Register

### ConsentCheckboxTile
Row ที่มี `Checkbox` + label + optional description ทั้ง row tap ได้เพื่อ toggle

### AnalysisStepTile
แสดงขั้นตอนการวิเคราะห์ 3 สถานะ: done (check ไอคอน (icon) เขียว), active (spinner สีหลัก), pending (opacity 40%)

### EmptyStateView
ไอคอน (icon) + title + subtitle สำหรับ list ที่ว่างเปล่า

### ErrorStateView
ไอคอน (icon) + message + ลองใหม่ (retry) ปุ่ม (button) สำหรับ ข้อผิดพลาด (error) สถานะ (state)

### LoadingOverlay
Full-screen กำลังโหลด (loading) overlay

### PermissionRequestView
แสดงเหตุผลและปุ่ม "เปิดการตั้งค่า" เมื่อ permission ถูกปฏิเสธ

### HistoryListItem
การ์ด (card) สำหรับแสดงรายการประวัติ: thumbnail 80x80, title, วันที่, `RiskProgressBar`, `RiskBadge`

---

## 8. Domain Entities

### User
```
id           ข้อความ (string)
email        ข้อความ (string)
displayName  ข้อความ (string)
avatarUrl    ข้อความ (string)? (optional)
```

### AnalysisResult
```
scanId       ข้อความ (string)
taskId       ข้อความ (string)
status       String ("completed" | "failed")
riskScore    int (0-100)
riskLevel    RiskLevel (enum: low, medium, high)
summary      String (คำอธิบายผลเป็นภาษาธรรมดา)
imageUrl     ข้อความ (string)? (URL รูปต้นฉบับ)
heatmapUrl   ข้อความ (string)? (URL รูป heatmap)
createdAt    DateTime
factors      List<RiskFactor>
```

### RiskFactor
```
type         String ("textual" | "source" | "visual")
score        int
title        ข้อความ (string)
details      List<ข้อความ (string)>
```

### ScanHistoryItem
```
scanId       ข้อความ (string)
thumbnailUrl ข้อความ (string)?
riskScore    int
riskLevel    RiskLevel
status       ข้อความ (string)
createdAt    DateTime
title        ข้อความ (string)?
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
- States: `SplashInitial`, `CheckingSession`, `Authenticated`, `Unauthenticated`, `ConsentRequired`, `ล้มเหลว (failure)`
- ตรวจ access โทเคน (token) -> ถ้าหมดอายุลอง ต่ออายุ (refresh) -> ถ้าไม่มี ความยินยอม (consent) นำไป onboarding

### AuthBloc
Events: `LoginRequested`, `RegisterRequested`, `LogoutRequested`
States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(User)`, `AuthUnauthenticated`, `AuthError(message)`
- Login/Register ผ่าน `AuthRepository`
- แปลง exception เป็นข้อความภาษาไทยที่เป็นมิตร

### ConsentCubit
จัดการสถานะ checkbox ในหน้า Onboarding
- `toggleTerms()` / `toggleResearch()`
- บันทึก ความยินยอม (consent) สถานะ (state) ก่อน เปลี่ยนหน้า (navigate) ไป login

### ScanBloc
Events: `ImageSelected`, `CropConfirmed`, `AnalysisStarted`, `AnalysisPollTick`, `AnalysisCompleted`
States: `ScanInitial`, `ImagePicked`, `ImageCropped`, `Uploading`, `Polling(progress, step)`, `AnalysisDone`, `ScanError`
- Polling `GET /scans/{taskId}` ทุก 3 วินาทีด้วย `Timer.periodic`
- หมดเวลา (timeout) หลัง 120 วินาที
- เมื่อ status = "completed" fetch result แล้ว เปลี่ยนหน้า (navigate) ไป `/result/:scanId`

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
- ตรงกลาง: glass การ์ด (card) มีไอคอน shield (80px) + ไอคอน search overlay
- ชื่อแอป "Scam Image Detection" (headlineLgMobile)
- คำบรรยาย "ตรวจจับรูปภาพหลอกลวง"
- ด้านล่าง: วงแหวน กำลังโหลด (loading) หมุน + ข้อความสถานะ cycling 4 ข้อความ
- `SplashCubit` ทำงานเบื้องหลัง เปลี่ยนหน้า (navigate) ไปหน้าที่เหมาะสมหลัง check เสร็จ

Requirement: REQ-001

### 10.2 OnboardingScreen (`/onboarding`)

แสดงครั้งแรกที่ผู้ใช้ยังไม่ได้ยอมรับ ความยินยอม (consent)

- Shield ไอคอน (icon) + หัวข้อ "ยินดีต้อนรับสู่ ScamGuard"
- คำอธิบายวัตถุประสงค์ของแอป
- Disclaimer: "ผลการประเมินเป็นเพียงการประเมินความเสี่ยง ไม่ใช่คำตัดสินทางกฎหมาย"
- `ConsentCheckboxTile` 2 ตัว:
  1. ยอมรับเงื่อนไขการใช้งาน (บังคับ)
  2. ยินยอมให้ใช้ข้อมูลปรับปรุงโมเดล (ไม่บังคับ)
- ปุ่ม "ดำเนินการต่อ" ถูกปิดใช้งาน (disabled) จนกว่าจะยอมรับข้อ 1

Requirement: REQ-002

### 10.3 LoginScreen (`/login`)

- พื้นหลัง `bgDark` พร้อม atmospheric blur พื้นหลัง (background)
- `GlassCard` ครอบ form ทั้งหมด
- ส่วน brand: shield ไอคอน (icon) + "ScamGuard" + คำบรรยาย
- Email field พร้อม mail ไอคอน (icon), validate: ไม่ว่าง + มี @
- Password field พร้อม lock ไอคอน (icon) + toggle visibility
- Link "ลืมรหัสผ่าน" ด้านขวา
- Checkbox "จดจำการใช้งานของฉัน"
- ปุ่ม "เข้าสู่ระบบ" (PrimaryButton) — กำลังโหลด (loading) ขณะรอ API
- Divider "หรือ"
- ปุ่ม Google Login (outlined พร้อม Google logo)
- Link "สมัครสมาชิก" ไปยัง `/register`
- `BlocListener` เปลี่ยนหน้า (navigate) ไป `/main/home` เมื่อ `AuthAuthenticated`

Requirement: REQ-003

### 10.4 RegisterScreen (`/register`)

- Display Name, Email, Password, Confirm Password fields
- Inline การตรวจสอบความถูกต้อง (validation): Password ขั้นต่ำ 8 ตัวอักษร, ต้องตรงกัน
- Checkbox ยอมรับเงื่อนไข
- ปุ่ม "สมัครสมาชิก"
- Link กลับไป login

Requirement: REQ-004

### 10.5 HomeScreen (`/main/home`)

หน้าหลักภายใน bottom nav shell

- `AppTopBar` พร้อม notifications icon (dot ป้ายกำกับ (badge) แสดงเมื่อมีแจ้งเตือนที่ยังไม่ได้อ่าน)
- Greeting section: "สวัสดี, [displayName]" + subtitle
- Upload Card (gradient `#162230` -> `#0F1720`):
  - วงกลม upload ไอคอน (icon) 80px
  - คำอธิบาย + hint ประเภทไฟล์ที่รองรับ
  - ปุ่ม "อัปโหลดรูปภาพ" พร้อม pulse animation
  - รองรับ jpg, jpeg, png, webp ขนาดสูงสุด 10MB
- Safety Tips Bento Grid (2 คอลัมน์):
  - verified_user ไอคอน (icon) การ์ด (card)
  - link_off ไอคอน (icon) การ์ด (card)
  - Full-width report การ์ด (card)
- Recent History section: รายการล่าสุด 3-5 รายการ + link "ดูทั้งหมด"
- เมื่อเลือกไฟล์สำเร็จ เปลี่ยนหน้า (navigate) ไป `/crop`
- `PermissionRequestView` เมื่อ permission ถูกปฏิเสธ

Requirement: REQ-005

---

### 10.6 ImageCropScreen (`/crop`)

รับ `filePath` ผ่าน route extra

- Full screen dark พื้นหลัง (background)
- `image_cropper` package แสดงรูปพร้อม crop overlay
- Bottom controls: ปุ่มหมุนภาพ, ปุ่มเปลี่ยนรูป
- ปุ่ม "เริ่มวิเคราะห์" (PrimaryButton) ด้านล่าง
- เมื่อกด back หลัง crop แล้ว — แสดง `AlertDialog` ยืนยันก่อนยกเลิก
- เมื่อยืนยัน เปลี่ยนหน้า (navigate) ไป `/กำลังโหลด (loading)` พร้อม filePath

Requirement: REQ-006

### 10.7 AnalysisLoadingScreen (`/กำลังโหลด (loading)`)

รับ `filePath` ผ่าน route extra

- `AppTopBar`
- Circular progress SVG วาดด้วย `CustomPainter` (radius 84):
  - Track สีเข้ม `#27313C`
  - Arc สีหลัก animated ตาม progress %
  - ตรงกลาง: thumbnail รูปที่เลือก พร้อม scanning line animation
  - ป้ายกำกับ (badge) % ลอยอยู่ด้านล่าง circle
- Heading "กำลังวิเคราะห์ความปลอดภัย" + dots wave animation
- Step Checklist Card (surfaceDark):
  - Step 1 (OCR): done — check ไอคอน (icon) สีเขียว
  - Step 2 (Source Check): active — spinner + search ไอคอน (icon)
  - Step 3 (Visual Analysis): pending — opacity 40%
- Privacy ป้ายกำกับ (badge): "การวิเคราะห์แบบเข้ารหัส"
- `ScanBloc` poll `GET /scans/{taskId}` ทุก 3 วินาที ด้วย `Timer.periodic`
- หมดเวลา (timeout) 120 วินาที แสดง `ErrorStateView` พร้อมปุ่ม ลองใหม่ (retry)
- เมื่อสำเร็จ เปลี่ยนหน้า (navigate) ไป `/result/:scanId`

Requirement: REQ-007

### 10.8 AnalysisResultScreen (`/result/:scanId`)

รับ `taskId` จาก เส้นทาง (path) พารามิเตอร์ (parameter)

- `AppTopBar`
- Risk Gauge Section:
  - SVG semicircle gauge วาดด้วย `CustomPainter` (viewBox 200x100)
  - ตัวเลข risk score ขนาดใหญ่ (สีตามระดับ)
  - `RiskBadge` แสดงระดับ
- Summary Card (surfaceDark): analytics ไอคอน (icon) + ข้อความอธิบายผล
- Analysis Bento Grid (2 คอลัมน์):
  - Contact info การ์ด (card)
  - Transaction การ์ด (card)
  - Full-width: Heatmap preview การ์ด (card) พร้อม image พื้นหลัง (background) overlay
- การสั่งงาน (action) Buttons (2 แถว):
  - แถว 1: "ดูรายละเอียด" (primary), "ดู Heatmap" (primary-container)
  - แถว 2: "รายงานภาพต้องสงสัย" (outlined danger), "แชร์ผลลัพธ์" (outlined cyan)
- Multi-layer detail sections (expandable): Textual, Source, Visual

Requirement: REQ-008

### 10.9 HeatmapViewerScreen (`/heatmap/:scanId`)

รับ `taskId`, `imageUrl`, `heatmapUrl` จาก เส้นทาง (path) + extra

- Full screen dark พื้นหลัง (background)
- `InteractiveViewer` รองรับ zoom/pan ด้วยนิ้ว
- Stack: รูปต้นฉบับ + heatmap overlay ที่ปรับ opacity ได้
- Toggle bar: "ต้นฉบับ" / "Heatmap"
- Opacity `Slider` (0.0 ถึง 1.0) ปรับความชัดของ heatmap
- ปุ่ม download/save รูป
- คำอธิบาย: สีร้อน (แดง) = ส่วนที่มีความเสี่ยงสูงที่สุด

Requirement: REQ-009

### 10.10 HistoryScreen (`/main/history`)

- `AppTopBar` + notifications ปุ่ม (button)
- Row: "ประวัติการตรวจสอบ" + ป้ายกำกับ (badge) จำนวนรายการ
- Search bar (rounded-xl, search ไอคอน (icon)) + Filter ปุ่ม (button)
- `HistoryBloc` dispatch `HistoryLoaded` เมื่อ init
- Search ใช้ debounce 400ms dispatch `HistorySearched`
- แต่ละรายการ: `_HistoryCard`
  - Thumbnail 80x80 (`CachedNetworkImage`)
  - Title + วันที่ (calendar ไอคอน (icon))
  - `RiskProgressBar` + score %
  - `RiskBadge` มุมบนขวา
  - Swipe left ลบ (`Dismissible` widget ด้วย `DismissDirection.endToStart`)
- `RefreshIndicator` pull-to-ต่ออายุ (refresh)
- `HistoryEmpty` สถานะ (state): `EmptyStateView` "ยังไม่มีประวัติการตรวจสอบ"
- การแบ่งหน้า (pagination): load more เมื่อ scroll ถึงท้าย list

Requirement: REQ-010

### 10.11 HistoryDetailScreen (`/main/history/:id`)

รับ `scanId` จาก เส้นทาง (path) พารามิเตอร์ (parameter)

- Layout เหมือน `AnalysisResultScreen`
- แสดงข้อมูล metadata + คะแนน แม้ไม่มีรูปต้นฉบับ
- แสดงหมายเหตุเมื่อรูปต้นฉบับถูกลบแล้ว
- ปุ่ม "สแกนภาพใหม่" เปลี่ยนหน้า (navigate) กลับไป home

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
- ปุ่ม "ส่งรายงาน" พร้อม กำลังโหลด (loading) สถานะ (state) + สำเร็จ (success) feedback

Requirement: REQ-012

### 10.13 NotificationsScreen (`/notifications`)

- `AppTopBar`
- รายการแจ้งเตือน 3 ประเภทพร้อม ไอคอน (icon):
  - analytics ไอคอน (icon) — งานวิเคราะห์เสร็จ
  - warning ไอคอน (icon) — งานล้มเหลว
  - campaign ไอคอน (icon) — Scam Alert ทั่วไป
- แตะ notification งานวิเคราะห์ เปลี่ยนหน้า (navigate) ไป `/result/:scanId`
- ปุ่ม "ล้างทั้งหมด" ด้านบนขวา
- `Dismissible` swipe เพื่อลบรายการ
- `EmptyStateView` เมื่อไม่มีแจ้งเตือน (notifications_off ไอคอน (icon))

Requirement: REQ-013

### 10.14 SettingsScreen (`/main/settings`)

- User info header: avatar placeholder + displayName + email
- ListTile sections:
  - โปรไฟล์ — เปลี่ยนหน้า (navigate) ไป `/main/settings/profile`
  - ความปลอดภัยของบัญชี
  - การแจ้งเตือน
  - ภาษา
  - รูปแบบ (theme toggle switch Light/Dark)
  - ความเป็นส่วนตัวและ ความยินยอม (consent) — เปลี่ยนหน้า (navigate) ไป `/main/settings/privacy`
  - ล้าง แคช (cache) — confirmation snackbar
  - ออกจากระบบ (สีแดง danger) — `AlertDialog` ยืนยัน -> ลบ โทเคน (token) + แคช (cache) -> เปลี่ยนหน้า (navigate) ไป `/login`

Requirement: REQ-014

### 10.15 UserProfileScreen (`/main/settings/profile`)

- `CircleAvatar` 80px + edit ไอคอน (icon) overlay
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
- ถอน research ความยินยอม (consent) ได้โดยไม่กระทบการใช้งานพื้นฐาน

Requirement: REQ-016

---

## 11. Security

| มาตรการ | รายละเอียด |
|---------|-----------|
| โทเคน (token) storage | Access โทเคน (token) และ ต่ออายุ (refresh) โทเคน (token) เก็บใน `flutter_secure_storage` เท่านั้น ไม่เก็บใน SharedPreferences หรือ plain storage |
| HTTPS | ทุก API call ใช้ HTTPS ห้ามใช้ HTTP ใน production |
| โทเคน (token) lifecycle | ลบ โทเคน (token) ทุกครั้งที่ logout หรือ ต่ออายุ (refresh) ล้มเหลว |
| Auto ต่ออายุ (refresh) | `AuthInterceptor` จัดการ 401 โดยอัตโนมัติ ไม่ต้องให้ผู้ใช้ login ใหม่ทันที |
| ข้อผิดพลาด (error) messages | ไม่แสดง stack trace หรือข้อความ technical ข้อผิดพลาด (error) ต่อผู้ใช้ แปลงเป็นภาษาไทยที่เข้าใจง่าย |
| Image upload | ตรวจสอบ format (jpg/jpeg/png/webp) และขนาด (<= 10MB) ก่อน upload |
| clientRequestId | ทุก scan คำขอ (request) ส่ง UUID เพื่อป้องกัน duplicate submission |

---

## 12. Performance

| เงื่อนไข | เป้าหมาย |
|---------|---------|
| เปิดแอปถึงหน้าแรก | ภายใน 3 วินาที |
| เลือกไฟล์เข้า preview | ภายใน 1 วินาที |
| Image compression | บีบอัดอัตโนมัติเมื่อไฟล์ > 10MB โดยใช้ image_picker quality พารามิเตอร์ (parameter) |
| Network หมดเวลา (timeout) | 30 วินาทีต่อ คำขอ (request) |
| Analysis หมดเวลา (timeout) | 120 วินาทีรวม polling ทั้งหมด |
| Polling interval | 3 วินาที |
| Search debounce | 400 milliseconds |

---

## 13. Accessibility

- ปุ่มทุกปุ่มมีพื้นที่แตะอย่างน้อย 44x44 px
- ทุก ไอคอน (icon) ปุ่ม (button) มี `tooltip` หรือ Semantic Label
- สีสถานะทุกสีมีข้อความประกอบเสมอ (ไม่ใช้สีอย่างเดียว)
- รองรับ dynamic แบบอักษร (font) size เท่าที่ layout ยังรับได้
- `ConsentCheckboxTile` ทั้ง row tap ได้ ไม่จำกัดให้แตะที่ checkbox เท่านั้น

---

## 14. ข้อผิดพลาด (error) Handling Pattern

ทุกหน้าที่เรียก API ต้องมีครบ 3 states:

1. **กำลังโหลด (loading) สถานะ (state)** — แสดง `CircularProgressIndicator` หรือ `LoadingOverlay`
2. **ข้อผิดพลาด (error) สถานะ (state)** — แสดง `ErrorStateView` พร้อมปุ่ม ลองใหม่ (retry) / open settings
3. **Empty สถานะ (state)** — แสดง `EmptyStateView` เมื่อ result ว่างเปล่า

---

## 15. Dependencies

### Runtime dependencies

| Package | Version | หน้าที่ |
|---------|---------|--------|
| flutter_bloc | ^9.1.1 | สถานะ (state) management (BLoC pattern) |
| equatable | ^2.0.7 | Value equality สำหรับ entities และ states |
| go_router | ^15.1.2 | Declarative routing |
| dio | ^5.8.0+1 | HTTP client |
| flutter_secure_storage | ^9.2.4 | เก็บ โทเคน (token) อย่างปลอดภัย |
| image_picker | ^1.1.2 | เลือกรูปจาก gallery/camera |
| image_cropper | ^9.0.0 | crop และ rotate รูป |
| cached_network_image | ^3.4.1 | แสดงรูปจาก URL พร้อม แคช (cache) |
| google_fonts | ^6.2.1 | Sarabun + Inter fonts |
| uuid | ^4.5.1 | สร้าง clientRequestId |
| intl | ^0.20.2 | date formatting |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| share_plus | ^10.1.4 | share ผลลัพธ์ผ่านแอปอื่น |

### Dev dependencies

| Package | Version | หน้าที่ |
|---------|---------|--------|
| flutter_test | SDK | Flutter widget testing เฟรมเวิร์ก (framework) |
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
      consent_checkbox_tile_test.dart       widget test checkbox + ปุ่ม (button) integration
  features/
    auth/
      presentation/
        bloc/
          auth_bloc_test.dart               BLoC test login/register
        screens/
          login_screen_test.dart            widget test form การตรวจสอบความถูกต้อง (validation)
    scan/
      presentation/
        bloc/
          scan_bloc_test.dart               BLoC test polling สถานะ (state)
    history/
      presentation/
        screens/
          history_screen_test.dart          widget test empty/กำลังโหลด (loading)/ข้อผิดพลาด (error)/data states
```

### สิ่งที่ครอบคลุม

- **Unit tests** — `RiskLevelHelper` boundary conditions (0, 39, 40, 69, 70, 100)
- **BLoC tests** — `AuthBloc` (login สำเร็จ (success)/ล้มเหลว (failure)), `ScanBloc` (polling transitions)
- **Widget tests**:
  - `RiskBadge` — ตรวจสี พื้นหลัง (background) และข้อความ Thai ทุก 4 ระดับ
  - `ConsentCheckboxTile` — label, description, value toggle, onChanged callback
  - `LoginScreen` — email empty, email invalid format, password empty, password visibility toggle
  - `HistoryScreen` — HistoryEmpty, HistoryLoading, HistoryDataLoaded, HistoryError states

### Test utilities

- `GoogleFonts.config.allowRuntimeFetching = false` ใน `setUpAll` เพื่อป้องกัน network call
- `MockHistoryRepository` extends `Mock implements HistoryRepository` (mocktail)
- `_MockHistoryBloc` extends `MockBloc` (bloc_test) สำหรับ control สถานะ (state) โดยตรง
- ทุก widget test wrap ใน `MaterialApp` dark theme เพื่อป้องกัน Directionality ข้อผิดพลาด (error)
- Screen ที่ใช้ go_router wrap ใน `MaterialApp.router` พร้อม `GoRouter` minimal routes

---

## 17. Flow การทำงานหลักของแอป

### 17.1 Flow แรกเข้าแอป

```
เปิดแอป
  -> SplashScreen (แสดง logo + กำลังโหลด (loading))
     -> SplashCubit.checkSession()
        -> มี โทเคน (token) ที่ยังใช้ได้     -> /main/home
        -> โทเคน (token) หมดอายุ             -> ต่ออายุ (refresh) โทเคน (token)
              -> ต่ออายุ (refresh) สำเร็จ      -> /main/home
              -> ต่ออายุ (refresh) ล้มเหลว     -> /login
        -> ไม่มี โทเคน (token)               -> /login
        -> ไม่มี ความยินยอม (consent)             -> /onboarding
```

### 17.2 Flow Onboarding

```
/onboarding
  -> ยอมรับ terms (บังคับ) + optional research ความยินยอม (consent)
  -> ปุ่ม "ดำเนินการต่อ" เปิด
  -> บันทึก ความยินยอม (consent) สถานะ (state)
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
        -> ScanBloc POST /scans (หลายส่วน (multipart))
        -> ได้ taskId
        -> poll GET /scans/{taskId} ทุก 3 วินาที
        -> status = "completed"
        -> GET /scans/{taskId}/result
        -> /result/:scanId
           -> แสดง risk gauge, ป้ายกำกับ (badge), summary, factors
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
  -> Pull to ต่ออายุ (refresh) -> reload
  -> Search -> debounce 400ms -> GET /history?keyword=...
```

### 17.5 Flow การรายงาน

```
/main/report (จาก bottom nav หรือ result screen)
  -> เลือก category (FilterChip)
  -> กรอกรายละเอียด (ขั้นต่ำ 10 ตัวอักษร)
  -> เลือก platform
  -> กรอก URL/account (optional)
  -> ยินยอม ความยินยอม (consent)
  -> "ส่งรายงาน" -> POST /reports
  -> สำเร็จ (success) feedback
```

### 17.6 Flow Logout

```
/main/settings
  -> "ออกจากระบบ" (สีแดง)
  -> AlertDialog "ยืนยันการออกจากระบบ?"
  -> ยืนยัน
  -> ลบ access โทเคน (token) + ต่ออายุ (refresh) โทเคน (token) จาก SecureStorage
  -> ล้าง แคช (cache)
  -> เปลี่ยนหน้า (navigate) ไป /login
```

---

## 18. Environment Configuration

แอปรับ configuration ผ่าน ตัวแปรสภาพแวดล้อมตอนคอมไพล์ (compile-time environment variable):

| Variable | ค่าเริ่มต้น (default) | คำอธิบาย |
|----------|---------|---------|
| API_BASE_URL | `http://localhost:8000` | Base URL ของ ระบบหลังบ้าน (Backend) API |

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
| `lib/core/di/injection_container.dart` | ServiceLocator, wire up ทุก การพึ่งพา (dependency) |
| `lib/core/router/app_router.dart` | Route definitions ทั้งหมด (go_router) |
| `lib/core/theme/app_theme.dart` | Dark + Light ThemeData |
| `lib/core/constants/app_colors.dart` | Color tokens ทั้งหมด |
| `lib/core/constants/app_typography.dart` | Text styles (Sarabun + Inter) |
| `lib/core/constants/app_spacing.dart` | Spacing constants (4-point grid) |
| `lib/core/network/dio_client.dart` | Dio factory + AuthInterceptor |
| `lib/core/network/api_endpoints.dart` | API เส้นทาง (path) constants |
| `lib/core/storage/secure_storage.dart` | flutter_secure_storage ตัวครอบ (wrapper) |
| `lib/core/utils/risk_level_helper.dart` | Score -> RiskLevel + Thai label |
| `lib/core/widgets/widgets.dart` | Barrel export ทุก shared widget |
