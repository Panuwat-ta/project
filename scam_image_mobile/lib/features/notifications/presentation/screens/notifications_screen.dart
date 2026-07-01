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
      case NotificationType.scanCompleted: return Icons.analytics_outlined;
      case NotificationType.scanFailed: return Icons.error_outline;
      case NotificationType.scamAlert: return Icons.warning_amber_outlined;
      case NotificationType.systemInfo: return Icons.campaign_outlined;
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
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          title: Text('การแจ้งเตือน', style: AppTypography.sectionHeader(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            TextButton(
              onPressed: () => _cubit.clearAll(),
              child: Text('ล้างทั้งหมด',
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
                final timeStr = DateFormat('dd MMM • HH:mm').format(notification.createdAt);

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
                        color: notification.isRead
                            ? AppColors.surfaceDark
                            : AppColors.inverseSurface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: notification.isRead
                              ? AppColors.outlineVariant.withValues(alpha: 0.15)
                              : AppColors.primaryFixedDim.withValues(alpha: 0.2),
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
                              color: iconColor, size: 22,
                              semanticLabel: notification.title),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(notification.title,
                                        style: AppTypography.bodyBase(
                                          color: notification.isRead
                                              ? AppColors.outlineVariant
                                              : Colors.white,
                                        ).copyWith(
                                          fontWeight: notification.isRead
                                              ? FontWeight.w400
                                              : FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8, height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryFixedDim,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(notification.body,
                                  style: AppTypography.caption(color: AppColors.outlineVariant),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: AppSpacing.xs),
                                Text(timeStr,
                                  style: AppTypography.caption(
                                    color: AppColors.outline).copyWith(fontSize: 11)),
                              ],
                            ),
                          ),
                          if (notification.scanId != null)
                            Icon(Icons.chevron_right, color: AppColors.outlineVariant, size: 18),
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
}
