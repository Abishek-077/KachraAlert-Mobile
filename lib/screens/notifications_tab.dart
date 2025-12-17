import 'package:flutter/material.dart';
import 'package:kachra_alert/widget/change_notifier_provider.dart';
import '../app_state.dart';

import '../models/notification_item.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ChangeNotifierProvider.of<AppState>(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00D9C0), Color(0xFF00F5D4)],
              ).createShader(bounds),
              child: const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.unreadNotifications} unread notifications',
              style: const TextStyle(fontSize: 14, color: Color(0xFF8F9BB3)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _buildNotificationCard(context, state, notification);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppState state,
    NotificationItem notification,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? const Color(0xFF1A1F3A)
            : const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? const Color(0xFF2A2F4A)
              : const Color(0xFF00D9C0),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            state.markNotificationAsRead(notification.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getNotificationColor(notification.type),
                        _getNotificationColor(
                          notification.type,
                        ).withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
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
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: notification.isRead
                                    ? const Color(0xFF8F9BB3)
                                    : Colors.white,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00D9C0),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8F9BB3),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
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
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'reminder':
        return Icons.notifications_active;
      case 'payment':
        return Icons.payment;
      case 'alert':
        return Icons.warning_amber;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'reminder':
        return const Color(0xFF00D9C0);
      case 'payment':
        return const Color(0xFFFF6B6B);
      case 'alert':
        return const Color(0xFFFFA726);
      case 'success':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF8F9BB3);
    }
  }
}
