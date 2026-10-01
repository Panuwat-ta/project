import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/router/app_router.dart';
import 'package:scam_image_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:scam_image_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/onboarding_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    required String deepLink,
  }) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = AppRouter.createRouter(authRepository: repository);
    router.go(deepLink);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(repository),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(router.dispose);
    return router;
  }

  testWidgets('protected deep link sends new users to onboarding', (
    tester,
  ) async {
    when(() => repository.hasSeenOnboarding()).thenAnswer((_) async => false);

    final router = await pumpRouter(tester, deepLink: '/result/scan-1');

    expect(router.routeInformationProvider.value.uri.path, '/onboarding');
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'protected deep link sends onboarded users without a token to login',
    (tester) async {
      when(() => repository.hasSeenOnboarding()).thenAnswer((_) async => true);
      when(() => repository.hasValidToken()).thenAnswer((_) async => false);

      final router = await pumpRouter(tester, deepLink: '/detail/scan-1');

      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('storage error redirects protected deep link to login', (
    tester,
  ) async {
    when(
      () => repository.hasSeenOnboarding(),
    ).thenThrow(Exception('secure storage unavailable'));

    final router = await pumpRouter(tester, deepLink: '/heatmap/scan-1');

    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
