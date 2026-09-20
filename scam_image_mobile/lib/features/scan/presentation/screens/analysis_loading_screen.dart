import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/scan_bloc.dart';
import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';

/// Analysis loading screen that polls the backend until the scan completes.
///
/// Receives [filePath] as a constructor argument (passed via route extra).
/// Uses the app-scoped production [ScanBloc] and dispatches [CropConfirmed]
/// on first frame.
///
/// BLoC listener:
/// - [ScanCompleted] → navigate to `/result/:taskId`
/// - [ScanError]/[ScanTimeout] stay on this screen and expose recovery actions.
class AnalysisLoadingScreen extends StatefulWidget {
  const AnalysisLoadingScreen({
    super.key,
    required this.filePath,
    this.scanName,
  });

  final String filePath;
  final String? scanName;

  @override
  State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
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
    );
    _scanLineAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));

    // Dots animation: 1.5-second repeating
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start the scan on first frame using the context-provided ScanBloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanBloc>().add(
        CropConfirmed(widget.filePath, scanName: widget.scanName),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      _scanLineCtrl.stop();
      _dotsCtrl.stop();
      _scanLineCtrl.value = 0.5;
      _dotsCtrl.value = 0;
    } else {
      if (!_scanLineCtrl.isAnimating) _scanLineCtrl.repeat();
      if (!_dotsCtrl.isAnimating) _dotsCtrl.repeat();
    }
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
      case AnalysisTaskStatus.processingSource:
        return _StepStatuses(
          step1: AnalysisStepStatus.active,
          step2: AnalysisStepStatus.pending,
          step3: AnalysisStepStatus.pending,
        );
      case AnalysisTaskStatus.processingVisual:
        return _StepStatuses(
          step1: AnalysisStepStatus.done,
          step2: AnalysisStepStatus.active,
          step3: AnalysisStepStatus.pending,
        );
      case AnalysisTaskStatus.processingText:
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
                  borderRadius: AppRadius.lgBorder,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryFixedDim.withValues(alpha: 0.2),
                      ),
                      borderRadius: AppRadius.lgBorder,
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
                            color: isDark
                                ? Colors.white38
                                : AppColors.outlineVariant,
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
                              AppColors.primaryFixedDim.withValues(alpha: 0.0),
                              AppColors.primaryFixedDim.withValues(alpha: 0.8),
                              AppColors.primaryFixedDim.withValues(alpha: 0.0),
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
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryFixedDim,
                borderRadius: AppRadius.pillBorder,
              ),
              child: Text(
                '$progress%',
                style: AppTypography.caption(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs / 2,
              ),
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
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          AnalysisStepTile(
            status: steps.step1,
            title: 'loading_step1_title'.tr(context),
            subtitle: steps.step1 == AnalysisStepStatus.done
                ? 'loading_step_done'.tr(context)
                : steps.step1 == AnalysisStepStatus.active
                ? 'loading_step1_desc_active'.tr(context)
                : 'loading_step_wait'.tr(context),
          ),
          AnalysisStepTile(
            status: steps.step2,
            title: 'loading_step2_title'.tr(context),
            subtitle: steps.step2 == AnalysisStepStatus.done
                ? 'loading_step_done'.tr(context)
                : steps.step2 == AnalysisStepStatus.active
                ? 'loading_step2_desc_active'.tr(context)
                : 'loading_step_wait'.tr(context),
          ),
          AnalysisStepTile(
            status: steps.step3,
            title: 'loading_step3_title'.tr(context),
            subtitle: steps.step3 == AnalysisStepStatus.done
                ? 'loading_step_done'.tr(context)
                : steps.step3 == AnalysisStepStatus.active
                ? 'loading_step3_desc_active'.tr(context)
                : 'loading_step_wait'.tr(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.inverseSurface.withValues(alpha: 0.5)
            : AppColors.bgLight.withValues(alpha: 0.5),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            semanticLabel: 'loading_encryption'.tr(context),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'loading_encryption'.tr(context),
              style: AppTypography.caption(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('loading_cancel_title'.tr(context)),
        content: Text('loading_cancel_desc'.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('loading_cancel_no'.tr(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'loading_cancel_yes'.tr(context),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ScanBloc>().add(AnalysisCancelled());
      context.go('/main/home');
    }
  }

  Future<void> _showBackgroundDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('loading_bg_title'.tr(context)),
        content: Text('loading_bg_desc'.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('loading_cancel'.tr(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('loading_bg_ok'.tr(context)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.go('/main/history');
    }
  }

  Widget _buildRecoveryState({required String message, required bool isDark}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'loading_error_title'.tr(context),
              style: AppTypography.headlineLgMobile(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyBase(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'loading_retry'.tr(context),
              leadingIcon: const Icon(Icons.refresh),
              onPressed: () => context.read<ScanBloc>().add(
                CropConfirmed(widget.filePath, scanName: widget.scanName),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'loading_edit_image'.tr(context),
              leadingIcon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.go('/crop', extra: {'filePath': widget.filePath}),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go('/main/history'),
              child: Text('loading_go_history'.tr(context)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ScanBloc, ScanState>(
      listener: (context, state) {
        if (state is ScanCompleted) {
          context.go(
            '/result/${state.taskId}',
            extra: {'scanName': widget.scanName},
          );
        }
      },
      child: Scaffold(
        appBar: AppTopBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'notifications'.tr(context),
              onPressed: () => context.push('/notifications'),
              icon: Icon(
                Icons.notifications_outlined,
                color: isDark
                    ? AppColors.outlineVariant
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        body: BlocBuilder<ScanBloc, ScanState>(
          builder: (context, state) {
            if (state is ScanError) {
              return _buildRecoveryState(
                message: state.message.tr(context),
                isDark: isDark,
              );
            }
            if (state is ScanTimeout) {
              return _buildRecoveryState(
                message: 'loading_timeout'.tr(context),
                isDark: isDark,
              );
            }

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
                    'loading_title'.tr(context),
                    style: AppTypography.headlineLgMobile(
                      color: isDark ? Colors.white : AppColors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'loading_subtitle'.tr(context),
                        style: AppTypography.bodyBase(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
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
                          label: 'loading_cancel'.tr(context),
                          onPressed: () => _showCancelDialog(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PrimaryButton(
                          label: 'loading_bg'.tr(context),
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
  bool shouldRepaint(_CircularProgressPainter old) => old.progress != progress;
}
