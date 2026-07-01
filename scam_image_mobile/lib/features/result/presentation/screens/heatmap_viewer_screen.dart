import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// Heatmap Viewer — shows the original image with an optional AI heatmap
/// overlay. Supports zoom/pan via [InteractiveViewer], a toggle between
/// original and heatmap modes, and an opacity slider.
class HeatmapViewerScreen extends StatefulWidget {
  const HeatmapViewerScreen({
    super.key,
    required this.taskId,
    this.imageUrl,
    this.heatmapUrl,
  });

  final String taskId;
  final String? imageUrl;
  final String? heatmapUrl;

  @override
  State<HeatmapViewerScreen> createState() => _HeatmapViewerScreenState();
}

class _HeatmapViewerScreenState extends State<HeatmapViewerScreen> {
  bool _showHeatmap = true;
  double _heatmapOpacity = 0.7;

  void _showSaveSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกภาพ (ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Image widgets ──────────────────────────────────────────────────────

  Widget _buildBaseImage() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.inverseSurface,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.outlineVariant,
          size: 80,
          semanticLabel: 'ไม่มีรูปภาพ',
        ),
      ),
    );
  }

  Widget _buildHeatmapOverlay() {
    if (!_showHeatmap) return const SizedBox.shrink();

    if (widget.heatmapUrl != null && widget.heatmapUrl!.isNotEmpty) {
      return Opacity(
        opacity: _heatmapOpacity,
        child: Image.network(
          widget.heatmapUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox.shrink(),
        ),
      );
    }

    // Demo heatmap overlay when no URL is provided
    return Opacity(
      opacity: _heatmapOpacity,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.2, -0.1),
            radius: 0.6,
            colors: [
              Colors.red.withValues(alpha: 0.7),
              Colors.orange.withValues(alpha: 0.4),
              Colors.yellow.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'กลับ',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Visual Heatmap',
          style: AppTypography.sectionHeader(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // ── Zoomable image area ──────────────────────────────────────
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildBaseImage(),
                  _buildHeatmapOverlay(),
                ],
              ),
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────────
          _BottomControls(
            showHeatmap: _showHeatmap,
            heatmapOpacity: _heatmapOpacity,
            onToggleChanged: (value) {
              setState(() => _showHeatmap = value == 1);
            },
            onOpacityChanged: (value) {
              setState(() => _heatmapOpacity = value);
            },
            onSave: _showSaveSnackBar,
          ),
        ],
      ),
    );
  }
}

// ── Bottom Controls Panel ──────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.showHeatmap,
    required this.heatmapOpacity,
    required this.onToggleChanged,
    required this.onOpacityChanged,
    required this.onSave,
  });

  final bool showHeatmap;
  final double heatmapOpacity;
  final ValueChanged<int> onToggleChanged;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceDark,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.safeMargin,
        AppSpacing.md,
        AppSpacing.safeMargin,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle: ต้นฉบับ | Heatmap
          Center(
            child: ToggleButtons(
              isSelected: [!showHeatmap, showHeatmap],
              onPressed: onToggleChanged,
              borderRadius: BorderRadius.circular(9999),
              selectedColor: AppColors.bgDark,
              fillColor: AppColors.primaryFixedDim,
              color: AppColors.outlineVariant,
              borderColor: AppColors.outlineVariant.withValues(alpha: 0.4),
              selectedBorderColor: AppColors.primaryFixedDim,
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'ต้นฉบับ',
                    style: AppTypography.buttonLabel(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'Heatmap',
                    style: AppTypography.buttonLabel(),
                  ),
                ),
              ],
            ),
          ),

          // Opacity slider (only visible in heatmap mode)
          if (showHeatmap) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  'ความโปร่งใส',
                  style: AppTypography.caption(
                    color: AppColors.outlineVariant,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: heatmapOpacity,
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppColors.primaryFixedDim,
                    inactiveColor:
                        AppColors.outlineVariant.withValues(alpha: 0.3),
                    onChanged: onOpacityChanged,
                  ),
                ),
                Text(
                  '${(heatmapOpacity * 100).round()}%',
                  style: AppTypography.codeData(
                    color: AppColors.primaryFixedDim,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Explanation card
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 18,
                  semanticLabel: 'ข้อมูล',
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'บริเวณสีส้ม/แดงคือพื้นที่ที่ระบบ AI ให้ความสำคัญมากที่สุดในการตรวจจับ',
                    style: AppTypography.caption(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Download button
          OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('บันทึกภาพ'),
            onPressed: onSave,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryFixedDim,
              side: const BorderSide(color: AppColors.primaryFixedDim),
              minimumSize: const Size(0, 48),
              shape: const StadiumBorder(),
              textStyle: AppTypography.buttonLabel(),
            ),
          ),
        ],
      ),
    );
  }
}
