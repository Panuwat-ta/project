# Tasks: ScamGuard Mobile App

## Phase 1: Foundation & Core Setup

- [x] 1. Setup project structure, dependencies, and design system
  - Update `pubspec.yaml` with all required dependencies (flutter_bloc, go_router, dio, flutter_secure_storage, image_picker, image_cropper, cached_network_image, google_fonts, uuid, intl, equatable, bloc_test, mocktail)
  - Create folder structure: `lib/core/` and `lib/features/` with all subdirectories
  - Create `lib/core/constants/app_colors.dart` with all color tokens from design (bgDark #0F1720, surfaceDark #162230, primary #006685, primaryFixedDim #6CD2FF, danger #DC2626, warning #D68900, success #006E2D, etc.)
  - Create `lib/core/constants/app_typography.dart` using google_fonts (Sarabun + Inter)
  - Create `lib/core/constants/app_spacing.dart` with spacing constants (xs:4, sm:8, gutter:12, md:16, safeMargin:20, lg:24, xl:32, xxl:48)
  - Create `lib/core/theme/app_theme.dart` with full dark and light ThemeData using color tokens
  - Create `lib/core/errors/failures.dart` and `exceptions.dart`
  - Create `lib/core/network/api_endpoints.dart`
  - Run `flutter pub get` to verify dependencies resolve
  - _Requirements: REQ-NF-004_

- [x] 2. Implement core shared widgets
  - Create `lib/core/widgets/primary_button.dart` — full-width ElevatedButton with loading state, uses AppColors.primary / primaryFixedDim
  - Create `lib/core/widgets/secondary_button.dart` — outlined button
  - Create `lib/core/widgets/risk_badge.dart` — colored badge chip for ต่ำ/ปานกลาง/สูง/ปลอดภัย with text + color from design
  - Create `lib/core/widgets/risk_progress_bar.dart` — horizontal progress bar with risk-colored fill
  - Create `lib/core/widgets/risk_gauge.dart` — SVG-based semicircle gauge using CustomPainter or flutter_svg
  - Create `lib/core/widgets/app_top_bar.dart` — PreferredSizeWidget with ScamGuard logo (shield_lock icon), title, optional actions
  - Create `lib/core/widgets/app_bottom_navigation.dart` — 4-tab bottom nav (หน้าหลัก/ประวัติ/แจ้งรายงาน/ตั้งค่า) with active state styling
  - Create `lib/core/widgets/empty_state_view.dart` — icon + title + subtitle
  - Create `lib/core/widgets/error_state_view.dart` — icon + message + retry button
  - Create `lib/core/widgets/loading_overlay.dart` — full-screen shimmer/spinner
  - Create `lib/core/widgets/consent_checkbox_tile.dart` — labeled checkbox for consent flows
  - Create `lib/core/widgets/analysis_step_tile.dart` — step with done/active/pending states
  - Create `lib/core/widgets/glass_card.dart` — semi-transparent card (bg rgba(22,34,48,0.8), backdrop blur)
  - _Requirements: REQ-NF-001, REQ-NF-003_

- [x] 3. Setup navigation router and app entry point
  - Create `lib/core/router/app_router.dart` using go_router with all routes: /splash, /onboarding, /login, /register, /main (ShellRoute for bottom nav), /main/home, /main/history, /main/history/:id, /main/report, /main/settings, /main/settings/profile, /main/settings/privacy, /crop, /loading, /result/:scanId, /heatmap/:scanId, /notifications
  - Implement `NavigationGuard` that redirects unauthenticated users to /login
  - Update `lib/main.dart` to use MaterialApp.router with AppTheme (dark by default), google_fonts textTheme, and app router
  - Create `lib/core/storage/secure_storage.dart` wrapper for flutter_secure_storage
  - _Requirements: REQ-001_

## Phase 2: Authentication Feature

- [x] 4. Auth domain layer
  - Create `lib/features/auth/domain/entities/user.dart` (id, email, displayName, avatarUrl)
  - Create `lib/features/auth/domain/entities/auth_token.dart` (accessToken, refreshToken, expiresAt)
  - Create `lib/features/auth/domain/repositories/auth_repository.dart` (abstract interface)
  - Create use cases: `login_usecase.dart`, `register_usecase.dart`, `logout_usecase.dart`, `refresh_token_usecase.dart`, `get_current_user_usecase.dart`
  - _Requirements: REQ-001, REQ-003, REQ-004_

- [x] 5. Auth data layer
  - Create `lib/features/auth/data/models/user_model.dart` (extends User, fromJson/toJson)
  - Create `lib/features/auth/data/models/auth_token_model.dart`
  - Create `lib/features/auth/data/datasources/auth_remote_datasource.dart` using Dio (POST /auth/login, /auth/register, /auth/refresh, /auth/logout, GET /auth/me)
  - Create `lib/features/auth/data/datasources/auth_local_datasource.dart` using SecureStorage (save/get/delete tokens)
  - Create `lib/features/auth/data/repositories/auth_repository_impl.dart`
  - Create `lib/core/network/dio_client.dart` with base URL, auth interceptor (attach Bearer token, handle 401 → auto refresh)
  - _Requirements: REQ-003, REQ-NF-002_

- [x] 6. Auth presentation — SplashScreen
  - Create `lib/features/auth/presentation/bloc/splash_cubit.dart` with states: SplashInitial, CheckingSession, Authenticated, Unauthenticated, ConsentRequired, Failure
  - SplashCubit checks token validity → emits appropriate state
  - Create `lib/features/auth/presentation/screens/splash_screen.dart`:
    - Full screen dark gradient (#0F1720 → #162230) matching design
    - Atmospheric blur circles (primary glow top-right, secondary glow bottom-left)
    - Glass card with shield icon (filled, white, 80px) + search icon overlay badge
    - App name "Scam Image Detection" (headline-lg-mobile) + subtitle
    - Security badge: "Secure & Reliable"
    - Bottom: spinning loading ring + cycling status text (4 messages)
    - Reacts to SplashCubit state → navigates via go_router
  - _Requirements: REQ-001_

- [x] 7. Auth presentation — Onboarding & Login & Register screens
  - Create `lib/features/auth/presentation/bloc/consent_cubit.dart`
  - Create `lib/features/auth/presentation/screens/onboarding_screen.dart`:
    - Shield logo, title, app purpose description
    - Disclaimer: "ผลการประเมินเป็นเพียงการประเมินความเสี่ยง ไม่ใช่คำตัดสินทางกฎหมาย"
    - ConsentCheckboxTile ×2 (terms required, research optional)
    - PrimaryButton disabled until terms checked
  - Create `lib/features/auth/presentation/bloc/auth_bloc.dart` with events/states per design.md
  - Create `lib/features/auth/presentation/screens/login_screen.dart`:
    - GlassCard layout matching HTML design
    - Email field (mail icon), Password field (lock icon + toggle visibility)
    - "ลืมรหัสผ่าน" link, "จดจำการใช้งาน" checkbox
    - PrimaryButton "เข้าสู่ระบบ" with loading state
    - Divider + Google Login button (outlined, Google SVG logo)
    - Link to register
    - Error messages below fields
  - Create `lib/features/auth/presentation/screens/register_screen.dart`:
    - Display Name, Email, Password, Confirm Password fields
    - Terms checkbox, PrimaryButton "สมัครสมาชิก"
    - Inline validation (8 char min, passwords match)
  - _Requirements: REQ-002, REQ-003, REQ-004_

## Phase 3: Scan Feature

- [x] 8. Scan domain layer
  - Create `lib/features/scan/domain/entities/scan_image.dart` (file path, file size, format)
  - Create `lib/features/scan/domain/entities/analysis_task.dart` (taskId, status, progress)
  - Create `lib/features/scan/domain/repositories/scan_repository.dart`
  - Create use cases: `select_image_usecase.dart`, `submit_image_usecase.dart`, `get_analysis_status_usecase.dart`
  - _Requirements: REQ-005, REQ-006, REQ-007_

- [x] 9. Scan data layer
  - Create `lib/features/scan/data/models/analysis_task_model.dart`
  - Create `lib/features/scan/data/datasources/scan_remote_datasource.dart`:
    - POST /scans with multipart (image, source: "upload", consentForResearch, clientRequestId: UUID)
    - GET /scans/{taskId} for polling
    - DELETE /scans/{taskId}
  - Create `lib/features/scan/data/repositories/scan_repository_impl.dart` with image compression logic (if > 10MB)
  - _Requirements: REQ-007, REQ-NF-001_

- [x] 10. Scan presentation — HomeScreen
  - Create `lib/features/scan/presentation/bloc/home_bloc.dart`
  - Create `lib/features/scan/presentation/screens/home_screen.dart`:
    - AppTopBar with notifications badge (unread dot on notifications icon)
    - Greeting section: "สวัสดี, [displayName]" + welcome subtitle
    - Upload Card (gradient surfaceDark → bgDark): upload icon circle (80px), title, description, file type hint, PrimaryButton "อัปโหลดรูปภาพ" with pulse-soft animation
    - Safety Tips Bento (2-col grid): verified_user card, link_off card, full-width report card
    - Recent History section: "ดูทั้งหมด" link + 3 HistoryListItem
    - PermissionRequestView when file permission denied
  - _Requirements: REQ-005_

- [x] 11. Scan presentation — ImageCropScreen & AnalysisLoadingScreen
  - Create `lib/features/scan/presentation/screens/image_crop_screen.dart`:
    - Full screen with image_cropper package
    - AppBar with back button (shows confirm dialog if cropped)
    - Bottom: rotate button, change image button
    - PrimaryButton "เริ่มวิเคราะห์"
  - Create `lib/features/scan/presentation/bloc/scan_bloc.dart` (full polling logic)
  - Create `lib/features/scan/presentation/screens/analysis_loading_screen.dart`:
    - AppTopBar
    - Circular progress SVG (CustomPainter: radius 84, dark track #27313C, primary fill, animated strokeDashOffset)
    - Center of circle: image thumbnail with pulse-border + horizontal scanning line animation
    - Floating % badge (primary bg, bottom center of circle)
    - Heading + dots wave animation
    - Step Checklist Card (surfaceDark): AnalysisStepTile ×3 (done/active/pending)
    - Privacy badge
    - Polling every 3s using Timer.periodic, stops on complete/error/timeout (120s)
  - _Requirements: REQ-006, REQ-007_

## Phase 4: Result Feature

- [x] 12. Result domain layer
  - Create `lib/features/result/domain/entities/analysis_result.dart` (scanId, taskId, status, riskScore, riskLevel, summary, imageUrl, heatmapUrl, createdAt, factors)
  - Create `lib/features/result/domain/entities/risk_factor.dart` (type, score, title, details)
  - Create `lib/features/result/domain/repositories/result_repository.dart`
  - Create `lib/features/result/domain/usecases/get_analysis_result_usecase.dart`
  - Create helper: `lib/core/utils/risk_level_helper.dart` (fromScore: 0-39=low, 40-69=medium, 70-100=high)
  - _Requirements: REQ-008_

- [x] 13. Result data layer
  - Create `lib/features/result/data/models/analysis_result_model.dart` (fromJson/toJson)
  - Create `lib/features/result/data/models/risk_factor_model.dart`
  - Create `lib/features/result/data/datasources/result_remote_datasource.dart` (GET /scans/{taskId}/result)
  - Create `lib/features/result/data/repositories/result_repository_impl.dart`
  - _Requirements: REQ-008_

- [x] 14. Result presentation — AnalysisResultScreen & HeatmapViewerScreen
  - Create `lib/features/result/presentation/bloc/result_bloc.dart`
  - Create `lib/features/result/presentation/screens/analysis_result_screen.dart`:
    - AppTopBar
    - Risk Gauge Section: RiskGauge widget (SVG semicircle, animates on load), risk score number, RiskBadge
    - Summary Card (surfaceDark): analytics icon + summary text
    - Analysis Bento Grid (2-col): contact info card, transaction card + full-width heatmap preview card with image bg overlay
    - Action buttons (2 rows): ดูรายละเอียด, ดู Heatmap, รายงานภาพต้องสงสัย (outlined danger), แชร์ผลลัพธ์ (outlined cyan)
    - Multi-layer detail sections (expandable/tabs): Textual, Source, Visual
  - Create `lib/features/result/presentation/screens/heatmap_viewer_screen.dart`:
    - InteractiveViewer for zoom/pan
    - Stack: original image + heatmap overlay with opacity
    - Toggle buttons (Original / Heatmap)
    - Opacity Slider
    - Download/save button
    - Explanation text card
  - _Requirements: REQ-008, REQ-009_

## Phase 5: History Feature

- [x] 15. History domain layer
  - Create `lib/features/history/domain/entities/scan_history_item.dart`
  - Create `lib/features/history/domain/repositories/history_repository.dart`
  - Create use cases: `get_scan_history_usecase.dart`, `delete_scan_history_item_usecase.dart`, `search_history_usecase.dart`
  - _Requirements: REQ-010, REQ-011_

- [x] 16. History data layer
  - Create `lib/features/history/data/models/scan_history_item_model.dart`
  - Create `lib/features/history/data/datasources/history_remote_datasource.dart` (GET/DELETE /history endpoints with pagination params)
  - Create `lib/features/history/data/repositories/history_repository_impl.dart`
  - _Requirements: REQ-010_

- [x] 17. History presentation
  - Create `lib/features/history/presentation/bloc/history_bloc.dart` (load, refresh, search, delete)
  - Create `lib/features/history/presentation/screens/history_screen.dart`:
    - AppTopBar + notifications button
    - Section title + count badge
    - Search bar (rounded-xl, search icon) + Filter button (tune icon)
    - Dismissible list (swipe left to delete with red delete action)
    - HistoryListItem: thumbnail (80×80, CachedNetworkImage), title, date with calendar icon, RiskProgressBar + %, RiskBadge top-right
    - Pull-to-refresh (RefreshIndicator)
    - EmptyStateView (history_off icon)
    - Pagination (load more on scroll end)
  - Create `lib/features/history/presentation/screens/history_detail_screen.dart`:
    - Same layout as AnalysisResultScreen
    - Shows note if original image unavailable
    - "สแกนภาพใหม่" button
  - _Requirements: REQ-010, REQ-011_

## Phase 6: Report & Notifications

- [x] 18. Report feature
  - Create `lib/features/report/domain/entities/scam_report.dart`
  - Create `lib/features/report/domain/repositories/report_repository.dart`
  - Create `lib/features/report/domain/usecases/submit_scam_report_usecase.dart`
  - Create `lib/features/report/data/models/scam_report_model.dart`
  - Create `lib/features/report/data/datasources/report_remote_datasource.dart` (POST /reports, GET /reports/categories)
  - Create `lib/features/report/data/repositories/report_repository_impl.dart`
  - Create `lib/features/report/presentation/bloc/report_bloc.dart`
  - Create `lib/features/report/presentation/screens/report_scam_screen.dart`:
    - AppBar "รายงานภาพต้องสงสัย"
    - Image preview card (from scanId or current image)
    - Category selector (FilterChip grid: Romance Scam, ซื้อขายออนไลน์, สลิปปลอม, ลงทุน, ปลอมแปลงตัวตน, AI/Deepfake, อื่นๆ)
    - Detail TextField (multiline, validator min 10 chars)
    - Platform selector (Facebook, LINE, Instagram, Marketplace, Website)
    - Reference URL / account TextField
    - ConsentCheckboxTile (research use)
    - PrimaryButton "ส่งรายงาน" with loading state + success feedback
  - _Requirements: REQ-012_

- [x] 19. Notifications feature
  - Create `lib/features/notifications/domain/entities/app_notification.dart` (id, type, title, body, createdAt, isRead, scanId?)
  - Create `lib/features/notifications/presentation/cubit/notifications_cubit.dart`
  - Create `lib/features/notifications/presentation/screens/notifications_screen.dart`:
    - AppTopBar
    - NotificationListItem: icon (analytics/warning/campaign) + title + body + time
    - Tap → navigate to result screen (if scan notification)
    - "ล้างทั้งหมด" button
    - Dismissible items (swipe to dismiss)
    - EmptyStateView (notifications_off icon)
  - _Requirements: REQ-013_

## Phase 7: Settings Feature

- [x] 20. Settings domain & data layers
  - Create `lib/features/settings/domain/entities/consent_setting.dart` (processingConsent, historyConsent, researchConsent)
  - Create `lib/features/settings/domain/repositories/settings_repository.dart`
  - Create use cases: `get_consents_usecase.dart`, `update_consents_usecase.dart`, `delete_account_usecase.dart`, `export_privacy_data_usecase.dart`
  - Create `lib/features/settings/data/datasources/settings_remote_datasource.dart` (GET/PUT /consents/me, POST /privacy/export, DELETE /privacy/account)
  - Create `lib/features/settings/data/repositories/settings_repository_impl.dart`
  - _Requirements: REQ-014, REQ-015, REQ-016_

- [x] 21. Settings presentation screens
  - Create `lib/features/settings/presentation/bloc/settings_bloc.dart` (theme, language, cache, logout)
  - Create `lib/features/settings/presentation/screens/settings_screen.dart`:
    - User info header (avatar placeholder + displayName + email)
    - ListTile sections: โปรไฟล์, ความปลอดภัยของบัญชี, การแจ้งเตือน, ภาษา
    - Theme toggle switch (Light/Dark)
    - ความเป็นส่วนตัวและ Consent → navigate to PrivacyConsentScreen
    - ล้าง Cache button (with confirmation snackbar)
    - ออกจากระบบ button (danger color) → confirmation AlertDialog → clears token + cache
  - Create `lib/features/settings/presentation/screens/user_profile_screen.dart`:
    - CircleAvatar (80px) with edit icon overlay
    - Display Name TextField (editable)
    - Email TextField (read-only)
    - PrimaryButton "บันทึก"
  - Create `lib/features/settings/presentation/screens/privacy_consent_screen.dart`:
    - Section: "การจัดการความยินยอม"
    - SwitchListTile ×3: ประมวลผลรูปภาพ (required), เก็บประวัติ, ใช้เพื่อวิจัย
    - Export data button
    - Delete account button (danger) → 2-step confirmation dialog
  - _Requirements: REQ-014, REQ-015, REQ-016_

## Phase 8: Main Shell & Integration

- [x] 22. Main shell with bottom navigation
  - Create `lib/features/auth/presentation/screens/main_shell.dart` — ShellRoute wrapper with AppBottomNavigation
  - Wire up all 4 tabs: Home, History, Report (แจ้งรายงาน), Settings
  - Handle bottom nav active state via go_router location
  - _Requirements: REQ-005 through REQ-016_

- [x] 23. Integration — dependency injection & final wiring
  - Create `lib/core/di/injection_container.dart` (or use get_it / manual DI via MultiRepositoryProvider)
  - Provide all BLoCs and Repositories via MultiBlocProvider in main.dart
  - Wire up all navigation callbacks (onUploadPressed → /crop, onAnalysisComplete → /result/:id, etc.)
  - Integrate Share functionality (result screen → share image + text via share_plus or url_launcher)
  - Final integration: run `flutter analyze` and fix all warnings
  - _Requirements: All_

## Phase 9: Testing & Polish

- [x] 24. Unit tests — Domain & BLoC
  - Write unit tests for RiskLevelHelper (fromScore boundary conditions)
  - Write unit tests for AuthBloc (login success/failure, token refresh)
  - Write unit tests for ScanBloc (polling state transitions)
  - Write BLoC tests using bloc_test and mocktail for mocking repositories
  - _Requirements: REQ-003, REQ-007, REQ-008_

- [x] 25. Widget tests
  - Write widget tests for LoginScreen form validation
  - Write widget tests for RiskBadge (correct color and text per level)
  - Write widget tests for HistoryScreen empty state
  - Write widget tests for ConsentCheckboxTile (button disabled until checked)
  - _Requirements: REQ-002, REQ-003, REQ-008, REQ-010_
