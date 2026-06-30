import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _analyzeConsent = true;
  bool _historyConsent = true;
  bool _researchConsent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConsentSettings();
  }

  Future<void> _loadConsentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _analyzeConsent = prefs.getBool('consent_accepted') ?? true;
      _historyConsent = prefs.getBool('consent_history_saved') ?? true;
      _researchConsent = prefs.getBool('consent_research_allowed') ?? false;
    });
  }

  Future<void> _saveConsentSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consent_accepted', _analyzeConsent);
    await prefs.setBool('consent_history_saved', _historyConsent);
    await prefs.setBool('consent_research_allowed', _researchConsent);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกการตั้งค่าความเป็นส่วนตัวแล้ว')),
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบบัญชีผู้ใช้ถาวร?'),
        content: const Text(
          'การขอลบบัญชีจะส่งผลให้ข้อมูลโปรไฟล์ ประวัติการสแกน และข้อมูลทั้งหมดของคุณถูกลบอย่างถาวรตามกฎหมาย PDPA การดำเนินการนี้ไม่สามารถยกเลิกได้',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // ในความเป็นจริงจะส่งคำขอลบไปยัง Backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ส่งคำขอลบบัญชีเข้าสู่ระบบแล้ว ระบบจะใช้เวลาดำเนินการภายใน 24 ชม.')),
              );
            },
            child: const Text('ยืนยันการลบ', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ความเป็นส่วนตัว & Consent'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                children: [
                  Text(
                    'การจัดการความยินยอม (Consent Management)',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'คุณสามารถเลือกเปิดหรือปิดความยินยอมในการประมวลผลข้อมูลของคุณได้ตลอดเวลาตามสิทธิของเจ้าของข้อมูลส่วนบุคคล (PDPA)',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Switched list tiles
                  SwitchListTile(
                    value: _analyzeConsent,
                    onChanged: (val) {
                      setState(() {
                        _analyzeConsent = val;
                      });
                    },
                    title: const Text('ยินยอมให้ประมวลผลรูปภาพเพื่อสแกนวิเคราะห์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('จำเป็นสำหรับการสแกนรูปภาพ หากปิดจะไม่สามารถใช้ฟังก์ชันสแกนตรวจสอบได้', style: TextStyle(fontSize: 12)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    value: _historyConsent,
                    onChanged: (val) {
                      setState(() {
                        _historyConsent = val;
                      });
                    },
                    title: const Text('ยินยอมให้ระบบบันทึกประวัติการสแกน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('เพื่อช่วยให้คุณสามารถกลับมาดูรายละเอียดผลวิเคราะห์ย้อนหลังได้ทุกเมื่อ', style: TextStyle(fontSize: 12)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    value: _researchConsent,
                    onChanged: (val) {
                      setState(() {
                        _researchConsent = val;
                      });
                    },
                    title: const Text('ยินยอมให้นำข้อมูลภาพไปใช้ในการวิจัยปรับปรุงโมเดล', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('เพื่อพัฒนาโมเดลตรวจสอบของแอปพลิเคชันให้มีประสิทธิภาพความแม่นยำสูงขึ้น (สมัครใจ)', style: TextStyle(fontSize: 12)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const Divider(height: 48),
                  
                  Text('สิทธิของเจ้าของข้อมูล (Data Subject Rights)', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  
                  // Data Export
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.download_outlined, color: AppColors.primary),
                      title: const Text('ขอรับสำเนาข้อมูลส่วนบุคคล (Data Portability)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('ส่งข้อมูลบัญชีและประวัติการสแกนทั้งหมดของคุณเข้าสู่อีเมล', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('กำลังดำเนินการส่งสำเนาข้อมูลไปยังอีเมลของคุณ...')),
                        );
                      },
                    ),
                  ),
                  
                  // Account Delete
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
                      title: const Text('ขอถอนการลงทะเบียนและลบข้อมูลถาวร', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.danger)),
                      subtitle: const Text('ลบบัญชีผู้ใช้งานและล้างประวัติข้อมูลทั้งหมดออกจากเซิร์ฟเวอร์', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.danger),
                      onTap: _confirmDeleteAccount,
                    ),
                  ),
                ],
              ),
            ),
            
            // Save Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveConsentSettings,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('บันทึกการตั้งค่าความเป็นส่วนตัว'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
