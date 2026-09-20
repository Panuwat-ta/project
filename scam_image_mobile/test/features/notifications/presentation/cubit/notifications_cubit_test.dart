import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:scam_image_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:scam_image_mobile/features/history/domain/entities/scan_history_item.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final tNotification1 = AppNotification(
  id: 'notif-1',
  type: NotificationType.scanCompleted,
  title: 'Scan completed',
  body: 'Your scan is ready',
  createdAt: DateTime(2026, 1, 1),
);

final tNotification2 = AppNotification(
  id: 'notif-2',
  type: NotificationType.scamAlert,
  title: 'Scam alert',
  body: 'Suspicious image detected',
  createdAt: DateTime(2026, 1, 2),
);

void main() {
  late NotificationsCubit cubit;

  setUp(() {
    cubit = NotificationsCubit();
  });

  tearDown(() {
    cubit.close();
  });

  group('initial state', () {
    test('has empty items', () {
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.unreadCount, 0);
    });
  });

  group('loadNotifications', () {
    test('emits state with empty items (stub)', () {
      cubit.loadNotifications();
      expect(cubit.state.items, isEmpty);
    });
  });

  group('syncFromHistory', () {
    ScanHistoryItem item({
      String scanId = 'scan-12345678',
      String status = 'completed',
      RiskLevel riskLevel = RiskLevel.low,
    }) => ScanHistoryItem(
      scanId: scanId,
      riskScore: 25,
      riskLevel: riskLevel,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      title: 'sample',
    );

    test('ignores non-terminal queued/processing scans', () {
      cubit.syncFromHistory([
        item(status: 'queued'),
        item(scanId: 'scan-2', status: 'processing_visual'),
      ]);

      expect(cubit.state.items, isEmpty);
    });

    test('failed scan with short id does not throw substring RangeError', () {
      cubit.syncFromHistory([item(scanId: 'abc', status: 'failed')]);

      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.items.single.type, NotificationType.scanFailed);
      expect(cubit.state.items.single.body, contains('abc'));
    });

    test('read state survives later history synchronization', () {
      final history = [item()];
      cubit.syncFromHistory(history);
      final id = cubit.state.items.single.id;
      cubit.markAsRead(id);

      cubit.syncFromHistory(history);

      expect(cubit.state.items.single.isRead, true);
    });

    test('dismissed and clear-all items stay hidden on resync', () {
      final first = item();
      final second = item(scanId: 'scan-second');
      cubit.syncFromHistory([first, second]);
      cubit.dismissNotification('notif_${first.scanId}');
      cubit.clearAll();

      cubit.syncFromHistory([first, second]);

      expect(cubit.state.items, isEmpty);
    });
  });

  group('markAsRead', () {
    test('marks a notification as read', () {
      // Manually set initial state with notifications
      cubit.emit(NotificationsState(items: [tNotification1, tNotification2]));
      expect(cubit.state.unreadCount, 2);

      cubit.markAsRead('notif-1');

      expect(cubit.state.items.length, 2);
      expect(cubit.state.items.first.isRead, true);
      expect(cubit.state.items.last.isRead, false);
      expect(cubit.state.unreadCount, 1);
    });

    test('does not change state when id not found', () {
      cubit.emit(NotificationsState(items: [tNotification1]));

      cubit.markAsRead('nonexistent');

      expect(cubit.state.items.length, 1);
      expect(cubit.state.items.first.isRead, false);
    });
  });

  group('dismissNotification', () {
    test('removes notification by id', () {
      cubit.emit(NotificationsState(items: [tNotification1, tNotification2]));

      cubit.dismissNotification('notif-1');

      expect(cubit.state.items.length, 1);
      expect(cubit.state.items.first.id, 'notif-2');
    });

    test('does not change state when id not found', () {
      cubit.emit(NotificationsState(items: [tNotification1]));

      cubit.dismissNotification('nonexistent');

      expect(cubit.state.items.length, 1);
    });
  });

  group('clearAll', () {
    test('clears all notifications', () {
      cubit.emit(NotificationsState(items: [tNotification1, tNotification2]));

      cubit.clearAll();

      expect(cubit.state.items, isEmpty);
      expect(cubit.state.unreadCount, 0);
    });
  });

  group('NotificationsState', () {
    test('unreadCount counts unread items correctly', () {
      final state = NotificationsState(
        items: [tNotification1, tNotification2.copyWith(isRead: true)],
      );
      expect(state.unreadCount, 1);
    });

    test('copyWith creates new state with updated items', () {
      final state = NotificationsState(items: [tNotification1]);
      final copied = state.copyWith(items: [tNotification1, tNotification2]);
      expect(copied.items.length, 2);
    });

    test('props returns items list', () {
      final state = NotificationsState(items: [tNotification1]);
      expect(state.props, [state.items]);
    });
  });

  group('AppNotification', () {
    test('copyWith overrides isRead', () {
      final read = tNotification1.copyWith(isRead: true);
      expect(read.isRead, true);
      expect(read.id, tNotification1.id);
      expect(read.title, tNotification1.title);
    });

    test('props includes all fields', () {
      expect(tNotification1.props.length, 7);
    });
  });
}
