import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/widgets.dart';

/// Full-screen image preview + crop screen.
///
/// Receives [filePath] (the picked image path) as a constructor argument.
/// Users can crop the image with [ImageCropper], change the image (pop back),
/// or confirm and navigate to `/loading` for analysis.
///
/// A back-press confirmation dialog is shown when the user tries to navigate
/// back after the screen has loaded.
class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({super.key, required this.filePath});

  final String filePath;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  String? _croppedPath;
  late String _currentPath = widget.filePath;
  final ImageCropper _imageCropper = ImageCropper();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  
  double _rotation = 0.0;
  double _scale = 1.0;

  String get _displayPath => _croppedPath ?? _currentPath;

  Future<void> _cropImage() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final croppedFile = await _imageCropper.cropImage(
      sourcePath: widget.filePath,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'crop_title'.tr(context),
          lockAspectRatio: false,
          toolbarColor: Theme.of(context).scaffoldBackgroundColor,
          toolbarWidgetColor: isDark ? Colors.white : AppColors.onSurface,
        ),
        IOSUiSettings(title: 'crop_title'.tr(context)),
      ],
    );
    if (croppedFile != null) {
      setState(() {
        _croppedPath = croppedFile.path;
      });
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('crop_discard_title'.tr(context)),
        content: Text('crop_discard_desc'.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('crop_no'.tr(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('crop_yes'.tr(context)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _pickNewImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _currentPath = image.path;
        _croppedPath = null;
        _rotation = 0.0;
        _scale = 1.0;
      });
    }
  }

  void _rotateLeft() {
    setState(() => _rotation -= 3.14159 / 2);
  }

  void _rotateRight() {
    setState(() => _rotation += 3.14159 / 2);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _scale += 0.5;
      if (_scale > 3.0) _scale = 1.0;
    });
  }

  void _resetImage() {
    setState(() {
      _currentPath = widget.filePath;
      _croppedPath = null;
      _rotation = 0.0;
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _confirmDiscard(context);
        if (confirmed && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.onSurface),
            tooltip: 'crop_back_tooltip'.tr(context),
            onPressed: () async {
              final confirmed = await _confirmDiscard(context);
              if (confirmed && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            'crop_check_image'.tr(context),
            style: AppTypography.sectionHeader(color: isDark ? Colors.white : AppColors.onSurface),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : AppColors.onSurface),
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
            // ── Subtitle ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Text(
                'crop_subtitle'.tr(context),
                style: AppTypography.bodyBase(color: isDark ? AppColors.outlineVariant : AppColors.textSecondary),
              ),
            ),
            
            // ── Image preview ──────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Transform.scale(
                          scale: _scale,
                          child: Transform.rotate(
                            angle: _rotation,
                            child: Image.file(
                              File(_displayPath),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image,
                                      color: isDark ? Colors.white54 : AppColors.textSecondary, size: 64),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'crop_error_load'.tr(context),
                                    style: AppTypography.bodyBase(color: isDark ? Colors.white54 : AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Fake crop corners (Cyan)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Stack(
                            children: [
                              // Grid lines
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(height: 1, color: Colors.white.withValues(alpha: 0.3)),
                                  Container(height: 1, color: Colors.white.withValues(alpha: 0.3)),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(width: 1, color: Colors.white.withValues(alpha: 0.3)),
                                  Container(width: 1, color: Colors.white.withValues(alpha: 0.3)),
                                ],
                              ),
                              // Corners
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: AppColors.primaryFixedDim, width: 3),
                                      left: BorderSide(color: AppColors.primaryFixedDim, width: 3),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: AppColors.primaryFixedDim, width: 3),
                                      right: BorderSide(color: AppColors.primaryFixedDim, width: 3),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: AppColors.primaryFixedDim, width: 3),
                                      left: BorderSide(color: AppColors.primaryFixedDim, width: 3),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: AppColors.primaryFixedDim, width: 3),
                                      right: BorderSide(color: AppColors.primaryFixedDim, width: 3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom section (Action buttons + Info + Main Buttons) ─────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 4 Action Buttons Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionItem(context, icon: Icons.rotate_left, label: 'crop_rotate_left'.tr(context), isDark: isDark, onTap: _rotateLeft),
                        _buildActionItem(context, icon: Icons.rotate_right, label: 'crop_rotate_right'.tr(context), isDark: isDark, onTap: _rotateRight),
                        _buildActionItem(context, icon: Icons.crop, label: 'crop_aspect_ratio'.tr(context), isDark: isDark, onTap: _cropImage),
                        _buildActionItem(context, icon: Icons.zoom_in, label: 'crop_zoom'.tr(context), isDark: isDark, onTap: _zoomIn),
                        _buildActionItem(context, icon: Icons.restore, label: 'crop_reset'.tr(context), isDark: isDark, onTap: _resetImage),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primaryFixedDim.withValues(alpha: 0.1) : const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.transparent : AppColors.primaryFixedDim.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user, color: isDark ? AppColors.primaryFixedDim : AppColors.primary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'crop_info'.tr(context),
                            style: AppTypography.caption(color: isDark ? AppColors.outlineVariant : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Scan Name Input
                  TextFormField(
                    controller: _nameController,
                    style: AppTypography.bodyBase(color: isDark ? Colors.white : AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'crop_name_hint'.tr(context),
                      hintStyle: AppTypography.bodyBase(color: AppColors.outlineVariant),
                      prefixIcon: const Icon(Icons.edit_document, color: AppColors.outlineVariant, size: 20),
                      filled: true,
                      fillColor: isDark ? AppColors.inverseSurface : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppColors.primaryFixedDim : AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Primary Action
                  PrimaryButton(
                    label: 'crop_start_analysis'.tr(context),
                    leadingIcon: const Icon(Icons.search, size: 20),
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('crop_error_empty_name'.tr(context)),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      context.go('/loading', extra: {
                        'filePath': _displayPath,
                        'scanName': _nameController.text.trim(),
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Secondary Action
                  OutlinedButton(
                    onPressed: _pickNewImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                      side: BorderSide(color: isDark ? AppColors.primaryFixedDim : AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_outlined, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text('crop_change_image'.tr(context), style: AppTypography.buttonLabel(color: isDark ? AppColors.primaryFixedDim : AppColors.primary)),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
);
}

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label, required bool isDark, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDark ? AppColors.outlineVariant : AppColors.onSurface, size: 24),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption(color: isDark ? AppColors.outlineVariant : AppColors.textSecondary)),
        ],
      ),
    );
  }
}

