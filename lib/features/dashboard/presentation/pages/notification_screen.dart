// lib/features/dashboard/presentation/pages/notification_screen.dart

import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Collection Tomorrow',
      'description':
          'Your garbage collection is scheduled for tomorrow at 10:30 AM',
      'time': '2 hours ago',
      'icon': Icons.calendar_today_rounded,
      'iconColor': Color(0xFF2DD4BF),
      'read': false,
    },
    {
      'title': 'Collection Completed',
      'description': 'Your garbage was successfully collected today',
      'time': '1 day ago',
      'icon': Icons.check_circle_rounded,
      'iconColor': Colors.green,
      'read': true,
    },
    {
      'title': 'Schedule Changed',
      'description':
          'Your collection schedule has been updated. Please review the new timing.',
      'time': '3 days ago',
      'icon': Icons.notifications_active_rounded,
      'iconColor': Colors.orange,
      'read': true,
    },
    {
      'title': 'Reminder: Missed Collection',
      'description':
          'You missed the collection on Friday. Please reschedule if needed.',
      'time': '5 days ago',
      'icon': Icons.warning_rounded,
      'iconColor': Colors.red,
      'read': true,
    },
    {
      'title': 'System Maintenance',
      'description': 'Scheduled maintenance on Saturday, 2:00 AM - 4:00 AM',
      'time': '1 week ago',
      'icon': Icons.build_rounded,
      'iconColor': Colors.purple,
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n['read']).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF2DD4BF).withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_rounded,
                        color: Color(0xFF2DD4BF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have $unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['read']
            ? Colors.white
            : const Color(0xFF2DD4BF).withOpacity(0.05),
        border: Border.all(
          color: notification['read']
              ? const Color(0xFFD1D5DB)
              : const Color(0xFF2DD4BF).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (notification['iconColor'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notification['icon'],
              color: notification['iconColor'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!notification['read'])
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2DD4BF),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification['description'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  notification['time'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('Mark as read')),
              const PopupMenuItem(child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
