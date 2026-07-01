import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../result/domain/entities/analysis_result.dart' as domain;
import '../../../result/presentation/bloc/result_bloc.dart';

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
    _bloc = ResultBloc(repository: MockResultRepository());
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
            'รายละเอียดผลการตรวจ',
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
                Share.share('ผลการตรวจจาก ScamGuard');
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.safeMargin, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overall Risk
              _buildOverallRisk(isDark),
              const SizedBox(height: AppSpacing.md),

              // 2. OCR Analysis
              _buildOcrCard(isDark),
              const SizedBox(height: AppSpacing.md),

              // 3. Source Check
              _buildSourceCard(isDark),
              const SizedBox(height: AppSpacing.md),

              // 4. Image Anomaly
              _buildImageAnomalyCard(isDark),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              _buildActionButtons(context, isDark),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
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

  Widget _buildOverallRisk(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ความเสี่ยงโดยรวม',
                    style: AppTypography.titleMd(
                        color: isDark ? Colors.white : AppColors.onSurface),
                  ),
                  Text(
                    'วิเคราะห์ล่าสุดเมื่อ 2 นาทีที่แล้ว',
                    style: AppTypography.caption(color: AppColors.outlineVariant),
                  ),
                ],
              ),
              _buildPill(
                'ความเสี่ยงสูง',
                isDark ? const Color(0xFF4A1818) : const Color(0xFFFFEBEB),
                isDark ? const Color(0xFFFFB4B4) : AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.danger,
                width: 8,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '92%',
                    style: AppTypography.displayHero(
                            color: isDark ? Colors.white : AppColors.danger)
                        .copyWith(fontSize: 36, height: 1.1),
                  ),
                  Text(
                    'Scam Score',
                    style: AppTypography.caption(
                        color: isDark ? AppColors.outlineVariant : AppColors.textSecondary),
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

  Widget _buildOcrCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined,
                      color: isDark ? AppColors.primaryFixedDim : AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'การวิเคราะห์ข้อความ (OCR)',
                    style: AppTypography.sectionHeader(
                        color: isDark ? Colors.white : AppColors.onSurface),
                  ),
                ],
              ),
              _buildPill(
                'เสี่ยงสูง',
                isDark ? const Color(0xFF4A1818) : const Color(0xFFFFEBEB),
                isDark ? const Color(0xFFFFB4B4) : AppColors.danger,
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
                  'ข้อความที่ตรวจพบ:',
                  style: AppTypography.caption(color: AppColors.outlineVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '"ยินดีด้วย! คุณได้รับรางวัลมูลค่า 50,000 บาท คลิกที่ลิงก์เพื่อรับสิทธิ์ด่วนก่อนหมดเวลา..."',
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
                'คำที่น่าสงสัย',
                style: AppTypography.caption(color: AppColors.outlineVariant),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ความแม่นยำ',
                    style: AppTypography.caption(color: AppColors.outlineVariant),
                  ),
                  Text(
                    '98.5% Match',
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
            children: [
              _buildSuspiciousChip('รางวัล', isDark),
              _buildSuspiciousChip('ด่วน', isDark),
              _buildSuspiciousChip('คลิกที่ลิงก์', isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: AppColors.border.withValues(alpha: isDark ? 0.2 : 1)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'พบรูปแบบประโยคเร่งเร้าและสร้างความตื่นตระหนก ซึ่งเป็นลักษณะเฉพาะของการหลอกลวงแบบ Phishing',
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

  Widget _buildSourceCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.manage_search_outlined,
                      color: isDark ? AppColors.primaryFixedDim : AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'การตรวจสอบแหล่งที่มา',
                    style: AppTypography.sectionHeader(
                        color: isDark ? Colors.white : AppColors.onSurface),
                  ),
                ],
              ),
              _buildPill(
                'ปานกลาง',
                isDark ? const Color(0xFF4A3818) : const Color(0xFFFFF4E5),
                isDark ? const Color(0xFFFFD494) : AppColors.warning,
              ),
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
                      'ตรวจพบครั้งแรก',
                      style: AppTypography.caption(color: AppColors.outlineVariant),
                    ),
                    Text(
                      '12 ม.ค. 2567',
                      style: AppTypography.bodyBase(
                          color: isDark ? Colors.white : AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'จำนวนที่พบซ้ำ',
                      style: AppTypography.caption(color: AppColors.outlineVariant),
                    ),
                    Text(
                      '42 ครั้ง',
                      style: AppTypography.bodyBase(
                          color: isDark ? Colors.white : AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ลิงก์ที่เกี่ยวข้องและรายงาน:',
            style: AppTypography.caption(color: AppColors.outlineVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildLinkRow('report-scam-th.org/database', Icons.link, isDark),
          const SizedBox(height: AppSpacing.sm),
          _buildLinkRow('blacklisted-domains.net/p...', Icons.security_outlined, isDark),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String url, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: isDark ? AppColors.primaryFixedDim : AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            url,
            style: AppTypography.bodyBase(
                color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.chevron_right, color: AppColors.outlineVariant),
      ],
    );
  }

  Widget _buildImageAnomalyCard(bool isDark) {
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
                        'การวิเคราะห์ความผิดปกติทางภาพ',
                        style: AppTypography.sectionHeader(
                            color: isDark ? Colors.white : AppColors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPill(
                'เสี่ยงต่ำ',
                isDark ? const Color(0xFF183C25) : const Color(0xFFE6F4EA),
                isDark ? const Color(0xFF81C995) : AppColors.success,
              ),
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
                    // A placeholder for the heatmap image
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
                      style: AppTypography.caption(color: AppColors.outlineVariant),
                    ),
                    Text(
                      '12%',
                      style: AppTypography.titleMd(color: AppColors.success),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Anomaly Score',
                      style: AppTypography.caption(color: AppColors.outlineVariant),
                    ),
                    Text(
                      'Low (0.14)',
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
                  'คำอธิบายจาก AI (XAI)',
                  style: AppTypography.bodyBase(
                      color: isDark ? Colors.white : AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'ภาพมีโครงสร้างพิกเซลที่สม่ำเสมอ ไม่พบการตัดต่อที่ชัดเจน อย่างไรก็ตาม พบความผิดปกติเล็กน้อยบริเวณโลโก้ธนาคารซึ่งอาจเกิดจากการใช้ภาพคุณภาพต่ำ',
                  style: AppTypography.caption(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.info_outline, size: 20),
          label: const Text('ส่งข้อมูลรายงานเจ้าหน้าที่'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: AppTypography.buttonLabel(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.go('/main/home'),
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('ตรวจสอบรูปภาพอื่น'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
            side: BorderSide(color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: AppTypography.buttonLabel(),
          ),
        ),
      ],
    );
  }
}
