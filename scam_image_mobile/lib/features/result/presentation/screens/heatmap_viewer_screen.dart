import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

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
  double _heatmapOpacity = 0.7;
  final TransformationController _transformationController = TransformationController();

  void _zoomIn() {
    final Matrix4 matrix = _transformationController.value;
    matrix.scale(1.2);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final Matrix4 matrix = _transformationController.value;
    matrix.scale(0.8);
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
    if (widget.heatmapUrl != null && widget.heatmapUrl!.isNotEmpty) {
      return Opacity(
        opacity: _heatmapOpacity,
        child: Image.network(
          widget.heatmapUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    }
    // Demo heatmap overlay
    return Opacity(
      opacity: _heatmapOpacity,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.2, -0.1),
            radius: 0.6,
            colors: [
              Colors.red.withValues(alpha: 0.8),
              Colors.orange.withValues(alpha: 0.5),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F8FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : AppColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'ตรวจสอบรายละเอียด',
          style: AppTypography.sectionHeader(color: isDark ? Colors.white : AppColors.onSurface),
        ),
        centerTitle: true,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.transparent : Colors.white,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                'ภาพต้นฉบับ',
                style: AppTypography.caption(color: isDark ? Colors.white : AppColors.onSurface),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.safeMargin, vertical: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162230) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF27313C) : AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.outlineVariant, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'พื้นที่สีแดงแสดงถึงจุดที่ AI ตรวจพบความผิดปกติของพิกเซลที่มักเกิดจากการตัดต่อหรือการสร้างภาพปลอม',
                    style: AppTypography.caption(color: isDark ? Colors.white70 : AppColors.textSecondary),
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
                    children: [
                      _buildBaseImage(),
                      _buildHeatmapOverlay(),
                    ],
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
          Container(
            color: isDark ? const Color(0xFF162230) : Colors.white,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.safeMargin,
              AppSpacing.md,
              AppSpacing.safeMargin,
              40, // extra padding for bottom safe area
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ความเข้มของ Heatmap',
                      style: AppTypography.bodyBase(color: isDark ? Colors.white : AppColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F1720) : const Color(0xFFE8F2FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(_heatmapOpacity * 100).round()}%',
                        style: AppTypography.codeData(color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.visibility_off_outlined, color: AppColors.outlineVariant, size: 24),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 6,
                          activeTrackColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                          inactiveTrackColor: AppColors.outlineVariant.withValues(alpha: 0.3),
                          thumbColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                          overlayColor: AppColors.primary.withValues(alpha: 0.1),
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
                    Icon(Icons.visibility_outlined, color: isDark ? Colors.white : AppColors.onSurface, size: 24),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.swipe, color: AppColors.outlineVariant, size: 18),
                        const SizedBox(width: 4),
                        Text('ลากเพื่อเลื่อน', style: AppTypography.caption(color: AppColors.outlineVariant)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.pinch, color: AppColors.outlineVariant, size: 18),
                        const SizedBox(width: 4),
                        Text('จีบเพื่อซูม', style: AppTypography.caption(color: AppColors.outlineVariant)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(IconData icon, VoidCallback onPressed, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF162230) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF27313C) : AppColors.border),
      ),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
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
