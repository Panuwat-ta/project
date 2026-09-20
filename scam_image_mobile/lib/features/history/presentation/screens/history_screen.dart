import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart' as core_widgets;
import '../../../history/domain/entities/scan_history_item.dart';
import '../bloc/history_bloc.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedRiskLevel;

  @override
  void initState() {
    super.initState();
    // Trigger initial load using the globally-provided HistoryBloc.
    context.read<HistoryBloc>().add(const HistoryLoaded());
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<HistoryBloc>().add(
          HistorySearched(_searchController.text),
        );
      }
    });
  }

  void _showFilterDialog() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'filter'.tr(context),
                style: AppTypography.sectionHeader(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: 12),
            ...[
              (null, 'filter_all'),
              ('high', 'risk_high'),
              ('medium', 'risk_medium'),
              ('low', 'risk_low'),
            ].map(
              (e) => ListTile(
                title: Text(
                  e.$2.tr(context),
                  style: TextStyle(color: scheme.onSurface),
                ),
                trailing: _selectedRiskLevel == e.$1
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedRiskLevel = e.$1);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: core_widgets.AppTopBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
            ),
            tooltip: 'notifications'.tr(context),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: core_widgets.AdaptiveContent(
        maxWidth: 840,
        child: Column(
          children: [
            // ── Search + filter header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.safeMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with count badge
                  BlocBuilder<HistoryBloc, HistoryState>(
                    builder: (context, state) {
                      int count = 0;
                      if (state is HistoryDataLoaded) {
                        count = _selectedRiskLevel == null
                            ? state.items.length
                            : state.items
                                  .where(
                                    (it) =>
                                        it.riskLevel.name == _selectedRiskLevel,
                                  )
                                  .length;
                      }
                      return Row(
                        children: [
                          Flexible(
                            child: Text(
                              'history_title'.tr(context),
                              style: AppTypography.sectionHeader(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixedDim.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: Text(
                              '$count ${'items'.tr(context)}',
                              style: AppTypography.caption(
                                color: isDark
                                    ? AppColors.primaryFixedDim
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Search field + filter button
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _searchController,
                          style: TextStyle(color: scheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'search_history'.tr(context),
                            hintStyle: AppTypography.bodyBase(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_outlined,
                              color: AppColors.outlineVariant,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 20,
                                      color: AppColors.outlineVariant,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: scheme.surfaceContainerLowest,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.lgBorder,
                              borderSide: BorderSide(
                                color: scheme.outlineVariant,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.lgBorder,
                              borderSide: BorderSide(
                                color: scheme.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.lgBorder,
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Stack(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.tune,
                                  color: _selectedRiskLevel != null
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.primaryFixedDim
                                            : AppColors.primary),
                                ),
                                onPressed: _showFilterDialog,
                                tooltip: 'filter'.tr(context),
                              ),
                              if (_selectedRiskLevel != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── List area ────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<HistoryBloc, HistoryState>(
                builder: (context, state) {
                  if (state is HistoryLoading || state is HistoryInitial) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryFixedDim,
                      ),
                    );
                  }

                  if (state is HistoryEmpty) {
                    return core_widgets.EmptyStateView(
                      icon: Icons.history_toggle_off_outlined,
                      title: 'history_empty_title'.tr(context),
                      subtitle: 'history_empty_desc'.tr(context),
                    );
                  }

                  if (state is HistoryError) {
                    return core_widgets.ErrorStateView(
                      message: state.message,
                      onRetry: () => context.read<HistoryBloc>().add(
                        const HistoryLoaded(),
                      ),
                    );
                  }

                  if (state is HistoryDataLoaded) {
                    // Apply client-side risk filter if selected
                    final filtered = _selectedRiskLevel == null
                        ? state.items
                        : state.items
                              .where(
                                (it) => it.riskLevel.name == _selectedRiskLevel,
                              )
                              .toList();
                    if (filtered.isEmpty) {
                      return core_widgets.EmptyStateView(
                        icon: Icons.search_off_outlined,
                        title: 'history_no_results_title'.tr(context),
                        subtitle: _selectedRiskLevel != null
                            ? 'history_no_risk_results'.tr(context).replaceAll(
                                '{risk}',
                                switch (_selectedRiskLevel) {
                                  'high' => 'risk_high'.tr(context),
                                  'medium' => 'risk_medium'.tr(context),
                                  'low' => 'risk_low'.tr(context),
                                  _ => 'risk_unknown'.tr(context),
                                },
                              )
                            : 'history_no_search_results'.tr(context),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.primaryFixedDim,
                      onRefresh: () {
                        final completer = Completer<void>();
                        context.read<HistoryBloc>().add(
                          HistoryRefreshed(completer),
                        );
                        return completer.future.timeout(
                          const Duration(seconds: 5),
                          onTimeout: () {
                            if (!completer.isCompleted) {
                              completer.complete();
                            }
                          },
                        );
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.safeMargin,
                          0,
                          AppSpacing.safeMargin,
                          AppSpacing.xxl,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (context2, i) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Dismissible(
                            key: Key(item.scanId),
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
                                size: 28,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('delete_confirm'.tr(context)),
                                  content: Text('delete_desc'.tr(context)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text('cancel'.tr(context)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(
                                        'delete'.tr(context),
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !context.mounted) {
                                return false;
                              }
                              final completer = Completer<bool>();
                              context.read<HistoryBloc>().add(
                                HistoryItemDeleted(item.scanId, completer),
                              );
                              final deleted = await completer.future;
                              if (!deleted && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'history_delete_failed'.tr(context),
                                    ),
                                  ),
                                );
                              }
                              return deleted;
                            },
                            child: GestureDetector(
                              onTap: () =>
                                  context.push('/result/${item.scanId}'),
                              child: _HistoryCard(item: item),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final ScanHistoryItem item;

  String _formatDate(DateTime date, BuildContext context) {
    final isThai = context.read<SettingsCubit>().state.language == 'th';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = isThai ? date.year + 543 : date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute${isThai ? ' น.' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = _formatDate(item.createdAt, context);
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!
        : 'history_untitled'.tr(context);

    return Material(
      color: scheme.surface,
      borderRadius: AppRadius.lgBorder,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadius.mdBorder,
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: item.thumbnailUrl?.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              ColoredBox(color: scheme.surfaceContainerHighest),
                          errorWidget: (_, _, _) => ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sectionHeader(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      date,
                      style: AppTypography.caption(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        core_widgets.RiskBadge(riskLevel: item.riskLevel),
                        Text(
                          '${item.riskScore}/100',
                          style: AppTypography.codeData(
                            color: scheme.onSurface,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (item.status == 'completed')
                          Text(
                            'completed'.tr(context),
                            style: AppTypography.caption(
                              color: AppColors.success,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
