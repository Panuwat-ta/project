import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/main_shell.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/history/presentation/screens/history_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/result/presentation/screens/analysis_result_screen.dart';
import '../../features/result/presentation/screens/heatmap_viewer_screen.dart';
import '../../features/report/presentation/screens/report_scam_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/scan/presentation/screens/home_screen.dart';
import '../../features/scan/presentation/screens/image_crop_screen.dart';
import '../../features/scan/presentation/screens/analysis_loading_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/user_profile_screen.dart';
import '../../features/settings/presentation/screens/privacy_consent_screen.dart';

/// [AppRouter] wires up the entire go_router configuration for ScamGuard.
///
/// Structure:
/// ```
/// /splash
/// /onboarding
/// /login
/// /register
/// /main  (ShellRoute — bottom nav)
///   /main/home
///   /main/history
///   /main/history/:id
///   /main/report
///   /main/settings
///   /main/settings/profile
///   /main/settings/privacy
/// /crop
/// /loading
/// /result/:scanId
/// /heatmap/:scanId
/// /notifications
/// ```
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // ── Auth / entry flow ─────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Main shell (bottom navigation) ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/main/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/main/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/main/report',
            builder: (context, state) => ReportScamScreen(
              scanId: (state.extra as Map<String, dynamic>?)?['scanId']
                  as String?,
            ),
          ),
          GoRoute(
            path: '/main/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (context, state) => const UserProfileScreen(),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacyConsentScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Standalone screens ────────────────────────────────────────────────
      GoRoute(
        path: '/crop',
        builder: (context, state) => ImageCropScreen(
          filePath: (state.extra as Map<String, dynamic>?)?['filePath']
                  as String? ??
              '',
        ),
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) => AnalysisLoadingScreen(
          filePath: (state.extra as Map<String, dynamic>?)?['filePath']
                  as String? ??
              '',
        ),
      ),
      GoRoute(
        path: '/result/:scanId',
        builder: (context, state) => AnalysisResultScreen(
          taskId: state.pathParameters['scanId']!,
        ),
      ),
      GoRoute(
        path: '/heatmap/:scanId',
        builder: (context, state) => HeatmapViewerScreen(
          taskId: state.pathParameters['scanId']!,
          imageUrl: (state.extra as Map<String, dynamic>?)?['imageUrl']
              as String?,
          heatmapUrl: (state.extra as Map<String, dynamic>?)?['heatmapUrl']
              as String?,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/detail/:scanId',
        builder: (context, state) => HistoryDetailScreen(
          scanId: state.pathParameters['scanId']!,
        ),
      ),
    ],
  );
}


