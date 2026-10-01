import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/history/domain/entities/scan_history_item.dart';
import 'package:scam_image_mobile/features/history/presentation/bloc/history_bloc.dart';
import 'package:scam_image_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:scam_image_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:scam_image_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';
import 'package:scam_image_mobile/features/settings/presentation/bloc/settings_bloc.dart';

class _MockHistoryBloc extends MockBloc<HistoryEvent, HistoryState>
    implements HistoryBloc {}

class _FakeHistoryEvent extends Fake implements HistoryEvent {}

class _MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeHistoryEvent());
  });

  group('NotificationsScreen with controlled HistoryBloc', () {
    testWidgets('HistoryEmpty displays the empty state without reloading', (
      tester,
    ) async {
      final harness = await _pumpNotifications(
        tester,
        historyState: const HistoryEmpty(),
      );

      expect(find.text('ไม่มีการแจ้งเตือน'), findsOneWidget);
      expect(find.text('การแจ้งเตือนใหม่จะปรากฏที่นี่'), findsOneWidget);
      expect(harness.notifications.state.items, isEmpty);
      verifyNever(() => harness.history.add(any()));
    });

    testWidgets('HistoryDataLoaded renders completed, high-risk and failed', (
      tester,
    ) async {
      final harness = await _pumpNotifications(
        tester,
        historyState: HistoryDataLoaded([
          _historyItem(scanId: 'completed-1', title: 'ภาพปกติ'),
          _historyItem(
            scanId: 'high-risk-2',
            title: 'ภาพเสี่ยง',
            riskLevel: RiskLevel.high,
            riskScore: 91,
          ),
          _historyItem(scanId: 'failed-3', status: 'failed'),
          _historyItem(scanId: 'processing-4', status: 'processing'),
        ]),
      );

      expect(find.text('สแกนเสร็จสิ้น'), findsOneWidget);
      expect(find.text('ตรวจพบความเสี่ยงสูง'), findsOneWidget);
      expect(find.text('การสแกนล้มเหลว'), findsOneWidget);
      expect(find.textContaining('ภาพปกติ'), findsOneWidget);
      expect(find.textContaining('ภาพเสี่ยง'), findsOneWidget);
      expect(find.textContaining('failed-3'), findsOneWidget);
      expect(harness.notifications.state.items, hasLength(3));
      expect(
        harness.notifications.state.items.map((item) => item.type),
        containsAll([
          NotificationType.scanCompleted,
          NotificationType.scamAlert,
          NotificationType.scanFailed,
        ]),
      );
    });

    testWidgets('groups notifications into today, yesterday and earlier', (
      tester,
    ) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      final yesterday = DateTime(now.year, now.month, now.day - 1, 12);
      final earlier = DateTime(now.year, now.month, now.day - 3, 12);
      await _pumpNotifications(
        tester,
        historyState: HistoryDataLoaded([
          _historyItem(scanId: 'today-1', createdAt: today),
          _historyItem(scanId: 'yesterday-2', createdAt: yesterday),
          _historyItem(scanId: 'earlier-3', createdAt: earlier),
        ]),
      );

      expect(find.text('วันนี้'), findsOneWidget);
      expect(find.text('เมื่อวาน'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('ก่อนหน้านี้'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('ก่อนหน้านี้'), findsOneWidget);
    });

    testWidgets('HistoryError keeps existing notifications visible', (
      tester,
    ) async {
      final historyEvents = StreamController<HistoryState>();
      addTearDown(historyEvents.close);
      final harness = await _pumpNotifications(
        tester,
        historyState: HistoryDataLoaded([
          _historyItem(scanId: 'still-visible', title: 'รายการที่โหลดแล้ว'),
        ]),
        historyStates: historyEvents.stream,
      );

      historyEvents.add(const HistoryError('history unavailable'));
      await tester.pump();

      expect(find.textContaining('รายการที่โหลดแล้ว'), findsOneWidget);
      expect(harness.notifications.state.items.single.scanId, 'still-visible');
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap marks notification as read and opens its scan result', (
      tester,
    ) async {
      final harness = await _pumpNotifications(
        tester,
        historyState: HistoryDataLoaded([
          _historyItem(scanId: 'scan-readable', title: 'รายการอ่านแล้ว'),
        ]),
      );

      await tester.tap(find.textContaining('รายการอ่านแล้ว'));
      await tester.pumpAndSettle();

      expect(harness.notifications.state.items.single.isRead, isTrue);
      expect(find.text('Result route: scan-readable'), findsOneWidget);
    });

    testWidgets('tap without scanId marks read and stays on notifications', (
      tester,
    ) async {
      final notification = _notification(id: 'manual-no-scan');
      final harness = await _pumpNotifications(
        tester,
        historyState: const HistoryEmpty(),
        notifications: [notification],
      );

      await tester.tap(find.text('รายการทดสอบ'));
      await tester.pump();

      expect(harness.notifications.state.items.single.isRead, isTrue);
      expect(find.text('การแจ้งเตือน'), findsOneWidget);
      expect(find.text('Result route: manual-no-scan'), findsNothing);
    });

    testWidgets('swiping a notification dismisses it from state and screen', (
      tester,
    ) async {
      final harness = await _pumpNotifications(
        tester,
        historyState: const HistoryEmpty(),
        notifications: [_notification(id: 'dismiss-me')],
      );

      await tester.drag(
        find.byKey(const Key('dismiss-me')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();

      expect(harness.notifications.state.items, isEmpty);
      expect(find.text('รายการทดสอบ'), findsNothing);
      expect(find.text('ไม่มีการแจ้งเตือน'), findsOneWidget);
    });

    testWidgets('Clear All empties state and displays the empty state', (
      tester,
    ) async {
      final harness = await _pumpNotifications(
        tester,
        historyState: const HistoryEmpty(),
        notifications: [
          _notification(id: 'clear-one'),
          _notification(id: 'clear-two', title: 'อีกรายการ'),
        ],
      );

      await tester.tap(find.text('ล้างการแจ้งเตือนทั้งหมด'));
      await tester.pump();

      expect(harness.notifications.state.items, isEmpty);
      expect(find.text('ไม่มีการแจ้งเตือน'), findsOneWidget);
    });
  });
}

typedef _Harness = ({
  _MockHistoryBloc history,
  NotificationsCubit notifications,
  GoRouter router,
});

Future<_Harness> _pumpNotifications(
  WidgetTester tester, {
  required HistoryState historyState,
  Stream<HistoryState>? historyStates,
  List<AppNotification> notifications = const [],
}) async {
  final history = _MockHistoryBloc();
  when(() => history.state).thenReturn(historyState);
  whenListen(
    history,
    historyStates ?? const Stream<HistoryState>.empty(),
    initialState: historyState,
  );
  final settings = _MockSettingsCubit();
  when(() => settings.state).thenReturn(const SettingsState());
  final notificationCubit = NotificationsCubit();
  if (notifications.isNotEmpty) {
    notificationCubit.emit(NotificationsState(items: notifications));
  }
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/result/:scanId',
        builder: (_, state) => Scaffold(
          body: Text('Result route: ${state.pathParameters['scanId']}'),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<HistoryBloc>.value(value: history),
        BlocProvider<SettingsCubit>.value(value: settings),
        BlocProvider<NotificationsCubit>.value(value: notificationCubit),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  // One explicit frame runs the post-frame HistoryBloc sync; no settle loop.
  await tester.pump();

  addTearDown(router.dispose);
  addTearDown(notificationCubit.close);
  return (history: history, notifications: notificationCubit, router: router);
}

ScanHistoryItem _historyItem({
  required String scanId,
  String status = 'completed',
  RiskLevel riskLevel = RiskLevel.low,
  int riskScore = 25,
  String? title = 'รายการจากประวัติ',
  DateTime? createdAt,
}) => ScanHistoryItem(
  scanId: scanId,
  riskScore: riskScore,
  riskLevel: riskLevel,
  status: status,
  createdAt: createdAt ?? DateTime.now(),
  title: title,
);

AppNotification _notification({
  required String id,
  String title = 'รายการทดสอบ',
}) => AppNotification(
  id: id,
  type: NotificationType.systemInfo,
  title: title,
  body: 'ข้อความทดสอบ',
  createdAt: DateTime.now(),
);
