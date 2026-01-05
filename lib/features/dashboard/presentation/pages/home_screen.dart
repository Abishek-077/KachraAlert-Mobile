// lib/features/dashboard/presentation/pages/home_screen.dart

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep your area clean today',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2DD4BF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Collection',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Monday, 10:30 AM',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.7,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '2 days remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.schedule_rounded,
                      label: 'View\nSchedule',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickActionCard(
                      icon: Icons.edit_notifications_rounded,
                      label: 'Edit\nPreferences',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickActionCard(
                      icon: Icons.location_on_rounded,
                      label: 'My\nLocation',
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Statistics
                const Text(
                  'Your Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard(
                      label: 'Collections',
                      value: '24',
                      icon: Icons.delete_outline_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'On-Time Rate',
                      value: '95%',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Activity
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActivityItem(
                  title: 'Garbage Collected',
                  subtitle: 'Monday, 10:45 AM',
                  icon: Icons.check_circle_rounded,
                  iconColor: Colors.green,
                ),
                const SizedBox(height: 12),
                _buildActivityItem(
                  title: 'Schedule Reminder',
                  subtitle: 'Friday, 8:00 PM',
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFF2DD4BF),
                ),
                const SizedBox(height: 12),
                _buildActivityItem(
                  title: 'Skipped Collection',
                  subtitle: 'Wednesday, 10:30 AM',
                  icon: Icons.info_rounded,
                  iconColor: Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2DD4BF), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
