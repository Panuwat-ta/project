import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class HistoryItem {
  final String id;
  final String title;
  final String date;
  final int riskScore;
  final String riskLevel;
  final IconData icon;

  HistoryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.riskScore,
    required this.riskLevel,
    required this.icon,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<HistoryItem> _allHistory = [
    HistoryItem(
      id: 'scan_001',
      title: 'สลิปโอนเงินธนาคาร',
      date: '24 ต.ค. 2566 • 14:20',
      riskScore: 92,
      riskLevel: 'high',
      icon: Icons.receipt_long_outlined,
    ),
    HistoryItem(
      id: 'scan_002',
      title: 'คิวอาร์โค้ดชำระเงิน',
      date: '23 ต.ค. 2566 • 10:45',
      riskScore: 45,
      riskLevel: 'medium',
      icon: Icons.qr_code_2_outlined,
    ),
    HistoryItem(
      id: 'scan_003',
      title: 'เอกสารยืนยันตัวตน',
      date: '22 ต.ค. 2566 • 09:12',
      riskScore: 12,
      riskLevel: 'low',
      icon: Icons.badge_outlined,
    ),
    HistoryItem(
      id: 'scan_004',
      title: 'ลิงก์ข้อความ SMS',
      date: '21 ต.ค. 2566 • 18:30',
      riskScore: 88,
      riskLevel: 'high',
      icon: Icons.sms_outlined,
    ),
  ];

  List<HistoryItem> _filteredHistory = [];
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, high, medium, low

  @override
  void initState() {
    super.initState();
    _filteredHistory = List.from(_allHistory);
  }

  void _applyFilter() {
    setState(() {
      _filteredHistory = _allHistory.where((item) {
        final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesFilter = _selectedFilter == 'all' || item.riskLevel == _selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
      default:
        return AppColors.danger;
    }
  }

  String _getRiskLevelText(String level) {
    switch (level) {
      case 'low':
        return 'ปลอดภัย';
      case 'medium':
        return 'ปานกลาง';
      case 'high':
      default:
        return 'ความเสี่ยงสูง';
    }
  }

  void _navigateToResult(HistoryItem item) {
    String summary = '';
    String textTitle = '';
    String textDetails = '';
    String sourceTitle = '';
    String sourceDetails = '';
    String visualTitle = '';
    String visualDetails = '';

    if (item.riskLevel == 'high') {
      summary = 'พบสัญญาณหลายอย่างที่เกี่ยวข้องกับการหลอกลวง ระบบตรวจพบองค์ประกอบที่น่าสงสัยภายในรูปภาพนี้';
      textTitle = 'วิเคราะห์คำเชิญชวนบนสลิป/ข้อความ';
      textDetails = 'พบคำหรือประโยคเร่งรัดและผิดปกติในสลิปโอนเงิน';
      sourceTitle = 'ตรวจสอบความถี่ในการแชร์';
      sourceDetails = 'รูปภาพนี้ตรงกับคดีหลอกโอนเงินที่มีการรายงานเข้ามาแล้ว';
      visualTitle = 'ตรวจพบความผิดปกติของพิกเซล';
      visualDetails = 'พบร่องรอยการแก้ไขพิกเซลยอดเงินและเวลาในสลิปอย่างเด่นชัด';
    } else if (item.riskLevel == 'medium') {
      summary = 'พบข้อมูลที่ต้องเฝ้าระวังและตรวจสอบเพิ่มเติมในไฟล์ภาพนี้';
      textTitle = 'วิเคราะห์ข้อความ';
      textDetails = 'ตรวจพบคีย์เวิร์ดที่เข้าข่ายแอบอ้างสิทธิ์การเป็นสถาบันการเงิน';
      sourceTitle = 'ตรวจเช็ค URL หรือลิงก์';
      sourceDetails = 'ลิงก์ในรูปเชื่อมต่อไปยังโดเมนที่ไม่มีใบรับรองความปลอดภัย HTTPS';
      visualTitle = 'วิเคราะห์สัณฐานโครงสร้าง';
      visualDetails = 'แสงและขอบเงาของภาพไม่สม่ำเสมอในระดับปานกลาง';
    } else {
      summary = 'ไม่พบสัญญาณเสี่ยงเด่นชัดในการตรวจสอบเบื้องต้น';
      textTitle = 'การวิเคราะห์ตัวอักษร';
      textDetails = 'โครงสร้างฟอนต์สม่ำเสมอและตรงตามสเปกราชการ';
      sourceTitle = 'ตรวจสอบความปลอดภัยทางระบบ';
      sourceDetails = 'ไม่พบลิงก์หรือประวัติรายงานแบล็คลิสต์ใดๆ';
      visualTitle = 'การตกแต่งพิกเซล';
      visualDetails = 'ภาพมีความเนียนสม่ำเสมอ ไม่พบร่องรอยการแก้ไขดัดแปลงรูปภาพ';
    }

    context.push(
      '/result',
      extra: {
        'imagePath': '', // empty fallback
        'riskScore': item.riskScore,
        'summary': summary,
        'factors': [
          {
            'type': 'textual',
            'score': item.riskScore > 15 ? item.riskScore - 15 : 10,
            'title': textTitle,
            'details': [textDetails],
          },
          {
            'type': 'source',
            'score': item.riskScore > 30 ? item.riskScore - 30 : 5,
            'title': sourceTitle,
            'details': [sourceDetails],
          },
          {
            'type': 'visual',
            'score': item.riskScore,
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
        title: const Text('ประวัติการตรวจสอบ', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Search & Filter Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'ค้นหาประวัติ...',
                            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            fillColor: isDark ? AppColors.darkSurface : Colors.white,
                            filled: true,
                          ),
                          onChanged: (val) {
                            _searchQuery = val;
                            _applyFilter();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune_outlined, color: AppColors.primary),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ทั้งหมด', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ความเสี่ยงสูง', 'high'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ปานกลาง', 'medium'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ปลอดภัย', 'low'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // List view
            Expanded(
              child: _filteredHistory.isEmpty
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: () async {
                        await Future.delayed(const Duration(seconds: 1));
                        setState(() {
                          _filteredHistory = List.from(_allHistory);
                        });
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = _filteredHistory[index];
                          final color = _getRiskColor(item.riskLevel);
                          
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            ),
                            onDismissed: (direction) {
                              setState(() {
                                _allHistory.removeWhere((h) => h.id == item.id);
                                _filteredHistory.removeAt(index);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ลบประวัติการตรวจสอบแล้ว')),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () => _navigateToResult(item),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image/Icon Simulator
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: color.withOpacity(0.15)),
                                        ),
                                        child: Icon(item.icon, color: color, size: 28),
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
                                                    item.title,
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
                                                    color: color.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    _getRiskLevelText(item.riskLevel),
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.date,
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
                                                      value: item.riskScore / 100.0,
                                                      minHeight: 6,
                                                      backgroundColor: isDark
                                                          ? Colors.white12
                                                          : AppColors.background,
                                                      valueColor: AlwaysStoppedAnimation(color),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '${item.riskScore}%',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: color,
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
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilter = value;
            _applyFilter();
          });
        }
      },
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primary
            : isDark
                ? AppColors.darkOnSurface
                : AppColors.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      checkmarkColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_toggle_off_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่พบประวัติการสแกนรูปภาพ',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'เริ่มทำการสแกนรูปภาพใบแรกเพื่อเก็บข้อมูล',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
