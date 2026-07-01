import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scam_image_mobile/core/constants/app_colors.dart';
import 'package:scam_image_mobile/core/widgets/risk_badge.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildBadge(RiskLevel level) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(child: RiskBadge(riskLevel: level)),
      ),
    );
  }

  group('RiskBadge', () {
    testWidgets('low — shows "ต่ำ" with success green background',
        (tester) async {
      await tester.pumpWidget(buildBadge(RiskLevel.low));
      await tester.pump();

      // Text is correct
      expect(find.text('ต่ำ'), findsOneWidget);

      // Background color is AppColors.success
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.success));
    });

    testWidgets('medium — shows "ปานกลาง" with warning amber background',
        (tester) async {
      await tester.pumpWidget(buildBadge(RiskLevel.medium));
      await tester.pump();

      expect(find.text('ปานกลาง'), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.warning));
    });

    testWidgets('high — shows "สูง" with danger red background',
        (tester) async {
      await tester.pumpWidget(buildBadge(RiskLevel.high));
      await tester.pump();

      expect(find.text('สูง'), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.danger));
    });

    testWidgets('safe — shows "ปลอดภัย" with success green background',
        (tester) async {
      await tester.pumpWidget(buildBadge(RiskLevel.safe));
      await tester.pump();

      expect(find.text('ปลอดภัย'), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.success));
    });

    group('levelFromString', () {
      test('maps "low" to RiskLevel.low', () {
        expect(RiskBadge.levelFromString('low'), RiskLevel.low);
      });

      test('maps "medium" to RiskLevel.medium', () {
        expect(RiskBadge.levelFromString('medium'), RiskLevel.medium);
      });

      test('maps "high" to RiskLevel.high', () {
        expect(RiskBadge.levelFromString('high'), RiskLevel.high);
      });

      test('maps "safe" to RiskLevel.safe', () {
        expect(RiskBadge.levelFromString('safe'), RiskLevel.safe);
      });

      test('maps unknown string to RiskLevel.low (default)', () {
        expect(RiskBadge.levelFromString('unknown'), RiskLevel.low);
      });
    });
  });
}
