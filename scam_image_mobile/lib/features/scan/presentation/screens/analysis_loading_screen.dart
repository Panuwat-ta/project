import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/scan_bloc.dart';
import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';

/// Analysis loading screen that polls the backend until the scan completes.
///
/// Receives [filePath] as a constructor argument (passed via route extra).
/// Creates a [ScanBloc] backed by [MockScanRepository] and dispatches
/// [CropConfirmed] on first frame.
///
/// BLoC listener:
/// - [ScanCompleted] → navigate to `/result/:taskId`
/// - [ScanError]     → show SnackBar, then pop after 1 second
/// - [ScanTimeout]   → show SnackBar "หมดเวลา กรุณาลองใหม่", then pop
class AnalysisLoadingScreen extends StatefulWidget {
  const AnalysisLoadingScreen({super.key, required this.filePath});

  final String filePath;

  @override
  State<AnalysisLoadingScreen> createState() =>
      _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen>
    with TickerProviderStateMixin {
  // Animation: scanning line inside thumbnail
  late final AnimationController _scanLineCtrl;
  late final Animation<double> _scanLineAnim;

  // Animation: staggered dots
  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();

    // Scanning line: 3-second repeating tween 0→1
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );

    // Dots animation: 1.5-second repeating
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Start the scan on first frame using the context-provided ScanBloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanBloc>().add(CropConfirmed(widget.filePath));
    });
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  // ── Step mapping ───────────────────────────────────────────────────────────

  /// Map current polling step to the 3-step tile statuses.
  _StepStatuses _stepStatusesFor(AnalysisTaskStatus step) {
    switch (step) {
      case AnalysisTaskStatus.uploading:
      case AnalysisTaskStatus.queued:
        return _StepStatuses(
          step1: AnalysisStepStatus.active,
          step2: AnalysisStepStatus.pending,
          step3: AnalysisStepStatus.pending,
        );
      case AnalysisTaskStatus.processingText:
        return _StepStatuses(
          step1: AnalysisStepStatus.active,
          step2: AnalysisStepStatus.pending,
          step3: AnalysisStepStatus.pending,
        );
      case AnalysisTaskStatus.processingSource:
        return _StepStatuses(
          step1: AnalysisStepStatus.done,
          step2: AnalysisStepStatus.active,
          step3: AnalysisStepStatus.pending,
        );
      case AnalysisTaskStatus.processingVisual:
        return _StepStatuses(
          step1: AnalysisStepStatus.done,
          step2: AnalysisStepStatus.done,
          step3: AnalysisStepStatus.active,
        );
      case AnalysisTaskStatus.completed:
        return _StepStatuses(
          step1: AnalysisStepStatus.done,
          step2: AnalysisStepStatus.done,
          step3: AnalysisStepStatus.done,
        );
      default:
        return _StepStatuses(
          step1: AnalysisStepStatus.active,
          step2: AnalysisStepStatus.pending,
          step3: AnalysisStepStatus.pending,
        );
    }
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildProgressRing(int progress, bool isDark) {
    return SizedBox(
      width: 192,
      height: 192,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress ring
          CustomPaint(
            size: const Size(192, 192),
            painter: _CircularProgressPainter(progress: progress / 100.0),
          ),
          // Thumbnail with scanning line
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryFixedDim
                            .withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        File(widget.filePath),
                        fit: BoxFit.cover,
                        width: 128,
                        height: 128,
                        errorBuilder: (context2, err, trace) => Container(
                          color: AppColors.inverseSurface,
                          child: Icon(
                            Icons.image_outlined,
                            color: isDark ? Colors.white38 : AppColors.outlineVariant,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Scanning line
                AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (context, _) {
                    return Positioned(
                      top: _scanLineAnim.value * 128,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryFixedDim
                                  .withValues(alpha: 0.0),
                              AppColors.primaryFixedDim
                                  .withValues(alpha: 0.8),
                              AppColors.primaryFixedDim
                                  .withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Percent badge
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryFixedDim,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$progress%',
                style: AppTypography.caption(color: Theme.of(context).scaffoldBackgroundColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDots(bool isDark) {
    return AnimatedBuilder(
      animation: _dotsCtrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.33
            final double phase = (_dotsCtrl.value - i * 0.33).clamp(0.0, 1.0);
            final double opacity = (math.sin(phase * math.pi)).clamp(0.0, 1.0);
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
              child: Opacity(
                opacity: 0.3 + opacity * 0.7,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStepCard(_StepStatuses steps) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          AnalysisStepTile(
            status: steps.step1,
            title: 'กำลังอ่านข้อความในภาพ',
            subtitle: steps.step1 == AnalysisStepStatus.done
                ? 'เสร็จสิ้น'
                : steps.step1 == AnalysisStepStatus.active
                    ? 'กำลังอ่านข้อมูล...'
                    : 'รอการประมวลผล',
          ),
          AnalysisStepTile(
            status: steps.step2,
            title: 'กำลังตรวจสอบแหล่งที่มา',
            subtitle: steps.step2 == AnalysisStepStatus.done
                ? 'เสร็จสิ้น'
                : steps.step2 == AnalysisStepStatus.active
                    ? 'กำลังตรวจสอบข้อมูลผู้ส่ง...'
                    : 'รอการประมวลผล',
          ),
          AnalysisStepTile(
            status: steps.step3,
            title: 'กำลังวิเคราะห์ความผิดปกติ',
            subtitle: steps.step3 == AnalysisStepStatus.done
                ? 'เสร็จสิ้น'
                : steps.step3 == AnalysisStepStatus.active
                    ? 'กำลังประมวลผลด้วย AI...'
                    : 'รอการประมวลผล',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.inverseSurface.withValues(alpha: 0.5) : AppColors.bgLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: AppColors.outlineVariant,
            semanticLabel: 'การวิเคราะห์แบบเข้ารหัส',
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'การวิเคราะห์แบบเข้ารหัส ข้อมูลของคุณจะถูกเก็บเป็นความลับ',
              style: AppTypography.caption(color: AppColors.outlineVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการยกเลิก?'),
        content: const Text('คุณต้องการยกเลิกการวิเคราะห์รูปภาพนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ไม่, ทำงานต่อ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ใช่, ยกเลิก', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ScanBloc>().add(AnalysisCancelled());
      context.go('/main/scan');
    }
  }

  Future<void> _showBackgroundDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ทำงานเบื้องหลัง'),
        content: const Text('การวิเคราะห์จะทำงานต่อไปในเบื้องหลัง คุณสามารถตรวจสอบผลลัพธ์ได้ในหน้า "ประวัติ" เมื่อการวิเคราะห์เสร็จสิ้น ระบบจะส่งการแจ้งเตือนให้คุณทราบ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.go('/main/history');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ScanBloc, ScanState>(
      listener: (context, state) async {
        if (state is ScanCompleted) {
          context.go('/result/${state.taskId}');
        } else if (state is ScanError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
          await Future.delayed(const Duration(seconds: 1));
          if (context.mounted) context.pop();
        } else if (state is ScanTimeout) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('หมดเวลา กรุณาลองใหม่'),
              backgroundColor: AppColors.error,
            ),
          );
          await Future.delayed(const Duration(seconds: 1));
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppTopBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'การแจ้งเตือน',
              onPressed: () => context.push('/notifications'),
              icon: Icon(
                Icons.notifications_outlined,
                color: isDark ? AppColors.outlineVariant : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        body: BlocBuilder<ScanBloc, ScanState>(
          builder: (context, state) {
            final int progress = state is ScanPolling
                ? state.progress
                : state is ScanUploading
                    ? 0
                    : 0;
            final AnalysisTaskStatus step = state is ScanPolling
                ? state.step
                : AnalysisTaskStatus.queued;
            final steps = _stepStatusesFor(step);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // 1. Circular progress ring with thumbnail
                  _buildProgressRing(progress, isDark),

                  const SizedBox(height: AppSpacing.xl),

                  // 2. Title
                  Text(
                    'กำลังวิเคราะห์ความปลอดภัย',
                    style: AppTypography.headlineLgMobile(
                        color: isDark ? Colors.white : AppColors.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'กรุณารอครู่หนึ่ง ระบบกำลังประมวลผลด้วย AI',
                        style: AppTypography.bodyBase(
                            color: AppColors.outlineVariant),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildAnimatedDots(isDark),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 3. Step checklist card
                  _buildStepCard(steps),

                  const SizedBox(height: AppSpacing.lg),

                  // 4. Privacy badge
                  _buildPrivacyBadge(isDark),

                  const SizedBox(height: AppSpacing.xl),

                  // 5. Actions
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'ยกเลิก',
                          onPressed: () => _showCancelDialog(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PrimaryButton(
                          label: 'ทำงานเบื้องหลัง',
                          onPressed: () => _showBackgroundDialog(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Step statuses helper ──────────────────────────────────────────────────────

class _StepStatuses {
  final AnalysisStepStatus step1;
  final AnalysisStepStatus step2;
  final AnalysisStepStatus step3;

  const _StepStatuses({
    required this.step1,
    required this.step2,
    required this.step3,
  });
}

// ── Circular progress painter ─────────────────────────────────────────────────

/// Draws a circular progress arc:
/// - Track: full circle in [AppColors.inverseSurface] with 20% opacity
/// - Fill: [AppColors.primaryFixedDim] sweeping from top (−π/2) by [progress]×2π
class _CircularProgressPainter extends CustomPainter {
  const _CircularProgressPainter({required this.progress});

  /// Value between 0.0 and 1.0.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 8.0;

    // Track
    final trackPaint = Paint()
      ..color = AppColors.inverseSurface.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Fill arc
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = AppColors.primaryFixedDim
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // start at top
        2 * math.pi * progress, // sweep
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress;
}
