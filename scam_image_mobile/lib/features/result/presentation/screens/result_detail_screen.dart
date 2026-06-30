import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class ResultDetailScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ResultDetailScreen({super.key, required this.resultData});

  Color _getRiskColor(int score) {
    if (score < 40) return AppColors.success;
    if (score < 70) return AppColors.warning;
    return AppColors.danger;
  }

  String _getRiskLevelText(int score) {
    if (score < 40) return 'ปลอดภัย';
    if (score < 70) return 'เฝ้าระวัง';
    return 'ความเสี่ยงสูง';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = resultData['riskScore'] as int? ?? 82;
    final riskColor = _getRiskColor(score);
    final riskLevel = _getRiskLevelText(score);
    final imagePath = resultData['imagePath'] as String? ?? '';

    // Mock data for OCR/Source/Visual details matching design spec
    final ocrText = score >= 70
        ? 'ยินดีด้วย! คุณได้รับรางวัลมูลค่า 50,000 บาท คลิกที่ลิงก์เพื่อรับสิทธิ์ด่วนก่อนหมดเวลา...'
        : score >= 40
            ? 'รับประกันรายได้เสริม 3,000 บาทต่อวัน งานง่ายทำที่บ้าน สนใจแอดไลน์เพื่อสมัคร...'
            : 'กสิกรไทย โอนเงินสำเร็จ วันที่ 28 มิ.ย. 2569 เวลา 10:00 น. นายสมชาย โอนเงินให้ นายสมศักดิ์';
    final ocrWords = score >= 70
        ? ['รางวัล', 'ด่วน', 'คลิกที่ลิงก์']
        : score >= 40
            ? ['รับประกัน', 'รายได้เสริม', 'แอดไลน์']
            : ['โอนเงินสำเร็จ'];
    final matchPercentage = score >= 70 ? '98.5%' : score >= 40 ? '78.2%' : '12.4%';
    
    final repeatCount = score >= 70 ? 42 : score >= 40 ? 15 : 0;
    final firstSeenDate = score >= 70 ? '12 ม.ค. 2569' : score >= 40 ? '18 มี.ค. 2569' : 'ไม่พบข้อมูล';

    final aiGeneratedProb = score >= 70 ? '88%' : score >= 40 ? '45%' : '12%';
    final anomalyScore = score >= 70 ? 'High (0.84)' : score >= 40 ? 'Medium (0.42)' : 'Low (0.14)';
    final xaiExplanation = score >= 70
        ? 'ตรวจพบความผิดปกติสูงในโครงสร้างพิกเซลบริเวณยอดเงินและตัวหนังสือบนสลิป คาดว่ามีการแก้ไขฟอนต์หรือตัดต่อข้อมูลตัวเลข'
        : score >= 40
            ? 'พบการกระจายตัวของพิกเซลไม่สม่ำเสมอในภาพถ่ายใบหน้า มีความเป็นไปได้ปานกลางที่จะเป็นภาพสร้างจาก AI'
            : 'โครงสร้างภาพและระดับการบีบอัดพิกเซลเป็นไปตามปกติ ไม่พบความผิดปกติที่ส่อไปในทางตัดต่อหรือตกแต่งภาพ';

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดผลการตรวจ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กำลังแชร์ข้อมูลเตือนภัย...')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Header with Circular Progress Gauge
              Card(
                elevation: 0,
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ความเสี่ยงโดยรวม',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'วิเคราะห์ล่าสุดเมื่อ 2 นาทีที่แล้ว',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              riskLevel,
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Circular Score Gauge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 8,
                              backgroundColor: theme.brightness == Brightness.dark
                                  ? Colors.white12
                                  : AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$score%',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor,
                                ),
                              ),
                              const Text(
                                'Scam Score',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Card 1: Textual Analysis (OCR)
              Card(
                elevation: 0,
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: riskColor.withOpacity(0.3), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.description_outlined, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'การวิเคราะห์ข้อความ (OCR)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              riskLevel,
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.black12
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ข้อความที่ตรวจพบ:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"$ocrText"',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'คำที่น่าสงสัย',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: ocrWords.map((word) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.danger.withOpacity(0.15)),
                                      ),
                                      child: Text(
                                        word,
                                        style: const TextStyle(
                                          color: AppColors.danger,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'ความแม่นยำ',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$matchPercentage Match',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        score >= 70
                            ? 'พบรูปแบบประโยคเร่งเร้าและสร้างความตื่นตระหนก ซึ่งเป็นลักษณะเฉพาะของการหลอกลวงแบบ Phishing'
                            : score >= 40
                                ? 'พบข้อมูลชักชวนหรืออ้างอิงรายได้ที่ดูเกินจริง กรุณาตรวจสอบให้แน่ใจก่อนทำการสมัครหรือโอนค่าค้ำประกัน'
                                : 'ข้อความในรูปภาพไม่มีเนื้อหาเข้าข่ายเสี่ยงต่อการหลอกลวงเบื้องต้น',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Source Verification
              Card(
                elevation: 0,
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: (score >= 70 ? AppColors.danger : score >= 40 ? AppColors.warning : AppColors.success).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.travel_explore, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'การตรวจสอบแหล่งที่มา',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (score >= 70 ? AppColors.danger : score >= 40 ? AppColors.warning : AppColors.success).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              riskLevel,
                              style: TextStyle(
                                color: (score >= 70 ? AppColors.danger : score >= 40 ? AppColors.warning : AppColors.success),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.black12
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ตรวจพบครั้งแรก',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  firstSeenDate,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'จำนวนที่พบซ้ำ',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$repeatCount ครั้ง',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (repeatCount > 0) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'ลิงก์ที่เกี่ยวข้องและรายงาน:',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildLinkItem(
                          title: 'report-scam-th.org/database/report_$score',
                          onTap: () {},
                        ),
                        const SizedBox(height: 6),
                        _buildLinkItem(
                          title: 'blacklisted-domains.net/profile_scammer_$score',
                          onTap: () {},
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card 3: Visual Anomaly Detection
              Card(
                elevation: 0,
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: (score >= 70 ? AppColors.danger : score >= 40 ? AppColors.warning : AppColors.success).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.visibility_outlined, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'การวิเคราะห์ความผิดปกติทางภาพ',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (score >= 70 ? AppColors.danger : score >= 40 ? AppColors.warning : AppColors.success).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              riskLevel,
                              style: TextStyle(
                                color: (score >= 70 ? AppColors.danger : score >= 40 ? AppColors.warning : AppColors.success),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: imagePath.isNotEmpty && File(imagePath).existsSync()
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(File(imagePath), fit: BoxFit.cover),
                                      Container(
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                    ],
                                  )
                                : const Center(
                                    child: Icon(Icons.photo_filter, color: AppColors.primary, size: 36),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AI-Generated Prob.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                Text(
                                  aiGeneratedProb,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: score >= 70 ? AppColors.danger : score >= 40 ? AppColors.warning : AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Anomaly Score',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                Text(
                                  anomalyScore,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.black12
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'คำอธิบายจาก AI (XAI):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              xaiExplanation,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Final CTA Buttons
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  context.push('/report', extra: imagePath);
                },
                icon: const Icon(Icons.report_gmailerrorred),
                label: const Text('ส่งข้อมูลรายงานเจ้าหน้าที่'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => context.pop(),
                child: const Text('ตรวจสอบรูปภาพอื่น'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
