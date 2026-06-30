import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingConsentScreen extends StatefulWidget {
  const OnboardingConsentScreen({super.key});

  @override
  State<OnboardingConsentScreen> createState() => _OnboardingConsentScreenState();
}

class _OnboardingConsentScreenState extends State<OnboardingConsentScreen> {
  bool _acceptTerms = false;
  bool _allowResearch = false;

  Future<void> _submitConsent() async {
    if (!_acceptTerms) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consent_accepted', true);
    await prefs.setBool('consent_research_allowed', _allowResearch);

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เงื่อนไขความเป็นส่วนตัว'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'ยินดีต้อนรับสู่ Scam Guard',
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'กรุณาตรวจสอบและกดยอมรับข้อตกลงเพื่อความมั่นใจในการใช้งานระบบตรวจสอบรูปภาพ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      
                      // Explanatory card
                      Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ข้อจำกัดและความรับผิดชอบ',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ผลวิเคราะห์ทั้งหมดเป็นการประเมินระดับความเสี่ยงเชิงสถิติจากระบบปัญญาประดิษฐ์และแหล่งข้อมูลสาธารณะ ไม่ถือเป็นข้อยืนยันหรือการตัดสินตามกฎหมาย โปรดใช้ความระมัดระวังก่อนการโอนเงินหรือเปิดเผยข้อมูลใดๆ',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Consents
                      CheckboxListTile(
                        value: _acceptTerms,
                        onChanged: (val) {
                          setState(() {
                            _acceptTerms = val ?? false;
                          });
                        },
                        title: const Text(
                          'ฉันยอมรับข้อตกลงการใช้งานและนโยบายความเป็นส่วนตัว (จำเป็น)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'อนุญาตให้ระบบประมวลผลไฟล์รูปภาพที่ส่งขึ้นระบบเพื่อทำการวิเคราะห์และแสดงผลระดับความเสี่ยง',
                          style: TextStyle(fontSize: 12),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(height: 32),
                      CheckboxListTile(
                        value: _allowResearch,
                        onChanged: (val) {
                          setState(() {
                            _allowResearch = val ?? false;
                          });
                        },
                        title: const Text(
                          'ยินยอมส่งต่อข้อมูลรูปภาพเพื่อการพัฒนาโมเดล (สมัครใจ)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'อนุญาตให้โครงการใช้รูปภาพที่ท่านสแกนสำหรับวิจัยและปรับปรุงโมเดลตรวจจับการหลอกลวงให้แม่นยำยิ่งขึ้น',
                          style: TextStyle(fontSize: 12),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Button
              ElevatedButton(
                onPressed: _acceptTerms ? _submitConsent : null,
                child: const Text('ยอมรับและดำเนินการต่อ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
