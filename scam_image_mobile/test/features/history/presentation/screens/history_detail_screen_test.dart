import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scam_image_mobile/core/di/injection_container.dart';
import 'package:scam_image_mobile/features/history/presentation/screens/history_detail_screen.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';
import 'package:scam_image_mobile/features/result/domain/entities/risk_factor.dart';
import 'package:scam_image_mobile/features/result/domain/repositories/result_repository.dart';

class MockResultRepository extends Mock implements ResultRepository {}

AnalysisResult buildResult({
  RiskLevel level = RiskLevel.high,
  int score = 88,
  String summary = 'สรุปผล',
  String? ocrText = 'ข้อความ OCR',
  String? xaiExplanation = 'คำอธิบาย XAI',
  double? manipulationConfidence = 0.82,
  List<RiskFactor> factors = const [
    RiskFactor(
      type: 'textual',
      score: 70,
      title: 'textual',
      details: ['โอนด่วน', 'รับรางวัล'],
    ),
    RiskFactor(
      type: 'source',
      score: 55,
      title: 'source',
      details: ['source-a'],
    ),
    RiskFactor(
      type: 'visual',
      score: 85,
      title: 'visual',
      details: ['visual-detail'],
    ),
  ],
}) => AnalysisResult(
  scanId: 'scan-1',
  taskId: 'scan-1',
  status: 'completed',
  riskScore: score,
  riskLevel: level,
  summary: summary,
  xaiExplanation: xaiExplanation,
  manipulationConfidence: manipulationConfidence,
  ocrText: ocrText,
  createdAt: DateTime.utc(2026, 9, 20),
  factors: factors,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<GoRouter> pumpDetail(
    WidgetTester tester, {
    AnalysisResult? result,
    Object? error,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final repository = MockResultRepository();
    ServiceLocator.resultRepository = repository;
    if (error != null) {
      when(() => repository.getAnalysisResult('scan-1')).thenThrow(error);
    } else {
      when(
        () => repository.getAnalysisResult('scan-1'),
      ).thenAnswer((_) async => result ?? buildResult());
    }

    final router = GoRouter(
      initialLocation: '/history/scan-1',
      routes: [
        GoRoute(
          path: '/history/:id',
          builder: (_, state) =>
              HistoryDetailScreen(scanId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/heatmap/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Heatmap ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/report-scam',
          builder: (_, _) => const Scaffold(body: Text('Report route')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(router.dispose);
    return router;
  }

  testWidgets('renders complete multi-layer evidence without fabrication', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(find.text('88%'), findsWidgets);
    expect(find.text('ข้อความ OCR'), findsOneWidget);
    expect(find.text('โอนด่วน'), findsWidgets);
    expect(find.text('source-a'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
    expect(find.text('คำอธิบาย XAI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing factors render explicit unavailable states', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      result: buildResult(
        level: RiskLevel.unknown,
        score: 0,
        summary: '',
        ocrText: null,
        xaiExplanation: null,
        manipulationConfidence: null,
        factors: const [],
      ),
    );

    expect(find.text('ไม่มีข้อมูลข้อความจากการวิเคราะห์'), findsOneWidget);
    expect(find.text('ไม่มีข้อมูลจากการวิเคราะห์ชั้นนี้'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'text details backfill OCR while source score-only stays honest',
    (tester) async {
      await pumpDetail(
        tester,
        result: buildResult(
          level: RiskLevel.medium,
          score: 55,
          ocrText: null,
          manipulationConfidence: 0.5,
          factors: const [
            RiskFactor(
              type: 'textual',
              score: 45,
              title: 'textual',
              details: ['keyword-only'],
            ),
            RiskFactor(type: 'source', score: 40, title: 'source', details: []),
            RiskFactor(type: 'visual', score: 45, title: 'visual', details: []),
          ],
        ),
      );

      expect(find.text('keyword-only'), findsWidgets);
      expect(find.text('50%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('low risk and dark mode render without layout exceptions', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      themeMode: ThemeMode.dark,
      result: buildResult(
        level: RiskLevel.low,
        score: 20,
        manipulationConfidence: 0.1,
        factors: const [
          RiskFactor(type: 'textual', score: 0, title: 'textual', details: []),
          RiskFactor(type: 'source', score: 0, title: 'source', details: []),
          RiskFactor(type: 'visual', score: 10, title: 'visual', details: []),
        ],
      ),
    );

    expect(find.text('20%'), findsWidgets);
    expect(find.text('10%'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long source evidence fits within compact mobile width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDetail(
      tester,
      themeMode: ThemeMode.dark,
      result: buildResult(
        factors: [
          const RiskFactor(
            type: 'textual',
            score: 70,
            title: 'textual',
            details: ['โอนด่วน', 'รับรางวัล'],
          ),
          RiskFactor(
            type: 'source',
            score: 55,
            title: 'source',
            details: [List.filled(64, 'Long source evidence record').join(' ')],
          ),
          const RiskFactor(
            type: 'visual',
            score: 85,
            title: 'visual',
            details: ['visual-detail'],
          ),
        ],
      ),
    );

    final layoutErrors = <Object>[];
    Object? layoutError;
    while ((layoutError = tester.takeException()) != null) {
      layoutErrors.add(layoutError!);
    }
    expect(
      layoutErrors,
      isEmpty,
      reason: layoutErrors.map(_describeError).join('\n'),
    );
  });

  testWidgets('missing evidence labels fit within compact mobile width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDetail(tester, result: buildResult(factors: const []));

    final layoutErrors = <Object>[];
    Object? layoutError;
    while ((layoutError = tester.takeException()) != null) {
      layoutErrors.add(layoutError!);
    }
    expect(
      layoutErrors,
      isEmpty,
      reason: layoutErrors.map(_describeError).join('\n'),
    );
  });

  testWidgets('History Detail fits in landscape dark mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDetail(
      tester,
      themeMode: ThemeMode.dark,
      result: buildResult(
        factors: [
          const RiskFactor(
            type: 'textual',
            score: 70,
            title: 'textual',
            details: ['โอนด่วน'],
          ),
          RiskFactor(
            type: 'source',
            score: 55,
            title: 'source',
            details: [
              'source.example.org/evidence/${List.filled(80, 'long-record').join('/')}?reference=case-12345',
            ],
          ),
          const RiskFactor(
            type: 'visual',
            score: 85,
            title: 'visual',
            details: ['visual-detail'],
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('repository error renders ResultError message', (tester) async {
    await pumpDetail(tester, error: StateError('detail failed'));

    expect(find.textContaining('detail failed'), findsOneWidget);
  });
}

String _describeError(Object error) => error is FlutterError
    ? error.diagnostics.map((diagnostic) => diagnostic.toString()).join('\n')
    : error.toString();
