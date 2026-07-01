# Design: ScamGuard Mobile App
## Flutter Clean Architecture — Dark Mode First

---

## 1. Architecture Overview

```
lib/
├── core/
│   ├── constants/           # app_colors.dart, app_typography.dart, app_spacing.dart
│   ├── errors/              # failures.dart, exceptions.dart
│   ├── network/             # dio_client.dart, api_endpoints.dart, interceptors/
│   ├── router/              # app_router.dart (go_router)
│   ├── storage/             # secure_storage.dart
│   ├── theme/               # app_theme.dart (light + dark ThemeData)
│   ├── utils/               # validators.dart, date_formatter.dart, image_compressor.dart
│   └── widgets/             # shared reusable widgets
├── features/
│   ├── auth/
│   │   ├── data/            # auth_remote_datasource.dart, auth_repository_impl.dart, models/
│   │   ├── domain/          # entities/, usecases/, auth_repository.dart (interface)
│   │   └── presentation/    # blocs/, screens/, widgets/
│   ├── scan/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── result/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── history/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── report/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── notifications/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

---

## 2. Design System

### 2.1 Color Tokens (`app_colors.dart`)

```dart
class AppColors {
  // Dark Mode (Primary)
  static const bgDark = Color(0xFF0F1720);
  static const surfaceDark = Color(0xFF162230);
  static const inverseSurface = Color(0xFF27313C);
  
  // Light Mode
  static const bgLight = Color(0xFFF6F8FB);
  static const surfaceLight = Color(0xFFFFFFFF);
  
  // Primary
  static const primary = Color(0xFF006685);
  static const primaryFixedDim = Color(0xFF6CD2FF);  // Dark mode primary
  static const primaryContainer = Color(0xFF00A6D6);
  
  // Risk Levels
  static const danger = Color(0xFFDC2626);
  static const error = Color(0xFFBA1A1A);
  static const warning = Color(0xFFD68900);  // tertiary-container
  static const success = Color(0xFF006E2D);  // secondary
  
  // Text
  static const textPrimary = Color(0xFF17212B);
  static const textSecondary = Color(0xFF5E6B78);
  static const surfaceLight_ = Color(0xFFFFFFFF);
  static const outlineVariant = Color(0xFFBDC8CF);
  
  // Border
  static const border = Color(0xFFD8E0EA);
}
```

### 2.2 Typography (`app_typography.dart`)
Font: `google_fonts` package — Sarabun + Inter

| Style | Size | Weight | Usage |
|---|---|---|---|
| displayHero | 48 | 700 | N/A in mobile |
| headlineLgMobile | 24 | 700 | Page titles |
| titleMd | 22 | 700 | Section titles |
| sectionHeader | 18 | 600 | Section headers |
| bodyBase | 16 | 400 | Body text |
| buttonLabel | 16 | 600 | Button labels |
| caption | 13 | 400 | Helper text |
| codeData | 14 | 500 | Numbers (Inter) |

### 2.3 Spacing (4-point grid)
```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const gutter = 12.0;
  static const md = 16.0;
  static const safeMargin = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

### 2.4 Border Radius
```dart
class AppRadius {
  static const sm = Radius.circular(4);
  static const md = Radius.circular(8);   // lg
  static const lg = Radius.circular(12);  // xl
  static const full = Radius.circular(9999);
}
```

---

## 3. Shared Core Widgets (`core/widgets/`)

| Widget | Description |
|---|---|
| `PrimaryButton` | Full-width primary CTA button with loading state |
| `SecondaryButton` | Outlined button |
| `RiskBadge` | Colored badge: ต่ำ/ปานกลาง/สูง/ปลอดภัย |
| `RiskGauge` | SVG semicircle gauge widget |
| `RiskProgressBar` | Horizontal progress bar with color |
| `AppBottomNavigation` | 4-tab bottom navigation |
| `AppTopBar` | Header with ScamGuard logo + icons |
| `HistoryListItem` | Card-style history list item |
| `EmptyStateView` | Icon + title + subtitle for empty lists |
| `ErrorStateView` | Icon + message + retry button |
| `LoadingOverlay` | Full-screen loading indicator |
| `ConsentCheckboxTile` | Labeled checkbox for consent screens |
| `PermissionRequestView` | Permission denied explanation + open settings |
| `AnalysisStepTile` | Step item: done/in-progress/pending |
| `GlassCard` | Semi-transparent card for dark mode |

