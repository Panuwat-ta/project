import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart' as core_widgets;
import '../../../history/domain/entities/scan_history_item.dart';
import '../../../result/domain/entities/analysis_result.dart' as domain;
import '../bloc/history_bloc.dart';

/// Maps a domain [domain.RiskLevel] to the widget-layer [core_widgets.RiskLevel].
core_widgets.RiskLevel _toWidgetLevel(domain.RiskLevel l) {
  switch (l) {
    case domain.RiskLevel.high:
      return core_widgets.RiskLevel.high;
    case domain.RiskLevel.medium:
      return core_widgets.RiskLevel.medium;
    case domain.RiskLevel.low:
      return core_widgets.RiskLevel.low;
  }
}

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
            tooltip: 'การแจ้งเตือน',
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
                              'ประวัติการตรวจสอบ',
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
                              '$count รายการ',
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
                            hintText: 'ค้นหาประวัติ...',
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
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                            borderRadius: BorderRadius.circular(12),
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
                            tooltip: 'กรองผลลัพธ์',
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
                      title: 'ยังไม่มีประวัติการตรวจสอบ',
                      subtitle: 'เริ่มสแกนรูปภาพแรกของคุณเพื่อความปลอดภัย',
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
                                borderRadius: BorderRadius.circular(12),
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
                                  title: const Text('ยืนยันการลบ'),
                                  content: const Text('คุณต้องการลบประวัตินี้ใช่หรือไม่?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('ยกเลิก'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('ลบ', style: TextStyle(color: Colors.red)),
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

  Color _riskColor(domain.RiskLevel level) {
    switch (level) {
      case domain.RiskLevel.high:
        return AppColors.danger;
      case domain.RiskLevel.medium:
        return AppColors.warning;
      case domain.RiskLevel.low:
        return AppColors.success;
    }
  }

  String _formatThaiDate(DateTime date) {
    const thaiMonths = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final year = date.year > 2500 ? date.year : date.year + 543;
    final month = thaiMonths[date.month];
    final day = date.day.toString().padLeft(2, '0');
    final hours = date.hour.toString().padLeft(2, '0');
    final mins = date.minute.toString().padLeft(2, '0');
    return '$day $month $year • $hours:$mins';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final widgetLevel = _toWidgetLevel(item.riskLevel);
    final riskColor = _riskColor(item.riskLevel);
    final dateStr = _formatThaiDate(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B222C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail 80×80
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 80,
              child: item.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) =>
                          Container(color: AppColors.inverseSurface),
                      errorWidget: (ctx, url, err) => Container(
                        color: AppColors.inverseSurface,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.inverseSurface,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.outlineVariant,
                      ),
                    ),
            ),
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
                      child: Text(
                        item.title ?? item.scanId,
                        style:
                            AppTypography.sectionHeader(color: isDark ? Colors.white : AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    core_widgets.RiskBadge(riskLevel: widgetLevel),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.outlineVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        dateStr,
                        style: AppTypography.caption(
                            color: AppColors.outlineVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Progress bar with score
                Row(
                  children: [
                    Expanded(
                      child:
                          core_widgets.RiskProgressBar(score: item.riskScore),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${item.riskScore}%',
                      style: AppTypography.codeData(color: riskColor)
                          .copyWith(fontWeight: FontWeight.w700),
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
