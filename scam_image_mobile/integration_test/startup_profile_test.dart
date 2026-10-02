import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scam_image_mobile/core/config/app_config.dart';
import 'package:scam_image_mobile/core/di/injection_container.dart';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:scam_image_mobile/main.dart' as app;

void main() {
  if (!kProfileMode ||
      AppConfig.fromEnvironment().environment != 'development') {
    throw StateError('This startup probe requires profile/development mode');
  }
  if (!const bool.fromEnvironment('E2E_DEDICATED_INSTALL')) {
    throw StateError('A dedicated test applicationId/install is required');
  }
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Signed-out startup produces Flutter frame timings', (
    tester,
  ) async {
    final storage = SecureStorage();
    expect(
      (await storage.getToken(kAccessToken)) == null,
      isTrue,
      reason:
          'Use a signed-out test installation; existing storage is preserved',
    );
    final stopwatch = Stopwatch();
    await binding.watchPerformance(() async {
      stopwatch.start();
      await ServiceLocator.init();
      runApp(const app.ScamGuardApp());
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while (find.byType(LoginScreen).evaluate().isEmpty &&
          find.byType(OnboardingScreen).evaluate().isEmpty &&
          DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException() == null, isTrue);
      }
      expect(
        find.byType(LoginScreen).evaluate().isNotEmpty ||
            find.byType(OnboardingScreen).evaluate().isNotEmpty,
        isTrue,
        reason: 'Expected signed-out startup route',
      );
      stopwatch.stop();
      await tester.pump(const Duration(seconds: 1));
    }, reportKey: 'signed_out_startup_frames');
    binding.reportData!['di_to_signed_out_route_ms'] =
        stopwatch.elapsedMilliseconds;
    binding.reportData!['scope'] =
        'Profile test harness DI to Login/Onboarding and Flutter frames; '
        'not OS cold startup, authenticated flows or full soak';
    final summary =
        binding.reportData!['signed_out_startup_frames']
            as Map<String, dynamic>;
    expect(summary['frame_count'] as int, greaterThan(0));
  });
}
