import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class AnalysisLoadingScreen extends StatefulWidget {
  final String imagePath;

  const AnalysisLoadingScreen({super.key, required this.imagePath});

  @override
  State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen> {
  int _currentStep = 0;
  late Timer _timer;
  
  final List<String> _statusMessages = [
    'กำลังอัปโหลดไฟล์ภาพไปยังเซิร์ฟเวอร์...',
    'กำลังอ่านข้อความและวิเคราะห์บริบทคำเชิญชวน (OCR & Textual Analysis)...',
    'กำลังตรวจสอบแหล่งที่มาของภาพในฐานข้อมูล (Source Verification)...',
    'กำลังวิเคราะห์สัณฐานและความผิดปกติของภาพ (Visual Anomaly & AI-Generated Check)...',
    'ประมวลผลเสร็จสิ้น กำลังจัดทำรายงาน...',
  ];

  @override
  void initState() {
    super.initState();
    _startMockAnalysis();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startMockAnalysis() {
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_currentStep < 4) {
        setState(() {
          _currentStep++;
        });
      } else {
        _timer.cancel();
        // ไปหน้า Result เมื่อโหลดจำลองครบกำหนด
        if (mounted) {
          context.pushReplacement(
            '/result',
            extra: {
              'imagePath': widget.imagePath,
              'riskScore': 82,
              'riskLevel': 'high',
              'summary': 'พบสัญญาณหลายอย่างที่ควรระวัง โปรดหลีกเลี่ยงการเปิดเผยข้อมูลหรือโอนเงิน',
              'factors': [
                {
                  'type': 'textual',
                  'score': 75,
                  'title': 'พบข้อความชักชวนให้โอนเงิน',
                  'details': ['พบคำชักชวนเชิงเร่งรัด: โอนทันที', 'พบเลขที่บัญชีธนาคารภายในรูปภาพ']
                },
                {
                  'type': 'source',
                  'score': 60,
                  'title': 'พบภาพใกล้เคียงจากฐานข้อมูลอื่น',
                  'details': ['พบประวัติรูปภาพเดียวกันถูกใช้งานในเว็บไซต์สื่อสังคมออนไลน์อื่น']
                },
                {
                  'type': 'visual',
                  'score': 90,
                  'title': 'พบความผิดปกติบนเนื้อหาภาพ',
                  'details': ['พบลักษณะแสงและขอบภาพไม่กลมกลืนบริเวณใบหน้า', 'มีความเป็นไปได้สูงที่เป็นรูปภาพสร้างจาก AI']
                }
              ]
            },
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Scanning Animation Placeholder
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: (_currentStep + 1) / 5,
                        strokeWidth: 6,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const Icon(
                      Icons.security,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Progress text
              Text(
                'ระบบกำลังประมวลผลรูปภาพ',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusMessages[_currentStep],
                  key: ValueKey<int>(_currentStep),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Stepper indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isCompleted = index < _currentStep;
                  final isCurrent = index == _currentStep;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary
                          : isCurrent
                              ? AppColors.primaryContainer
                              : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const Spacer(),
              
              // Cancel Button
              OutlinedButton(
                onPressed: () {
                  _timer.cancel();
                  context.go('/');
                },
                child: const Text('ยกเลิกการสแกน'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
