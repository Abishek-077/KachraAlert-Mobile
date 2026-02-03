import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/media_permissions.dart';
import '../../../../core/ui/snackbar.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/media_url.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/data/services/user_profile_api_service.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _changePhoto() async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authStateProvider).valueOrNull;
    final token = auth?.session?.accessToken;
    if (token == null || token.isEmpty) {
      if (mounted) {
        AppSnack.show(context, l10n.signInToUpdatePhoto, error: true);
      }
      return;
    }

    await MediaPermissions.requestPhotoVideoAccess(context);
    if (!mounted) return;

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() => _uploading = true);
    try {
      final profileApi = ref.read(userProfileApiServiceProvider);
      final photoUrl = await profileApi.uploadProfilePhoto(
        bytes: bytes,
        filename: picked.name,
        mimeType: picked.mimeType,
        accessToken: token,
      );
      await ref.read(authStateProvider.notifier).updateProfilePhoto(photoUrl);
      if (mounted) {
        AppSnack.show(context, l10n.profilePhotoUpdated, error: false);
      }
    } catch (e) {
      if (mounted) {
        AppSnack.show(context, l10n.profilePhotoUpdateFailed(e.toString()), error: true);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _showLanguageSelector(AppLocalizations l10n) async {
    final settings = ref.read(settingsProvider).valueOrNull;
    final current = settings?.languageCode ?? 'en';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.languageSelectionTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.languageSelectionSubtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _LanguageOptionTile(
                  title: l10n.english,
                  subtitle: 'English',
                  selected: current == 'en',
                  onTap: () => _setLanguage('en'),
                ),
                const SizedBox(height: 12),
                _LanguageOptionTile(
                  title: l10n.nepali,
                  subtitle: 'नेपाली',
                  selected: current == 'ne',
                  onTap: () => _setLanguage('ne'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setLanguage(String code) async {
    await ref.read(settingsProvider.notifier).setLanguageCode(code);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final email = (auth?.session?.email ?? '').trim();
    final isAdmin = auth?.session?.role == 'admin_driver';
    final displayName =
        email.isEmpty ? l10n.guestUser : email.split('@').first;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final apiBase = ref.watch(apiBaseUrlProvider);
    final token = auth?.session?.accessToken;
    final profilePhotoUrl = resolveMediaUrl(apiBase, auth?.session?.profilePhotoUrl);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final languageCode = settings?.languageCode ?? 'en';

    final reports = ref.watch(reportsProvider).valueOrNull ?? const [];
    final myReports = (auth?.session?.userId == null)
        ? const []
        : reports.where((r) => r.userId == auth!.session!.userId).toList();
    final resolved = myReports.where((r) => r.status == 'resolved').length;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header (teal gradient)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0E6E66), Color(0xFF0B5D56)],
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _uploading ? null : _changePhoto,
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        alignment: Alignment.center,
                        child: profilePhotoUrl == null
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  profilePhotoUrl,
                                  width: 86,
                                  height: 86,
                                  fit: BoxFit.cover,
                                  headers: token?.isNotEmpty == true
                                      ? {'Authorization': 'Bearer $token'}
                                      : null,
                                  errorBuilder: (_, __, ___) => Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1ECA92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF0B5D56), width: 3),
                          ),
                          child: _uploading
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleCase(displayName),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email.isEmpty ? l10n.notSignedIn : email,
                        style: TextStyle(color: Colors.white.withOpacity(0.78), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium_outlined, size: 16, color: Color(0xFF1ECA92)),
                            const SizedBox(width: 8),
                            Text(
                              l10n.topContributor,
                              style: const TextStyle(color: Color(0xFF1ECA92), fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _HeaderEditButton(onTap: () => context.push('/settings')),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: l10n.reports.toUpperCase(),
                    value: '${myReports.length}',
                    delta: '+5',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: l10n.resolved.toUpperCase(),
                    value: '$resolved',
                    delta: '+3',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: l10n.impact.toUpperCase(),
                    value: '${(resolved * 47).clamp(0, 9999)}',
                    delta: '+120',
                  ),
                ),
              ],
            ),
          ),

          // Achievements
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Text(
              l10n.achievements.toUpperCase(),
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
                fontSize: 12,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _AchievementCard(
                    title: l10n.topContributor,
                    subtitle: l10n.topContributorTitle,
                    icon: Icons.workspace_premium_outlined,
                    colorA: Color(0xFF1ECA92),
                    colorB: Color(0xFF16B481),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AchievementCard(
                    title: l10n.quickReporter,
                    subtitle: l10n.reportsInWeek,
                    icon: Icons.eco_outlined,
                    colorA: Color(0xFF0E6E66),
                    colorB: Color(0xFF0B5D56),
                  ),
                ),
              ],
            ),
          ),

          // Settings list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Text(
              l10n.settings.toUpperCase(),
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
                fontSize: 12,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
            child: KCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    iconBg: const Color(0xFFE7F1FF),
                    title: l10n.notifications,
                    subtitle: l10n.manageAlertPrefs,
                    onTap: () => context.go('/alerts'),
                  ),
                  _SettingsTile(
                    icon: Icons.receipt_long_outlined,
                    iconBg: const Color(0xFFE8FFF7),
                    title: l10n.payments,
                    subtitle: l10n.viewInvoices,
                    onTap: () => context.push('/payments'),
                  ),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    iconBg: const Color(0xFFE8FFF7),
                    title: l10n.language,
                    subtitle:
                        languageCode == 'ne' ? l10n.nepali : l10n.english,
                    onTap: () => _showLanguageSelector(l10n),
                  ),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFFFFF1E6),
                    title: l10n.privacy,
                    subtitle: l10n.dataPermissions,
                    onTap: () {},
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final settings =
                          ref.watch(settingsProvider).valueOrNull;
                      final mode = (settings?.isDarkMode ?? false)
                          ? l10n.darkMode
                          : l10n.lightMode;
                      return _SettingsTile(
                        icon: Icons.nightlight_round,
                        iconBg: const Color(0xFFEAF2F2),
                        title: l10n.appearance,
                        subtitle: mode,
                        onTap: () => ref.read(settingsProvider.notifier).toggleTheme(),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    iconBg: const Color(0xFFEAF2F2),
                    title: l10n.helpSupport,
                    subtitle: l10n.faqContact,
                    onTap: () {},
                  ),
                  if (isAdmin) ...[
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconBg: const Color(0xFFE7F1FF),
                      title: l10n.adminPanel,
                      subtitle: l10n.broadcastAnnouncements,
                      onTap: () => context.push('/admin/broadcast'),
                    ),
                  ],
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    iconBg: const Color(0xFFFFECEC),
                    title: l10n.logout,
                    subtitle: l10n.signOutDevice,
                    onTap: () => ref.read(authStateProvider.notifier).logout(),
                    danger: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderEditButton extends StatelessWidget {
  const _HeaderEditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.delta});
  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return KCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: cs.onSurface.withOpacity(0.55), fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11)),
          const SizedBox(height: 6),
          Text('↗ $delta', style: const TextStyle(color: Color(0xFF1ECA92), fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorA,
    required this.colorB,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorA, colorB]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(blurRadius: 24, offset: const Offset(0, 12), color: Colors.black.withOpacity(0.10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleColor = danger ? cs.error : cs.onSurface;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: danger ? cs.error : cs.primary),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: titleColor)),
      subtitle: Text(subtitle, style: TextStyle(color: cs.onSurface.withOpacity(0.62), fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.45)),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor =
        selected ? cs.primary : cs.onSurface.withOpacity(0.08);
    final background =
        selected ? cs.primary.withOpacity(0.08) : cs.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: selected ? cs.primary : cs.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _titleCase(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ').trim();
  if (cleaned.isEmpty) return 'User';
  final parts = cleaned.split(RegExp(r'\s+'));
  return parts.map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
}
