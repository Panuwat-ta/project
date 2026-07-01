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
        title: 'วิเคราะห์เสร็จสิ้น',
        body: 'รูปภาพสลิปโอนเงินของคุณวิเคราะห์เสร็จแล้ว',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        scanId: 'mock_scan_001',
      ),
      AppNotification(
        id: 'n2',
        type: NotificationType.scamAlert,
        title: 'พบความเสี่ยงใหม่',
        body: 'Scam Alert: ระวังลิงก์ปลอมจาก SMS กู้เงินด่วน',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'n3',
        type: NotificationType.scanFailed,
        title: 'งานวิเคราะห์ล้มเหลว',
        body: 'ไม่สามารถประมวลผลรูปภาพได้ เนื่องจากขนาดไฟล์ใหญ่เกินไป',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
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