---

## 4. Navigation & Routing (`app_router.dart` — go_router)

### Routes
```
/splash              → SplashScreen
/onboarding          → OnboardingScreen
/login               → LoginScreen
/register            → RegisterScreen
/main                → MainShell (Bottom Nav Shell)
  /home              → HomeScreen
  /history           → HistoryScreen
    /history/:id     → HistoryDetailScreen
  /report            → ReportScamScreen (from nav or result)
  /settings          → SettingsScreen
    /settings/profile    → UserProfileScreen
    /settings/privacy    → PrivacyConsentScreen
/crop                → ImageCropScreen (modal route)
/loading             → AnalysisLoadingScreen
/result/:scanId      → AnalysisResultScreen
/heatmap/:scanId     → HeatmapViewerScreen
/notifications       → NotificationsScreen
```

### Navigation Guards
- `SplashScreen` checks auth state → redirects accordingly
- Protected routes redirect to `/login` if unauthenticated

---

## 5. State Management (BLoC/Cubit)

### AuthBloc
```
Events: LoginRequested, RegisterRequested, LogoutRequested, GoogleLoginRequested
States: AuthInitial, AuthLoading, Authenticated(User), Unauthenticated, AuthError(message)
```

### SplashCubit
```
States: SplashInitial, CheckingSession, Authenticated, Unauthenticated, ConsentRequired, Failure
```

### ScanBloc
```
Events: ImageSelected, CropConfirmed, AnalysisStarted, AnalysisPollTick, AnalysisCompleted
States: ScanInitial, ImagePicked(File), ImageCropped(File), Uploading, Polling(progress, step), 
        AnalysisDone(AnalysisResult), ScanError(message)
```

### HistoryBloc
```
Events: HistoryLoaded, HistoryRefreshed, HistorySearched, HistoryItemDeleted
States: HistoryInitial, HistoryLoading, HistoryLoaded(items), HistoryError
```

### ReportBloc
```
Events: ReportSubmitted(data)
States: ReportInitial, ReportSubmitting, ReportSuccess, ReportError
```

### ConsentCubit
```
States: ConsentState(terms, research)
Methods: toggleTerms(), toggleResearch(), submit()
```

### SettingsBloc
```
Events: ThemeToggled, LanguageChanged, CacheCleared, LogoutRequested
States: SettingsState(themeMode, language)
```

### NotificationsCubit
```
States: NotificationsState(items, unreadCount)
```

---

## 6. Screen Designs

### 6.1 SplashScreen
**Layout:** Full screen dark gradient (`#0F1720` → `#162230`), centered content
- Atmospheric blur circles (primary/secondary glow)
- Logo container: `glass-effect` rounded box, shield icon + search overlay
- App name: "Scam Image Detection", subtitle: "ตรวจจับรูปภาพหลอกลวง"
- Bottom: loading ring animation, cycling status text
- Animated shield logo (pulse-shield: scale 1→1.05)

### 6.2 OnboardingScreen
**Layout:** Scrollable, centered, `bg-dark`
- Header with shield icon
- Onboarding text: purpose, disclaimer (ผลการประเมิน ไม่ใช่คำตัดสินทางกฎหมาย)
- ConsentCheckboxTile ×2 (terms required, research optional)
- PrimaryButton "ดำเนินการต่อ" (disabled until terms accepted)

### 6.3 LoginScreen
**Layout:** `bg-dark`, centered card, atmospheric blur bg
- GlassCard with brand identity (shield icon + app name)
- Email input, Password input (toggle visibility)
- "ลืมรหัสผ่าน" link
- "จดจำการใช้งาน" checkbox  
- PrimaryButton "เข้าสู่ระบบ"
- Divider "หรือ"
- Google Login button (outlined)
- Link "สมัครสมาชิก"

### 6.4 RegisterScreen
**Layout:** Similar to Login
- Display Name, Email, Password, Confirm Password fields
- Terms checkbox
- PrimaryButton "สมัครสมาชิก"
- Link "เข้าสู่ระบบ"

