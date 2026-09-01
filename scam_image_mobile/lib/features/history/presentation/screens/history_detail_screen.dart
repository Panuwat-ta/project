import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/di/injection_container.dart';
import '../../../result/presentation/bloc/result_bloc.dart';
import '../../../result/domain/entities/analysis_result.dart';
import '../../../result/domain/entities/risk_factor.dart';
import 'package:intl/intl.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.scanId});

  final String scanId;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late final ResultBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ResultBloc(repository: ServiceLocator.resultRepository);
    _bloc.add(ResultLoadRequested(widget.scanId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F8FB),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F8FB),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'result_scan_details'.tr(context),
            style: AppTypography.sectionHeader(
                color: isDark ? Colors.white : AppColors.primary),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.share_outlined, color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
              onPressed: () {
                // ignore: deprecated_member_use
                Share.share('result_share_text'.tr(context));
              },
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
              final result = state.result;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.safeMargin, vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverallRisk(isDark, result),
                    const SizedBox(height: AppSpacing.md),
                    _buildOcrCard(isDark, result),
                    const SizedBox(height: AppSpacing.md),
                    _buildSourceCard(isDark, result),
                    const SizedBox(height: AppSpacing.md),
                    _buildImageAnomalyCard(isDark, result),
                    const SizedBox(height: AppSpacing.xl),
                    _buildActionButtons(context, isDark),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162230) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1))
            : Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildPill(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        text,
        style: AppTypography.caption(color: textColor).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildOverallRisk(bool isDark, AnalysisResult result) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'result_overall_risk'.tr(context),
                      style: AppTypography.titleMd(
                          color: isDark ? Colors.white : AppColors.onSurface),
                    ),
                    Text(
                      result.summary,
                      style: AppTypography.caption(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildRiskLevelPill(result.riskLevel, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getRiskColor(result.riskLevel),
                width: 8,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${result.riskScore}%',
                    style: AppTypography.displayHero(
                            color: isDark ? Colors.white : _getRiskColor(result.riskLevel))
                        .copyWith(fontSize: 36, height: 1.1),
                  ),
                  Text(
                    'Scam Score',
                    style: AppTypography.caption(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildOcrCard(bool isDark, AnalysisResult result) {
    final texts = result.factors.where((f) => f.type == 'textual');
    final textFactor = texts.isNotEmpty ? texts.first : const RiskFactor(type: 'textual', score: 0, title: '', details: []);
    final ocrText = textFactor.details.isNotEmpty ? textFactor.details.join(', ') : 'ไม่พบข้อความอันตราย';
    
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.description_outlined,
                        color: isDark ? AppColors.primaryFixedDim : AppColors.primary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'result_ocr'.tr(context),
                        style: AppTypography.sectionHeader(
                            color: isDark ? Colors.white : AppColors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildScorePill(textFactor.score, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27313C) : const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'result_text_detected'.tr(context),
                  style: AppTypography.caption(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ocrText,
                  style: AppTypography.bodyBase(
                      color: isDark ? Colors.white : AppColors.onSurface).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'result_suspicious_words'.tr(context),
                style: AppTypography.caption(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'result_accuracy'.tr(context),
                    style: AppTypography.caption(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '${textFactor.score}% Match',
                    style: AppTypography.codeData(
                        color: isDark ? Colors.white : AppColors.onSurface),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: textFactor.details.isNotEmpty 
                ? textFactor.details.map((word) => _buildSuspiciousChip(word, isDark)).toList()
                : [Text('ไม่มีข้อความอันตราย', style: AppTypography.caption(color: AppColors.textSecondary))],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: AppColors.border.withValues(alpha: isDark ? 0.2 : 1)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'result_ocr_analysis_desc'.tr(context),
            style: AppTypography.bodyBase(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspiciousChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF4A1818) : Colors.white,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: isDark ? const Color(0xFFFFB4B4) : AppColors.danger),
      ),
    );
  }

  Widget _buildSourceCard(bool isDark, AnalysisResult result) {
    final sources = result.factors.where((f) => f.type == 'source');
    final sourceFactor = sources.isNotEmpty ? sources.first : const RiskFactor(type: 'source', score: 0, title: '', details: []);
    
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.manage_search_outlined,
                        color: isDark ? AppColors.primaryFixedDim : AppColors.primary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'result_source_check'.tr(context),
                        style: AppTypography.sectionHeader(
                            color: isDark ? Colors.white : AppColors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildScorePill(sourceFactor.score, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border.withValues(alpha: isDark ? 0.2 : 1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'result_first_detected'.tr(context),
                      style: AppTypography.caption(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(result.createdAt),
                      style: AppTypography.bodyBase(
                          color: isDark ? Colors.white : AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'result_recurring'.tr(context),
                      style: AppTypography.caption(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      sourceFactor.details.isNotEmpty ? sourceFactor.details.join(', ') : '1 ครั้ง',
                      style: AppTypography.bodyBase(
                          color: isDark ? Colors.white : AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }


  Widget _buildImageAnomalyCard(bool isDark, AnalysisResult result) {
    final visuals = result.factors.where((f) => f.type == 'visual');
    final visualFactor = visuals.isNotEmpty ? visuals.first : const RiskFactor(type: 'visual', score: 0, title: '', details: []);
    
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined,
                        color: isDark ? AppColors.primaryFixedDim : AppColors.primary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'result_visual_analysis'.tr(context),
                        style: AppTypography.sectionHeader(
                            color: isDark ? Colors.white : AppColors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildScorePill(visualFactor.score, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF1E293B),
                ),
                child: Stack(
                  children: [
                    if (result.heatmapUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '${ServiceLocator.dio.options.baseUrl}${result.heatmapUrl}',
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.image, color: Colors.white54, size: 40),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildPill(
                        'HEATMAP',
                        const Color(0xFF7CF994),
                        const Color(0xFF006E2D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Generated Prob.',
                      style: AppTypography.caption(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${visualFactor.score}%',
                      style: AppTypography.titleMd(color: AppColors.danger),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Anomaly Score',
                      style: AppTypography.caption(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${visualFactor.score / 100}',
                      style: AppTypography.titleMd(
                          color: isDark ? Colors.white : AppColors.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27313C) : const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'result_xai'.tr(context),
                  style: AppTypography.bodyBase(
                      color: isDark ? Colors.white : AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'result_xai_desc'.tr(context),
                  style: AppTypography.caption(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return AppColors.danger;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.low:
        return AppColors.primary;
      case RiskLevel.safe:
        return AppColors.success;
    }
  }

  Widget _buildRiskLevelPill(RiskLevel level, bool isDark) {
    final String text;
    final Color bgColor;
    final Color textColor;
    
    switch (level) {
      case RiskLevel.high:
        text = 'result_high_risk'.tr(context);
        bgColor = isDark ? const Color(0xFF4A1818) : const Color(0xFFFFEBEB);
        textColor = isDark ? const Color(0xFFFFB4B4) : AppColors.danger;
        break;
      case RiskLevel.medium:
        text = 'result_medium'.tr(context);
        bgColor = isDark ? const Color(0xFF4A3818) : const Color(0xFFFFF4E5);
        textColor = isDark ? const Color(0xFFFFD494) : AppColors.warning;
        break;
      case RiskLevel.low:
        text = 'result_low'.tr(context);
        bgColor = isDark ? const Color(0xFF16324A) : const Color(0xFFE5F6FB);
        textColor = isDark ? const Color(0xFF94DFFF) : AppColors.primary;
        break;
      case RiskLevel.safe:
        text = 'result_safe'.tr(context);
        bgColor = isDark ? const Color(0xFF184A2A) : const Color(0xFFE5FBF0);
        textColor = isDark ? const Color(0xFF94FFC8) : AppColors.success;
        break;
    }
    
    return _buildPill(text, bgColor, textColor);
  }
  
  Widget _buildScorePill(int score, bool isDark) {
    final String text = score >= 80 ? 'result_high_risk'.tr(context) : (score >= 60 ? 'result_medium'.tr(context) : (score >= 40 ? 'result_low'.tr(context) : 'result_safe'.tr(context)));
    final Color bgColor;
    final Color textColor;
    
    if (score >= 80) {
      bgColor = isDark ? const Color(0xFF4A1818) : const Color(0xFFFFEBEB);
      textColor = isDark ? const Color(0xFFFFB4B4) : AppColors.danger;
    } else if (score >= 60) {
      bgColor = isDark ? const Color(0xFF4A3818) : const Color(0xFFFFF4E5);
      textColor = isDark ? const Color(0xFFFFD494) : AppColors.warning;
    } else if (score >= 40) {
      bgColor = isDark ? const Color(0xFF16324A) : const Color(0xFFE5F6FB);
      textColor = isDark ? const Color(0xFF94DFFF) : AppColors.primary;
    } else {
      bgColor = isDark ? const Color(0xFF184A2A) : const Color(0xFFE5FBF0);
      textColor = isDark ? const Color(0xFF94FFC8) : AppColors.success;
    }
    
    return _buildPill(text, bgColor, textColor);
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined, size: 20),
                label: Text('result_details'.tr(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.flag_outlined, size: 20),
                label: Text('result_report_scam'.tr(context)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: isDark ? AppColors.danger.withValues(alpha: 0.5) : AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  foregroundColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                  side: BorderSide(color: isDark ? AppColors.primaryFixedDim.withValues(alpha: 0.5) : AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, size: 20),
                label: Text('delete'.tr(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF3F191D) : const Color(0xFFFFEBEB),
                  foregroundColor: isDark ? const Color(0xFFFFB4B4) : AppColors.danger,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
