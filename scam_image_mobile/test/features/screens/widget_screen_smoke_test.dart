import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/auth/domain/entities/user.dart';
import 'package:scam_image_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:scam_image_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:scam_image_mobile/features/history/domain/repositories/history_repository.dart';
import 'package:scam_image_mobile/features/history/presentation/bloc/history_bloc.dart';
import 'package:scam_image_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:scam_image_mobile/features/scan/presentation/screens/home_screen.dart';
import 'package:scam_image_mobile/features/scan/presentation/screens/image_crop_screen.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';
import 'package:scam_image_mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:scam_image_mobile/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:scam_image_mobile/features/settings/presentation/screens/privacy_consent_screen.dart';
import 'package:scam_image_mobile/features/settings/presentation/screens/user_profile_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ConsentSetting());
  });

  late _MockAuthRepository authRepository;
  late _MockHistoryRepository historyRepository;
  late _MockSettingsRepository settingsRepository;

  setUp(() {
    authRepository = _MockAuthRepository();
    historyRepository = _MockHistoryRepository();
    settingsRepository = _MockSettingsRepository();
    when(
      () => settingsRepository.getConsents(),
    ).thenAnswer((_) async => const ConsentSetting());
    when(
      () => settingsRepository.updateConsents(any()),
    ).thenAnswer((_) async {});
    when(
      () => settingsRepository.exportPrivacyData(),
    ).thenThrow(UnimplementedError('privacy export is unavailable'));
    when(
      () => historyRepository.getScanHistory(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        riskLevel: any(named: 'riskLevel'),
        fromDate: any(named: 'fromDate'),
        toDate: any(named: 'toDate'),
        keyword: any(named: 'keyword'),
      ),
    ).thenAnswer((_) async => []);
  });

  Future<
    ({
      AuthBloc auth,
      HistoryBloc history,
      SettingsCubit settings,
      GoRouter router,
    })
  >
  pumpScreen(
    WidgetTester tester, {
    required String initialLocation,
    required Widget screen,
    User? user,
  }) async {
    final auth = AuthBloc(authRepository);
    if (user != null) {
      auth.add(AuthSessionRestored(user));
      await auth.stream.firstWhere((state) => state is AuthAuthenticated);
    }
    final history = HistoryBloc(repository: historyRepository);
    final settings = SettingsCubit(repository: settingsRepository);
    final notifications = NotificationsCubit();
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: initialLocation, builder: (_, _) => screen),
        GoRoute(
          path: '/main/home',
          builder: (_, _) => const Scaffold(body: Text('Home route')),
        ),
        GoRoute(
          path: '/loading',
          builder: (_, state) => Scaffold(body: Text('Loading ${state.extra}')),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const Scaffold(body: Text('Notifications route')),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: auth),
          BlocProvider<HistoryBloc>.value(value: history),
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<NotificationsCubit>.value(value: notifications),
        ],
        child: MaterialApp.router(
          theme: ThemeData.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(auth.close);
    addTearDown(history.close);
    addTearDown(settings.close);
    addTearDown(notifications.close);
    addTearDown(router.dispose);
    return (auth: auth, history: history, settings: settings, router: router);
  }

  testWidgets('Home renders upload and safety sections and requests history', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      initialLocation: '/home',
      screen: const HomeScreen(),
    );

    expect(find.byIcon(Icons.upload_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    verify(
      () => historyRepository.getScanHistory(page: 1, limit: 100, keyword: ''),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Crop preview exposes zoom and reset actions for missing image', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      initialLocation: '/crop',
      screen: const ImageCropScreen(filePath: '/missing/test-image.png'),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    expect((image.image as FileImage).file.path, '/missing/test-image.png');
    final imageTransform = find.ancestor(
      of: find.byType(Image).first,
      matching: find.byType(Transform),
    );
    final transform = tester.widget<Transform>(imageTransform.first);
    expect(transform.transform.getMaxScaleOnAxis(), 1.0);

    await tester.ensureVisible(find.text('ขยาย'));
    await tester.tap(find.text('ขยาย'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Transform>(imageTransform.first)
          .transform
          .getMaxScaleOnAxis(),
      1.5,
    );
    await tester.tap(find.text('รีเซ็ต'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Transform>(imageTransform.first)
          .transform
          .getMaxScaleOnAxis(),
      1.0,
    );
  });

  testWidgets('Profile renders authenticated identity and unsupported action', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      initialLocation: '/profile',
      screen: const UserProfileScreen(),
      user: const User(
        id: 'profile-test',
        email: 'person@example.com',
        displayName: 'Test Person',
      ),
    );

    expect(find.text('Test Person'), findsWidgets);
    expect(find.text('person@example.com'), findsWidgets);
    await tester.ensureVisible(find.text('แก้ไขโปรไฟล์'));
    await tester.tap(find.text('แก้ไขโปรไฟล์'));
    await tester.pumpAndSettle();
    expect(find.text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้'), findsOneWidget);
  });

  testWidgets(
    'Privacy export reports unavailable when service rejects request',
    (tester) async {
      await pumpScreen(
        tester,
        initialLocation: '/privacy',
        screen: const PrivacyConsentScreen(),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ขอสำเนาข้อมูลส่วนตัว'));
      await tester.pumpAndSettle();
      expect(
        find.text('เซิร์ฟเวอร์ยังไม่รองรับการส่งออกข้อมูลส่วนตัว'),
        findsOneWidget,
      );
      verify(() => settingsRepository.exportPrivacyData()).called(1);
    },
  );
}
