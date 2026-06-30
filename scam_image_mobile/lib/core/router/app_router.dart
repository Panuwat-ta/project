import 'package:go_router/go_router.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/onboarding_consent_screen.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:scam_image_mobile/features/scan/presentation/screens/main_shell.dart';
import 'package:scam_image_mobile/features/scan/presentation/screens/image_preview_crop_screen.dart';
import 'package:scam_image_mobile/features/scan/presentation/screens/analysis_loading_screen.dart';
import 'package:scam_image_mobile/features/result/presentation/screens/analysis_result_screen.dart';
import 'package:scam_image_mobile/features/result/presentation/screens/result_detail_screen.dart';
import 'package:scam_image_mobile/features/settings/presentation/screens/privacy_consent_screen.dart';
import 'package:scam_image_mobile/features/report/presentation/screens/report_scam_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => const OnboardingConsentScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/crop',
        builder: (context, state) {
          final imagePath = state.extra as String;
          return ImagePreviewCropScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) {
          final imagePath = state.extra as String;
          return AnalysisLoadingScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final resultData = state.extra as Map<String, dynamic>;
          return AnalysisResultScreen(resultData: resultData);
        },
      ),
      GoRoute(
        path: '/result-detail',
        builder: (context, state) {
          final resultData = state.extra as Map<String, dynamic>;
          return ResultDetailScreen(resultData: resultData);
        },
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) {
          final imagePath = state.extra as String;
          return ReportScamScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/privacy-consent',
        builder: (context, state) => const PrivacyConsentScreen(),
      ),
    ],
  );
}
