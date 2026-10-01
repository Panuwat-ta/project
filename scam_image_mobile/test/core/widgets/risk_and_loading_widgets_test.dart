import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';
import 'package:scam_image_mobile/core/widgets/loading_overlay.dart';
import 'package:scam_image_mobile/core/widgets/risk_progress_bar.dart';

void main() {
  group('RiskProgressBar', () {
    testWidgets('uses the expected risk color at each score boundary', (
      tester,
    ) async {
      for (final (score, color) in [
        (0, AppColors.success),
        (39, AppColors.success),
        (40, AppColors.warning),
        (69, AppColors.warning),
        (70, AppColors.danger),
        (100, AppColors.danger),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RiskProgressBar(score: score)),
          ),
        );

        final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.value, score / 100.0, reason: 'score $score');
        expect(bar.valueColor?.value, color, reason: 'score $score');
        expect(find.text('$score%'), findsOneWidget);
      }
    });

    testWidgets('hides the percentage label when requested', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RiskProgressBar(score: 45, showLabel: false)),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('45%'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('LoadingOverlay', () {
    testWidgets(
      'full-screen overlay shows message and uses light-theme color',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(body: LoadingOverlay(message: 'กำลังตรวจสอบ')),
          ),
        );

        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.byType(CircularProgressIndicator),
                matching: find.byType(Container),
              )
              .first,
        );
        final spinner = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(container.color, AppColors.bgDark.withValues(alpha: 0.7));
        expect(spinner.valueColor?.value, AppColors.primary);
        expect(find.text('กำลังตรวจสอบ'), findsOneWidget);
      },
    );

    testWidgets(
      'contained overlay omits full-screen scrim and optional message',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(body: LoadingOverlay(isFullScreen: false)),
          ),
        );

        final spinner = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(spinner.valueColor?.value, AppColors.primaryFixedDim);
        expect(find.text(''), findsNothing);
        expect(
          find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(Container),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
