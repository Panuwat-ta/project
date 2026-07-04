import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
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
      case NotificationType.scamAlert: return Icons.warning;
      case NotificationType.scanFailed: return Icons.error;
      case NotificationType.systemInfo: return Icons.info;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.scanCompleted: return AppColors.primaryFixedDim;
      case NotificationType.scamAlert: return AppColors.danger;
      case NotificationType.scanFailed: return AppColors.warning;
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
          title: Text('notif_title'.tr(context), style: AppTypography.sectionHeader(color: Theme.of(context).colorScheme.onSurface)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/main/scan');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => _cubit.clearAll(),
              child: Text('notif_clear_all'.tr(context),
                style: AppTypography.caption(color: AppColors.primaryFixedDim).copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        body: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return EmptyStateView(
                icon: Icons.notifications_off_outlined,
                title: 'notif_empty_title'.tr(context),
                subtitle: 'notif_empty_subtitle'.tr(context),
              );
            }
            
            final grouped = _groupNotifications(state.items, context);
            final groupKeys = grouped.keys.toList();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeMargin,
                vertical: AppSpacing.md,
              ),
              itemCount: groupKeys.length,
              itemBuilder: (context, index) {
                final key = groupKeys[index];
                final notifications = grouped[key]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                      child: Text(
                        key,
                        style: AppTypography.titleMd(
                          color: Theme.of(context).colorScheme.onSurface,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ...notifications.map((notification) {
                      final iconColor = _colorForType(notification.type);



                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Dismissible(
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
                          context.push('/result/${notification.scanId}');
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.15),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                                                    child: Text(
                                                      notification.title,
                                                      style: AppTypography.bodyBase(
                                                        color: notification.type == NotificationType.scamAlert
                                                            ? AppColors.danger
                                                            : (notification.isRead
                                                                ? (isDark ? AppColors.outlineVariant : AppColors.textSecondary)
                                                                : Theme.of(context).colorScheme.onSurface),
                                                      ).copyWith(
                                                        fontWeight: notification.isRead
                                                            ? FontWeight.w500
                                                            : FontWeight.w700,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _formatTimeRelative(notification.createdAt, context),
                                                    style: AppTypography.caption(
                                                      color: isDark ? AppColors.outlineVariant : AppColors.textSecondary,
                                                    ).copyWith(fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                notification.body,
                                                style: AppTypography.caption(color: isDark ? AppColors.outlineVariant : Colors.black87),
                                                maxLines: 2, 
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                    }).toList(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
  Map<String, List<AppNotification>> _groupNotifications(List<AppNotification> items, BuildContext context) {
    final Map<String, List<AppNotification>> groups = {};
    final now = DateTime.now();
    for (var item in items) {
      final date = item.createdAt;
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(date.year, date.month, date.day))
          .inDays;
      String key;
      if (diff == 0) {
        key = 'notif_today'.tr(context);
      } else if (diff == 1) {
        key = 'notif_yesterday'.tr(context);
      } else {
        key = 'notif_earlier'.tr(context);
      }
      
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(item);
    }
    return groups;
  }

  String _formatTimeRelative(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final isThai = context.read<SettingsCubit>().state.language == 'th';
    
    if (diff.inMinutes < 1) {
      return isThai ? 'เมื่อสักครู่' : 'Just now';
    } else if (diff.inMinutes < 60) {
      return isThai ? '${diff.inMinutes} นาทีที่แล้ว' : '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return isThai ? '${diff.inHours} ชั่วโมงที่แล้ว' : '${diff.inHours} hrs ago';
    } else {
      return _formatTime(date, context);
    }
  }

  String _formatTime(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final isThai = context.read<SettingsCubit>().state.language == 'th';
    final timeStr = DateFormat(isThai ? 'HH:mm น.' : 'HH:mm').format(date);
    
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
        
    if (diff == 0) {
      return timeStr;
    } else if (diff == 1) {
      return '${'notif_yesterday_time'.tr(context)} $timeStr';
    } else {
      final dateStr = DateFormat(isThai ? 'dd MMM yyyy' : 'MMM dd, yyyy').format(date);
      return '$dateStr $timeStr';
    }
  }
}
