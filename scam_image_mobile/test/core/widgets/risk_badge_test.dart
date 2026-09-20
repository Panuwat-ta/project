import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scam_image_mobile/core/theme/app_colors.dart';
import 'package:scam_image_mobile/core/widgets/risk_badge.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

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
    testWidgets(
      'low — shows localized low-risk label with success green background',
      (tester) async {
        await tester.pumpWidget(buildBadge(RiskLevel.low));
        await tester.pump();

        // Text is correct
        expect(find.text('ความเสี่ยงต่ำ'), findsOneWidget);

        // Background color is AppColors.success
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          equals(AppColors.success.withValues(alpha: 0.15)),
        );
      },
    );

    testWidgets(
      'medium — shows localized medium-risk label with warning amber background',
      (tester) async {
        await tester.pumpWidget(buildBadge(RiskLevel.medium));
        await tester.pump();

        expect(find.text('ความเสี่ยงปานกลาง'), findsOneWidget);

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          equals(AppColors.warning.withValues(alpha: 0.15)),
        );
      },
    );

    testWidgets('high — shows "สูง" with danger red background', (
      tester,
    ) async {
      await tester.pumpWidget(buildBadge(RiskLevel.high));
      await tester.pump();

      expect(find.text('ความเสี่ยงสูง'), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.color,
        equals(AppColors.danger.withValues(alpha: 0.15)),
      );
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

      test('maps "safe" to RiskLevel.unknown (no Safe level)', () {
        expect(RiskBadge.levelFromString('safe'), RiskLevel.unknown);
      });

      test('maps unknown string to RiskLevel.unknown (never Low)', () {
        expect(RiskBadge.levelFromString('unknown'), RiskLevel.unknown);
      });
    });

    testWidgets('unknown — uses readable neutral foreground in dark mode', (
      tester,
    ) async {
      await tester.pumpWidget(buildBadge(RiskLevel.unknown));
      await tester.pump();

      final text = tester.widget<Text>(find.text('ยังประเมินไม่ได้'));
      expect(text.style?.color, AppColors.outlineVariant);
    });
  });
}
