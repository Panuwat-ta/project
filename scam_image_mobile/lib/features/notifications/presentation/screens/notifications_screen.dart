import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Sync with real history data if already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyState = context.read<HistoryBloc>().state;
      if (historyState is HistoryDataLoaded) {
        context.read<NotificationsCubit>().syncFromHistory(historyState.items);
      } else if (historyState is HistoryEmpty) {
        context.read<NotificationsCubit>().loadNotifications();
      } else {
        // Trigger history load and listen for result
        context.read<HistoryBloc>().add(const HistoryLoaded());
      }
    });
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.scanCompleted:
        return Icons.check_circle;
      case NotificationType.scamAlert:
        return Icons.warning;
      case NotificationType.scanFailed:
        return Icons.error;
      case NotificationType.systemInfo:
        return Icons.info;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.scanCompleted:
        return AppColors.primaryFixedDim;
      case NotificationType.scamAlert:
        return AppColors.danger;
      case NotificationType.scanFailed:
        return AppColors.warning;
      case NotificationType.systemInfo:
        return AppColors.outlineVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'notif_title'.tr(context),
          style: AppTypography.sectionHeader(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/main/home');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationsCubit>().clearAll(),
            child: Text(
              'notif_clear_all'.tr(context),
              style: AppTypography.caption(
                color: AppColors.primaryFixedDim,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<HistoryBloc, HistoryState>(
            listener: (context, state) {
              if (state is HistoryDataLoaded) {
                context.read<NotificationsCubit>().syncFromHistory(state.items);
              } else if (state is HistoryEmpty) {
                context.read<NotificationsCubit>().loadNotifications();
              }
            },
          ),
        ],
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
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
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: AppSpacing.sm,
                      ),
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
                            padding: const EdgeInsets.only(
                              right: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.8),
                              borderRadius: AppRadius.lgBorder,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          onDismissed: (_) => context
                              .read<NotificationsCubit>()
                              .dismissNotification(notification.id),
                          child: GestureDetector(
                            onTap: () {
                              context.read<NotificationsCubit>().markAsRead(
                                notification.id,
                              );
                              if (notification.scanId != null) {
                                context.push('/result/${notification.scanId}');
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: AppRadius.lgBorder,
                                boxShadow: isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.03,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                border: Border.all(
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: AppRadius.lgBorder,
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Icon circle
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: iconColor.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  _iconForType(
                                                    notification.type,
                                                  ),
                                                  color: iconColor,
                                                  size: 24,
                                                  semanticLabel:
                                                      _notificationTitle(
                                                        notification,
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.md,
                                              ),
                                              // Content
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            _notificationTitle(
                                                              notification,
                                                              context,
                                                            ),
                                                            style:
                                                                AppTypography.bodyBase(
                                                                  color:
                                                                      notification
                                                                              .type ==
                                                                          NotificationType
                                                                              .scamAlert
                                                                      ? AppColors
                                                                            .danger
                                                                      : (notification.isRead
                                                                            ? Theme.of(
                                                                                context,
                                                                              ).colorScheme.onSurfaceVariant
                                                                            : Theme.of(
                                                                                context,
                                                                              ).colorScheme.onSurface),
                                                                ).copyWith(
                                                                  fontWeight:
                                                                      notification
                                                                          .isRead
                                                                      ? FontWeight
                                                                            .w500
                                                                      : FontWeight
                                                                            .w700,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          _formatTimeRelative(
                                                            notification
                                                                .createdAt,
                                                            context,
                                                          ),
                                                          style: AppTypography.caption(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ).copyWith(fontSize: 11),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _notificationBody(
                                                        notification,
                                                        context,
                                                      ),
                                                      style: AppTypography.caption(
                                                        color: isDark
                                                            ? AppColors
                                                                  .outlineVariant
                                                            : Colors.black87,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                    }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _notificationTitle(
    AppNotification notification,
    BuildContext context,
  ) {
    return notification.title.tr(context);
  }

  String _notificationBody(AppNotification notification, BuildContext context) {
    if (notification.type == NotificationType.scanFailed &&
        notification.title == 'notif_scan_failed_title') {
      return 'notif_scan_failed_body'
          .tr(context)
          .replaceAll('{id}', notification.body);
    }
    if ((notification.type == NotificationType.scanCompleted ||
            notification.type == NotificationType.scamAlert) &&
        notification.riskScore != null &&
        notification.title.startsWith('notif_')) {
      final subject = notification.body.trim().isEmpty
          ? 'notif_image_default'.tr(context)
          : notification.body;
      return 'notif_scan_score_body'
          .tr(context)
          .replaceAll('{title}', subject)
          .replaceAll('{score}', '${notification.riskScore}');
    }
    return notification.body.tr(context);
  }

  Map<String, List<AppNotification>> _groupNotifications(
    List<AppNotification> items,
    BuildContext context,
  ) {
    final Map<String, List<AppNotification>> groups = {};
    final now = DateTime.now();
    for (var item in items) {
      final date = item.createdAt;
      final diff = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(date.year, date.month, date.day)).inDays;
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
    if (diff.inMinutes < 1) {
      return 'notif_just_now'.tr(context);
    } else if (diff.inMinutes < 60) {
      return 'notif_minutes_ago'
          .tr(context)
          .replaceAll('{count}', '${diff.inMinutes}');
    } else if (diff.inHours < 24) {
      return 'notif_hours_ago'
          .tr(context)
          .replaceAll('{count}', '${diff.inHours}');
    } else {
      return _formatTime(date, context);
    }
  }

  String _formatTime(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final isThai = context.read<SettingsCubit>().state.language == 'th';
    final timeStr =
        '${DateFormat('HH:mm').format(date)}${'notif_time_suffix'.tr(context)}';

    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(date.year, date.month, date.day)).inDays;

    if (diff == 0) {
      return timeStr;
    } else if (diff == 1) {
      return '${'notif_yesterday_time'.tr(context)} $timeStr';
    } else {
      final dateStr = DateFormat(
        isThai ? 'dd MMM yyyy' : 'MMM dd, yyyy',
      ).format(date);
      return '$dateStr $timeStr';
    }
  }
}
