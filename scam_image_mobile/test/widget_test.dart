// Basic smoke test — verifies the ScamGuardApp widget tree can be built and
// that the router renders the initial splash route without errors.

import 'package:flutter_test/flutter_test.dart';

import 'package:scam_image_mobile/main.dart';

void main() {
  testWidgets('App smoke test — renders without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScamGuardApp());
    // The router shows the splash placeholder on startup.
    expect(find.text('Splash Screen'), findsOneWidget);
  });
}
