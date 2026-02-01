import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/media_permissions.dart';
import '../../../../core/ui/snackbar.dart';
import '../../../../core/theme/app_spacing.dart';
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
    final auth = ref.read(authStateProvider).valueOrNull;
    final token = auth?.session?.accessToken;
    if (token == null || token.isEmpty) {
      if (mounted) {
        AppSnack.show(context, 'Please sign in to update your photo.', error: true);
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
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
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
        AppSnack.show(context, 'Profile photo updated.', error: false);
      }
    } catch (e) {
      if (mounted) {
        AppSnack.show(context, 'Failed to update profile photo: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final email = (auth?.session?.email ?? '').trim();
    final isAdmin = auth?.session?.role == 'admin_driver';
    final displayName = email.isEmpty ? 'Guest User' : email.split('@').first;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final apiBase = ref.watch(apiBaseUrlProvider);
    final token = auth?.session?.accessToken;
    final profilePhotoUrl = resolveMediaUrl(apiBase, auth?.session?.profilePhotoUrl);

    final reports = ref.watch(reportsProvider).valueOrNull ?? const [];
    final myReports = (auth?.session?.userId == null)
        ? const []
        : reports.where((r) => r.userId == auth!.session!.userId).toList();
    final resolved = myReports.where((r) => r.status == 'resolved').length;

    return AppScaffold(
      padding: EdgeInsets.zero,
      child: ListView(
        padding: AppSpacing.screenInsetsBottom,
        children: [
          Row(
            children: [
              Text('Profile', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          CivicCard(
            child: Row(
              children: [
                InkWell(
                  onTap: _uploading ? null : _changePhoto,
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        alignment: Alignment.center,
                        child: profilePhotoUrl == null
                            ? Text(
                                initial,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  profilePhotoUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  headers: token?.isNotEmpty == true
                                      ? {'Authorization': 'Bearer $token'}
                                      : null,
                                  errorBuilder: (_, __, ___) => Text(
                                    initial,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.surface, width: 2),
                          ),
                          child: _uploading
                              ? const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.itemSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleCase(displayName),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.labelSpacing),
                      Text(
                        email.isEmpty ? 'Not signed in' : email,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      const StatusChip(
                        label: 'Resident account',
                        tone: StatusTone.neutral,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          Row(
            children: [
              Expanded(
                child: CivicCard(
                  child: _StatSummary(
                    label: 'Reports',
                    value: '${myReports.length}',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.itemSpacing),
              Expanded(
                child: CivicCard(
                  child: _StatSummary(
                    label: 'Resolved',
                    value: '$resolved',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.itemSpacing),
              Expanded(
                child: CivicCard(
                  child: _StatSummary(
                    label: 'Impact',
                    value: '${(resolved * 47).clamp(0, 9999)}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          const SectionHeader(label: 'Settings'),
          const SizedBox(height: AppSpacing.labelSpacing),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage alert preferences',
                  onTap: () => context.go('/alerts'),
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.receipt_long_outlined,
                  title: 'Payments',
                  subtitle: 'View invoices and pay dues',
                  onTap: () => context.push('/payments'),
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Privacy',
                  subtitle: 'Data and permissions',
                  onTap: () {},
                ),
                const Divider(height: 1),
                Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(settingsProvider).valueOrNull;
                    final mode = (settings?.isDarkMode ?? false)
                        ? 'Dark mode'
                        : 'Light mode';
                    return _SettingsRow(
                      icon: Icons.nightlight_round,
                      title: 'Appearance',
                      subtitle: mode,
                      onTap: () =>
                          ref.read(settingsProvider.notifier).toggleTheme(),
                    );
                  },
                ),
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact',
                  onTap: () {},
                ),
                if (isAdmin) ...[
                  const Divider(height: 1),
                  _SettingsRow(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Panel',
                    subtitle: 'Broadcast announcements',
                    onTap: () => context.push('/admin/broadcast'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          const SectionHeader(label: 'Account'),
          const SizedBox(height: AppSpacing.labelSpacing),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: _SettingsRow(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out of this device',
              onTap: () => ref.read(authStateProvider.notifier).logout(),
              danger: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatSummary extends StatelessWidget {
  const _StatSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.labelSpacing),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: cs.onSurface.withOpacity(0.55),
            letterSpacing: 1.2,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
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
      leading: Icon(icon, color: danger ? cs.error : cs.onSurface.withOpacity(0.7)),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w700, color: titleColor)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: cs.onSurface.withOpacity(0.45)),
    );
  }
}

String _titleCase(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ').trim();
  if (cleaned.isEmpty) return 'User';
  final parts = cleaned.split(RegExp(r'\s+'));
  return parts.map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
}
