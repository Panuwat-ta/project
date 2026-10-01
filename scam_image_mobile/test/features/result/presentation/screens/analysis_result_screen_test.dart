import 'package:bloc_test/bloc_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';
import 'package:scam_image_mobile/features/result/domain/entities/risk_factor.dart';
import 'package:scam_image_mobile/features/result/domain/repositories/result_repository.dart';
import 'package:scam_image_mobile/features/result/presentation/bloc/result_bloc.dart';
import 'package:scam_image_mobile/features/result/presentation/screens/analysis_result_screen.dart';
import 'package:scam_image_mobile/features/history/domain/repositories/history_repository.dart';
import 'package:scam_image_mobile/features/history/presentation/bloc/history_bloc.dart';

class _MockResultRepository extends Mock implements ResultRepository {}

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockResultBloc extends MockBloc<ResultEvent, ResultState>
    implements ResultBloc {}

const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('result image preview has no faux non-interactive slider', (
    tester,
  ) async {
    final repository = _MockResultRepository();
    final result = AnalysisResult(
      scanId: 'scan-1',
      taskId: 'task-1',
      status: 'completed',
      riskScore: 85,
      riskLevel: RiskLevel.high,
      summary: 'พบความเสี่ยง',
      createdAt: DateTime(2026, 9, 20),
      factors: const [
        RiskFactor(type: 'visual', score: 85, title: 'visual', details: []),
      ],
    );
    when(
      () => repository.getAnalysisResult(any()),
    ).thenAnswer((_) async => result);
    final bloc = ResultBloc(repository: repository);
    final router = GoRouter(
      initialLocation: '/result/task-1',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(FractionallySizedBox), findsNothing);
    expect(find.text('Safe'), findsNothing);
    expect(find.text('ไม่มีรายละเอียดภาพเพิ่มเติมจากระบบ'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(find.text('85/100'), findsWidgets);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('หลักฐานจากการวิเคราะห์'), findsOneWidget);
    expect(find.text('ร่องรอยในภาพ'), findsOneWidget);
    expect(find.text('ข้อความในภาพ'), findsOneWidget);
    expect(find.text('ข้อมูลแหล่งที่มา'), findsOneWidget);
    expect(find.text('ไม่มีข้อมูลจากการวิเคราะห์ชั้นนี้'), findsNWidgets(2));

    bloc.close();
  });

  testWidgets('processing result shows pending XAI explanation state', (
    tester,
  ) async {
    final result = AnalysisResult(
      scanId: 'scan-pending',
      taskId: 'task-pending',
      status: 'processing_visual',
      riskScore: 42,
      riskLevel: RiskLevel.medium,
      summary: '',
      createdAt: DateTime(2026, 9, 20),
      factors: const [],
    );
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(ResultLoaded(result));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-pending',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(
      find.text(
        'กำลังสร้างคำอธิบายจาก AI กรุณารอสักครู่ ระบบจะแสดงข้อความเมื่อสร้างเสร็จ',
      ),
      findsOneWidget,
    );
    expect(find.text('42/100'), findsWidgets);
  });

  testWidgets('completed result with empty summary shows unavailable state', (
    tester,
  ) async {
    final result = AnalysisResult(
      scanId: 'scan-no-summary',
      taskId: 'task-no-summary',
      status: 'completed',
      riskScore: 18,
      riskLevel: RiskLevel.low,
      summary: '',
      createdAt: DateTime(2026, 9, 20),
      factors: const [],
    );
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(ResultLoaded(result));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-no-summary',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(
      find.text('ยังไม่มีคำอธิบายสรุปจากระบบสำหรับรายการนี้'),
      findsOneWidget,
    );
    expect(find.text('18/100'), findsWidgets);
    expect(find.text('0%'), findsNothing);
    expect(find.text('ไม่มีข้อมูลจากการวิเคราะห์ชั้นนี้'), findsWidgets);
  });

  testWidgets('preview label reflects heatmap and source image availability', (
    tester,
  ) async {
    Future<void> pumpResult(AnalysisResult result) async {
      final bloc = _MockResultBloc();
      when(() => bloc.state).thenReturn(ResultLoaded(result));
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      final router = GoRouter(
        initialLocation: '/result/${result.taskId}',
        routes: [
          GoRoute(
            path: '/result/:id',
            builder: (_, state) => BlocProvider<ResultBloc>.value(
              value: bloc,
              child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      router.dispose();
    }

    AnalysisResult buildPreviewResult({String? imageUrl, String? heatmapUrl}) =>
        AnalysisResult(
          scanId: 'scan-preview',
          taskId: 'task-preview',
          status: 'completed',
          riskScore: 20,
          riskLevel: RiskLevel.low,
          summary: '',
          createdAt: DateTime(2026, 9, 20),
          imageUrl: imageUrl,
          heatmapUrl: heatmapUrl,
          factors: const [],
        );

    await pumpResult(
      buildPreviewResult(heatmapUrl: 'https://example.com/heatmap.png'),
    );
    expect(find.text('HEATMAP'), findsOneWidget);
    expect(find.text('ภาพต้นฉบับ'), findsNothing);
    expect(find.text('ไม่มีภาพตัวอย่าง'), findsNothing);

    await pumpResult(
      buildPreviewResult(imageUrl: 'https://example.com/source.png'),
    );
    expect(find.text('HEATMAP'), findsNothing);
    expect(find.text('ภาพต้นฉบับ'), findsOneWidget);
    expect(find.text('ไม่มีภาพตัวอย่าง'), findsNothing);

    await pumpResult(buildPreviewResult());
    expect(find.text('HEATMAP'), findsNothing);
    expect(find.text('ภาพต้นฉบับ'), findsNothing);
    expect(find.text('ไม่มีภาพตัวอย่าง'), findsOneWidget);
  });

  testWidgets('visual details render as evidence alerts', (tester) async {
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(
      ResultLoaded(
        AnalysisResult(
          scanId: 'scan-visual-details',
          taskId: 'task-visual-details',
          status: 'completed',
          riskScore: 84,
          riskLevel: RiskLevel.high,
          summary: 'ตรวจพบจุดที่ควรพิจารณา',
          manipulationConfidence: 0.82,
          createdAt: DateTime(2026, 9, 20),
          factors: const [
            RiskFactor(
              type: 'visual',
              score: 84,
              title: 'visual',
              details: ['ขอบภาพไม่สม่ำเสมอ', 'พบการแก้ไขบริเวณข้อความ'],
            ),
          ],
        ),
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-visual-details',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('ขอบภาพไม่สม่ำเสมอ'), findsWidgets);
    expect(find.text('พบการแก้ไขบริเวณข้อความ'), findsOneWidget);
    expect(find.text('ความมั่นใจว่าถูกดัดแปลง: 82%'), findsOneWidget);
    expect(find.text('ไม่มีรายละเอียดภาพเพิ่มเติมจากระบบ'), findsNothing);
  });

  testWidgets('result loading failure displays the repository message', (
    tester,
  ) async {
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(const ResultError('โหลดผลตรวจไม่สำเร็จ'));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-error',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.text('โหลดผลตรวจไม่สำเร็จ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report action passes scan id to the report route', (
    tester,
  ) async {
    final result = AnalysisResult(
      scanId: 'scan-report-1',
      taskId: 'task-report-1',
      status: 'completed',
      riskScore: 74,
      riskLevel: RiskLevel.high,
      summary: 'พบความเสี่ยง',
      createdAt: DateTime(2026, 9, 20),
      imageUrl: 'https://example.com/report-image.png',
      factors: const [],
    );
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(ResultLoaded(result));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-report-1',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/main/report',
          builder: (_, state) => Scaffold(body: Text('${state.extra}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.ensureVisible(find.text('แจ้งรายงาน'));
    await tester.tap(find.text('แจ้งรายงาน'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/main/report');
    expect(find.textContaining('scan-report-1'), findsOneWidget);
    expect(
      find.textContaining('https://example.com/report-image.png'),
      findsOneWidget,
    );
  });

  testWidgets('detail action opens the current task detail route', (
    tester,
  ) async {
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(
      ResultLoaded(
        AnalysisResult(
          scanId: 'scan-detail-1',
          taskId: 'task-detail-1',
          status: 'completed',
          riskScore: 74,
          riskLevel: RiskLevel.high,
          summary: 'พบความเสี่ยง',
          createdAt: DateTime(2026, 9, 20),
          factors: const [],
        ),
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-detail-1',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/detail/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Detail ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.ensureVisible(find.text('รายละเอียด'));
    await tester.tap(find.text('รายละเอียด'));
    await tester.pumpAndSettle();

    expect(find.text('Detail task-detail-1'), findsOneWidget);
  });

  testWidgets('canceling result deletion keeps the result visible', (
    tester,
  ) async {
    final result = AnalysisResult(
      scanId: 'scan-delete-cancel',
      taskId: 'task-delete-cancel',
      status: 'completed',
      riskScore: 74,
      riskLevel: RiskLevel.high,
      summary: 'พบความเสี่ยง',
      createdAt: DateTime(2026, 9, 20),
      factors: const [],
    );
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(ResultLoaded(result));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-delete-cancel',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(find.text('ยืนยันการลบ'), findsNothing);
    expect(find.text('74/100'), findsWidgets);
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
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_shareChannel, null),
    );
    final result = AnalysisResult(
      scanId: 'scan-share',
      taskId: 'task-share',
      status: 'completed',
      riskScore: 72,
      riskLevel: RiskLevel.high,
      summary: 'พบความเสี่ยง',
      createdAt: DateTime(2026, 9, 20),
      factors: const [],
    );
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(ResultLoaded(result));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-share',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.ensureVisible(find.byIcon(Icons.share_outlined));
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pump();

    expect(shareCall?.method, 'share');
    expect(
      shareCall?.arguments,
      containsPair('text', 'ผลการตรวจสอบรูปภาพจาก ScamGuard'),
    );
  });

  testWidgets(
    'tapping result evidence opens heatmap with available image URLs',
    (tester) async {
      const imageUrl = 'https://example.com/scan.png';
      const heatmapUrl = 'https://example.com/heatmap.png';
      final result = AnalysisResult(
        scanId: 'scan-heatmap',
        taskId: 'task-heatmap',
        status: 'completed',
        riskScore: 72,
        riskLevel: RiskLevel.high,
        summary: 'พบความเสี่ยง',
        createdAt: DateTime(2026, 9, 20),
        imageUrl: imageUrl,
        heatmapUrl: heatmapUrl,
        factors: const [],
      );
      final bloc = _MockResultBloc();
      when(() => bloc.state).thenReturn(ResultLoaded(result));
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      final router = GoRouter(
        initialLocation: '/result/task-heatmap',
        routes: [
          GoRoute(
            path: '/result/:id',
            builder: (_, state) => BlocProvider<ResultBloc>.value(
              value: bloc,
              child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/heatmap/:id',
            builder: (_, state) => Scaffold(
              body: Text(
                'Heatmap ${state.pathParameters['id']} '
                '${(state.extra! as Map<String, dynamic>)['imageUrl']} '
                '${(state.extra! as Map<String, dynamic>)['heatmapUrl']}',
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      final evidenceImage = find.byType(CachedNetworkImage);
      await tester.ensureVisible(evidenceImage);
      await tester.tap(
        find
            .ancestor(of: evidenceImage, matching: find.byType(GestureDetector))
            .first,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Heatmap task-heatmap $imageUrl $heatmapUrl'),
        findsOneWidget,
      );
    },
  );

  testWidgets('named result can return to the previous route', (tester) async {
    final result = AnalysisResult(
      scanId: 'scan-back',
      taskId: 'task-back',
      status: 'completed',
      riskScore: 48,
      riskLevel: RiskLevel.medium,
      summary: 'ผลตรวจ',
      createdAt: DateTime(2026, 9, 20),
      factors: const [],
    );
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(ResultLoaded(result));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/result/task-back'),
              child: const Text('Open result'),
            ),
          ),
        ),
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(
              taskId: state.pathParameters['id']!,
              scanName: 'Named scan',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Open result'));
    await tester.pumpAndSettle();
    expect(find.text('Named scan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Open result'), findsOneWidget);
  });

  testWidgets('notification action opens notifications from result', (
    tester,
  ) async {
    final result = AnalysisResult(
      scanId: 'scan-notify',
      taskId: 'task-notify',
      status: 'completed',
      riskScore: 48,
      riskLevel: RiskLevel.medium,
      summary: 'ผลตรวจ',
      createdAt: DateTime(2026, 9, 20),
      factors: const [],
    );
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(ResultLoaded(result));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-notify',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const Scaffold(body: Text('Notifications route')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();

    expect(find.text('Notifications route'), findsOneWidget);
  });

  testWidgets('check-another and root back actions return to home', (
    tester,
  ) async {
    final result = AnalysisResult(
      scanId: 'scan-home-actions',
      taskId: 'task-home-actions',
      status: 'completed',
      riskScore: 48,
      riskLevel: RiskLevel.medium,
      summary: 'ผลตรวจ',
      createdAt: DateTime(2026, 9, 20),
      factors: const [],
    );
    final bloc = _MockResultBloc();
    when(() => bloc.state).thenReturn(ResultLoaded(result));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    final router = GoRouter(
      initialLocation: '/result/task-home-actions',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: bloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/main/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/result/task-home-actions'),
              child: const Text('Home route'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.ensureVisible(find.text('ตรวจสอบรูปภาพอื่น'));
    await tester.tap(find.text('ตรวจสอบรูปภาพอื่น'));
    await tester.pumpAndSettle();
    expect(find.text('Home route'), findsOneWidget);

    await tester.tap(find.text('Home route'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home route'), findsOneWidget);
  });

  testWidgets('confirming result deletion returns home after server success', (
    tester,
  ) async {
    const scanId = 'scan-delete-success';
    final resultBloc = _MockResultBloc();
    when(() => resultBloc.state).thenReturn(
      ResultLoaded(
        AnalysisResult(
          scanId: scanId,
          taskId: scanId,
          status: 'completed',
          riskScore: 74,
          riskLevel: RiskLevel.high,
          summary: 'พบความเสี่ยง',
          createdAt: DateTime(2026, 9, 20),
          factors: const [],
        ),
      ),
    );
    when(() => resultBloc.stream).thenAnswer((_) => const Stream.empty());
    final historyRepository = _MockHistoryRepository();
    when(
      () => historyRepository.deleteScanHistoryItem(scanId),
    ).thenAnswer((_) async {});
    final historyBloc = HistoryBloc(repository: historyRepository);
    final router = GoRouter(
      initialLocation: '/result/$scanId',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: resultBloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/main/home',
          builder: (_, _) => const Scaffold(body: Text('Home route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(historyBloc.close);

    await tester.pumpWidget(
      BlocProvider<HistoryBloc>.value(
        value: historyBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();

    expect(find.text('Home route'), findsOneWidget);
    verify(() => historyRepository.deleteScanHistoryItem(scanId)).called(1);
  });

  testWidgets('delete failure keeps result open and shows feedback', (
    tester,
  ) async {
    const scanId = 'scan-delete-failure';
    final resultBloc = _MockResultBloc();
    when(() => resultBloc.state).thenReturn(
      ResultLoaded(
        AnalysisResult(
          scanId: scanId,
          taskId: scanId,
          status: 'completed',
          riskScore: 74,
          riskLevel: RiskLevel.high,
          summary: 'พบความเสี่ยง',
          createdAt: DateTime(2026, 9, 20),
          factors: const [],
        ),
      ),
    );
    when(() => resultBloc.stream).thenAnswer((_) => const Stream.empty());
    final historyRepository = _MockHistoryRepository();
    when(
      () => historyRepository.deleteScanHistoryItem(scanId),
    ).thenThrow(Exception('delete unavailable'));
    final historyBloc = HistoryBloc(repository: historyRepository);
    final router = GoRouter(
      initialLocation: '/result/$scanId',
      routes: [
        GoRoute(
          path: '/result/:id',
          builder: (_, state) => BlocProvider<ResultBloc>.value(
            value: resultBloc,
            child: AnalysisResultScreen(taskId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/main/home',
          builder: (_, _) => const Scaffold(body: Text('Home route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(historyBloc.close);

    await tester.pumpWidget(
      BlocProvider<HistoryBloc>.value(
        value: historyBloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();

    expect(find.text('ลบประวัติไม่สำเร็จ กรุณาลองอีกครั้ง'), findsOneWidget);
    expect(find.text('74/100'), findsWidgets);
  });
}
