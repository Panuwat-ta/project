import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:scam_image_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';

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
      final state = NotificationsState(items: [
        tNotification1,
        tNotification2.copyWith(isRead: true),
      ]);
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
