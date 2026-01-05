// lib/features/dashboard/presentation/pages/profile_screen.dart

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Profile Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: Color(0xFF2DD4BF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'John Doe',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'john@example.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  _buildStatCard(label: 'Collections', value: '24'),
                  const SizedBox(width: 12),
                  _buildStatCard(label: 'On-Time', value: '95%'),
                  const SizedBox(width: 12),
                  _buildStatCard(label: 'Points', value: '850'),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 16),

                  // Account Section
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    label: 'Edit Profile',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons
                        .location_on_outlined, // ← Fixed: Available in all versions
                    label: 'Manage Addresses',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.payment,
                    label: 'Payment Methods',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),

                  // Preferences Section
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notification Settings',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.language,
                    label: 'Language & Region',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.dark_mode_outlined,
                    label: 'Theme Settings',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),

                  // Support Section
                  const Text(
                    'Support & Legal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    label: 'Help & FAQs',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Version
                  Center(
                    child: Text(
                      'KacharaAlert v1.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2DD4BF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2DD4BF), size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFD1D5DB),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Clear auth state and navigate to login
              Navigator.pushReplacementNamed(context, '/auth');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
