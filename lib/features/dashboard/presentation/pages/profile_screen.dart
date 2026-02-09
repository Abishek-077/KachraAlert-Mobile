import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_waste_app/core/localization/app_localizations.dart';

import '../../../../core/utils/media_permissions.dart';
import '../../../../core/ui/snackbar.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/media_url.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/data/services/user_profile_api_service.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

// Premium color constants
const Color _premiumGreen = Color(0xFF1ECA92);
const Color _premiumDarkGreen = Color(0xFF0E6E66);
const Color _accentGreen = Color(0xFF16B584);
const Color _premiumSoftCanvas = Color(0xFFF5F8F7);
const List<BoxShadow> _premiumWhite3dShadow = [
  BoxShadow(
    color: Color(0x1A102218),
    blurRadius: 24,
    offset: Offset(0, 12),
  ),
  BoxShadow(
    color: Color(0xEDFFFFFF),
    blurRadius: 10,
    offset: Offset(-4, -4),
  ),
];
const List<BoxShadow> _premiumWhiteSoftShadow = [
  BoxShadow(
    color: Color(0x14102218),
    blurRadius: 14,
    offset: Offset(0, 6),
  ),
  BoxShadow(
    color: Color(0xE0FFFFFF),
    blurRadius: 8,
    offset: Offset(-2, -2),
  ),
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _uploading = false;
  late AnimationController _fadeController;
  late ScrollController _scrollController;
  double _scrollOffset = 0;
  static const double _headerCollapsedHeight = 100;
  static const double _headerExpandedHeight = 380;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

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
        AppSnack.show(context, l10n.profilePhotoUpdateFailed('$e'),
            error: true);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final email = (auth?.session?.email ?? '').trim();
    final isAdmin = auth?.session?.role == 'admin_driver';
    final displayName = email.isEmpty ? l10n.guestUser : email.split('@').first;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final apiBase = ref.watch(apiBaseUrlProvider);
    final token = auth?.session?.accessToken;
    final profilePhotoUrl =
        resolveMediaUrl(apiBase, auth?.session?.profilePhotoUrl);

    // Calculate header scroll progress
    final scrollProgress =
        (_scrollOffset / (_headerExpandedHeight - _headerCollapsedHeight))
            .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? cs.surface : _premiumSoftCanvas,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Premium Collapsible Header
          SliverAppBar(
            expandedHeight: _headerExpandedHeight,
            collapsedHeight: _headerCollapsedHeight,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildPremiumHeader(
                context,
                cs,
                displayName,
                email,
                initial,
                profilePhotoUrl,
                token,
                _uploading,
                scrollProgress,
                _fadeController,
              ),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          // Settings section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.choice(
                  'SETTINGS & PREFERENCES',
                  'सेटिङ र प्राथमिकताहरू',
                ),
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          // Settings Cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
            sliver: SliverToBoxAdapter(
              child: KCard(
                backgroundColor:
                    isDark ? cs.surfaceContainerHigh : Colors.white,
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : _premiumWhite3dShadow,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _PremiumSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconBg: const Color(0xFF6B9EFF),
                      title: l10n.notifications,
                      subtitle: l10n.manageAlertPrefs,
                      onTap: () => context.go('/alerts'),
                    ),
                    _divider(context),
                    _PremiumSettingsTile(
                      icon: Icons.receipt_long_outlined,
                      iconBg: const Color(0xFFFFA500),
                      title: l10n.payments,
                      subtitle: l10n.viewInvoices,
                      onTap: () => context.push('/payments'),
                    ),
                    _divider(context),
                    _PremiumSettingsTile(
                      icon: Icons.language_rounded,
                      iconBg: _premiumGreen,
                      title: l10n.language,
                      subtitle: ref
                                  .watch(settingsProvider)
                                  .valueOrNull
                                  ?.languageCode ==
                              'ne'
                          ? l10n.nepali
                          : l10n.english,
                      onTap: () => context.push('/settings'),
                    ),
                    _divider(context),
                    _PremiumSettingsTile(
                      icon: Icons.shield_outlined,
                      iconBg: _premiumDarkGreen,
                      title: l10n.choice(
                          'Privacy & Security', 'गोपनीयता र सुरक्षा'),
                      subtitle: l10n.dataPermissions,
                      onTap: () {},
                    ),
                    _divider(context),
                    Consumer(
                      builder: (context, ref, _) {
                        final settings =
                            ref.watch(settingsProvider).valueOrNull;
                        final mode = (settings?.isDarkMode ?? false)
                            ? l10n.darkMode
                            : l10n.lightMode;
                        return _PremiumSettingsTile(
                          icon: Icons.nightlight_round,
                          iconBg: const Color(0xFFD4A574),
                          title: l10n.appearance,
                          subtitle: mode,
                          onTap: () =>
                              ref.read(settingsProvider.notifier).toggleTheme(),
                        );
                      },
                    ),
                    _divider(context),
                    _PremiumSettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconBg: const Color(0xFF9B59B6),
                      title: l10n.helpSupport,
                      subtitle: l10n.faqContact,
                      onTap: () {},
                    ),
                    if (isAdmin) ...[
                      _divider(context),
                      _PremiumSettingsTile(
                        icon: Icons.admin_panel_settings_outlined,
                        iconBg: _premiumGreen,
                        title: l10n.adminPanel,
                        subtitle: l10n.broadcastAnnouncements,
                        onTap: () => context.push('/admin/broadcast'),
                      ),
                    ],
                    _divider(context),
                    _PremiumSettingsTile(
                      icon: Icons.logout_rounded,
                      iconBg: const Color(0xFFFF6B6B),
                      title: l10n.logout,
                      subtitle: l10n.signOutDevice,
                      onTap: () =>
                          ref.read(authStateProvider.notifier).logout(),
                      danger: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(
    BuildContext context,
    ColorScheme cs,
    String displayName,
    String email,
    String initial,
    String? profilePhotoUrl,
    String? token,
    bool uploading,
    double scrollProgress,
    AnimationController fadeController,
  ) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        // Premium animated background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surface,
                cs.surface.withOpacity(0.98),
              ],
            ),
          ),
        ),
        // Decorative animated circles
        Positioned(
          top: -100 + (scrollProgress * 50),
          right: -100 + (scrollProgress * 30),
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _premiumGreen.withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          bottom: -50 - (scrollProgress * 40),
          left: -50 + (scrollProgress * 20),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentGreen.withOpacity(0.05),
            ),
          ),
        ),
        // Main content with smooth animation
        FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 1.0).animate(
              CurvedAnimation(parent: fadeController, curve: Curves.easeOut)),
          child: Transform.translate(
            offset: Offset(0, scrollProgress * 80),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 24 + scrollProgress * 20, 16, 28 - scrollProgress * 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium Avatar with enhanced effects
                  Center(
                    child: Stack(
                      children: [
                        // Animated glow effect
                        ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 0.8)
                              .animate(CurvedAnimation(
                            parent: fadeController,
                            curve: Curves.easeOut,
                          )),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _premiumGreen.withOpacity(0.3),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Avatar container
                        InkWell(
                          onTap: uploading ? null : _changePhoto,
                          borderRadius: BorderRadius.circular(60),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _premiumGreen.withOpacity(0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _premiumDarkGreen.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _premiumGreen.withOpacity(0.12),
                                    _accentGreen.withOpacity(0.08),
                                  ],
                                ),
                              ),
                              child: profilePhotoUrl == null
                                  ? Center(
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          color: _premiumDarkGreen,
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    )
                                  : ClipOval(
                                      child: Image.network(
                                        profilePhotoUrl,
                                        fit: BoxFit.cover,
                                        headers: token?.isNotEmpty == true
                                            ? {'Authorization': 'Bearer $token'}
                                            : null,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: _premiumDarkGreen,
                                              fontSize: 48,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        // Camera icon badge with premium styling
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_premiumGreen, _accentGreen],
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _premiumGreen.withOpacity(0.5),
                                  blurRadius: 16,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: uploading
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Name with gradient effect
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_premiumGreen, _accentGreen],
                    ).createShader(bounds),
                    child: Text(
                      _titleCase(displayName),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.1,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Email
                  Text(
                    email.isEmpty ? l10n.notSignedIn : email,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.65),
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Premium badge with smooth animation
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _premiumGreen.withOpacity(0.15),
                          _accentGreen.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _premiumGreen.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _premiumGreen.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_premiumGreen, _accentGreen],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.topContributor,
                          style: TextStyle(
                            color: _premiumGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.5,
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
      ],
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  const _PremiumStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumAchievementCard extends StatelessWidget {
  const _PremiumAchievementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.index,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorA, colorB],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorA.withOpacity(0.25),
            blurRadius: 24,
            offset: Offset(0, 8 + (index * 2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSettingsTile extends StatefulWidget {
  const _PremiumSettingsTile({
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
  State<_PremiumSettingsTile> createState() => _PremiumSettingsTileState();
}

class _PremiumSettingsTileState extends State<_PremiumSettingsTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = widget.danger ? cs.error : cs.onSurface;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark
                    ? cs.surfaceContainerHighest
                    : const Color(0xFFF8FBFA))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isHovered
                ? (isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : _premiumWhiteSoftShadow)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? cs.surface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        widget.iconBg.withValues(alpha: isDark ? 0.32 : 0.24),
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : _premiumWhiteSoftShadow,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconBg,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: isDark ? 0.58 : 0.3),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _divider(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Divider(
    height: 1,
    indent: 64,
    endIndent: 16,
    color: cs.outlineVariant.withValues(alpha: 0.28),
  );
}

String _titleCase(String value) {
  final cleaned = value.trim();
  if (cleaned.isEmpty) return 'User';
  final parts = cleaned.split(RegExp(r'\s+'));
  return parts
      .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}
