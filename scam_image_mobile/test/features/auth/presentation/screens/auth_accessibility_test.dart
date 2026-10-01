import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/theme/app_theme.dart';
import 'package:scam_image_mobile/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:scam_image_mobile/features/auth/presentation/bloc/splash_cubit.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:scam_image_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:scam_image_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/onboarding_screen.dart';

class _Repository extends Mock implements AuthRepository {}

class _Splash extends MockCubit<SplashState> implements SplashCubit {}

class _Settings extends MockCubit<SettingsState> implements SettingsCubit {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final language in ['th', 'en']) {
    for (final size in [
      const Size(390, 844),
      const Size(844, 390),
      const Size(1024, 768),
    ]) {
      for (final scale in [1.0, 1.3, 1.5]) {
        for (final dark in [false, true]) {
          for (final screen in <String, Widget>{
            'login': const LoginScreen(),
            'register': const RegisterScreen(),
            'onboarding': const OnboardingScreen(),
            'splash': const SplashScreen(),
          }.entries) {
            testWidgets(
              '${screen.key} size=$size scale=$scale dark=$dark language=$language no overflow',
              (tester) async {
                tester.view.physicalSize = size;
                tester.view.devicePixelRatio = 1;
                addTearDown(tester.view.resetPhysicalSize);
                addTearDown(tester.view.resetDevicePixelRatio);
                final bloc = AuthBloc(_Repository());
                addTearDown(bloc.close);
                final splash = _Splash();
                when(() => splash.state).thenReturn(const CheckingSession());
                when(() => splash.checkSession()).thenAnswer((_) async {});
                addTearDown(splash.close);
                final settings = _Settings();
                when(
                  () => settings.state,
                ).thenReturn(SettingsState(language: language));
                addTearDown(settings.close);
                await tester.pumpWidget(
                  MultiBlocProvider(
                    providers: [
                      BlocProvider<AuthBloc>.value(value: bloc),
                      BlocProvider<SplashCubit>.value(value: splash),
                      BlocProvider<SettingsCubit>.value(value: settings),
                    ],
                    child: MaterialApp(
                      theme: dark ? AppTheme.dark : AppTheme.light,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(scale),
                          disableAnimations: true,
                          viewInsets: size.width > size.height
                              ? const EdgeInsets.only(bottom: 120)
                              : EdgeInsets.zero,
                        ),
                        child: child!,
                      ),
                      home: screen.value,
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                if (screen.key == 'login' || screen.key == 'register') {
                  final passwordButton = find.byTooltip(
                    language == 'th' ? 'แสดงรหัสผ่าน' : 'Show password',
                  );
                  expect(
                    passwordButton,
                    findsNWidgets(screen.key == 'register' ? 2 : 1),
                  );
                  for (final element in passwordButton.evaluate()) {
                    final bounds = tester.getSize(
                      find.byWidget(element.widget),
                    );
                    expect(bounds.width, greaterThanOrEqualTo(48));
                    expect(bounds.height, greaterThanOrEqualTo(48));
                  }
                }
              },
            );
          }
        }
      }
    }
  }
}
