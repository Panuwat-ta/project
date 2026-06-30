import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class ImagePreviewCropScreen extends StatefulWidget {
  final String imagePath;

  const ImagePreviewCropScreen({super.key, required this.imagePath});

  @override
  State<ImagePreviewCropScreen> createState() => _ImagePreviewCropScreenState();
}

class _ImagePreviewCropScreenState extends State<ImagePreviewCropScreen> {
  late String _currentImagePath;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  Future<void> _cropImage() async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _currentImagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'ปรับขอบเขตรูปภาพ',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primaryContainer,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'ปรับขอบเขตรูปภาพ',
            doneButtonTitle: 'เสร็จสิ้น',
            cancelButtonTitle: 'ยกเลิก',
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _currentImagePath = croppedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถครอปรูปภาพได้')),
        );
      }
    }
  }

  void _startAnalysis() {
    // นำทางไปยังหน้า Loading พร้อมส่ง path รูปภาพ
    context.pushReplacement('/loading', extra: _currentImagePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบรูปภาพ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // แสดง Dialog ยืนยันยกเลิกหากมีการแก้ไข
            if (_currentImagePath != widget.imagePath) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ยกเลิกการเปลี่ยนแปลง?'),
                  content: const Text('การแก้ไขและรูปภาพนี้จะไม่ถูกบันทึก'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // ปิด Dialog
                        context.pop(); // กลับหน้าหลัก
                      },
                      child: const Text('ยืนยัน'),
                    ),
                  ],
                ),
              );
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    File(_currentImagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'คำแนะนำ: ครอปเฉพาะบริเวณสำคัญ เช่น ข้อความสลิปโอนเงิน หรือรูปโปรไฟล์ เพื่อความแม่นยำในการวิเคราะห์ระดับความเสี่ยง',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cropImage,
                      icon: const Icon(Icons.crop),
                      label: const Text('ครอปภาพ'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startAnalysis,
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('เริ่มวิเคราะห์'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
