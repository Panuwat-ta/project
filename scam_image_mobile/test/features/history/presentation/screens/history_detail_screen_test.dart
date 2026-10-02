import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scam_image_mobile/core/di/injection_container.dart';
import 'package:scam_image_mobile/features/history/domain/repositories/history_repository.dart';
import 'package:scam_image_mobile/features/history/presentation/bloc/history_bloc.dart';
import 'package:scam_image_mobile/features/history/presentation/screens/history_detail_screen.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';
import 'package:scam_image_mobile/features/result/domain/entities/risk_factor.dart';
import 'package:scam_image_mobile/features/result/domain/repositories/result_repository.dart';

class MockResultRepository extends Mock implements ResultRepository {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

AnalysisResult buildResult({
  RiskLevel level = RiskLevel.high,
  int score = 88,
  String summary = 'สรุปผล',
  String? ocrText = 'ข้อความ OCR',
  String? xaiExplanation = 'คำอธิบาย XAI',
  double? manipulationConfidence = 0.82,
  String? imageUrl,
  String? heatmapUrl,
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
  imageUrl: imageUrl,
  heatmapUrl: heatmapUrl,
  factors: factors,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
  });

  Future<GoRouter> pumpDetail(
    WidgetTester tester, {
    AnalysisResult? result,
    Object? error,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final repository = MockResultRepository();
    final historyRepository = MockHistoryRepository();
    when(
      () => historyRepository.deleteScanHistoryItem(any()),
    ).thenAnswer((_) async {});
    final historyBloc = HistoryBloc(repository: historyRepository);
    ServiceLocator.historyRepository = historyRepository;
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
        GoRoute(
          path: '/main/report',
          builder: (_, state) =>
              Scaffold(body: Text('Report data ${state.extra}')),
        ),
        GoRoute(
          path: '/main/home',
          builder: (_, _) => const Scaffold(body: Text('Home route')),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<HistoryBloc>.value(
        value: historyBloc,
        child: MaterialApp.router(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(router.dispose);
    addTearDown(historyBloc.close);
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
    expect(find.text('คะแนนความเสี่ยงข้อความ'), findsOneWidget);
    expect(find.text('วันที่วิเคราะห์'), findsOneWidget);
    expect(find.text('รายละเอียดการตรวจสอบแหล่งที่มา'), findsOneWidget);
    expect(find.text('20 Sep 2026'), findsOneWidget);
    expect(find.text('HEATMAP'), findsNothing);
    expect(find.text('ไม่มีภาพตัวอย่าง'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history preview distinguishes source image from heatmap', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      result: buildResult(imageUrl: 'https://example.com/source.png'),
    );
    expect(find.text('ภาพต้นฉบับ'), findsOneWidget);
    expect(find.text('HEATMAP'), findsNothing);
    expect(find.text('ไม่มีภาพตัวอย่าง'), findsNothing);

    await pumpDetail(
      tester,
      result: buildResult(
        imageUrl: 'https://example.com/source.png',
        heatmapUrl: 'https://example.com/heatmap.png',
      ),
    );
    expect(find.text('HEATMAP'), findsOneWidget);
    expect(find.text('ภาพต้นฉบับ'), findsNothing);
  });

  testWidgets('report action passes the current scan id to report route', (
    tester,
  ) async {
    final router = await pumpDetail(tester);
    await tester.ensureVisible(find.byIcon(Icons.flag_outlined));
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/main/report');
    expect(find.textContaining('scanId: scan-1'), findsOneWidget);
  });

  testWidgets('heatmap action opens the heatmap for this scan', (tester) async {
    await pumpDetail(tester);
    await tester.ensureVisible(find.text('ดู Heatmap'));
    await tester.tap(find.text('ดู Heatmap'));
    await tester.pumpAndSettle();

    expect(find.text('Heatmap scan-1'), findsOneWidget);
  });

  testWidgets('share action sends the localized result summary', (
    tester,
  ) async {
    MethodCall? shareCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (call) async {
          shareCall = call;
          return 'success';
        });
    await pumpDetail(tester);

    await tester.ensureVisible(find.byIcon(Icons.share_outlined).first);
    await tester.tap(find.byIcon(Icons.share_outlined).first);
    await tester.pump();

    expect(shareCall?.method, 'share');
    expect(
      shareCall?.arguments,
      containsPair('text', 'ผลการตรวจสอบรูปภาพจาก ScamGuard'),
    );
  });

  testWidgets('canceling detail deletion keeps the scan visible', (
    tester,
  ) async {
    await pumpDetail(tester);

    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('ยืนยันการลบ'), findsOneWidget);

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(find.text('ยืนยันการลบ'), findsNothing);
    expect(find.text('88%'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirming detail deletion returns home after server success', (
    tester,
  ) async {
    final router = await pumpDetail(tester);

    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();

    expect(find.text('Home route'), findsOneWidget);
    verify(
      () => (ServiceLocator.historyRepository as MockHistoryRepository)
          .deleteScanHistoryItem('scan-1'),
    ).called(1);
    expect(router.routeInformationProvider.value.uri.path, '/main/home');
  });

  testWidgets('delete failure keeps detail open and shows feedback', (
    tester,
  ) async {
    await pumpDetail(tester);
    final repository =
        ServiceLocator.historyRepository as MockHistoryRepository;
    when(
      () => repository.deleteScanHistoryItem('scan-1'),
    ).thenThrow(Exception('delete unavailable'));

    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();

    expect(find.text('ลบประวัติไม่สำเร็จ กรุณาลองอีกครั้ง'), findsOneWidget);
    expect(find.text('88%'), findsWidgets);
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

  testWidgets('visual risk does not color a different confidence metric', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      result: buildResult(
        manipulationConfidence: 0.1,
        factors: const [
          RiskFactor(type: 'visual', score: 85, title: 'visual', details: []),
        ],
      ),
    );
    final confidence = tester.widget<Text>(find.text('10%'));
    expect(confidence.style?.color, ThemeData.light().colorScheme.onSurface);
    expect(find.text('ความมั่นใจว่าถูกดัดแปลง'), findsOneWidget);
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
