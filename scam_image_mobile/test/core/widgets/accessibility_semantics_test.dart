import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scam_image_mobile/core/widgets/analysis_step_tile.dart';
import 'package:scam_image_mobile/core/widgets/risk_badge.dart';
import 'package:scam_image_mobile/core/widgets/risk_gauge.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('risk badge exposes a meaningful semantics label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RiskBadge(riskLevel: RiskLevel.high)),
      ),
    );
    final finder = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'ความเสี่ยงสูง',
    );
    expect(finder, findsOneWidget);
  });

  testWidgets('analysis step exposes title and status to TalkBack', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnalysisStepTile(
            status: AnalysisStepStatus.active,
            title: 'วิเคราะห์ภาพ',
            subtitle: 'กำลังประมวลผล',
          ),
        ),
      ),
    );
    final finder = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'วิเคราะห์ภาพ, กำลังประมวลผล' &&
          widget.properties.liveRegion == true,
    );
    expect(finder, findsOneWidget);
  });

  testWidgets('risk gauge exposes score value to TalkBack', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RiskGauge(score: 72))),
    );
    final finder = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.value == '72/100',
    );
    expect(finder, findsOneWidget);
  });
}
