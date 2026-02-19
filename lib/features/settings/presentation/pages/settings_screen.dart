import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);

    return MotionScaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      safeAreaBody: true,
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            l10n.choice(
              'Failed to load settings: $e',
              '????? ??? ???? ?????: $e',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        data: (settings) => RefreshIndicator(
          onRefresh: () => ref.read(settingsProvider.notifier).load(),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              StaggeredRevealList(
                baseDelayMs: 40,
                stepDelayMs: 60,
                children: [
                  _SettingsSection(
                    title: l10n.choice('Preferences', '?????????????'),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: settings.isDarkMode,
                          title: Text(l10n.darkMode),
                          subtitle: Text(
                            l10n.choice(
                              'Make it easy on your eyes',
                              '??????? ??? ??????????',
                            ),
                          ),
                          onChanged: (_) =>
                              ref.read(settingsProvider.notifier).toggleTheme(),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: settings.pickupRemindersEnabled,
                          title: Text(
                            l10n.choice('Pickup reminders', '????? ?????????'),
                          ),
                          subtitle: Text(
                            l10n.choice(
                              'Keep schedule reminders active',
                              '?????? ????????? ?????? ??????????',
                            ),
                          ),
                          onChanged: (enabled) => ref
                              .read(settingsProvider.notifier)
                              .setPickupReminders(enabled),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: settings.reduceMotion,
                          title: Text(
                            l10n.choice('Reduce motion', '???????? ??????????'),
                          ),
                          subtitle: Text(
                            l10n.choice(
                              'Use gentler transitions and fewer effects',
                              '?????????? ? ????????? ?? ?????????',
                            ),
                          ),
                          onChanged: (enabled) => ref
                              .read(settingsProvider.notifier)
                              .setReduceMotion(enabled),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: settings.hapticsEnabled,
                          title: Text(
                            l10n.choice('Haptics', '????????? ???????????'),
                          ),
                          subtitle: Text(
                            l10n.choice(
                              'Vibration feedback for taps and actions',
                              '????? ? ??????? ????? ???????????',
                            ),
                          ),
                          onChanged: (enabled) => ref
                              .read(settingsProvider.notifier)
                              .setHapticsEnabled(enabled),
                        ),
                      ],
                    ),
                  ),
                  _SettingsSection(
                    title: l10n.choice('App', '??'),
                    child: Column(
                      children: [
                        _SettingsActionTile(
                          icon: Icons.language_rounded,
                          title: l10n.language,
                          subtitle: settings.languageCode == 'ne'
                              ? l10n.nepali
                              : l10n.english,
                          onTap: () => _showLanguageSheet(
                            context,
                            ref,
                            settings.languageCode,
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingsActionTile(
                          icon: Icons.info_outline_rounded,
                          title: l10n.choice(
                            'About Developer',
                            '?????? ????',
                          ),
                          subtitle: l10n.choice(
                            'A tiny story behind the app',
                            '?? ??????? ???? ???',
                          ),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(
                                l10n.choice(
                                  'About Developer',
                                  '?????? ????',
                                ),
                              ),
                              content: Text(
                                l10n.choice(
                                  'Built with focus and care. If something breaks, we fix it quickly.',
                                  '?? ?? ????? ? ???? ??? ??????? ??? ???? ????????? ????? ??????????',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingsActionTile(
                          icon: Icons.restart_alt_rounded,
                          title: l10n.choice(
                            'Show onboarding again',
                            '???? ?????? ??????? ???????????',
                          ),
                          subtitle: l10n.choice(
                            'Reset intro screens and restart flow',
                            '?????? ??????? ????? ???? ???? ???? ?????????',
                          ),
                          onTap: () async {
                            await ref
                                .read(settingsProvider.notifier)
                                .resetOnboarded();
                            if (!context.mounted) return;
                            context.go('/splash');
                          },
                        ),
                      ],
                    ),
                  ),
                  _SettingsSection(
                    title: l10n.choice('Account', '????'),
                    child: _SettingsActionTile(
                      icon: Icons.logout_rounded,
                      title: l10n.logout,
                      subtitle: l10n.choice(
                        'Sign out from this device',
                        '?? ???????? ???? ??? ?????????',
                      ),
                      textColor: Theme.of(context).colorScheme.error,
                      onTap: () =>
                          ref.read(authStateProvider.notifier).logout(),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontSize: 11,
            ),
          ),
        ),
        KCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = textColor ?? cs.onSurface;

    return KPressable(
      borderRadius: BorderRadius.circular(0),
      onTap: onTap,
      haptic: PressHaptic.selection,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            KIconCircle(
              icon: icon,
              background: cs.primary.withValues(alpha: 0.12),
              foreground: cs.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: effectiveColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.64),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.52),
            ),
          ],
        ),
      ),
    );
  }
}
