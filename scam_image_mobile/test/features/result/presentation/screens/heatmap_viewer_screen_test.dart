import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:scam_image_mobile/features/result/presentation/screens/heatmap_viewer_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'missing heatmap shows unavailable state without simulated anomaly gradient',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const HeatmapViewerScreen(taskId: 'scan-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ไม่มีข้อมูล Heatmap'), findsOneWidget);
      expect(find.byType(Slider), findsNothing);

      final hasRadialGradient = tester
          .widgetList<Container>(find.byType(Container))
          .any((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.gradient is RadialGradient;
          });
      expect(hasRadialGradient, isFalse);
    },
  );
  testWidgets('heatmap toggle really hides and restores the overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const HeatmapViewerScreen(
          taskId: 'scan-2',
          imageUrl: 'https://example.invalid/original.jpg',
          heatmapUrl: 'https://example.invalid/heatmap.jpg',
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('heatmap-overlay')), findsOneWidget);
    expect(find.text('ซ่อน Heatmap'), findsOneWidget);

    await tester.tap(find.byKey(const Key('heatmap-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('heatmap-overlay')), findsNothing);
    expect(find.text('แสดง Heatmap'), findsOneWidget);

    await tester.tap(find.byKey(const Key('heatmap-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('heatmap-overlay')), findsOneWidget);
  });

  testWidgets('heatmap intensity and zoom controls update the viewer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const HeatmapViewerScreen(
          taskId: 'scan-controls',
          imageUrl: 'https://example.invalid/original.jpg',
          heatmapUrl: 'https://example.invalid/heatmap.jpg',
        ),
      ),
    );
    await tester.pump();

    InteractiveViewer viewer = tester.widget(find.byType(InteractiveViewer));
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1.0);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    viewer = tester.widget(find.byType(InteractiveViewer));
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1.2);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    viewer = tester.widget(find.byType(InteractiveViewer));
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1.0);

    final slider = tester.widget<Slider>(find.byType(Slider));
    await tester.drag(find.byType(Slider), const Offset(-100, 0));
    await tester.pump();
    final updatedSlider = tester.widget<Slider>(find.byType(Slider));
    expect(updatedSlider.value, lessThan(slider.value));
    expect(
      find.text('${(updatedSlider.value * 100).round()}%'),
      findsOneWidget,
    );
  });
}
