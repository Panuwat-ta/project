import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/di/injection_container.dart';
import 'package:scam_image_mobile/features/history/domain/entities/scan_history_item.dart';
import 'package:scam_image_mobile/features/history/domain/repositories/history_repository.dart';
import 'package:scam_image_mobile/features/history/presentation/bloc/history_bloc.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';
import 'package:scam_image_mobile/features/report/domain/entities/scam_report.dart';
import 'package:scam_image_mobile/features/report/domain/repositories/report_repository.dart';
import 'package:scam_image_mobile/features/report/presentation/screens/report_scam_screen.dart';

class MockReportRepository extends Mock implements ReportRepository {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

class FakeScamReport extends Fake implements ScamReport {}

void main() {
  late MockReportRepository repo;
  late MockHistoryRepository historyRepo;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(FakeScamReport());
  });

  setUp(() {
    repo = MockReportRepository();
    historyRepo = MockHistoryRepository();
    ServiceLocator.reportRepository = repo;
    when(
      () => historyRepo.getScanHistory(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        riskLevel: any(named: 'riskLevel'),
        fromDate: any(named: 'fromDate'),
        toDate: any(named: 'toDate'),
        keyword: any(named: 'keyword'),
      ),
    ).thenAnswer(
      (_) async => [
        ScanHistoryItem(
          scanId: 'scan-select-1',
          riskScore: 72,
          riskLevel: RiskLevel.high,
          status: 'completed',
          createdAt: DateTime(2026, 9, 20),
          title: 'หลักฐานจากประวัติ',
        ),
      ],
    );
  });

  Widget buildApp({String? scanId, String? imageUrl, double textScale = 1.0}) {
    final router = GoRouter(
      initialLocation: '/main/report',
      routes: [
        GoRoute(
          path: '/main/report',
          builder: (_, _) =>
              ReportScamScreen(scanId: scanId, imageUrl: imageUrl),
        ),
        GoRoute(
          path: '/main/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/main/history',
          builder: (_, _) => const Scaffold(body: Text('History')),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const Scaffold(body: Text('Notifications')),
        ),
      ],
    );
    return BlocProvider<HistoryBloc>(
      create: (_) => HistoryBloc(repository: historyRepo),
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
  }

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('report screen renders at phone width without layout exception', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      buildApp(scanId: '00000000-0000-0000-0000-000000000001'),
    );
    await tester.pumpAndSettle();

    expect(find.text('แจ้งรายงานการหลอกลวง'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the analyzed image passed from result', (tester) async {
    usePhoneViewport(tester);
    const imageUrl = 'https://example.invalid/scan.jpg';
    await tester.pumpWidget(
      buildApp(
        scanId: '00000000-0000-0000-0000-000000000001',
        imageUrl: imageUrl,
      ),
    );
    await tester.pump();

    final imageFinder = find.byWidgetPredicate(
      (widget) => widget is CachedNetworkImage && widget.imageUrl == imageUrl,
    );
    expect(imageFinder, findsOneWidget);
  });

  testWidgets('change image returns to scan selector', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      buildApp(scanId: '00000000-0000-0000-0000-000000000001'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เปลี่ยนรูป'));
    await tester.pumpAndSettle();

    expect(find.text('เลือกผลตรวจที่ต้องการรายงาน'), findsOneWidget);
    expect(find.text('หลักฐานจากประวัติ'), findsOneWidget);
  });

  testWidgets(
    'main report route lets user select a completed scan before form',
    (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('เลือกผลตรวจที่ต้องการรายงาน'), findsOneWidget);
      expect(find.text('หลักฐานจากประวัติ'), findsOneWidget);
      expect(find.text('ส่งรายงาน'), findsNothing);

      await tester.tap(find.text('หลักฐานจากประวัติ'));
      await tester.pumpAndSettle();

      expect(find.text('แจ้งรายงานการหลอกลวง'), findsOneWidget);
      expect(find.text('รูปภาพที่ตรวจสอบ'), findsOneWidget);
      verifyNever(() => repo.submitReport(any()));
    },
  );

  testWidgets('viewport matrix renders without overflow at text scale 1.3', (
    tester,
  ) async {
    const sizes = <Size>[
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
      Size(600, 960),
      Size(844, 390),
      Size(840, 1180),
      Size(1180, 840),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        buildApp(
          scanId: '00000000-0000-0000-0000-000000000001',
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'layout exception at ${size.width}x${size.height}',
      );
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('390 phone remains usable at text scale 1.5', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      buildApp(scanId: '00000000-0000-0000-0000-000000000001', textScale: 1.5),
    );
    await tester.pumpAndSettle();

    expect(find.text('แจ้งรายงานการหลอกลวง'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
