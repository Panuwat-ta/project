import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Status of a single analysis step.
enum AnalysisStepStatus { done, active, pending }

/// Row widget representing one step in the analysis loading screen checklist.
///
/// * done    — filled green circle with a check mark.
/// * active  — spinning border ring + search icon in primary color.
/// * pending — gray circle, reduced opacity.
class AnalysisStepTile extends StatefulWidget {
  const AnalysisStepTile({
    super.key,
    required this.status,
    required this.title,
    this.subtitle,
  });

  final AnalysisStepStatus status;
  final String title;
  final String? subtitle;

  @override
  State<AnalysisStepTile> createState() => _AnalysisStepTileState();
}

class _AnalysisStepTileState extends State<AnalysisStepTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.status == AnalysisStepStatus.active) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(AnalysisStepTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == AnalysisStepStatus.active) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor =
        isDark ? AppColors.primaryFixedDim : AppColors.primary;

    switch (widget.status) {
      case AnalysisStepStatus.done:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 18),
        );

      case AnalysisStepStatus.active:
        return SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _ctrl,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 2.5),
                  ),
                  // Clip one side to simulate spinning arc
                  child: ClipArc(child: const SizedBox()),
                ),
              ),
              Icon(Icons.search, color: primaryColor, size: 16),
            ],
          ),
        );

      case AnalysisStepStatus.pending:
        return Opacity(
          opacity: 0.4,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textSecondary,
                width: 2,
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPending = widget.status == AnalysisStepStatus.pending;

    return Opacity(
      opacity: isPending ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStatusIndicator(context),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.bodyBase(),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: AppTypography.caption(
                          color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple painter helper used for the spinning arc effect in active state.
/// Clips the top-right quarter of the circle so it looks like an arc spinner.
class ClipArc extends StatelessWidget {
  const ClipArc({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
