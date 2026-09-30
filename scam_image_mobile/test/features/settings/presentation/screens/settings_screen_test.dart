import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scam_image_mobile/features/auth/domain/entities/user.dart';
import 'package:scam_image_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:scam_image_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';
import 'package:scam_image_mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:scam_image_mobile/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:scam_image_mobile/features/settings/presentation/screens/settings_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(ThemeMode.light);
  });

  Future<({AuthBloc authBloc, SettingsCubit settingsCubit, GoRouter router})>
  pumpSettings(
    WidgetTester tester, {
    User user = const User(
      id: 'user-1',
      email: 'tester@example.com',
      displayName: 'Tester',
    ),
    ThemeMode appThemeMode = ThemeMode.light,
    String language = 'th',
    int cacheSize = 0,
  }) async {
    final authRepository = MockAuthRepository();
    final settingsRepository = MockSettingsRepository();
    when(() => settingsRepository.saveLanguage(any())).thenAnswer((_) async {});
    when(
      () => settingsRepository.saveThemeMode(any()),
    ).thenAnswer((_) async {});
    when(
      () => settingsRepository.getCacheSizeBytes(),
    ).thenAnswer((_) async => cacheSize);
    when(() => settingsRepository.clearCache()).thenAnswer((_) async {});
    when(
      () => settingsRepository.getConsents(),
    ).thenAnswer((_) async => const ConsentSetting());

    final authBloc = AuthBloc(authRepository)..add(AuthSessionRestored(user));
    await authBloc.stream.firstWhere((state) => state is AuthAuthenticated);
    final settingsCubit = SettingsCubit(repository: settingsRepository);
    if (language != 'th') await settingsCubit.setLanguage(language);
    if (appThemeMode != ThemeMode.light) {
      await settingsCubit.setTheme(appThemeMode);
    }
    await settingsCubit.loadCacheSize();

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const Scaffold(body: Text('Notifications route')),
        ),
        GoRoute(
          path: '/main/settings/profile',
          builder: (_, _) => const Scaffold(body: Text('Profile route')),
        ),
        GoRoute(
          path: '/main/settings/privacy',
          builder: (_, _) => const Scaffold(body: Text('Privacy route')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login route')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp.router(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: appThemeMode,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(authBloc.close);
    addTearDown(settingsCubit.close);
    addTearDown(router.dispose);
    return (authBloc: authBloc, settingsCubit: settingsCubit, router: router);
  }

  testWidgets('shows authenticated display name and formatted cache size', (
    tester,
  ) async {
    await pumpSettings(tester, cacheSize: 1536);

    expect(find.text('Tester'), findsOneWidget);
    expect(find.text('1.5 KB'), findsOneWidget);
    expect(find.text('ภาษา'), findsOneWidget);
    expect(find.text('ธีม'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to email prefix when display name is empty', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      user: const User(
        id: 'user-2',
        email: 'fallback@example.com',
        displayName: '',
      ),
    );

    expect(find.text('fallback'), findsOneWidget);
  });

  testWidgets('language dialog switches to English', (tester) async {
    final env = await pumpSettings(tester);
    final repository = env.settingsCubit.repository as MockSettingsRepository;

    await tester.tap(find.text('ภาษา'));
    await tester.pumpAndSettle();
    expect(find.text('เลือกภาษา'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(env.settingsCubit.state.language, 'en');
    verify(() => repository.saveLanguage('en')).called(1);
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('theme dialog switches state to dark', (tester) async {
    final env = await pumpSettings(tester);
    final repository = env.settingsCubit.repository as MockSettingsRepository;

    await tester.tap(find.text('ธีม'));
    await tester.pumpAndSettle();
    expect(find.text('เลือกธีม'), findsOneWidget);
    await tester.tap(find.text('มืด'));
    await tester.pumpAndSettle();

    expect(env.settingsCubit.state.themeMode, ThemeMode.dark);
    verify(() => repository.saveThemeMode(ThemeMode.dark)).called(1);
  });

  testWidgets('clear cache cancel does not clear and confirm clears', (
    tester,
  ) async {
    final env = await pumpSettings(tester, cacheSize: 2048);
    final repository = env.settingsCubit.repository as MockSettingsRepository;

    await tester.dragUntilVisible(
      find.text('ล้างแคช'),
      find.byType(ListView),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ล้างแคช'));
    await tester.pumpAndSettle();
    expect(find.text('ล้างแคช', skipOffstage: false), findsWidgets);
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    verifyNever(() => repository.clearCache());

    await tester.tap(find.text('ล้างแคช'));
    await tester.pumpAndSettle();
    final clearButtons = find.text('ล้างแคช');
    await tester.tap(clearButtons.last);
    await tester.pumpAndSettle();

    verify(() => repository.clearCache()).called(1);
    expect(find.text('ล้าง Cache สำเร็จ'), findsOneWidget);
  });

  testWidgets('dark mode and English state render without layout errors', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      appThemeMode: ThemeMode.dark,
      language: 'en',
      cacheSize: 0,
    );

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('0 B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
