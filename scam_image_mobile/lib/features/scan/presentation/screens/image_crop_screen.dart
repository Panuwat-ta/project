import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../image_crop_navigation.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/image_file_transform.dart';

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
  bool _isTransforming = false;
  double _scale = 1.0;

  String get _displayPath => _croppedPath ?? _currentPath;

  Future<void> _cropImage() async {
    if (_isTransforming) return;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    setState(() => _isTransforming = true);
    try {
      final croppedFile = await _imageCropper.cropImage(
        sourcePath: _displayPath,
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
      if (!mounted) return;
      if (croppedFile != null) {
        setState(() => _croppedPath = croppedFile.path);
      }
    } catch (_) {
      if (mounted) _showImageEditError();
    } finally {
      if (mounted) setState(() => _isTransforming = false);
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('crop_discard_title'.tr(context)),
        content: Text('crop_discard_desc'.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('crop_no'.tr(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('crop_yes'.tr(context)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _pickNewImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _currentPath = image.path;
          _croppedPath = null;
          _scale = 1.0;
        });
      }
    } catch (_) {
      if (mounted) _showImageEditError();
    }
  }

  Future<void> _rotateImage(int angleDegrees) async {
    if (_isTransforming) return;
    setState(() => _isTransforming = true);
    try {
      final path = await rotateImageFile(
        sourcePath: _displayPath,
        angleDegrees: angleDegrees,
      );
      if (!mounted) return;
      setState(() {
        _croppedPath = path;
        _scale = 1.0;
      });
    } catch (_) {
      if (mounted) _showImageEditError();
    } finally {
      if (mounted) setState(() => _isTransforming = false);
    }
  }

  void _showImageEditError() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('crop_edit_error'.tr(context))));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _scale += 0.5;
      if (_scale > 3.0) {
        _scale = 1.0;
      }
    });
  }

  void _resetImage() {
    setState(() {
      _croppedPath = null;
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
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
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
            style: AppTypography.sectionHeader(
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'crop_subtitle'.tr(context),
                      style: AppTypography.bodyBase(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                          borderRadius: AppRadius.lgBorder,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: AppRadius.lgBorder,
                              child: Transform.scale(
                                scale: _scale,
                                child: Image.file(
                                  File(_displayPath),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            color: isDark
                                                ? Colors.white54
                                                : AppColors.textSecondary,
                                            size: 64,
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            'crop_error_load'.tr(context),
                                            style: AppTypography.bodyBase(
                                              color: isDark
                                                  ? Colors.white54
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 4 Action Buttons Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionItem(
                                context,
                                icon: Icons.rotate_left,
                                label: 'crop_rotate_left'.tr(context),
                                isDark: isDark,
                                onTap: () => _rotateImage(-90),
                              ),
                              _buildActionItem(
                                context,
                                icon: Icons.rotate_right,
                                label: 'crop_rotate_right'.tr(context),
                                isDark: isDark,
                                onTap: () => _rotateImage(90),
                              ),
                              _buildActionItem(
                                context,
                                icon: Icons.crop,
                                label: 'crop_aspect_ratio'.tr(context),
                                isDark: isDark,
                                onTap: _cropImage,
                              ),
                              _buildActionItem(
                                context,
                                icon: Icons.zoom_in,
                                label: 'crop_zoom'.tr(context),
                                isDark: isDark,
                                onTap: _zoomIn,
                              ),
                              _buildActionItem(
                                context,
                                icon: Icons.restore,
                                label: 'crop_reset'.tr(context),
                                isDark: isDark,
                                onTap: _resetImage,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryFixedDim.withValues(
                                    alpha: 0.1,
                                  )
                                : AppColors.primarySoftMuted,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                              color: isDark
                                  ? Colors.transparent
                                  : AppColors.primaryFixedDim.withValues(
                                      alpha: 0.2,
                                    ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: isDark
                                    ? AppColors.primaryFixedDim
                                    : AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'crop_info'.tr(context),
                                  style: AppTypography.caption(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Scan Name Input
                        TextFormField(
                          controller: _nameController,
                          style: AppTypography.bodyBase(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'crop_name_hint'.tr(context),
                            hintStyle: AppTypography.bodyBase(
                              color: AppColors.outlineVariant,
                            ),
                            prefixIcon: const Icon(
                              Icons.edit_document,
                              color: AppColors.outlineVariant,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.inverseSurface
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.lgBorder,
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.lgBorder,
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.lgBorder,
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.primaryFixedDim
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Primary Action
                        PrimaryButton(
                          label: 'crop_start_analysis'.tr(context),
                          leadingIcon: const Icon(Icons.search, size: 20),
                          onPressed: () {
                            context.go(
                              '/loading',
                              extra: buildAnalysisNavigationExtra(
                                filePath: _displayPath,
                                scanName: _nameController.text,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Secondary Action
                        OutlinedButton(
                          onPressed: _pickNewImage,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? AppColors.primaryFixedDim
                                : AppColors.primary,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.primaryFixedDim
                                  : AppColors.primary,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.image_outlined, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'crop_change_image'.tr(context),
                                style: AppTypography.buttonLabel(
                                  color: isDark
                                      ? AppColors.primaryFixedDim
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
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

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smBorder,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDark ? AppColors.outlineVariant : AppColors.onSurface,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
