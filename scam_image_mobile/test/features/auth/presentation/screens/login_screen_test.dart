import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scam_image_mobile/features/auth/presentation/screens/login_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Build the app with a GoRouter that has both /login and /main/home routes.
  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/main/home',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Home'))),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Register'))),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      theme: ThemeData.dark(),
    );
  }

  /// Trigger form validation by tapping the submit button.
  Future<void> submitForm(WidgetTester tester) async {
    // The login button has label text "เข้าสู่ระบบ"
    final loginButton = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }

  group('LoginScreen — email validation', () {
    testWidgets('empty email shows "กรุณากรอกอีเมล"', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Leave email empty, clear password so only email error shows
      await submitForm(tester);

      expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
    });

    testWidgets('email without "@" shows "รูปแบบอีเมลไม่ถูกต้อง"',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Type an email without '@'
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalidemail',
      );

      await submitForm(tester);

      expect(find.text('รูปแบบอีเมลไม่ถูกต้อง'), findsOneWidget);
    });

    testWidgets('valid email clears email error', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@example.com',
      );

      await submitForm(tester);

      expect(find.text('กรุณากรอกอีเมล'), findsNothing);
      expect(find.text('รูปแบบอีเมลไม่ถูกต้อง'), findsNothing);
    });
  });

  group('LoginScreen — password validation', () {
    testWidgets('empty password shows "กรุณากรอกรหัสผ่าน"', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Fill in a valid email so only password error fires
      await tester.enterText(
        find.byType(TextFormField).first,
        'user@example.com',
      );

      await submitForm(tester);

      expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    });

    testWidgets('non-empty password clears password error', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'user@example.com');
      await tester.enterText(fields.at(1), 'password123');

      await submitForm(tester);

      expect(find.text('กรุณากรอกรหัสผ่าน'), findsNothing);
    });
  });

  group('LoginScreen — password visibility toggle', () {
    testWidgets('password is obscured by default', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // The password TextFormField (index 1) should have obscureText = true
      final passwordField =
          tester.widget<EditableText>(find.byType(EditableText).at(1));
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('tapping visibility icon reveals password', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap the visibility toggle icon button
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      final passwordField =
          tester.widget<EditableText>(find.byType(EditableText).at(1));
      expect(passwordField.obscureText, isFalse);
    });

    testWidgets('tapping visibility icon again hides password', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Show password
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Hide password again
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      final passwordField =
          tester.widget<EditableText>(find.byType(EditableText).at(1));
      expect(passwordField.obscureText, isTrue);
    });
  });
}
