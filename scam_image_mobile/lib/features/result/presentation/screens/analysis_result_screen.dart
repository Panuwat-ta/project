import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/analysis_result.dart' as domain;
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
          _buildBentoGrid(context),
          const SizedBox(height: AppSpacing.xl),
          _buildActionButtons(context),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildRiskGauge(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 120, // Half circle height approx
          child: CustomPaint(
            painter: _ArcPainter(score: result.riskScore),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${result.riskScore}',
                    style: AppTypography.displayHero(color: AppColors.danger)
                        .copyWith(fontSize: 40, height: 1.0),
                  ),
                  Text(
                    'result_risk_score'.tr(context),
                    style: AppTypography.caption(color: AppColors.outlineVariant),
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
            color: isDark ? const Color(0xFF4A1818) : const Color(0xFFFFEBEB),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: isDark ? const Color(0xFFFFB4B4) : AppColors.danger, size: 16),
              const SizedBox(width: 4),
              Text(
                'result_high_risk'.tr(context),
                style: AppTypography.caption(color: isDark ? const Color(0xFFFFB4B4) : AppColors.danger).copyWith(fontWeight: FontWeight.w600),
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
        borderRadius: BorderRadius.circular(12),
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
                  'result_summary_desc'.tr(context),
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

  Widget _buildBentoGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                icon: Icons.badge_outlined,
                caption: 'result_contact_info'.tr(context),
                valueText: 'result_suspicious'.tr(context),
                valueColor: AppColors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.account_balance_wallet_outlined,
                caption: 'result_transaction'.tr(context),
                valueText: 'result_high_risk'.tr(context),
                valueColor: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildVisualAnomalyCard(context),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required String caption,
    required String valueText,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162230) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF27313C) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.outlineVariant, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            caption,
            style: AppTypography.caption(color: isDark ? Colors.white70 : AppColors.textSecondary),
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Flexible(child: Text('result_details'.tr(context), overflow: TextOverflow.ellipsis)),
                onPressed: () {
                  context.push('/detail/${result.taskId}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.grid_view_outlined, size: 18),
                label: Flexible(child: Text('result_view_heatmap'.tr(context), overflow: TextOverflow.ellipsis)),
                onPressed: () => context.push('/heatmap/${result.taskId}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Flexible(child: Text('result_report_scam'.tr(context), overflow: TextOverflow.ellipsis)),
                onPressed: () => context.go('/main/report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Flexible(child: Text('result_share'.tr(context), overflow: TextOverflow.ellipsis)),
                onPressed: () {
                  // ignore: deprecated_member_use
                  Share.share('result_share_text'.tr(context));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                  side: BorderSide(color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: AppTypography.buttonLabel(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text('result_check_another'.tr(context)),
            onPressed: () => context.go('/main/history'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
              side: BorderSide(color: AppColors.outlineVariant),
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: AppTypography.buttonLabel(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualAnomalyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162230) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '88%',
                  style: AppTypography.caption(color: const Color(0xFFE11D48)).copyWith(fontWeight: FontWeight.bold),
                ),
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
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Image Placeholder or Network image
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: const Color(0xFF0F172A),
                    child: result.imageUrl != null 
                        ? Image.network(result.imageUrl!, fit: BoxFit.cover)
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
                        color: Colors.white.withOpacity(0.85),
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
                                widthFactor: 0.7, // Simulated value
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
          
          // Alerts
          _buildAlertItem(
            icon: Icons.error,
            iconColor: const Color(0xFFE11D48),
            title: 'anomaly_edit_title'.tr(context),
            subtitle: 'anomaly_edit_desc'.tr(context),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildAlertItem(
            icon: Icons.warning,
            iconColor: const Color(0xFFF59E0B),
            title: 'anomaly_pixel_title'.tr(context),
            subtitle: 'anomaly_pixel_desc'.tr(context),
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

  _ArcPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final paintFg = Paint()
      ..color = AppColors.danger
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
