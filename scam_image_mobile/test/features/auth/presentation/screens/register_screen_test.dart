import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/di/injection_container.dart';
import 'package:scam_image_mobile/features/auth/domain/entities/user.dart';
import 'package:scam_image_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:scam_image_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:scam_image_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';
import 'package:scam_image_mobile/features/settings/domain/repositories/settings_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

const user = User(id: '7', email: 'user@example.com', displayName: 'User Name');

void main() {
  late MockAuthRepository authRepo;
  late MockSettingsRepository settingsRepo;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    authRepo = MockAuthRepository();
    settingsRepo = MockSettingsRepository();
    ServiceLocator.authRepository = authRepo;
    ServiceLocator.settingsRepository = settingsRepo;
    when(
      () => settingsRepo.getConsents(),
    ).thenAnswer((_) async => const ConsentSetting(researchConsent: true));
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/main/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    return BlocProvider(
      create: (_) => AuthBloc(authRepo),
      child: MaterialApp.router(routerConfig: router, theme: ThemeData.dark()),
    );
  }

  Future<void> fill(
    WidgetTester tester, {
    String name = 'User Name',
    String email = 'user@example.com',
    String password = 'password123',
    String? confirm,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), email);
    await tester.enterText(fields.at(2), password);
    await tester.enterText(fields.at(3), confirm ?? password);
  }

  Future<void> submit(WidgetTester tester, {bool acceptTerms = true}) async {
    if (acceptTerms) {
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();
    }
    final button = find.widgetWithText(ElevatedButton, 'สมัครสมาชิก');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('invalid email is rejected before repository call', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await fill(tester, email: 'invalid-email');
    await submit(tester);

    expect(find.text('รูปแบบอีเมลไม่ถูกต้อง'), findsOneWidget);
    verifyNever(
      () => authRepo.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
        systemConsent: any(named: 'systemConsent'),
        researchConsent: any(named: 'researchConsent'),
      ),
    );
  });

  testWidgets('password shorter than 8 is rejected', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await fill(tester, password: '1234567');
    await submit(tester);

    expect(find.text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'), findsOneWidget);
  });

  testWidgets('password longer than 128 is rejected', (tester) async {
    final longPassword = List.filled(129, 'a').join();
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await fill(tester, password: longPassword);
    await submit(tester);

    expect(find.text('รหัสผ่านต้องไม่เกิน 128 ตัวอักษร'), findsOneWidget);
  });

  testWidgets('consent read failure shows feedback and does not register', (
    tester,
  ) async {
    when(
      () => settingsRepo.getConsents(),
    ).thenThrow(Exception('storage failed'));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await fill(tester);
    await submit(tester);

    expect(
      find.text('ไม่สามารถอ่านการตั้งค่าความยินยอมได้ กรุณาลองอีกครั้ง'),
      findsOneWidget,
    );
    verifyNever(
      () => authRepo.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
        systemConsent: any(named: 'systemConsent'),
        researchConsent: any(named: 'researchConsent'),
      ),
    );
  });

  testWidgets(
    'valid form forwards persisted research consent to auth repository',
    (tester) async {
      when(
        () => authRepo.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
          systemConsent: any(named: 'systemConsent'),
          researchConsent: any(named: 'researchConsent'),
        ),
      ).thenAnswer((_) async => user);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await fill(tester);
      await submit(tester);

      verify(
        () => authRepo.register(
          email: 'user@example.com',
          password: 'password123',
          displayName: 'User Name',
          systemConsent: true,
          researchConsent: true,
        ),
      ).called(1);
      expect(find.text('Home'), findsOneWidget);
    },
  );
}