### 6.5 HomeScreen
**Layout:** Sticky top bar + scrollable content + Bottom Nav
- **AppTopBar:** ScamGuard logo, search icon, notifications icon (with dot badge)
- **Greeting section:** "สวัสดี, [name]" + subtitle
- **Upload Card** (gradient: `#162230` → `#0F1720`):
  - Upload icon (80×80 primary/10 circle)
  - Heading + description
  - PrimaryButton "อัปโหลดรูปภาพ" with pulse animation
- **Safety Tips Bento** (2-col grid + 1 full-width):
  - verified_user, link_off, report_gmailerrorred
- **Recent History** (3 items):
  - Thumbnail + title + date + RiskBadge

### 6.6 ImageCropScreen
**Layout:** Full screen, dark bg
- Back button (AppBar)
- Image preview with crop overlay (`crop_your_image` or `image_cropper`)
- Bottom controls: rotate, change image
- PrimaryButton "เริ่มวิเคราะห์"
- Confirm dialog on back if image was cropped

### 6.7 AnalysisLoadingScreen
**Layout:** Centered, full screen
- AppTopBar
- **Circular Progress SVG** (radius 84, dark track + primary fill):
  - Center: image thumbnail with scanning line animation, % badge
- Heading "กำลังวิเคราะห์ความปลอดภัย" + dots wave
- **Step Checklist Card** (surfaceDark rounded-xl):
  - Step 1 (done): check icon, green background
  - Step 2 (active): spinning border + search icon, primary color
  - Step 3 (pending): gray, opacity 40%
- Privacy badge: "การวิเคราะห์แบบเข้ารหัส..."

### 6.8 AnalysisResultScreen
**Layout:** Scrollable + sticky AppTopBar + Bottom Nav
- **Risk Gauge Section:**
  - SVG semicircle gauge (viewBox 200×100, arc from 20,90 to 180,90)
  - Score number (large, danger color if high)
  - RiskBadge (danger/warning/success background)
- **Summary Card** (surfaceDark):
  - analytics icon + title + summary text
- **Analysis Bento Grid** (2-col):
  - Contact info card, Transaction card
  - Full-width: Heatmap preview card (image bg + overlay text)
- **Action Buttons** (2 rows):
  - Row 1: ดูรายละเอียด (primary), ดู Heatmap (primary-container)
  - Row 2: รายงานภาพต้องสงสัย (outlined danger), แชร์ผลลัพธ์ (outlined cyan)

### 6.9 HeatmapViewerScreen
**Layout:** Full screen dark bg
- AppBar with back button
- Image display (original or heatmap overlay, interactable zoom/pan)
- Toggle bar: Original / Heatmap
- Opacity Slider (0.0 → 1.0)
- Bottom: explanation text + download button

### 6.10 HistoryScreen
**Layout:** Sticky header + scrollable list + Bottom Nav
- AppTopBar
- Search bar (rounded-xl, search icon left) + Filter button
- Section title + count badge
- **HistoryListItem** (card per item):
  - Thumbnail (80×80)
  - Title + date (calendar icon)
  - RiskProgressBar (full width) + score %
  - RiskBadge (top right)
  - Swipe left to delete
- Empty state: history_off icon + text

### 6.11 HistoryDetailScreen
- Same layout as AnalysisResultScreen
- Additional: "สแกนภาพใหม่" button if image unavailable note

### 6.12 ReportScamScreen
**Layout:** Scrollable form
- AppBar "รายงานภาพต้องสงสัย"
- Image preview card
- Category picker (Dropdown/FilterChip)
- Detail text field (multiline, min 10 chars)
- Platform picker
- Reference URL / account field
- ConsentCheckboxTile (research use)
- PrimaryButton "ส่งรายงาน"

### 6.13 NotificationsScreen
**Layout:** List + AppTopBar
- Notification items with icons (analytics, warning, campaign)
- Swipe or "ล้างทั้งหมด" button
- Empty state: notifications_off

### 6.14 SettingsScreen
**Layout:** List of sections
- User info header (avatar + name + email)
- Sections: โปรไฟล์, ความปลอดภัย, การแจ้งเตือน, ภาษา, รูปแบบ (theme toggle), ความเป็นส่วนตัว, ล้าง Cache, ออกจากระบบ
- Logout → confirmation dialog

