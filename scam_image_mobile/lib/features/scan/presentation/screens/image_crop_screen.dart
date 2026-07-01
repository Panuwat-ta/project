import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
          toolbarTitle: 'ครอปรูปภาพ',
          lockAspectRatio: false,
          toolbarColor: Theme.of(context).scaffoldBackgroundColor,
          toolbarWidgetColor: isDark ? Colors.white : AppColors.onSurface,
        ),
        IOSUiSettings(title: 'ครอปรูปภาพ'),
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
        title: const Text('ยกเลิกการแก้ไข?'),
        content: const Text('รูปภาพที่แก้ไขจะไม่ถูกบันทึก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ใช่'),
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
            tooltip: 'ย้อนกลับ',
            onPressed: () async {
              final confirmed = await _confirmDiscard(context);
              if (confirmed && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            'ตรวจสอบรูปภาพ',
            style: AppTypography.sectionHeader(color: isDark ? Colors.white : AppColors.onSurface),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : AppColors.onSurface),
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Subtitle ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Text(
                'ปรับแต่งรูปภาพของคุณให้เห็นส่วนที่ต้องการวิเคราะห์ได้ชัดเจนที่สุด',
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
                                    'ไม่สามารถโหลดรูปภาพได้',
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
                        _buildActionItem(context, icon: Icons.rotate_left, label: 'หมุนซ้าย', isDark: isDark, onTap: _rotateLeft),
                        _buildActionItem(context, icon: Icons.rotate_right, label: 'หมุนขวา', isDark: isDark, onTap: _rotateRight),
                        _buildActionItem(context, icon: Icons.crop, label: 'สัดส่วน', isDark: isDark, onTap: _cropImage),
                        _buildActionItem(context, icon: Icons.zoom_in, label: 'ขยาย', isDark: isDark, onTap: _zoomIn),
                        _buildActionItem(context, icon: Icons.restore, label: 'รีเซ็ต', isDark: isDark, onTap: _resetImage),
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
                            'รูปภาพจะถูกส่งไปวิเคราะห์บนระบบคลาวด์อย่างปลอดภัย ข้อมูลของคุณจะได้รับการเข้ารหัสและไม่มีการเปิดเผยต่อสาธารณะ',
                            style: AppTypography.caption(color: isDark ? AppColors.outlineVariant : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Primary Action
                  PrimaryButton(
                    label: 'เริ่มวิเคราะห์',
                    leadingIcon: const Icon(Icons.search, size: 20),
                    onPressed: () {
                      context.go('/loading', extra: {'filePath': _displayPath});
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
                        Text('เปลี่ยนรูป', style: AppTypography.buttonLabel(color: isDark ? AppColors.primaryFixedDim : AppColors.primary)),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
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

