// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:scam_image_mobile/main.dart';

void main() {
  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ScamGuardApp());

    // Verify that the splash screen shows Scam Image Detection.
    expect(find.text('Scam Image Detection'), findsOneWidget);

    // รอให้ Timer ในหน้า Splash ทำงานเสร็จสิ้นโดยไม่อิงการเปลี่ยนหน้าต่อเนื่อง
    await tester.pump(const Duration(seconds: 3));
  });
}
