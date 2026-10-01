import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/di/injection_container.dart';
import 'package:scam_image_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';
import 'package:scam_image_mobile/features/settings/domain/repositories/settings_repository.dart';

class _Auth extends Mock implements AuthRepository {}

class _Settings extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const ConsentSetting());
  });
  for (final fail in [false, true]) {
    testWidgets(
      'onboarding prevents duplicate persistence and recovers failure=$fail',
      (tester) async {
        final auth = _Auth();
        final settings = _Settings();
        ServiceLocator.authRepository = auth;
        ServiceLocator.settingsRepository = settings;
        final pending = Completer<void>();
        var calls = 0;
        when(() => settings.updateConsents(any())).thenAnswer((_) {
          calls++;
          return calls == 1 ? pending.future : Future<void>.value();
        });
        when(() => auth.markOnboardingSeen()).thenAnswer((_) async {});
        final router = GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (_, _) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) =>
                  const Scaffold(body: Text('login destination')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(CheckboxListTile).first);
        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();
        final button = find.byType(ElevatedButton);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
        verify(() => settings.updateConsents(any())).called(1);
        if (fail) {
          pending.completeError(Exception('storage unavailable'));
          await tester.pumpAndSettle();
          verifyNever(() => auth.markOnboardingSeen());
          expect(find.text('login destination'), findsNothing);
          expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
          await tester.tap(button);
        } else {
          pending.complete();
        }
        await tester.pumpAndSettle();
        verify(() => auth.markOnboardingSeen()).called(1);
        expect(find.text('login destination'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
