import 'package:equatable/equatable.dart';

enum NotificationType { scanCompleted, scanFailed, scamAlert, systemInfo }

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? scanId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.scanId,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id, type: type, title: title, body: body,
    createdAt: createdAt, isRead: isRead ?? this.isRead, scanId: scanId,
  );

  @override
  List<Object?> get props => [id, type, title, body, createdAt, isRead, scanId];
}
