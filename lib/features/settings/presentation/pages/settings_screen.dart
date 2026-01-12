import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load settings: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                title: const Text('About Developer'),
                subtitle: const Text('A tiny story behind the app 😄'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('About Developer'),
                    content: Text(
                      "Built with love, coffee, and a little panic before deadlines. "
                      "If something breaks, it’s not a bug — it’s a surprise feature 😅",
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Logout'),
                trailing: const Icon(Icons.logout),
                onTap: () => ref.read(authStateProvider.notifier).logout(),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Show onboarding again'),
                subtitle: const Text('Reset intro screens and restart flow'),
                leading: const Icon(Icons.restart_alt_rounded),
                onTap: () async {
                  await ref.read(settingsProvider.notifier).resetOnboarded();
                  if (!context.mounted) return;
                  context.go('/splash'); // router will redirect to onboarding
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
