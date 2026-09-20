import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/di/injection_container.dart';
import 'package:scam_image_mobile/features/report/domain/entities/scam_report.dart';
import 'package:scam_image_mobile/features/report/domain/repositories/report_repository.dart';
import 'package:scam_image_mobile/features/report/presentation/screens/report_scam_screen.dart';

class MockReportRepository extends Mock implements ReportRepository {}

class FakeScamReport extends Fake implements ScamReport {}

void main() {
  late MockReportRepository repo;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(FakeScamReport());
  });

  setUp(() {
    repo = MockReportRepository();
    ServiceLocator.reportRepository = repo;
  });

  Widget buildApp({String? scanId, String? imageUrl}) {
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
    return MaterialApp.router(routerConfig: router, theme: ThemeData.dark());
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

  testWidgets('change image returns to history', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      buildApp(scanId: '00000000-0000-0000-0000-000000000001'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เปลี่ยนรูป'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
  });

  testWidgets(
    'main report route without scan id blocks submission before form validation',
    (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final label = find.text('ส่งรายงาน');
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(label, 350, scrollable: scrollable);
      await tester.ensureVisible(label);
      await tester.pumpAndSettle();
      await tester.tap(label);
      await tester.pump();

      expect(find.text('กรุณาสแกนรูปภาพก่อนส่งรายงาน'), findsOneWidget);
      verifyNever(() => repo.submitReport(any()));
    },
  );
}
