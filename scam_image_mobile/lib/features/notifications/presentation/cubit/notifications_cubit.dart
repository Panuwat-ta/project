import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_notification.dart';

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
    emit(NotificationsState(items: [
      AppNotification(
        id: 'n1',
        type: NotificationType.scanCompleted,
        title: 'การวิเคราะห์เสร็จสิ้น',
        body: 'รูปภาพของคุณถูกวิเคราะห์แล้ว คะแนนความเสี่ยง: 82%',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        scanId: 'mock_scan_001',
      ),
      AppNotification(
        id: 'n2',
        type: NotificationType.scamAlert,
        title: '⚠️ Scam Alert ใหม่',
        body: 'พบรูปแบบการหลอกลวงใหม่ระบาดใน LINE กลุ่ม',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n3',
        type: NotificationType.systemInfo,
        title: 'คำแนะนำความปลอดภัย',
        body: 'อย่าโอนเงินให้บัญชีที่ไม่รู้จักโดยไม่ตรวจสอบ',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      AppNotification(
        id: 'n4',
        type: NotificationType.scanFailed,
        title: 'การวิเคราะห์ล้มเหลว',
        body: 'ไม่สามารถวิเคราะห์รูปภาพได้ กรุณาลองใหม่',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ]));
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