### 6.15 UserProfileScreen
**Layout:** Form
- Avatar with edit button
- Display name field (editable)
- Email (read-only)
- Save button

### 6.16 PrivacyConsentScreen
**Layout:** Scrollable settings
- Consent toggles (3 types)
- Export data button
- Delete account button → confirmation dialog (2-step)

---

## 7. Data Models

### AnalysisResult (domain entity)
```dart
class AnalysisResult {
  final String scanId;
  final String taskId;
  final String status;
  final int riskScore;
  final String riskLevel;   // "low" | "medium" | "high"
  final String summary;
  final String? imageUrl;
  final String? heatmapUrl;
  final DateTime createdAt;
  final List<RiskFactor> factors;
}

class RiskFactor {
  final String type;         // "textual" | "source" | "visual"
  final int score;
  final String title;
  final List<String> details;
}
```

### ScanHistoryItem (domain entity)
```dart
class ScanHistoryItem {
  final String scanId;
  final String? thumbnailUrl;
  final int riskScore;
  final String riskLevel;
  final String status;
  final DateTime createdAt;
}
```

### User (domain entity)
```dart
class User {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
}
```

### ConsentSetting (domain entity)
```dart
class ConsentSetting {
  final bool processingConsent;
  final bool historyConsent;
  final bool researchConsent;
}
```

---

## 8. API Integration

### Base Config (`dio_client.dart`)
- Base URL: configurable via env
- Headers: `Authorization: Bearer {token}`
- Interceptors: `AuthInterceptor` (auto-attach token), `LoggingInterceptor`

### Endpoints
```
POST   /auth/login
POST   /auth/register  
POST   /auth/refresh
POST   /auth/logout
GET    /auth/me

POST   /scans           (multipart/form-data: image, source, consentForResearch, clientRequestId)
GET    /scans/{taskId}
GET    /scans/{taskId}/result
DELETE /scans/{taskId}

GET    /history?page&limit&riskLevel&fromDate&toDate&keyword
GET    /history/{scanId}
DELETE /history/{scanId}
DELETE /history

POST   /reports
GET    /reports/categories

GET    /consents/me
PUT    /consents/me
POST   /privacy/export
DELETE /privacy/account
```

### Polling Strategy (ScanBloc)
1. POST /scans → receive taskId
2. Poll GET /scans/{taskId} every 3 seconds
3. When status = "completed" → fetch GET /scans/{taskId}/result
4. Timeout after 120 seconds → show timeout error

---

## 9. pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^9.1.1
  equatable: ^2.0.7
  
  # Navigation
  go_router: ^15.1.2
  
  # Network
  dio: ^5.8.0+1
  
  # Storage
  flutter_secure_storage: ^9.2.4
  
  # Image
  image_picker: ^1.1.2
  image_cropper: ^9.0.0
  cached_network_image: ^3.4.1
  
  # Fonts
  google_fonts: ^6.2.1
  
  # Utils
  equatable: ^2.0.7
  uuid: ^4.5.1
  intl: ^0.20.2
  
  # Icons (Material Symbols)
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  bloc_test: ^10.0.0
  mocktail: ^1.0.4
```

---

## 10. Key Implementation Notes

### Image Compression
- ก่อนอัปโหลด ตรวจสอบขนาดไฟล์ > 10MB → บีบอัดโดยใช้ `image_picker` quality parameter
- ตรวจสอบ format: jpg, jpeg, png, webp เท่านั้น

### Token Management
- Access Token: เก็บใน `flutter_secure_storage`
- Refresh Token: เก็บใน `flutter_secure_storage`
- AuthInterceptor: จัดการ 401 response → ลอง refresh → ถ้าล้มเหลว → logout

### Dark/Light Theme
- ใช้ `ThemeMode.system` เป็น default
- User override เก็บใน SharedPreferences
- AppTheme ใช้ Color Tokens จาก design HTML ทุกอัน

### Risk Level Calculation (Client-side display only)
```dart
RiskLevel fromScore(int score) {
  if (score < 40) return RiskLevel.low;
  if (score < 70) return RiskLevel.medium;
  return RiskLevel.high;
}
```
