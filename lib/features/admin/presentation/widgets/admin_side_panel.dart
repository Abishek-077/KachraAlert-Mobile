import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/utils/media_url.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class AdminSidePanel extends ConsumerWidget {
  const AdminSidePanel({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final apiBase = ref.watch(apiBaseUrlProvider);
    final email = auth?.session?.email ?? '';
    final displayName = _displayName(email);
    final avatarUrl = resolveMediaUrl(apiBase, auth?.session?.profilePhotoUrl);
    final token = auth?.session?.accessToken;
    final avatarHeaders =
        token?.isNotEmpty == true ? {'Authorization': 'Bearer $token'} : null;

    final items = <_AdminNavItem>[
      const _AdminNavItem(
        label: 'User Management',
        icon: Icons.supervisor_account_rounded,
        route: '/admin/users',
      ),
      const _AdminNavItem(
        label: 'Broadcast Alerts',
        icon: Icons.campaign_rounded,
        route: '/admin/broadcast',
      ),
      const _AdminNavItem(
        label: 'Schedule Control',
        icon: Icons.event_available_rounded,
        route: '/admin/schedule',
      ),
      const _AdminNavItem(
        label: 'Back to Home',
        icon: Icons.home_rounded,
        route: '/home',
      ),
    ];

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.panelGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: -40,
                child: _PanelOrb(
                  size: 180,
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              Positioned(
                left: -80,
                bottom: -60,
                child: _PanelOrb(
                  size: 220,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admin Panel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Control Center',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withOpacity(0.22),
                            foregroundImage: avatarUrl == null
                                ? null
                                : NetworkImage(
                                    avatarUrl,
                                    headers: avatarHeaders,
                                  ),
                            child: avatarUrl == null
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName.substring(0, 1)
                                        : 'A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.isNotEmpty ? displayName : 'Admin',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email.isNotEmpty ? email : 'admin@kachra.app',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'ADMIN CONTROLS',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = currentRoute == item.route ||
                            currentRoute.startsWith('${item.route}/');
                        return _AdminNavTile(
                          item: item,
                          selected: selected,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(item.route);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: cs.onPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'All actions are synced with live backend data.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

class _AdminNavItem {
  final String label;
  final IconData icon;
  final String route;

  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: cs.onPrimary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _displayName(String email) {
  final cleaned = email.trim();
  if (cleaned.isEmpty) return 'Admin';
  final name = cleaned.split('@').first;
  if (name.isEmpty) return 'Admin';
  return name
      .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .map((part) =>
          part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _PanelOrb extends StatelessWidget {
  const _PanelOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.3),
          colors: [
            color,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
