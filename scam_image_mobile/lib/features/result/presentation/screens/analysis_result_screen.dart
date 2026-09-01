import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/risk_level_helper.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_top_bar.dart';
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
        backgroundColor: isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F8FB),
        appBar: AppTopBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.onSurface),
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
              icon: Icon(Icons.notifications_none,
                  color: isDark ? Colors.white : AppColors.onSurface),
              onPressed: () {},
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
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/main/home');
          if (index == 1) context.go('/main/history');
          if (index == 2) context.go('/main/report');
          if (index == 3) context.go('/main/settings');
        },
      ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result, required this.isDark, this.scanName});

  final domain.AnalysisResult result;
  final bool isDark;
  final String? scanName;

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
          if (scanName != null && scanName!.isNotEmpty) ...[
            Text(
              scanName!,
              textAlign: TextAlign.center,
              style: AppTypography.headlineLgMobile(color: isDark ? Colors.white : AppColors.primary).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _buildRiskGauge(context),
          const SizedBox(height: AppSpacing.xl),
          _buildSummaryCard(context),
          const SizedBox(height: AppSpacing.md),
          _buildVisualAnomalyCard(context),
          const SizedBox(height: AppSpacing.xl),
          _buildActionButtons(context),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildRiskGauge(BuildContext context) {
    final riskColor = RiskLevelHelper.toColor(result.riskLevel);
    final badgeBg = RiskLevelHelper.toBgColor(result.riskLevel, isDark: isDark);
    final badgeTextColor = RiskLevelHelper.toTextColor(result.riskLevel, isDark: isDark);
    final badgeIcon = RiskLevelHelper.toIcon(result.riskLevel);
    final badgeLabelKey = RiskLevelHelper.toLabelKey(result.riskLevel);

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 120, // Half circle height approx
          child: CustomPaint(
            painter: _ArcPainter(score: result.riskScore, arcColor: riskColor),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${result.riskScore}',
                    style: AppTypography.displayHero(color: riskColor)
                        .copyWith(fontSize: 40, height: 1.0),
                  ),
                  Text(
                    'result_risk_score'.tr(context),
                    style: AppTypography.caption(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, color: badgeTextColor, size: 16),
              const SizedBox(width: 4),
              Text(
                badgeLabelKey.tr(context),
                style: AppTypography.caption(color: badgeTextColor).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162230) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF27313C) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27313C) : const Color(0xFFE8F2FF),
              borderRadius: BorderRadius.circular(8),
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
                  result.summary.isNotEmpty ? result.summary : 'result_summary_desc'.tr(context),
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

  Widget _buildActionButtons(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/main/report'),
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
                          child: Text('delete'.tr(context), style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    context.read<HistoryBloc>().add(HistoryItemDeleted(result.taskId));
                    context.go('/main/home');
                  }
                },
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
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/main/history'), // Should be /main/home? Current app uses history, let's keep it.
            icon: const Icon(Icons.photo_camera_outlined, size: 20),
            label: Text('result_check_another'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8F9FA),
              foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
              side: isDark ? BorderSide.none : const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: AppTypography.buttonLabel(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualAnomalyCard(BuildContext context) {
    final visuals = result.factors.where((f) => f.type == 'visual');
    final visualFactor = visuals.isNotEmpty ? visuals.first : const domain.RiskFactor(type: 'visual', score: 0, title: '', details: []);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162230) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF27313C) : AppColors.border,
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
                    Icon(Icons.image_search, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'visual_anomaly_title'.tr(context),
                        style: AppTypography.sectionHeader(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                  final vLevel = RiskLevelHelper.fromScore(visualFactor.score);
                  final vBg = RiskLevelHelper.toBgColor(vLevel, isDark: isDark);
                  final vFg = RiskLevelHelper.toTextColor(vLevel, isDark: isDark);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: vBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${visualFactor.score}%',
                      style: AppTypography.caption(color: vFg).copyWith(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Image / Slider container
          GestureDetector(
            onTap: () {
              context.push(
                '/heatmap/${result.taskId}',
                extra: <String, dynamic>{
                  if (result.imageUrl != null) 'imageUrl': result.imageUrl,
                  if (result.heatmapUrl != null) 'heatmapUrl': result.heatmapUrl,
                },
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Image Placeholder or Network image
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: const Color(0xFF0F172A),
                    child: (result.heatmapUrl != null || result.imageUrl != null) 
                        ? Image.network((result.heatmapUrl ?? result.imageUrl)!, fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.image, color: Colors.white24, size: 48)),
                  ),
                  // Slider overlay at bottom
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, color: Color(0xFF64748B), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: visualFactor.score / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.layers, color: Color(0xFF0284C7), size: 20),
                        ],
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
            ...visualFactor.details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAlertItem(
                icon: Icons.error,
                iconColor: RiskLevelHelper.toColor(RiskLevelHelper.fromScore(visualFactor.score)),
                title: detail,
                subtitle: '',
                isDark: isDark,
              ),
            ))
          else
            _buildAlertItem(
              icon: Icons.check_circle,
              iconColor: AppColors.success,
              title: 'result_safe'.tr(context),
              subtitle: '',
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
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
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: AppTypography.caption(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final int score;
  final Color arcColor;

  _ArcPainter({required this.score, required this.arcColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final paintFg = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height),
      width: size.width,
      height: size.height * 2,
    );

    // Draw background arc
    canvas.drawArc(rect, 3.14, 3.14, false, paintBg);

    // Draw foreground arc based on score
    final sweepAngle = 3.14 * (score / 100);
    canvas.drawArc(rect, 3.14, sweepAngle, false, paintFg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
