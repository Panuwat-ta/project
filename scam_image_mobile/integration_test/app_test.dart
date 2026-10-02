import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scam_image_mobile/core/di/injection_container.dart';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';
import 'package:scam_image_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:scam_image_mobile/features/history/presentation/screens/history_screen.dart';
import 'package:scam_image_mobile/features/scan/presentation/screens/home_screen.dart';
import 'package:scam_image_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:scam_image_mobile/main.dart' as app;

import 'support/staging_test_config.dart';

Future<void> waitFor(
  WidgetTester tester,
  bool Function() ready,
  String step,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.takeException() == null,
      isTrue,
      reason: 'Flutter exception during $step',
    );
  }
  expect(ready(), isTrue, reason: 'Timed out during $step');
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  final config = StagingTestConfig.fromEnvironment();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Staging login, History, Settings and confirmed logout', (
    tester,
  ) async {
    // Dedicated signed-out test installation; never delete user storage.
    await ServiceLocator.init();
    runApp(const app.ScamGuardApp());
    await waitFor(
      tester,
      () =>
          find.byType(LoginScreen).evaluate().isNotEmpty ||
          find.byType(OnboardingScreen).evaluate().isNotEmpty ||
          find.byType(HomeScreen).evaluate().isNotEmpty,
      'initial route',
    );
    expect(
      find.byType(HomeScreen),
      findsNothing,
      reason: 'Use a dedicated signed-out staging installation',
    );
    if (find.byType(OnboardingScreen).evaluate().isNotEmpty) {
      expect(
        config.acceptTerms,
        isTrue,
        reason: 'Explicit E2E_ACCEPT_TERMS approval required for onboarding',
      );
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsNWidgets(2));
      if (!tester.widget<CheckboxListTile>(checkboxes.first).value!) {
        await tapVisible(tester, checkboxes.first);
      }
      // Do not enable research consent.
      await tapVisible(tester, find.byType(ElevatedButton));
      await waitFor(
        tester,
        () => find.byType(LoginScreen).evaluate().isNotEmpty,
        'onboarding completion',
      );
    }
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.first, config.email);
    await tester.enterText(fields.last, config.password);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tapVisible(tester, find.byType(ElevatedButton));
    await waitFor(
      tester,
      () => find.byType(HomeScreen).evaluate().isNotEmpty,
      'authenticated Home',
    );
    final navigation = find.byWidgetPredicate(
      (widget) => widget is NavigationBar || widget is NavigationRail,
    );
    await tapVisible(
      tester,
      find.descendant(
        of: navigation,
        matching: find.byIcon(Icons.history_outlined),
      ),
    );
    await waitFor(
      tester,
      () => find.byType(HistoryScreen).evaluate().isNotEmpty,
      'History navigation',
    );
    await tapVisible(
      tester,
      find.descendant(
        of: navigation,
        matching: find.byIcon(Icons.settings_outlined),
      ),
    );
    await waitFor(
      tester,
      () => find.byType(SettingsScreen).evaluate().isNotEmpty,
      'Settings navigation',
    );
    await tapVisible(tester, find.byIcon(Icons.logout));
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    final actions = find.descendant(
      of: dialog,
      matching: find.byType(TextButton),
    );
    expect(actions, findsNWidgets(2));
    await tapVisible(tester, actions.last);
    await waitFor(
      tester,
      () =>
          find.byType(LoginScreen).evaluate().isNotEmpty &&
          tester.element(find.byType(LoginScreen)).read<AuthBloc>().state
              is AuthUnauthenticated,
      'completed local logout',
    );
    expect(
      (await ServiceLocator.secureStorage.getToken(kAccessToken)) == null,
      isTrue,
      reason: 'Access token must be absent after logout',
    );
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(HistoryScreen), findsNothing);
    expect(tester.takeException() == null, isTrue);
  });
}
