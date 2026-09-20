import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scam_image_mobile/core/widgets/analysis_step_tile.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('active analysis step settles when system disables animations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AnalysisStepTile(
              status: AnalysisStepStatus.active,
              title: 'วิเคราะห์ภาพ',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('วิเคราะห์ภาพ'), findsOneWidget);
  });
}
