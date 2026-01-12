import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final authAsync = ref.watch(authStateProvider);

    final auth = authAsync.valueOrNull;

    final email = (auth?.session?.email ?? '').trim();
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';
    final isAdmin = auth?.session?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),

      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load settings: $e')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        child: Text(
                          initial,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email.isNotEmpty ? email : 'Guest User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              settings.isDarkMode
                                  ? 'Dark Mode: ON'
                                  : 'Dark Mode: OFF',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: SwitchListTile(
                  value: settings.isDarkMode,
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Make it easy on your eyes 🌙'),
                  onChanged: (_) =>
                      ref.read(settingsProvider.notifier).toggleTheme(),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About Developer'),
                  subtitle: const Text('Fun + short'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('About Developer'),
                      content: Text(
                        "Built with love, coffee, and last-minute debugging.\n"
                        "If something breaks, I’ll call it a ‘feature’ 😅",
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ Only show for admins
              if (isAdmin == true) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded),
                    title: const Text('Admin Panel'),
                    subtitle: const Text('Send alerts to citizens'),
                    onTap: () => context.push('/admin/broadcast'),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ✅ Everyone can view announcements
              Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign_rounded),
                  title: const Text('Announcements'),
                  subtitle: const Text('Updates from admin'),
                  onTap: () {
                    // ⚠️ Only if you have this route
                    // If you DON'T have /announcements route, remove this line
                    context.push('/announcements');
                  },
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Logout'),
                  onTap: () => ref.read(authStateProvider.notifier).logout(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
