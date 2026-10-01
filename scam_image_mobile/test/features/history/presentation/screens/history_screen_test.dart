import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scam_image_mobile/features/history/domain/entities/scan_history_item.dart';
import 'package:scam_image_mobile/features/history/domain/repositories/history_repository.dart';
import 'package:scam_image_mobile/features/history/presentation/bloc/history_bloc.dart';
import 'package:scam_image_mobile/features/history/presentation/screens/history_screen.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

import 'package:scam_image_mobile/features/settings/presentation/bloc/settings_bloc.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class _MockHistoryRepository extends Mock implements HistoryRepository {}

// MockBloc lets us control the emitted state without touching the repository
class _MockHistoryBloc extends MockBloc<HistoryEvent, HistoryState>
    implements HistoryBloc {}

class _MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class _FakeHistoryEvent extends Fake implements HistoryEvent {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Build the HistoryScreen inside a GoRouter so go_router navigation calls
/// don't throw. The HistoryBloc is provided externally via [bloc].
Widget buildHistoryScreen(HistoryBloc bloc) {
  final settingsCubit = _MockSettingsCubit();
  when(() => settingsCubit.state).thenReturn(const SettingsState());

  final router = GoRouter(
    initialLocation: '/main/history',
    routes: [
      GoRoute(
        path: '/main/history',
        builder: (_, _) => MultiBlocProvider(
          providers: [
            BlocProvider<HistoryBloc>.value(value: bloc),
            BlocProvider<SettingsCubit>.value(value: settingsCubit),
          ],
          child: const HistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('Notifications'))),
      ),
      GoRoute(
        path: '/main/history/:id',
        builder: (_, state) => Scaffold(
          body: Center(child: Text('Detail ${state.pathParameters['id']}')),
        ),
      ),
      GoRoute(
        path: '/result/:id',
        builder: (_, state) => Scaffold(
          body: Center(child: Text('Result ${state.pathParameters['id']}')),
        ),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router, theme: ThemeData.dark());
}

/// A fake [ScanHistoryItem] for testing.
ScanHistoryItem fakeItem({
  String scanId = 'scan_test_001',
  String title = 'สลิปทดสอบ',
  RiskLevel riskLevel = RiskLevel.high,
  int riskScore = 90,
}) {
  return ScanHistoryItem(
    scanId: scanId,
    riskScore: riskScore,
    riskLevel: riskLevel,
    status: 'completed',
    createdAt: DateTime(2024, 1, 15, 10, 30),
    title: title,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(_FakeHistoryEvent());
  });

  late _MockHistoryRepository mockRepo;

  setUp(() {
    mockRepo = _MockHistoryRepository();
    // Default stub: getScanHistory returns empty list
    when(
      () => mockRepo.getScanHistory(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        riskLevel: any(named: 'riskLevel'),
        fromDate: any(named: 'fromDate'),
        toDate: any(named: 'toDate'),
        keyword: any(named: 'keyword'),
      ),
    ).thenAnswer((_) async => []);
  });

  group('HistoryScreen — HistoryEmpty state', () {
    testWidgets('shows EmptyStateView with "ยังไม่มีประวัติการตรวจสอบ"', (
      tester,
    ) async {
      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      // Let initState trigger HistoryLoaded and the async repository respond
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีประวัติการตรวจสอบ'), findsOneWidget);

      bloc.close();
    });
  });

  group('HistoryScreen — HistoryLoading state', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      // Use MockBloc to control the state directly — no timer/future needed
      final mockBloc = _MockHistoryBloc();
      when(() => mockBloc.state).thenReturn(const HistoryLoading());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildHistoryScreen(mockBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('notification action opens notifications', (tester) async {
      final bloc = _MockHistoryBloc();
      when(() => bloc.state).thenReturn(const HistoryLoading());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });
  });

  group('HistoryScreen — HistoryDataLoaded state', () {
    testWidgets('tapping a history card opens its analysis result', (
      tester,
    ) async {
      final bloc = _MockHistoryBloc();
      when(() => bloc.state).thenReturn(
        HistoryDataLoaded([
          fakeItem(scanId: 'scan-open-result', title: 'เปิดผลตรวจรายการนี้'),
        ]),
      );
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pump();
      await tester.tap(find.text('เปิดผลตรวจรายการนี้'));
      await tester.pumpAndSettle();

      expect(find.text('Result scan-open-result'), findsOneWidget);
    });

    testWidgets('risk filter updates visible rows and count', (tester) async {
      final bloc = _MockHistoryBloc();
      when(() => bloc.state).thenReturn(
        HistoryDataLoaded([
          fakeItem(scanId: 'high', title: 'รายการเสี่ยงสูง'),
          fakeItem(
            scanId: 'low',
            title: 'รายการความเสี่ยงต่ำ',
            riskLevel: RiskLevel.low,
            riskScore: 10,
          ),
        ]),
      );
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pump();
      expect(find.text('รายการเสี่ยงสูง'), findsOneWidget);
      expect(find.text('รายการความเสี่ยงต่ำ'), findsOneWidget);

      await tester.tap(find.byTooltip('กรองผลลัพธ์'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ความเสี่ยงสูง').last);
      await tester.pumpAndSettle();

      expect(find.text('รายการเสี่ยงสูง'), findsOneWidget);
      expect(find.text('รายการความเสี่ยงต่ำ'), findsNothing);
      expect(find.text('1 รายการ'), findsOneWidget);
    });

    testWidgets('risk filter shows an empty state when no scans match', (
      tester,
    ) async {
      final bloc = _MockHistoryBloc();
      when(() => bloc.state).thenReturn(
        HistoryDataLoaded([
          fakeItem(
            scanId: 'only-medium',
            title: 'ผลตรวจความเสี่ยงปานกลาง',
            riskLevel: RiskLevel.medium,
            riskScore: 55,
          ),
        ]),
      );
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pump();
      await tester.tap(find.byTooltip('กรองผลลัพธ์'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ความเสี่ยงสูง').last);
      await tester.pumpAndSettle();

      expect(find.text('ไม่พบผลลัพธ์'), findsOneWidget);
      expect(find.text('ไม่พบประวัติระดับ ความเสี่ยงสูง'), findsOneWidget);

      await tester.tap(find.byTooltip('กรองผลลัพธ์'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ความเสี่ยงต่ำ').last);
      await tester.pumpAndSettle();

      expect(find.text('ไม่พบประวัติระดับ ความเสี่ยงต่ำ'), findsOneWidget);
      expect(find.text('ผลตรวจความเสี่ยงปานกลาง'), findsNothing);
    });

    testWidgets('search debounce dispatches the entered keyword', (
      tester,
    ) async {
      final bloc = _MockHistoryBloc();
      when(
        () => bloc.state,
      ).thenReturn(HistoryDataLoaded([fakeItem(title: 'รายการเดิม')]));
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'คำค้นทดสอบ');
      await tester.pump(const Duration(milliseconds: 400));

      verify(
        () => bloc.add(
          any(
            that: isA<HistorySearched>().having(
              (event) => event.keyword,
              'keyword',
              'คำค้นทดสอบ',
            ),
          ),
        ),
      ).called(1);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '',
      );
      verify(
        () => bloc.add(
          any(
            that: isA<HistorySearched>().having(
              (event) => event.keyword,
              'keyword',
              '',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('shows item title when list has one item', (tester) async {
      final item = fakeItem(title: 'สลิปโอนเงิน');

      when(
        () => mockRepo.getScanHistory(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          riskLevel: any(named: 'riskLevel'),
          fromDate: any(named: 'fromDate'),
          toDate: any(named: 'toDate'),
          keyword: any(named: 'keyword'),
        ),
      ).thenAnswer((_) async => [item]);

      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      expect(find.textContaining('สลิปโอนเงิน'), findsOneWidget);

      bloc.close();
    });

    testWidgets('does not derive forensic evidence tags from risk level', (
      tester,
    ) async {
      final item = fakeItem(
        title: 'รายการเสี่ยงสูง',
        riskLevel: RiskLevel.high,
      );

      when(
        () => mockRepo.getScanHistory(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          riskLevel: any(named: 'riskLevel'),
          fromDate: any(named: 'fromDate'),
          toDate: any(named: 'toDate'),
          keyword: any(named: 'keyword'),
        ),
      ).thenAnswer((_) async => [item]);

      final bloc = HistoryBloc(repository: mockRepo);
      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      expect(find.text('พบรอยต่อพิกเซล'), findsNothing);
      expect(find.text('Metadata ขัดแย้ง'), findsNothing);
      expect(find.text('ฟิลเตอร์แสง'), findsNothing);
      expect(find.text('ไฟล์ต้นฉบับ'), findsNothing);

      bloc.close();
    });

    testWidgets('shows multiple item titles when list has multiple items', (
      tester,
    ) async {
      final items = [
        fakeItem(scanId: 'a', title: 'รายการที่ 1'),
        fakeItem(scanId: 'b', title: 'รายการที่ 2'),
      ];

      when(
        () => mockRepo.getScanHistory(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          riskLevel: any(named: 'riskLevel'),
          fromDate: any(named: 'fromDate'),
          toDate: any(named: 'toDate'),
          keyword: any(named: 'keyword'),
        ),
      ).thenAnswer((_) async => items);

      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      expect(find.textContaining('รายการที่ 1'), findsOneWidget);
      expect(find.textContaining('รายการที่ 2'), findsOneWidget);

      bloc.close();
    });

    testWidgets('delete confirmation can cancel or delete a history item', (
      tester,
    ) async {
      const scanId = 'delete-confirmation-scan';
      final item = fakeItem(scanId: scanId, title: 'รายการสำหรับลบ');
      when(
        () => mockRepo.getScanHistory(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          riskLevel: any(named: 'riskLevel'),
          fromDate: any(named: 'fromDate'),
          toDate: any(named: 'toDate'),
          keyword: any(named: 'keyword'),
        ),
      ).thenAnswer((_) async => [item]);
      when(
        () => mockRepo.deleteScanHistoryItem(scanId),
      ).thenAnswer((_) async {});
      final bloc = HistoryBloc(repository: mockRepo);
      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      Finder dismissibleForItem() => find.ancestor(
        of: find.textContaining('รายการสำหรับลบ'),
        matching: find.byType(Dismissible),
      );

      var dismissible = tester.widget<Dismissible>(dismissibleForItem());
      final cancelFuture = dismissible.confirmDismiss!(
        DismissDirection.endToStart,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(await cancelFuture, isFalse);
      verifyNever(() => mockRepo.deleteScanHistoryItem(scanId));

      dismissible = tester.widget<Dismissible>(dismissibleForItem());
      final deleteFuture = dismissible.confirmDismiss!(
        DismissDirection.endToStart,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลบ').last);
      await tester.pumpAndSettle();
      expect(await deleteFuture, isTrue);
      verify(() => mockRepo.deleteScanHistoryItem(scanId)).called(1);
      expect(find.text('ยังไม่มีประวัติการตรวจสอบ'), findsOneWidget);

      bloc.close();
    });
  });

  group('HistoryScreen — HistoryError state', () {
    testWidgets('retry from error requests history again', (tester) async {
      final bloc = _MockHistoryBloc();
      when(
        () => bloc.state,
      ).thenReturn(const HistoryError('โหลดประวัติไม่ได้'));
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pump();
      await tester.tap(find.text('ลองอีกครั้ง'));

      verify(() => bloc.add(any(that: isA<HistoryLoaded>()))).called(2);
    });

    testWidgets('shows error widget when repository throws', (tester) async {
      when(
        () => mockRepo.getScanHistory(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          riskLevel: any(named: 'riskLevel'),
          fromDate: any(named: 'fromDate'),
          toDate: any(named: 'toDate'),
          keyword: any(named: 'keyword'),
        ),
      ).thenThrow(Exception('network error'));

      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      // ErrorStateView renders the error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      bloc.close();
    });

    testWidgets('shows error message text when repository throws', (
      tester,
    ) async {
      when(
        () => mockRepo.getScanHistory(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          riskLevel: any(named: 'riskLevel'),
          fromDate: any(named: 'fromDate'),
          toDate: any(named: 'toDate'),
          keyword: any(named: 'keyword'),
        ),
      ).thenThrow(Exception('ไม่สามารถโหลดข้อมูลได้'));

      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      // The error message propagated from the exception
      expect(find.textContaining('ไม่สามารถโหลดข้อมูลได้'), findsOneWidget);

      bloc.close();
    });
  });
}
