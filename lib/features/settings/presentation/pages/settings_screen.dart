import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            l10n.choice(
              'Failed to load settings: $e',
              'सेटिङ लोड गर्न सकिएन: $e',
            ),
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: SwitchListTile(
                value: settings.isDarkMode,
                title: Text(l10n.darkMode),
                subtitle: Text(
                  l10n.choice(
                    'Make it easy on your eyes',
                    'आँखालाई सहज बनाउनुहोस्',
                  ),
                ),
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleTheme(),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(l10n.language),
                subtitle: Text(
                  settings.languageCode == 'ne' ? l10n.nepali : l10n.english,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _showLanguageSheet(context, ref, settings.languageCode),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(l10n.choice('About Developer', 'डेभलपर बारे')),
                subtitle: Text(
                  l10n.choice(
                    'A tiny story behind the app',
                    'एप पछाडिको सानो कथा',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(l10n.choice('About Developer', 'डेभलपर बारे')),
                    content: Text(
                      l10n.choice(
                        'Built with love, coffee, and focus. If something breaks, we fix it fast.',
                        'यो एप माया, कफी र ध्यानका साथ बनाइएको हो। केही बिग्रिए छिट्टै सुधारिन्छ।',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(l10n.logout),
                trailing: const Icon(Icons.logout),
                onTap: () => ref.read(authStateProvider.notifier).logout(),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(
                  l10n.choice(
                    'Show onboarding again',
                    'फेरि सुरुका स्क्रिन देखाउनुहोस्',
                  ),
                ),
                subtitle: Text(
                  l10n.choice(
                    'Reset intro screens and restart flow',
                    'सुरुका स्क्रिन रिसेट गरेर पुनः सुरु गर्नुहोस्',
                  ),
                ),
                leading: const Icon(Icons.restart_alt_rounded),
                onTap: () async {
                  await ref.read(settingsProvider.notifier).resetOnboarded();
                  if (!context.mounted) return;
                  context.go('/splash');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    String currentLanguageCode,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Radio<String>(
                  value: 'en',
                  groupValue: currentLanguageCode,
                  onChanged: (v) => Navigator.of(sheetContext).pop(v),
                ),
                title: Text(l10n.english),
                onTap: () => Navigator.of(sheetContext).pop('en'),
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'ne',
                  groupValue: currentLanguageCode,
                  onChanged: (v) => Navigator.of(sheetContext).pop(v),
                ),
                title: Text(l10n.nepali),
                onTap: () => Navigator.of(sheetContext).pop('ne'),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == currentLanguageCode) return;
    await ref.read(settingsProvider.notifier).setLanguageCode(selected);
  }
}
