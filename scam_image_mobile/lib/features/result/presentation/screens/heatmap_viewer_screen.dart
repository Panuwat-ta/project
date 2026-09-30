import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';

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
  double _heatmapOpacity = 1.0;
  bool _showHeatmap = true;

  bool get _hasHeatmap => widget.heatmapUrl?.trim().isNotEmpty == true;
  final TransformationController _transformationController =
      TransformationController();

  void _zoomIn() {
    final matrix = _transformationController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(1.2, 1.2, 1));
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformationController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(0.8, 0.8, 1));
    _transformationController.value = matrix;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

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
        ),
      ),
    );
  }

  Widget _buildHeatmapOverlay() {
    if (!_hasHeatmap || !_showHeatmap) return const SizedBox.shrink();

    return Opacity(
      key: const Key('heatmap-overlay'),
      opacity: _heatmapOpacity,
      child: Image.network(
        widget.heatmapUrl!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'heatmap_check_details'.tr(context),
          style: AppTypography.sectionHeader(
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasHeatmap)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton.icon(
                key: const Key('heatmap-toggle'),
                onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
                icon: Icon(
                  _showHeatmap
                      ? Icons.layers_clear_outlined
                      : Icons.layers_outlined,
                ),
                label: Text(
                  (_showHeatmap
                          ? 'heatmap_hide_overlay'
                          : 'heatmap_show_overlay')
                      .tr(context),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  'heatmap_unavailable_short'.tr(context),
                  style: AppTypography.caption(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.safeMargin,
              vertical: AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: AppRadius.smBorder,
              border: Border.all(
                color: isDark ? AppColors.inverseSurface : AppColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.outlineVariant,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    (_hasHeatmap ? 'heatmap_desc' : 'heatmap_unavailable_desc')
                        .tr(context),
                    style: AppTypography.caption(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image Viewer Area
          Expanded(
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [_buildBaseImage(), _buildHeatmapOverlay()],
                  ),
                ),

                // Floating Action Buttons on the right
                Positioned(
                  right: AppSpacing.safeMargin,
                  top: MediaQuery.of(context).size.height * 0.2,
                  child: Column(
                    children: [
                      _buildFloatingButton(Icons.add, _zoomIn, isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildFloatingButton(Icons.remove, _zoomOut, isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildFloatingButton(Icons.refresh, _resetZoom, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls
          SafeArea(
            top: false,
            child: Container(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.safeMargin,
                AppSpacing.md,
                AppSpacing.safeMargin,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasHeatmap && _showHeatmap) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'heatmap_intensity'.tr(context),
                          style: AppTypography.bodyBase(
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.bgDark
                                : AppColors.inverseOnSurface,
                            borderRadius: AppRadius.xsBorder,
                          ),
                          child: Text(
                            '${(_heatmapOpacity * 100).round()}%',
                            style: AppTypography.codeData(
                              color: isDark
                                  ? AppColors.primaryFixedDim
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_off_outlined,
                          color: AppColors.outlineVariant,
                          size: 24,
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 6,
                              activeTrackColor: isDark
                                  ? AppColors.primaryFixedDim
                                  : AppColors.primary,
                              inactiveTrackColor: AppColors.outlineVariant
                                  .withValues(alpha: 0.3),
                              thumbColor: isDark
                                  ? AppColors.primaryFixedDim
                                  : AppColors.primary,
                              overlayColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            child: Slider(
                              value: _heatmapOpacity,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) {
                                setState(() {
                                  _heatmapOpacity = val;
                                });
                              },
                            ),
                          ),
                        ),
                        Icon(
                          Icons.visibility_outlined,
                          color: isDark ? Colors.white : AppColors.onSurface,
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.swipe,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'heatmap_drag_to_pan'.tr(context),
                            style: AppTypography.caption(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.pinch,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'heatmap_pinch_to_zoom'.tr(context),
                            style: AppTypography.caption(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(
    IconData icon,
    VoidCallback onPressed,
    bool isDark,
  ) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgBorder,
        side: BorderSide(
          color: isDark ? AppColors.inverseSurface : AppColors.border,
        ),
      ),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.lgBorder,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: isDark ? Colors.white : AppColors.onSurface),
        ),
      ),
    );
  }
}
