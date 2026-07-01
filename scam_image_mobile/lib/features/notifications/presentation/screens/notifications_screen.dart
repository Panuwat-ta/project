import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = NotificationsCubit();
    _cubit.loadNotifications();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.scanCompleted: return Icons.check_circle;
      case NotificationType.scanFailed: return Icons.error;
      case NotificationType.scamAlert: return Icons.warning;
      case NotificationType.systemInfo: return Icons.info;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.scanCompleted: return AppColors.primaryFixedDim;
      case NotificationType.scanFailed: return AppColors.danger;
      case NotificationType.scamAlert: return AppColors.warning;
      case NotificationType.systemInfo: return AppColors.outlineVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('การแจ้งเตือน', style: AppTypography.sectionHeader(color: Theme.of(context).colorScheme.onSurface)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
          actions: [
            TextButton(
              onPressed: () => _cubit.clearAll(),
              child: Text('ล้างการแจ้งเตือนทั้งหมด',
                style: AppTypography.caption(color: AppColors.primaryFixedDim).copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        body: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return EmptyStateView(
                icon: Icons.notifications_off_outlined,
                title: 'ไม่มีการแจ้งเตือน',
                subtitle: 'การแจ้งเตือนใหม่จะปรากฏที่นี่',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeMargin,
                vertical: AppSpacing.md,
              ),
              itemCount: state.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final notification = state.items[index];
                final iconColor = _colorForType(notification.type);


                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                  ),
                  onDismissed: (_) => _cubit.dismissNotification(notification.id),
                  child: GestureDetector(
                    onTap: () {
                      _cubit.markAsRead(notification.id);
                      if (notification.scanId != null) {
                        context.go('/result/${notification.scanId}');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isDark ? null : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border(
                          left: BorderSide(
                            color: !notification.isRead ? AppColors.danger : Colors.transparent,
                            width: 4,
                          ),
                          top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
                          right: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
                          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon circle
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_iconForType(notification.type),
                              color: iconColor, size: 24,
                              semanticLabel: notification.title),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(notification.title,
                                        style: AppTypography.bodyBase(
                                          color: notification.isRead
                                              ? AppColors.outlineVariant
                                              : Theme.of(context).colorScheme.onSurface,
                                        ).copyWith(
                                          fontWeight: notification.isRead
                                              ? FontWeight.w400
                                              : FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    ),
                                    Text(_getTimeAgo(notification.createdAt),
                                      style: AppTypography.caption(
                                        color: AppColors.outlineVariant).copyWith(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(notification.body,
                                  style: AppTypography.caption(color: AppColors.outlineVariant),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes > 0 ? diff.inMinutes : 1} นาทีที่แล้ว';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} วันที่แล้ว';
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }
}
