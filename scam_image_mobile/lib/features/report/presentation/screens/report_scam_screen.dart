import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class ReportScamScreen extends StatefulWidget {
  final String imagePath;

  const ReportScamScreen({super.key, required this.imagePath});

  @override
  State<ReportScamScreen> createState() => _ReportScamScreenState();
}

class _ReportScamScreenState extends State<ReportScamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _suspectInfoController = TextEditingController();
  final _platformController = TextEditingController();

  String _selectedCategory = 'Romance Scam (หลอกให้รัก)';
  bool _allowResearch = true;
  bool _disclaimerConfirmed = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Romance Scam (หลอกให้รัก)',
    'Online Shopping (ซื้อของไม่ได้ของ)',
    'Fake Slip (สลิปปลอม)',
    'Investment Scam (หลอกลงทุน)',
    'Identity Theft (สวมรอยตัวตน)',
    'AI / Deepfake',
    'อื่นๆ'
  ];

  final List<String> _platforms = [
    'Facebook',
    'LINE',
    'Instagram',
    'TikTok',
    'Marketplace',
    'เว็บไซต์ทั่วไป',
    'อื่นๆ'
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _suspectInfoController.dispose();
    _platformController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_disclaimerConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากดยืนยันข้อตกลงเกี่ยวกับการคุ้มครองข้อมูลของบุคคลที่สาม')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // จำลองการเรียก API ส่งรายงาน (1.5 วินาที)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ส่งรายงานสำเร็จแล้ว'),
          content: const Text('ขอบคุณสำหรับการร่วมสร้างสังคมที่ปลอดภัย ข้อมูลของท่านจะได้รับการตรวจสอบและอัปเดตเข้าระบบกลางเพื่อแจ้งเตือนผู้อื่นต่อไป'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ปิด Dialog
                context.go('/'); // กลับสู่หน้าหลัก
              },
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานภาพมิจฉาชีพ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image preview thumbnail
                if (widget.imagePath.isNotEmpty) ...[
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        Image.file(
                          File(widget.imagePath),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'รูปภาพที่จะรายงาน',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.imagePath.split('/').last,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Dropdown Category
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'ประเภทเหตุการณ์มิจฉาชีพ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Platform Autocomplete or Choice
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'ช่องทางแพลตฟอร์มที่พบภัย',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: _platforms.map((plat) {
                    return DropdownMenuItem<String>(
                      value: plat,
                      child: Text(plat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _platformController.text = val;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาเลือกช่องทางที่พบ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Suspect / Account info
                TextFormField(
                  controller: _suspectInfoController,
                  decoration: const InputDecoration(
                    labelText: 'ข้อมูลบัญชีต้องสงสัย (ลิงก์/ชื่อผู้ใช้/หมายเลขบัญชี)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดพฤติการณ์ (ขั้นต่ำ 10 ตัวอักษร)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรายละเอียดเหตุการณ์';
                    }
                    if (value.length < 10) {
                      return 'กรุณากรอกรายละเอียดอย่างน้อย 10 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Consents & Disclaimers
                CheckboxListTile(
                  value: _allowResearch,
                  onChanged: (val) {
                    setState(() {
                      _allowResearch = val ?? true;
                    });
                  },
                  title: const Text('ยินยอมให้ใช้รูปภาพและข้อมูลเพื่อปรับปรุงระบบตรวจจับส่วนกลาง', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _disclaimerConfirmed,
                  onChanged: (val) {
                    setState(() {
                      _disclaimerConfirmed = val ?? false;
                    });
                  },
                  title: const Text('ฉันยืนยันว่าไม่มีข้อมูลส่วนบุคคลที่ไม่จำเป็นของบุคคลที่สามในคำอธิบายและรูปภาพนี้', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('ส่งรายงานความผิดปกติ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
