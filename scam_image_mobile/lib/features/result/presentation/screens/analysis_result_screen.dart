import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class AnalysisResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;

  const AnalysisResultScreen({super.key, required this.resultData});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  double _heatmapOpacity = 0.5;

  Color _getRiskColor(int score) {
    if (score < 40) return AppColors.success;
    if (score < 70) return AppColors.warning;
    return AppColors.danger;
  }

  String _getRiskLevelText(int score) {
    if (score < 40) return 'ความเสี่ยงต่ำ';
    if (score < 70) return 'ความเสี่ยงปานกลาง';
    return 'ความเสี่ยงสูง';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = widget.resultData['riskScore'] as int? ?? 82;
    final riskColor = _getRiskColor(score);
    final riskLevel = _getRiskLevelText(score);
    final summary = widget.resultData['summary'] as String? ?? 'พบสัญญาณหลายอย่างที่เกี่ยวข้องกับการหลอกลวง';
    final imagePath = widget.resultData['imagePath'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ผลการวิเคราะห์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Semi-circular/circular Risk Gauge at the top
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  width: 200,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gauge path background simulator
                      Positioned(
                        top: 10,
                        child: CustomPaint(
                          size: const Size(180, 90),
                          painter: GaugeArcPainter(
                            percentage: score / 100.0,
                            color: riskColor,
                            backgroundColor: theme.brightness == Brightness.dark
                                ? Colors.white12
                                : AppColors.border,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const Text(
                              'Risk Score',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Risk level indicator pill
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: riskColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        riskLevel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Summary Card
              Card(
                elevation: 0,
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'สรุปผลการวิเคราะห์',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Bento Grid Section
              Row(
                children: [
                  Expanded(
                    child: _buildBentoCard(
                      icon: Icons.contact_mail_outlined,
                      label: 'ข้อมูลติดต่อ',
                      value: score >= 70 ? 'น่าสงสัย' : score >= 40 ? 'เฝ้าระวัง' : 'ปกติ',
                      valueColor: score >= 70 ? AppColors.danger : score >= 40 ? AppColors.warning : AppColors.success,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'ธุรกรรม',
                      value: score >= 70 ? 'ความเสี่ยงสูง' : score >= 40 ? 'เสี่ยงปานกลาง' : 'ปกติ',
                      valueColor: score >= 70 ? AppColors.danger : score >= 40 ? AppColors.warning : AppColors.success,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Wide visual heatmap card
              Card(
                elevation: 0,
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openHeatmapViewer(imagePath),
                  child: Stack(
                    children: [
                      // BG image simulator
                      Positioned.fill(
                        child: imagePath.isNotEmpty && File(imagePath).existsSync()
                            ? Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                opacity: const AlwaysStoppedAnimation(0.15),
                              )
                            : Container(
                                color: AppColors.primary.withOpacity(0.05),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Visual Heatmap',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'ดูพื้นที่ที่ระบบ AI ตรวจพบความผิดปกติในเชิงลึก',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'พร้อมดู',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 4. Action Cluster
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.push('/result-detail', extra: widget.resultData);
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      label: const Text('ดูรายละเอียด'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimaryContainer,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _openHeatmapViewer(imagePath),
                      icon: const Icon(Icons.grid_view_outlined, size: 20),
                      label: const Text('ดู Heatmap'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger, width: 1.5),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.push('/report', extra: imagePath);
                      },
                      icon: const Icon(Icons.flag_outlined, size: 20),
                      label: const Text('รายงานภาพต้องสงสัย'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('กำลังเตรียมแชร์ผลการวิเคราะห์...')),
                        );
                      },
                      icon: const Icon(Icons.share_outlined, size: 20),
                      label: const Text('แชร์ผลลัพธ์'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.dark
          ? AppColors.darkSurface
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Heatmap modal viewer with InteractiveViewer and Alpha slider
  void _openHeatmapViewer(String imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Heatmap Viewer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Interactive Viewer
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InteractiveViewer(
                        maxScale: 4.0,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Base Image
                            imagePath.isNotEmpty && File(imagePath).existsSync()
                                ? Image.file(
                                    File(imagePath),
                                    fit: BoxFit.contain,
                                  )
                                : const Center(
                                    child: Icon(Icons.image, color: Colors.white30, size: 64),
                                  ),
                            // Simulated Heatmap Overlay
                            Opacity(
                              opacity: _heatmapOpacity,
                              child: CustomPaint(
                                painter: HeatmapPainter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Heatmap explanation
                  const Text(
                    'คำอธิบาย: บริเวณสีแดงเข้มหมายถึงจุดที่โมเดล AI ให้ความสนใจและพบความผิดปกติ เช่น โครงสร้างรอยต่อใบหน้า หรือจุดบกพร่องพิกเซล',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Alpha Slider
                  Row(
                    children: [
                      const Icon(Icons.opacity, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _heatmapOpacity,
                          onChanged: (val) {
                            setModalState(() {
                              _heatmapOpacity = val;
                            });
                            setState(() {
                              _heatmapOpacity = val;
                            });
                          },
                          min: 0.0,
                          max: 1.0,
                          activeColor: AppColors.primaryContainer,
                          inactiveColor: Colors.white24,
                        ),
                      ),
                      Text(
                        '${(_heatmapOpacity * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Custom Painter to draw a half-circular gauge arc
class GaugeArcPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  GaugeArcPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, size.height);

    // Track arc (half circle from PI to 0)
    final trackPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 7),
      3.14159265, // starts at 180 degrees (left side)
      3.14159265, // length is 180 degrees
      false,
      trackPaint,
    );

    // Active arc
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 7),
      3.14159265,
      3.14159265 * percentage,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter to simulate a heatmap over the image
class HeatmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw 2 radial heatpoints
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.red.withOpacity(0.9),
          Colors.orange.withOpacity(0.6),
          Colors.yellow.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.45),
        radius: size.width * 0.25,
      ));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), size.width * 0.25, paint1);

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.red.withOpacity(0.8),
          Colors.yellow.withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.65, size.height * 0.43),
        radius: size.width * 0.15,
      ));
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.43), size.width * 0.15, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
