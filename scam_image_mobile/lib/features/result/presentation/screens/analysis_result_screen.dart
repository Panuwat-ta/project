import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/analysis_result.dart' as domain;
import '../bloc/result_bloc.dart';

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
    context.read<ResultBloc>().add(ResultLoadRequested(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF162230) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.security, color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'ScamGuard',
              style: AppTypography.titleMd(
                  color: isDark ? Colors.white : AppColors.primary),
            ),
          ],
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
            return _ResultBody(result: state.result, isDark: isDark);
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF162230) : Colors.white,
        selectedItemColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
        unselectedItemColor: AppColors.outlineVariant,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) context.go('/main/home');
          if (index == 1) context.go('/main/history');
          if (index == 2) context.go('/main/report');
          if (index == 3) context.go('/main/settings');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'ประวัติ'),
          BottomNavigationBarItem(icon: Icon(Icons.flag_outlined), label: 'แจ้งรายงาน'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'ตั้งค่า'),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result, required this.isDark});

  final domain.AnalysisResult result;
  final bool isDark;

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
          _buildRiskGauge(),
          const SizedBox(height: AppSpacing.xl),
          _buildSummaryCard(),
          const SizedBox(height: AppSpacing.md),
          _buildBentoGrid(context),
          const SizedBox(height: AppSpacing.xl),
          _buildActionButtons(context),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildRiskGauge() {
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
                    'RISK SCORE',
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
                'ความเสี่ยงสูง',
                style: AppTypography.caption(color: isDark ? const Color(0xFFFFB4B4) : AppColors.danger).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
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
                  'สรุปผลการวิเคราะห์',
                  style: AppTypography.sectionHeader(
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'พบสัญญาณหลายอย่างที่เกี่ยวข้องกับการหลอกลวง ระบบตรวจพบองค์ประกอบที่น่าสงสัยภายในรูปภาพนี้',
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
                caption: 'ข้อมูลติดต่อ',
                valueText: 'น่าสงสัย',
                valueColor: AppColors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.account_balance_wallet_outlined,
                caption: 'ธุรกรรม',
                valueText: 'ความเสี่ยงสูง',
                valueColor: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
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
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162230) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF27313C) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visual Heatmap',
                        style: AppTypography.sectionHeader(
                            color: isDark ? Colors.white : AppColors.onSurface),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'ดูพื้นที่ที่ระบบ AI ตรวจพบความผิดปกติในเชิงลึก',
                        style: AppTypography.caption(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.white54,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'พร้อมดู',
                    style: AppTypography.caption(
                      color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                label: const Text('ดูรายละเอียด'),
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
                label: const Text('ดู Heatmap'),
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
                label: const Text('รายงานภาพต้องสงสัย', overflow: TextOverflow.ellipsis),
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
                label: const Text('แชร์ผลลัพธ์'),
                onPressed: () {
                  Share.share('ผลการตรวจสอบรูปภาพจาก ScamGuard');
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
