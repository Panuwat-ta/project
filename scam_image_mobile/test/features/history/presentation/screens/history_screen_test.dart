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

// ── Mocks ─────────────────────────────────────────────────────────────────────

class _MockHistoryRepository extends Mock implements HistoryRepository {}

// MockBloc lets us control the emitted state without touching the repository
class _MockHistoryBloc extends MockBloc<HistoryEvent, HistoryState>
    implements HistoryBloc {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Build the HistoryScreen inside a GoRouter so go_router navigation calls
/// don't throw. The HistoryBloc is provided externally via [bloc].
Widget buildHistoryScreen(HistoryBloc bloc) {
  final router = GoRouter(
    initialLocation: '/main/history',
    routes: [
      GoRoute(
        path: '/main/history',
        builder: (_, _) => BlocProvider.value(
          value: bloc,
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
        builder: (_, state) =>
            Scaffold(body: Center(child: Text('Detail ${state.pathParameters['id']}'))),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    theme: ThemeData.dark(),
  );
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
  });

  late _MockHistoryRepository mockRepo;

  setUp(() {
    mockRepo = _MockHistoryRepository();
    // Default stub: getScanHistory returns empty list
    when(() => mockRepo.getScanHistory(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          riskLevel: any(named: 'riskLevel'),
          fromDate: any(named: 'fromDate'),
          toDate: any(named: 'toDate'),
          keyword: any(named: 'keyword'),
        )).thenAnswer((_) async => []);
  });

  group('HistoryScreen — HistoryEmpty state', () {
    testWidgets('shows EmptyStateView with "ยังไม่มีประวัติการตรวจสอบ"',
        (tester) async {
      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      // Let initState trigger HistoryLoaded and the async repository respond
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีประวัติการตรวจสอบ'), findsOneWidget);

      bloc.close();
    });
  });

  group('HistoryScreen — HistoryLoading state', () {
    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      // Use MockBloc to control the state directly — no timer/future needed
      final mockBloc = _MockHistoryBloc();
      when(() => mockBloc.state).thenReturn(const HistoryLoading());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildHistoryScreen(mockBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HistoryScreen — HistoryDataLoaded state', () {
    testWidgets('shows item title when list has one item', (tester) async {
      final item = fakeItem(title: 'สลิปโอนเงิน');

      when(() => mockRepo.getScanHistory(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            riskLevel: any(named: 'riskLevel'),
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            keyword: any(named: 'keyword'),
          )).thenAnswer((_) async => [item]);

      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      expect(find.text('สลิปโอนเงิน'), findsOneWidget);

      bloc.close();
    });

    testWidgets('shows multiple item titles when list has multiple items',
        (tester) async {
      final items = [
        fakeItem(scanId: 'a', title: 'รายการที่ 1'),
        fakeItem(scanId: 'b', title: 'รายการที่ 2'),
      ];

      when(() => mockRepo.getScanHistory(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            riskLevel: any(named: 'riskLevel'),
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            keyword: any(named: 'keyword'),
          )).thenAnswer((_) async => items);

      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      expect(find.text('รายการที่ 1'), findsOneWidget);
      expect(find.text('รายการที่ 2'), findsOneWidget);

      bloc.close();
    });
  });

  group('HistoryScreen — HistoryError state', () {
    testWidgets('shows error widget when repository throws', (tester) async {
      when(() => mockRepo.getScanHistory(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            riskLevel: any(named: 'riskLevel'),
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            keyword: any(named: 'keyword'),
          )).thenThrow(Exception('network error'));

      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      // ErrorStateView renders the error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      bloc.close();
    });

    testWidgets('shows error message text when repository throws',
        (tester) async {
      when(() => mockRepo.getScanHistory(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            riskLevel: any(named: 'riskLevel'),
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            keyword: any(named: 'keyword'),
          )).thenThrow(Exception('ไม่สามารถโหลดข้อมูลได้'));

      final bloc = HistoryBloc(repository: mockRepo);

      await tester.pumpWidget(buildHistoryScreen(bloc));
      await tester.pumpAndSettle();

      // The error message propagated from the exception
      expect(
        find.textContaining('ไม่สามารถโหลดข้อมูลได้'),
        findsOneWidget,
      );

      bloc.close();
    });
  });
}
