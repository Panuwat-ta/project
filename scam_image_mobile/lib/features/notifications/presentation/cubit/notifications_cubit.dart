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
    // TODO: Fetch real notifications from API when available
    emit(const NotificationsState(items: []));
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
