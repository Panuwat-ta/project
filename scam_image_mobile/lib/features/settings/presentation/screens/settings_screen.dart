import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userEmail = 'กำลังโหลด...';
  String _userName = 'กำลังโหลด...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('user_email') ?? 'user@scamguard.com';
      _userName = prefs.getString('user_name') ?? 'สมชาย รักดี';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    
    if (mounted) {
      context.go('/login');
    }
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ?'),
        content: const Text('คุณต้องการออกจากระบบการใช้งานในบัญชีปัจจุบันใช่หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('ยืนยันออกจากระบบ', style: TextStyle(color: AppColors.danger)),
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
        title: const Text('ตั้งค่า'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            // User profile header
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryContainer.withOpacity(0.2),
                      child: const Icon(Icons.person, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userEmail,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Settings options
            Text('บัญชีและการใช้งาน', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.security_outlined,
              title: 'ความปลอดภัยของบัญชี',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.notifications_none_outlined,
              title: 'ตั้งค่าการแจ้งเตือน',
              onTap: () {},
            ),
            const Divider(height: 32),
            
            Text('ข้อมูลส่วนบุคคลและความเป็นส่วนตัว', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'ความยินยอมและสิทธิข้อมูลส่วนบุคคล',
              onTap: () {
                context.push('/privacy-consent');
              },
            ),
            _buildSettingsTile(
              icon: Icons.delete_outline_outlined,
              title: 'ล้างข้อมูลแคชในแอปพลิเคชัน',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ล้างข้อมูลแคชสำเร็จแล้ว')),
                );
              },
            ),
            const Divider(height: 32),

            Text('ข้อมูลระบบ', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildSettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'เกี่ยวกับ Scam Guard',
              trailing: const Text('v1.0.0', style: TextStyle(color: AppColors.textSecondary)),
              onTap: () {},
            ),
            
            const SizedBox(height: 24),
            
            // Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: _showLogoutConfirmDialog,
              icon: const Icon(Icons.logout),
              label: const Text('ออกจากระบบ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
