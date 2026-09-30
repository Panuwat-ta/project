import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/risk_level_helper.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/adaptive_content.dart';
import '../../domain/entities/analysis_result.dart' as domain;
import '../../domain/entities/risk_factor.dart' as domain;
import '../../../history/presentation/bloc/history_bloc.dart';
import '../bloc/result_bloc.dart';

class AnalysisResultScreen extends StatefulWidget {
  const AnalysisResultScreen({super.key, required this.taskId, this.scanName});

  final String taskId;
  final String? scanName;

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ResultBloc>().add(ResultLoadRequested(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bool canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/main/home');
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        appBar: AppTopBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
            onPressed: () {
              if (canPop) {
                context.pop();
              } else {
                context.go('/main/home');
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.notifications_none,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),
        body: BlocBuilder<ResultBloc, ResultState>(
          builder: (context, state) {
            if (state is ResultLoading || state is ResultInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ResultError) {
              return Center(child: Text(state.message));
            }
            if (state is ResultLoaded) {
              return _ResultBody(
                result: state.result,
                isDark: isDark,
                scanName: widget.scanName,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.result,
    required this.isDark,
    this.scanName,
  });

  final domain.AnalysisResult result;
  final bool isDark;
  final String? scanName;

  @override
  Widget build(BuildContext context) {
    return AdaptiveContent(
      maxWidth: 840,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.safeMargin,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (scanName != null && scanName!.isNotEmpty) ...[
              Text(
                scanName!,
                textAlign: TextAlign.center,
                style: AppTypography.headlineLgMobile(
                  color: isDark ? Colors.white : AppColors.primary,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _buildVerdictHeader(context),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryCard(context),
            const SizedBox(height: AppSpacing.md),
            _buildEvidenceOverview(context),
            const SizedBox(height: AppSpacing.lg),
            _buildActionButtons(context),
            const SizedBox(height: AppSpacing.lg),
            _buildVisualAnomalyCard(context),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final riskColor = RiskLevelHelper.toColor(result.riskLevel);
    final riskLabel = RiskLevelHelper.toLabelKey(result.riskLevel).tr(context);

    return Semantics(
      label:
          '$riskLabel ${result.riskScore} ${'result_score_out_of_100'.tr(context)}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                RiskLevelHelper.toIcon(result.riskLevel),
                color: riskColor,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    riskLabel,
                    style: AppTypography.titleMd(color: scheme.onSurface),
                  ),
                  Text(
                    'result_risk_score'.tr(context),
                    style: AppTypography.caption(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${result.riskScore}/100',
              style: AppTypography.codeData(
                color: riskColor,
              ).copyWith(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: isDark ? AppColors.inverseSurface : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.inverseSurface
                  : AppColors.inverseOnSurface,
              borderRadius: AppRadius.smBorder,
            ),
            child: Icon(
              Icons.bar_chart,
              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'result_summary_title'.tr(context),
                  style: AppTypography.sectionHeader(
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  result.summary.isNotEmpty
                      ? result.summary
                      : 'result_summary_unavailable'.tr(context),
                  style: AppTypography.bodyBase(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  domain.RiskFactor? _factorFor(String type) {
    for (final factor in result.factors) {
      if (factor.type == type) return factor;
    }
    return null;
  }

  Widget _buildEvidenceOverview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'result_evidence_title'.tr(context),
            style: AppTypography.sectionHeader(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildEvidenceRow(
            context,
            label: 'result_evidence_visual'.tr(context),
            icon: Icons.image_search_outlined,
            factor: _factorFor('visual'),
          ),
          const Divider(height: AppSpacing.lg),
          _buildEvidenceRow(
            context,
            label: 'result_evidence_text'.tr(context),
            icon: Icons.text_snippet_outlined,
            factor: _factorFor('textual'),
          ),
          const Divider(height: AppSpacing.lg),
          _buildEvidenceRow(
            context,
            label: 'result_evidence_source'.tr(context),
            icon: Icons.travel_explore_outlined,
            factor: _factorFor('source'),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceRow(
    BuildContext context, {
    required String label,
    required IconData icon,
    required domain.RiskFactor? factor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    if (factor == null) {
      return Semantics(
        label: '$label: ${'result_evidence_unavailable'.tr(context)}',
        child: Row(
          children: [
            Icon(icon, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyBase(
                      color: scheme.onSurface,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'result_evidence_unavailable'.tr(context),
                    style: AppTypography.caption(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.remove_circle_outline, color: scheme.outline),
          ],
        ),
      );
    }

    final level = RiskLevelHelper.factorLevelForScore(factor.score);
    final scoreColor = RiskLevelHelper.toColor(level);
    final detail = factor.details.isNotEmpty
        ? factor.details.first
        : 'result_evidence_score_only'.tr(context);
    return Semantics(
      label: '$label ${factor.score} ${'result_score_out_of_100'.tr(context)}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scoreColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyBase(
                    color: scheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${factor.score}/100',
            style: AppTypography.codeData(
              color: scoreColor,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/detail/${result.taskId}'),
                icon: const Icon(Icons.visibility_outlined, size: 20),
                label: Text('result_details'.tr(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(
                  '/main/report',
                  extra: <String, dynamic>{
                    'scanId': result.scanId.isNotEmpty
                        ? result.scanId
                        : result.taskId,
                    if (result.imageUrl != null) 'imageUrl': result.imageUrl,
                  },
                ),
                icon: const Icon(Icons.flag_outlined, size: 20),
                label: Text('result_report_scam'.tr(context)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.danger.withValues(alpha: 0.5)
                        : AppColors.danger,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // ignore: deprecated_member_use
                  Share.share('result_share_text'.tr(context));
                },
                icon: const Icon(Icons.share_outlined, size: 20),
                label: Text('result_share'.tr(context)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.primaryFixedDim
                      : AppColors.primary,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.primaryFixedDim.withValues(alpha: 0.5)
                        : AppColors.primary,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
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
                          child: Text(
                            'delete'.tr(context),
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    final completer = Completer<bool>();
                    context.read<HistoryBloc>().add(
                      HistoryItemDeleted(result.taskId, completer),
                    );
                    final deleted = await completer.future;
                    if (!context.mounted) return;
                    if (deleted) {
                      context.go('/main/home');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('history_delete_failed'.tr(context)),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 20),
                label: Text('delete'.tr(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.dangerDarkSurface
                      : AppColors.dangerLightContainer,
                  foregroundColor: isDark
                      ? AppColors.dangerDarkForeground
                      : AppColors.danger,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/main/home'),
            icon: const Icon(Icons.photo_camera_outlined, size: 20),
            label: Text('result_check_another'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
              foregroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outlineVariant, width: 1.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              textStyle: AppTypography.buttonLabel(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualAnomalyCard(BuildContext context) {
    final visuals = result.factors.where((f) => f.type == 'visual');
    final visualFactor = visuals.isNotEmpty
        ? visuals.first
        : const domain.RiskFactor(
            type: 'visual',
            score: 0,
            title: '',
            details: [],
          );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: isDark ? AppColors.inverseSurface : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.image_search,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'visual_anomaly_title'.tr(context),
                        style: AppTypography.sectionHeader(
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Builder(
                builder: (_) {
                  final vLevel = RiskLevelHelper.factorLevelForScore(
                    visualFactor.score,
                  );
                  final vBg = RiskLevelHelper.toBgColor(vLevel, isDark: isDark);
                  final vFg = RiskLevelHelper.toTextColor(
                    vLevel,
                    isDark: isDark,
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: vBg,
                      borderRadius: AppRadius.smBorder,
                    ),
                    child: Text(
                      '${visualFactor.score}%',
                      style: AppTypography.caption(
                        color: vFg,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Evidence image preview
          GestureDetector(
            onTap:
                (result.imageUrl?.trim().isNotEmpty == true ||
                    result.heatmapUrl?.trim().isNotEmpty == true)
                ? () {
                    context.push(
                      '/heatmap/${result.taskId}',
                      extra: <String, dynamic>{
                        if (result.imageUrl != null)
                          'imageUrl': result.imageUrl,
                        if (result.heatmapUrl != null)
                          'heatmapUrl': result.heatmapUrl,
                      },
                    );
                  }
                : null,
            child: ClipRRect(
              borderRadius: AppRadius.lgBorder,
              child: Stack(
                children: [
                  // Image with offline cache support
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.slate900,
                    child:
                        (result.heatmapUrl != null || result.imageUrl != null)
                        ? CachedNetworkImage(
                            imageUrl: (result.heatmapUrl ?? result.imageUrl)!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white24,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'result_image_load_failed'.tr(context),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.white24,
                              size: 48,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Alerts from visual factor details
          if (visualFactor.details.isNotEmpty)
            ...visualFactor.details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAlertItem(
                  context: context,
                  icon: Icons.error,
                  iconColor: RiskLevelHelper.toColor(
                    RiskLevelHelper.factorLevelForScore(visualFactor.score),
                  ),
                  title: detail,
                  subtitle: '',
                  isDark: isDark,
                ),
              ),
            )
          else
            _buildAlertItem(
              context: context,
              icon: Icons.check_circle,
              iconColor: AppColors.success,
              title: 'result_no_visual_details'.tr(context),
              subtitle: '',
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyBase(
                  color: scheme.onSurface,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: AppTypography.caption(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
