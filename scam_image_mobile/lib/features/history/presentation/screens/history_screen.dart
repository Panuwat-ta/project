import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart' as core_widgets;
import '../../../history/domain/entities/scan_history_item.dart';
import '../../../result/domain/entities/analysis_result.dart' as domain;
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

  @override
  void initState() {
    super.initState();
    // Trigger initial load using the globally-provided HistoryBloc.
    context.read<HistoryBloc>().add(const HistoryLoaded());
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<HistoryBloc>().add(HistorySearched(_searchController.text));
    });
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
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141921) : const Color(0xFFF5F6F8),
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
        body: Column(
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
                      final count =
                          state is HistoryDataLoaded ? state.items.length : 0;
                      return Row(
                        children: [
                          Flexible(
                            child: Text(
                              'history_title'.tr(context),
                              style: AppTypography.sectionHeader(
                                  color: isDark ? Colors.white : AppColors.onSurface),
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
                              color: AppColors.primaryFixedDim
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '$count ${'items'.tr(context)}',
                              style: AppTypography.caption(
                                  color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
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
                          style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: InputDecoration(
                            hintText: 'search_history'.tr(context),
                            hintStyle: AppTypography.bodyBase(
                              color: AppColors.outlineVariant
                                  .withValues(alpha: 0.6),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_outlined,
                              color: AppColors.outlineVariant,
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF141921) : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
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
                            color: isDark ? const Color(0xFF141921) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.tune,
                              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                            ),
                            onPressed: () {}, // Filter dialog — future feature
                            tooltip: 'filter'.tr(context),
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
                      onRetry: () => context.read<HistoryBloc>().add(const HistoryLoaded()),
                    );
                  }

                  if (state is HistoryDataLoaded) {
                    return RefreshIndicator(
                      color: AppColors.primaryFixedDim,
                      onRefresh: () async {
                        context.read<HistoryBloc>().add(const HistoryRefreshed());
                        await context.read<HistoryBloc>().stream.firstWhere(
                          (s) => s is! HistoryLoading,
                        );
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.safeMargin,
                          0,
                          AppSpacing.safeMargin,
                          AppSpacing.xxl,
                        ),
                        itemCount: state.items.length,
                        separatorBuilder: (context2, i) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return Dismissible(
                            key: Key(item.scanId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(
                                  right: AppSpacing.lg),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.danger.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) =>
                                context.read<HistoryBloc>().add(HistoryItemDeleted(item.scanId)),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('delete_confirm'.tr(context)),
                                  content: Text('delete_desc'.tr(context)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('cancel'.tr(context)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('delete'.tr(context), style: const TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
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
      );
  }
}

// ── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final ScanHistoryItem item;

  String _formatThaiDate(DateTime date, BuildContext context) {
    const thaiMonths = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final year = date.year > 2500 ? date.year : date.year + 543;
    final month = thaiMonths[date.month];
    final day = date.day.toString();
    final hours = date.hour.toString().padLeft(2, '0');
    final mins = date.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hours:$mins ${context.read<SettingsCubit>().state.language == 'th' ? 'น.' : ''}';
  }

  Widget _buildRiskBadge(BuildContext context, domain.RiskLevel level, int score) {
    Color bgColor;
    IconData icon;
    String label;
    
    switch (level) {
      case domain.RiskLevel.high:
        bgColor = const Color(0xFFDC2626); // red-600
        icon = Icons.warning_amber_rounded;
        label = 'high_risk'.tr(context);
        break;
      case domain.RiskLevel.medium:
        bgColor = const Color(0xFFD97706); // amber-600
        icon = Icons.info_outline;
        label = 'suspicious'.tr(context);
        break;
      case domain.RiskLevel.low:
        bgColor = const Color(0xFF16A34A); // green-600
        icon = Icons.check_circle_outline;
        label = 'safe'.tr(context);
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '$label ($score%)',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  List<String> _getMockTags(BuildContext context, domain.RiskLevel level) {
    if (level == domain.RiskLevel.high) {
      return ['pixel_edge'.tr(context), 'metadata_conflict'.tr(context)];
    } else if (level == domain.RiskLevel.medium) {
      return ['light_filter'.tr(context)];
    } else {
      return ['original_file'.tr(context)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = _formatThaiDate(item.createdAt, context);
    final tags = _getMockTags(context, item.riskLevel);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image Section ──
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: item.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          errorWidget: (ctx, url, err) => Container(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            child: const Icon(Icons.image_outlined, color: Colors.grey, size: 48),
                          ),
                        )
                      : Container(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          child: const Icon(Icons.image_outlined, color: Colors.grey, size: 48),
                        ),
                ),
              ),
              // Risk Badge Overlay
              Positioned(
                top: 12,
                left: 12,
                child: _buildRiskBadge(context, item.riskLevel, item.riskScore),
              ),
            ],
          ),
          
          // ── Content Section ──
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title ?? item.scanId,
                        style: AppTypography.titleMd(color: isDark ? Colors.white : AppColors.textPrimary)
                            .copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black38, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.white54 : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: AppTypography.bodyBase(color: isDark ? Colors.white54 : AppColors.textSecondary)
                          .copyWith(fontSize: 13),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                const SizedBox(height: 12),
                
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7).withValues(alpha: isDark ? 0.1 : 1.0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status == 'completed' ? 'completed'.tr(context) : item.status,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

