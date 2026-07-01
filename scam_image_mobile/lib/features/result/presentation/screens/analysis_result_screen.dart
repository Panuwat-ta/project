import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart' as core_widgets;
import '../../domain/entities/analysis_result.dart' as domain;
import '../../domain/entities/risk_factor.dart';
import '../bloc/result_bloc.dart';

// Convenience alias: domain RiskLevel → widget RiskLevel
core_widgets.RiskLevel _toWidgetRiskLevel(domain.RiskLevel level) {
  switch (level) {
    case domain.RiskLevel.low:
      return core_widgets.RiskLevel.low;
    case domain.RiskLevel.medium:
      return core_widgets.RiskLevel.medium;
    case domain.RiskLevel.high:
      return core_widgets.RiskLevel.high;
  }
}

/// Analysis Result Screen — shows risk gauge, summary, bento grid, and action
/// buttons for a completed scan identified by [taskId].
class AnalysisResultScreen extends StatefulWidget {
  const AnalysisResultScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch load event to the globally-provided ResultBloc.
    context.read<ResultBloc>().add(ResultLoadRequested(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: const core_widgets.AppTopBar(automaticallyImplyLeading: true),
      body: BlocBuilder<ResultBloc, ResultState>(
        builder: (context, state) {
          if (state is ResultLoading || state is ResultInitial) {
            return const core_widgets.LoadingOverlay(
              message: 'กำลังโหลดผลวิเคราะห์...',
            );
          }
          if (state is ResultError) {
            return core_widgets.ErrorStateView(
              message: state.message,
              onRetry: () =>
                  context.read<ResultBloc>().add(ResultLoadRequested(widget.taskId)),
            );
          }
          if (state is ResultLoaded) {
            return _ResultBody(result: state.result);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});

  final domain.AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.safeMargin,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Risk Gauge Section
          _RiskGaugeSection(result: result),
          const SizedBox(height: AppSpacing.lg),

          // 2. Summary Card
          _SummaryCard(summary: result.summary),
          const SizedBox(height: AppSpacing.lg),

          // 3. Analysis Bento Grid
          _BentoGrid(result: result),
          const SizedBox(height: AppSpacing.lg),

          // 4. Action Buttons
          _ActionButtons(result: result),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── Risk Gauge Section ─────────────────────────────────────────────────────

class _RiskGaugeSection extends StatelessWidget {
  const _RiskGaugeSection({required this.result});

  final domain.AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final widgetLevel = _toWidgetRiskLevel(result.riskLevel);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        core_widgets.RiskGauge(score: result.riskScore),
        const SizedBox(height: AppSpacing.sm),
        core_widgets.RiskBadge(riskLevel: widgetLevel),
      ],
    );
  }
}

// ── Summary Card ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: AppColors.primaryFixedDim,
            size: 40,
            semanticLabel: 'ผลการวิเคราะห์',
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สรุปผลการวิเคราะห์',
                  style: AppTypography.sectionHeader(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  summary,
                  style: AppTypography.bodyBase(
                    color: AppColors.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Analysis Bento Grid ────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  const _BentoGrid({required this.result});

  final domain.AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final textualFactor = _factorByType(result.factors, 'textual');
    final sourceFactor = _factorByType(result.factors, 'source');

    return Column(
      children: [
        // Top row: 2 equal columns
        Row(
          children: [
            Expanded(
              child: _BentoCard(
                icon: Icons.contact_mail_outlined,
                caption: 'ข้อมูลติดต่อ',
                valueText: textualFactor != null ? 'น่าสงสัย' : 'ปกติ',
                valueColor: textualFactor != null
                    ? AppColors.danger
                    : AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _BentoCard(
                icon: Icons.account_balance_wallet_outlined,
                caption: 'ธุรกรรม',
                valueText: sourceFactor != null
                    ? 'ความเสี่ยง ${sourceFactor.score}%'
                    : 'ปกติ',
                valueColor: _riskColor(sourceFactor?.score ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Full-width: Heatmap preview card
        _HeatmapBentoCard(result: result),
      ],
    );
  }

  static RiskFactor? _factorByType(List<RiskFactor> factors, String type) {
    try {
      return factors.firstWhere((f) => f.type == type);
    } catch (_) {
      return null;
    }
  }

  static Color _riskColor(int score) {
    if (score < 40) return AppColors.success;
    if (score < 70) return AppColors.warning;
    return AppColors.danger;
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.icon,
    required this.caption,
    required this.valueText,
    required this.valueColor,
  });

  final IconData icon;
  final String caption;
  final String valueText;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryFixedDim, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            caption,
            style: AppTypography.caption(color: AppColors.outlineVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            valueText,
            style: AppTypography.sectionHeader(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _HeatmapBentoCard extends StatelessWidget {
  const _HeatmapBentoCard({required this.result});

  final domain.AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(
          '/heatmap/${result.taskId}',
          extra: <String, dynamic>{
            if (result.imageUrl != null) 'imageUrl': result.imageUrl,
            if (result.heatmapUrl != null) 'heatmapUrl': result.heatmapUrl,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.grain,
              color: AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visual Heatmap',
                    style: AppTypography.sectionHeader(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'แสดงพื้นที่ที่ระบบ AI ตรวจพบความผิดปกติ',
                    style: AppTypography.caption(
                      color: AppColors.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryFixedDim.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'พร้อมดู',
                style: AppTypography.caption(
                  color: AppColors.primaryFixedDim,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Buttons ─────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.result});

  final domain.AnalysisResult result;

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailBottomSheet(factors: result.factors),
    );
  }

  Future<void> _shareResult(BuildContext context) async {
    final riskLabel = result.riskLevel == domain.RiskLevel.high
        ? 'สูง'
        : result.riskLevel == domain.RiskLevel.medium
            ? 'ปานกลาง'
            : 'ต่ำ';

    final text = '🛡️ ScamGuard — ผลการตรวจสอบรูปภาพ\n\n'
        'คะแนนความเสี่ยง: ${result.riskScore}/100 (ระดับ$riskLabel)\n\n'
        '${result.summary}\n\n'
        'ตรวจสอบด้วย ScamGuard แอปตรวจสอบรูปภาพต้องสงสัย';

    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text,
      subject: 'ผลการตรวจสอบรูปภาพจาก ScamGuard',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1
        Row(
          children: [
            Expanded(
              child: core_widgets.PrimaryButton(
                label: 'ดูรายละเอียด',
                leadingIcon: const Icon(Icons.visibility_outlined, size: 18),
                onPressed: () => _showDetailSheet(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.grid_view_outlined, size: 18),
                label: const Text('ดู Heatmap'),
                onPressed: () => context.go('/heatmap/${result.taskId}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: const StadiumBorder(),
                  elevation: 0,
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Row 2
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('รายงานภาพต้องสงสัย'),
                onPressed: () => context.go('/main/report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size(0, 52),
                  shape: const StadiumBorder(),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('แชร์ผลลัพธ์'),
                onPressed: () => _shareResult(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryFixedDim,
                  side: const BorderSide(color: AppColors.primaryFixedDim),
                  minimumSize: const Size(0, 52),
                  shape: const StadiumBorder(),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Detail Bottom Sheet ────────────────────────────────────────────────────

class _DetailBottomSheet extends StatelessWidget {
  const _DetailBottomSheet({required this.factors});

  final List<RiskFactor> factors;

  static String _titleForType(String type) {
    switch (type) {
      case 'textual':
        return 'การวิเคราะห์ข้อความ';
      case 'source':
        return 'การตรวจสอบแหล่งที่มา';
      case 'visual':
        return 'การวิเคราะห์ภาพ';
      default:
        return type;
    }
  }

  static Color _colorForScore(int score) {
    if (score < 40) return AppColors.success;
    if (score < 70) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.safeMargin,
              vertical: AppSpacing.md,
            ),
            child: Text(
              'รายละเอียดการวิเคราะห์',
              style: AppTypography.sectionHeader(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.safeMargin,
                vertical: AppSpacing.sm,
              ),
              itemCount: factors.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, index) {
                final factor = factors[index];
                final color = _colorForScore(factor.score);
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.inverseSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type label + score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _titleForType(factor.type),
                            style: AppTypography.caption(
                              color: AppColors.outlineVariant,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${factor.score}%',
                            style: AppTypography.codeData(color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        factor.title,
                        style:
                            AppTypography.bodyBase(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Score bar
                      core_widgets.RiskProgressBar(score: factor.score),
                      const SizedBox(height: AppSpacing.sm),
                      // Details list
                      ...factor.details.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: color,
                                semanticLabel: '',
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  d,
                                  style: AppTypography.caption(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
