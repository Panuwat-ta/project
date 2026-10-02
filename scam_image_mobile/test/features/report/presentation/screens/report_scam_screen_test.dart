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

  testWidgets(
    'report form blocks submit when category and details are missing',
    (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        buildApp(scanId: '00000000-0000-0000-0000-000000000001'),
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('ส่งรายงาน'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.ensureVisible(find.text('ส่งรายงาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ส่งรายงาน'));
      await tester.pumpAndSettle();

      expect(find.text('กรุณาเลือกประเภทการหลอกลวง'), findsOneWidget);
      expect(
        find.text('กรุณาระบุรายละเอียดอย่างน้อย 10 ตัวอักษร'),
        findsOneWidget,
      );
      verifyNever(() => repo.submitReport(any()));
    },
  );

  testWidgets(
    'report submission sends canonical category and shows network error',
    (tester) async {
      usePhoneViewport(tester);
      when(
        () => repo.submitReport(any()),
      ).thenThrow(Exception('NetworkException: connection lost'));
      await tester.pumpWidget(
        buildApp(scanId: '00000000-0000-0000-0000-000000000001'),
      );
      await tester.pumpAndSettle();

      final categoryMenu = find.byType(DropdownMenu<String>).first;
      await tester.tap(categoryMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Romance Scam').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'ผู้ติดต่อขอให้โอนเงินล่วงหน้าก่อนส่งสินค้า',
      );
      await tester.dragUntilVisible(
        find.text('ส่งรายงาน'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.ensureVisible(find.text('ส่งรายงาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ส่งรายงาน'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
        ),
        findsOneWidget,
      );
      final submitted =
          verify(() => repo.submitReport(captureAny())).captured.single
              as ScamReport;
      expect(submitted.category, 'romance_scam');
      expect(submitted.scanId, '00000000-0000-0000-0000-000000000001');
    },
  );

  testWidgets(
    'other category and platform require values and submit trimmed data',
    (tester) async {
      usePhoneViewport(tester);
      when(
        () => repo.submitReport(any()),
      ).thenThrow(Exception('NetworkException: connection lost'));
      await tester.pumpWidget(
        buildApp(scanId: '00000000-0000-0000-0000-000000000001'),
      );
      await tester.pumpAndSettle();

      final menus = find.byType(DropdownMenu<String>);
      await tester.tap(menus.at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('อื่นๆ').last);
      await tester.pumpAndSettle();
      await tester.tap(menus.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('อื่นๆ').last);
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('ส่งรายงาน'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(
        fields.at(2),
        'รายละเอียดเหตุการณ์อย่างน้อยสิบอักษร',
      );
      await tester.dragUntilVisible(
        find.text('ส่งรายงาน'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.ensureVisible(find.text('ส่งรายงาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ส่งรายงาน'));
      await tester.pumpAndSettle();

      expect(find.text('กรุณาระบุประเภท'), findsOneWidget);
      expect(find.text('กรุณาระบุแพลตฟอร์ม'), findsOneWidget);
      verifyNever(() => repo.submitReport(any()));

      await tester.enterText(fields.at(0), '  เว็บประกาศ  ');
      await tester.enterText(fields.at(1), '  เว็บบอร์ด  ');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('ส่งรายงาน'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.ensureVisible(find.text('ส่งรายงาน'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('ส่งรายงาน'));
      await tester.pumpAndSettle();

      final submitted =
          verify(() => repo.submitReport(captureAny())).captured.single
              as ScamReport;
      expect(submitted.category, 'other');
      expect(
        submitted.description,
        '[เว็บประกาศ] รายละเอียดเหตุการณ์อย่างน้อยสิบอักษร',
      );
      expect(submitted.platform, 'เว็บบอร์ด');
      expect(submitted.allowResearchUse, isTrue);
    },
  );

  testWidgets('successful report confirms submission and returns home', (
    tester,
  ) async {
    usePhoneViewport(tester);
    when(() => repo.submitReport(any())).thenAnswer((_) async {});
    await tester.pumpWidget(
      buildApp(scanId: '00000000-0000-0000-0000-000000000001'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownMenu<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Romance Scam').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).last,
      'ผู้ติดต่อขอให้โอนเงินล่วงหน้าก่อนส่งสินค้า',
    );
    await tester.dragUntilVisible(
      find.text('ส่งรายงาน'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('ส่งรายงาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งรายงาน'));
    await tester.pumpAndSettle();

    expect(
      find.text('ส่งรายงานสำเร็จ ขอบคุณที่ช่วยปกป้องผู้ใช้คนอื่น'),
      findsOneWidget,
    );
    verify(() => repo.submitReport(any())).called(1);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
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

  testWidgets('scan selector shows repository error and retries history', (
    tester,
  ) async {
    var historyCalls = 0;
    when(
      () => historyRepo.getScanHistory(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        riskLevel: any(named: 'riskLevel'),
        fromDate: any(named: 'fromDate'),
        toDate: any(named: 'toDate'),
        keyword: any(named: 'keyword'),
      ),
    ).thenAnswer((_) async {
      historyCalls += 1;
      if (historyCalls == 1) throw Exception('history unavailable');
      return [];
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('history unavailable'), findsOneWidget);

    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('เลือกผลตรวจที่ต้องการรายงาน'), findsOneWidget);
    verify(
      () => historyRepo.getScanHistory(page: 1, limit: 100, keyword: ''),
    ).called(2);
  });

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
