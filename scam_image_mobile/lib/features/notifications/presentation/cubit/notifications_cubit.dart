import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_notification.dart';
import '../../../history/domain/entities/scan_history_item.dart';
import '../../../result/domain/entities/analysis_result.dart' show RiskLevel;

class NotificationsState extends Equatable {
  final List<AppNotification> items;
  const NotificationsState({this.items = const []});
  int get unreadCount => items.where((n) => !n.isRead).length;
  NotificationsState copyWith({List<AppNotification>? items}) =>
      NotificationsState(items: items ?? this.items);
  @override List<Object?> get props => [items];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(const NotificationsState());

  void loadNotifications() {
    if (state.items.isNotEmpty) return;
    emit(const NotificationsState(items: []));
  }

  /// Build notifications from real scan history — called by the screen
  /// when history data is available. No backend notification API needed.
  void syncFromHistory(List<ScanHistoryItem> history) {
    if (history.isEmpty) {
      emit(const NotificationsState(items: []));
      return;
    }
    final now = DateTime.now();
    final notifs = <AppNotification>[];
    for (final item in history.take(20)) {
      final isHigh = item.riskLevel == RiskLevel.high;
      final isFailed = item.status != 'completed';
      notifs.add(AppNotification(
        id: 'notif_${item.scanId}',
        type: isFailed
            ? NotificationType.scanFailed
            : isHigh
                ? NotificationType.scamAlert
                : NotificationType.scanCompleted,
        title: isFailed
            ? 'การสแกนล้มเหลว'
            : isHigh
                ? 'ตรวจพบความเสี่ยงสูง'
                : 'สแกนเสร็จสิ้น',
        body: isFailed
            ? 'รูป ${item.scanId.substring(0, 8)} ประมวลผลไม่สำเร็จ'
            : '${item.title ?? 'รูปภาพ'} — คะแนนความเสี่ยง ${item.riskScore}%',
        createdAt: item.createdAt.isAfter(now) ? now : item.createdAt,
        scanId: item.scanId,
      ));
    }
    notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    emit(NotificationsState(items: notifs));
  }

  void markAsRead(String id) {
    final updated = state.items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    emit(state.copyWith(items: updated));
  }

  void dismissNotification(String id) {
    final updated = state.items.where((n) => n.id != id).toList();
    emit(state.copyWith(items: updated));
  }

  void clearAll() => emit(const NotificationsState());
}
