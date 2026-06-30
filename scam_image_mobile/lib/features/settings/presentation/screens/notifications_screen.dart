import 'package:flutter/material.dart';
import 'package:scam_image_mobile/core/theme/app_colors.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final IconData icon;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.icon,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif_001',
      title: 'งานวิเคราะห์สำเร็จเสร็จสิ้น',
      body: 'รูปภาพ สลิปโอนเงิน กสิกรไทย.jpg ได้รับการประมวลผลแล้ว (ความเสี่ยงสูง)',
      time: '1 ชั่วโมงที่แล้ว',
      isRead: false,
      icon: Icons.check_circle_outline,
    ),
    AppNotification(
      id: 'notif_002',
      title: 'ภัยกลโกงใหม่: Romance Scam ระบาด',
      body: 'โปรดเฝ้าระวังผู้ใช้โปรไฟล์ที่น่าสงสัยและเร่งรัดให้ทำธุรกรรมทางการเงิน',
      time: '1 วันที่แล้ว',
      isRead: true,
      icon: Icons.warning_amber_rounded,
    ),
  ];

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ล้างการแจ้งเตือนทั้งหมดแล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('ล้างทั้งหมด', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: SafeArea(
        child: _notifications.isEmpty
            ? _buildEmptyState(theme)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: notif.isRead
                        ? null
                        : AppColors.primary.withOpacity(0.03),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notif.isRead
                            ? Colors.grey[200]
                            : AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          notif.icon,
                          color: notif.isRead ? Colors.grey[600] : AppColors.primary,
                        ),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            notif.time,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          notif.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _notifications[index] = AppNotification(
                            id: notif.id,
                            title: notif.title,
                            body: notif.body,
                            time: notif.time,
                            isRead: true,
                            icon: notif.icon,
                          );
                        });
                      },
                    ),
                  );
                },
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
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือนใหม่',
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
