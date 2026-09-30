import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/widgets/adaptive_content.dart';

void main() {
  testWidgets('caps content width on expanded windows', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdaptiveContent(
            maxWidth: 720,
            child: ColoredBox(
              key: Key('content'),
              color: Colors.black,
              child: SizedBox(height: 100),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('content'))).width, 720);
  });

  testWidgets('fills compact windows without horizontal overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdaptiveContent(
            maxWidth: 720,
            child: ColoredBox(
              key: Key('content'),
              color: Colors.black,
              child: SizedBox(height: 100),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('content'))).width, 390);
    expect(tester.takeException(), isNull);
  });
}
