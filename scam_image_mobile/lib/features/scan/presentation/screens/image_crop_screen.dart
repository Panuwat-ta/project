import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
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
  final ImageCropper _imageCropper = ImageCropper();

  String get _displayPath => _croppedPath ?? widget.filePath;

  Future<void> _cropImage() async {
    final croppedFile = await _imageCropper.cropImage(
      sourcePath: widget.filePath,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'ครอปรูปภาพ',
          lockAspectRatio: false,
          toolbarColor: AppColors.bgDark,
          toolbarWidgetColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            style: AppTypography.sectionHeader(color: Colors.white),
          ),
        ),
        body: Column(
          children: [
            // ── Image preview ──────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Image.file(
                  File(_displayPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image,
                          color: Colors.white54, size: 64),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'ไม่สามารถโหลดรูปภาพได้',
                        style: AppTypography.bodyBase(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Info text ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Text(
                'รูปภาพจะถูกส่งไปประมวลผลบนระบบ Backend',
                style: AppTypography.caption(
                    color: AppColors.outlineVariant.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
            ),

            // ── Bottom action bar ──────────────────────────────────────────
            Container(
              color: AppColors.surfaceDark,
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  // เปลี่ยนรูป
                  Expanded(
                    child: SecondaryButton(
                      label: 'เปลี่ยนรูป',
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // ครอปรูป
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cropImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryFixedDim,
                        side: const BorderSide(
                            color: AppColors.primaryFixedDim),
                        shape: const StadiumBorder(),
                        minimumSize: const Size(0, 52),
                      ),
                      child: Text(
                        'ครอปรูป',
                        style: AppTypography.buttonLabel(
                            color: AppColors.primaryFixedDim),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // เริ่มวิเคราะห์
                  Expanded(
                    child: PrimaryButton(
                      label: 'เริ่มวิเคราะห์',
                      onPressed: () {
                        context.go(
                          '/loading',
                          extra: {'filePath': _displayPath},
                        );
                      },
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
}
