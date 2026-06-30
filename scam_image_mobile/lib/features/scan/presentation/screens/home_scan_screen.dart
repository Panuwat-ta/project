import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class HomeScanScreen extends StatefulWidget {
  const HomeScanScreen({super.key});

  @override
  State<HomeScanScreen> createState() => _HomeScanScreenState();
}

class _HomeScanScreenState extends State<HomeScanScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      
      if (image != null && mounted) {
        context.push('/crop', extra: image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเข้าถึงกล้องหรือแกลเลอรีได้')),
        );
      }
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('เลือกจากแกลเลอรี'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('ถ่ายภาพด้วยกล้อง'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToResult(int score, String title, String date, String summary, String textTitle, String textDetails, String sourceTitle, String sourceDetails, String visualTitle, String visualDetails) {
    context.push(
      '/result',
      extra: {
        'imagePath': '', // empty fallback
        'riskScore': score,
        'summary': summary,
        'factors': [
          {
            'type': 'textual',
            'score': score > 15 ? score - 15 : 10,
            'title': textTitle,
            'details': [textDetails],
          },
          {
            'type': 'source',
            'score': score > 30 ? score - 30 : 5,
            'title': sourceTitle,
            'details': [sourceDetails],
          },
          {
            'type': 'visual',
            'score': score,
            'title': visualTitle,
            'details': [visualDetails],
          }
        ]
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: isDark ? AppColors.primaryContainer : AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'ScamGuard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.primaryContainer : AppColors.primary,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting Section
              Text(
                'สวัสดี, ผู้ใช้งาน',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'ยินดีต้อนรับกลับสู่ระบบรักษาความปลอดภัยของคุณ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Upload Card
              GestureDetector(
                onTap: _showImageSourceBottomSheet,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [AppColors.darkSurface, Color(0xFF1B2A3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Colors.white, Color(0xFFEDF4FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.outline.withOpacity(0.5) : AppColors.border,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload_outlined,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ตรวจสอบรูปภาพต้องสงสัย',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'เลือกรูปภาพจากอุปกรณ์เพื่อตรวจสอบความเสี่ยง\n(jpg, jpeg, png, webp)',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showImageSourceBottomSheet,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('อัปโหลดรูปภาพ'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Safety Tips Section (Bento Grid Style)
              Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'เคล็ดลับความปลอดภัย',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildBentoTip(
                      icon: Icons.verified_user_outlined,
                      iconColor: AppColors.secondary,
                      text: 'เช็คเครื่องหมายยืนยันตัวตนเสมอ',
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoTip(
                      icon: Icons.link_off_outlined,
                      iconColor: AppColors.tertiary,
                      text: 'ระวังลิงก์แปลกปลอมในข้อความ',
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBentoTip(
                icon: Icons.report_gmailerrorred_outlined,
                iconColor: AppColors.danger,
                text: 'อย่าโอนเงินให้บัญชีบุคคลที่ไม่รู้จัก',
                theme: theme,
              ),
              const SizedBox(height: 32),

              // Recent Scan History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ประวัติการสแกนล่าสุด',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('ดูทั้งหมด', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Custom items with score progress bars
              _buildRecentHistoryItem(
                title: 'สลิปโอนเงินธนาคาร',
                date: '24 ต.ค. 2566 • 14:20',
                score: 92,
                level: 'ความเสี่ยงสูง',
                levelColor: AppColors.danger,
                theme: theme,
                onTap: () => _navigateToResult(
                  92, 'สลิปโอนเงินธนาคาร', '24 ต.ค. 2566',
                  'พบสัญญาณหลายอย่างที่เกี่ยวข้องกับการหลอกลวง ระบบตรวจพบองค์ประกอบที่น่าสงสัยภายในรูปภาพนี้',
                  'วิเคราะห์คำเชิญชวนบนเอกสารสลิป', 'พบคำหรือประโยคเร่งรัดในข้อมูลรายละเอียดการโอนเงิน',
                  'ตรวจสอบฐานข้อมูลสลิปโอนเงิน', 'ไม่พบการทำรายการจริงในประวัติของร้านค้า',
                  'สัณฐานความผิดปกติของภาพ', 'พบคอมพิวเตอร์กราฟิกและการตัดต่อตัวอักษรยอดเงินสลิป'
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentHistoryItem(
                title: 'คิวอาร์โค้ดชำระเงิน',
                date: '23 ต.ค. 2566 • 10:45',
                score: 45,
                level: 'ปานกลาง',
                levelColor: AppColors.warning,
                theme: theme,
                onTap: () => _navigateToResult(
                  45, 'คิวอาร์โค้ดชำระเงิน', '23 ต.ค. 2566',
                  'พบข้อมูลที่ต้องเฝ้าระวังและตรวจสอบเพิ่มเติมในภาพคิวอาร์โค้ดชำระเงินนี้',
                  'วิเคราะห์ข้อความ QR Code', 'ข้อความมีความน่าเชื่อถือในเกณฑ์ปกติ',
                  'วิเคราะห์ตรวจสอบลิงก์ใน QR', 'ลิงก์นำทางไปยังเว็บไซต์แปลกปลอมที่ไม่ใช่โดเมนทางการ',
                  'ตรวจจับร่องรอยการแก้ไข', 'โครงสร้างพิกเซล QR ปกติ แต่ขอบภาพไม่สม่ำเสมอ'
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentHistoryItem(
                title: 'เอกสารยืนยันตัวตน',
                date: '22 ต.ค. 2566 • 09:12',
                score: 12,
                level: 'ปลอดภัย',
                levelColor: AppColors.secondary,
                theme: theme,
                onTap: () => _navigateToResult(
                  12, 'เอกสารยืนยันตัวตน', '22 ต.ค. 2566',
                  'ไม่พบสัญญาณเสี่ยงเด่นชัดในการตรวจสอบเอกสารยืนยันตัวตนนี้เบื้องต้น',
                  'วิเคราะห์ข้อความบัตรประจำตัว', 'ข้อความและฟอนต์สอดคล้องกับมาตรฐานราชการ',
                  'ตรวจสอบการสวมสิทธิ์', 'ไม่พบความเชื่อมโยงกับฐานข้อมูลแบล็คลิสต์ประวัติต้องหา',
                  'การตัดต่อแสงและเงา', 'พื้นผิวของบัตรสม่ำเสมอเป็นเนื้อเดียวกัน ไม่มีรอยแก้'
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoTip({
    required IconData icon,
    required Color iconColor,
    required String text,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.dark
          ? AppColors.darkSurface
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistoryItem({
    required String title,
    required String date,
    required int score,
    required String level,
    required Color levelColor,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.dark
          ? AppColors.darkSurface
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon/Thumbnail Simulator
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: levelColor.withOpacity(0.15)),
                ),
                child: Icon(Icons.image_search_outlined, color: levelColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            level,
                            style: TextStyle(
                              color: levelColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Mini progress indicator
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: score / 100.0,
                              minHeight: 6,
                              backgroundColor: theme.brightness == Brightness.dark
                                  ? Colors.white12
                                  : AppColors.background,
                              valueColor: AlwaysStoppedAnimation(levelColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$score%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
