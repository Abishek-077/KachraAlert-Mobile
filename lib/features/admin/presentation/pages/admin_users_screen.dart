import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/ui/snackbar.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/admin_user_model.dart';
import '../providers/admin_user_providers.dart';
import '../widgets/admin_side_panel.dart';

const Color _kSoftCanvas = Color(0xFFF5F8F7);
const List<BoxShadow> _kWhite3dShadow = [
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

const List<BoxShadow> _kWhiteSoftShadow = [
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

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  AdminUserStatusFilter _statusFilter = AdminUserStatusFilter.all;
  AdminUserRoleFilter _roleFilter = AdminUserRoleFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(adminUsersProvider.notifier).load();
  }

  Widget _filterChip(AdminUserStatusFilter filter, String label) {
    return _StatusFilterChip(
      label: label,
      selected: _statusFilter == filter,
      onTap: () => setState(() => _statusFilter = filter),
    );
  }

  Future<void> _confirmToggleBan(AdminUser user) async {
    final cs = Theme.of(context).colorScheme;
    final shouldBan = !user.isBanned;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shouldBan ? 'Remove User' : 'Restore User'),
        content: Text(
          shouldBan
              ? 'This will ban ${user.name} from the system.'
              : 'This will restore ${user.name} and allow access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: shouldBan ? cs.error : cs.primary,
            ),
            child: Text(shouldBan ? 'Remove' : 'Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(adminUsersProvider.notifier).updateStatus(
            id: user.id,
            isBanned: shouldBan,
          );
      if (!mounted) return;
      AppSnack.show(
        context,
        shouldBan
            ? 'User removed successfully.'
            : 'User restored successfully.',
        error: false,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(context, 'Failed to update user: $e', error: true);
    }
  }

  Future<void> _confirmDelete(AdminUser user) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'This will permanently delete ${user.name}. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(adminUsersProvider.notifier).deleteUser(user.id);
      if (!mounted) return;
      AppSnack.show(context, 'User deleted successfully.', error: false);
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(context, 'Failed to delete user: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final usersAsync = ref.watch(adminUsersProvider);
    final lastSync = ref.watch(adminUsersLastSyncProvider);
    final apiBase = ref.watch(apiBaseUrlProvider);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final token = auth?.session?.accessToken;
    final avatarHeaders =
        token?.isNotEmpty == true ? {'Authorization': 'Bearer $token'} : null;

    return Scaffold(
      backgroundColor: _kSoftCanvas,
      drawer: const AdminSidePanel(currentRoute: '/admin/users'),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  DelayedReveal(
                    delay: const Duration(milliseconds: 60),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(Icons.menu_rounded),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Admin Control',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => context.push('/admin/users/form'),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('New'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DelayedReveal(
                    delay: const Duration(milliseconds: 140),
                    child: KCard(
                      backgroundColor: Colors.white,
                      boxShadow: _kWhite3dShadow,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Management',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage residents and admin drivers with live backend data.',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.65),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _LiveBadge(
                                label: 'Live data',
                                foreground: cs.primary,
                                borderColor: cs.primary,
                              ),
                              const SizedBox(width: 10),
                              _LiveBadge(
                                label: lastSync == null
                                    ? 'Last sync: -'
                                    : 'Last sync: ${_formatTime(lastSync)}',
                                foreground: cs.onSurface.withOpacity(0.7),
                                borderColor: cs.outlineVariant,
                              ),
                              const Spacer(),
                              Icon(Icons.sync_rounded, color: cs.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DelayedReveal(
                    delay: const Duration(milliseconds: 220),
                    child: usersAsync.when(
                      loading: () => const _StatsSkeleton(),
                      error: (_, __) => const _StatsSkeleton(),
                      data: (users) => _StatsGrid(users: users),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DelayedReveal(
                    delay: const Duration(milliseconds: 280),
                    child: KCard(
                      backgroundColor: Colors.white,
                      boxShadow: _kWhite3dShadow,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: cs.onSurface.withOpacity(0.45),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText:
                                    'Search users by name, email, society, or ID',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: cs.onSurface.withOpacity(0.45),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DelayedReveal(
                    delay: const Duration(milliseconds: 320),
                    child: Row(
                      children: [
                        Expanded(
                          child: KCard(
                            backgroundColor: Colors.white,
                            boxShadow: _kWhite3dShadow,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: DropdownButtonFormField<AdminUserRoleFilter>(
                              value: _roleFilter,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                labelText: 'Role',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: AdminUserRoleFilter.all,
                                  child: Text('All roles'),
                                ),
                                DropdownMenuItem(
                                  value: AdminUserRoleFilter.adminDrivers,
                                  child: Text('Admin/Driver'),
                                ),
                                DropdownMenuItem(
                                  value: AdminUserRoleFilter.residents,
                                  child: Text('Residents'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _roleFilter = value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        usersAsync.maybeWhen(
                          data: (users) {
                            final filtered = _applyFilters(
                              users,
                              _statusFilter,
                              _roleFilter,
                              _searchController.text,
                            );
                            return Text(
                              '${filtered.length} of ${users.length} users',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.65),
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                          orElse: () => Text(
                            '0 users',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.65),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  DelayedReveal(
                    delay: const Duration(milliseconds: 360),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip(AdminUserStatusFilter.all, 'All'),
                          const SizedBox(width: 10),
                          _filterChip(AdminUserStatusFilter.active, 'Active'),
                          const SizedBox(width: 10),
                          _filterChip(AdminUserStatusFilter.banned, 'Banned'),
                          const SizedBox(width: 10),
                          _filterChip(AdminUserStatusFilter.removed, 'Removed'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  usersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _ErrorState(
                      message: 'Failed to load users: $e',
                      onRetry: _refresh,
                    ),
                    data: (users) {
                      final filtered = _applyFilters(
                        users,
                        _statusFilter,
                        _roleFilter,
                        _searchController.text,
                      );
                      if (filtered.isEmpty) {
                        return _EmptyState(
                          onCreate: () => context.push('/admin/users/form'),
                        );
                      }

                      return Column(
                        children: [
                          for (final user in filtered) ...[
                            _UserCard(
                              user: user,
                              avatarUrl: resolveMediaUrl(
                                apiBase,
                                user.profileImageUrl,
                              ),
                              avatarHeaders: avatarHeaders,
                              onView: () => _showDetails(
                                context,
                                user,
                                resolveMediaUrl(
                                  apiBase,
                                  user.profileImageUrl,
                                ),
                                avatarHeaders,
                              ),
                              onEdit: () => context.push('/admin/users/form',
                                  extra: user),
                              onToggleBan: () => _confirmToggleBan(user),
                              onDelete: () => _confirmDelete(user),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      );
                    },
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

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({
    required this.label,
    required this.foreground,
    required this.borderColor,
  });

  final String label;
  final Color foreground;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor.withOpacity(0.28)),
        boxShadow: _kWhiteSoftShadow,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? cs.primary.withOpacity(0.35)
                  : cs.outlineVariant.withOpacity(0.35),
            ),
            boxShadow: _kWhiteSoftShadow,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? cs.primary : cs.onSurface.withOpacity(0.72),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.users});

  final List<AdminUser> users;

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final active = users.where((u) => !u.isBanned).length;
    final admins = users.where((u) => u.isAdmin).length;
    final banned = users.where((u) => u.isBanned).length;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _StatCard(
          title: 'Total users',
          value: total.toString(),
          subtitle: 'All accounts',
          icon: Icons.groups_rounded,
          gradient: AppColors.tealEmeraldGradient,
        ),
        _StatCard(
          title: 'Active users',
          value: active.toString(),
          subtitle: 'Ready to collect',
          icon: Icons.verified_user_rounded,
          gradient: AppColors.blueCyanGradient,
        ),
        _StatCard(
          title: 'Admin / Drivers',
          value: admins.toString(),
          subtitle: 'Operations team',
          icon: Icons.shield_rounded,
          gradient: AppColors.goldGradient,
        ),
        _StatCard(
          title: 'Banned users',
          value: banned.toString(),
          subtitle: 'Restricted access',
          icon: Icons.person_off_rounded,
          gradient: AppColors.errorGradient,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
        boxShadow: _kWhite3dShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.buttonShadow,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.avatarUrl,
    required this.avatarHeaders,
    required this.onView,
    required this.onEdit,
    required this.onToggleBan,
    required this.onDelete,
  });

  final AdminUser user;
  final String? avatarUrl;
  final Map<String, String>? avatarHeaders;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggleBan;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = user.isBanned ? cs.error : cs.primary;
    final roleColor = user.isAdmin ? cs.secondary : cs.primary;

    return KCard(
      backgroundColor: Colors.white,
      boxShadow: _kWhite3dShadow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(
                name: user.name,
                avatarUrl: avatarUrl,
                avatarHeaders: avatarHeaders,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Pill(
                          label: user.roleLabel,
                          color: roleColor,
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          label: user.statusLabel,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                user.isBanned ? Icons.block_rounded : Icons.verified_rounded,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.apartment_rounded,
                label: user.society,
              ),
              _InfoChip(
                icon: Icons.business_rounded,
                label: user.building,
              ),
              _InfoChip(
                icon: Icons.meeting_room_rounded,
                label: user.apartment,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'ID: ${user.id.substring(0, math.min(6, user.id.length))}',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(Icons.circle, size: 8, color: statusColor),
              const SizedBox(width: 6),
              Text(
                user.isBanned ? 'Restricted' : 'Live',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionPill(
                label: 'View',
                icon: Icons.visibility_rounded,
                onTap: onView,
              ),
              _ActionPill(
                label: 'Edit',
                icon: Icons.edit_rounded,
                onTap: onEdit,
              ),
              _ActionPill(
                label: user.isBanned ? 'Restore' : 'Remove',
                icon: user.isBanned
                    ? Icons.restart_alt_rounded
                    : Icons.block_rounded,
                color: user.isBanned ? cs.primary : cs.error,
                onTap: onToggleBan,
              ),
              _ActionPill(
                label: 'Delete',
                icon: Icons.delete_rounded,
                color: cs.error,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    required this.avatarUrl,
    required this.avatarHeaders,
  });

  final String name;
  final String? avatarUrl;
  final Map<String, String>? avatarHeaders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: _kWhiteSoftShadow,
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: cs.primary.withOpacity(0.12),
        foregroundImage: avatarUrl == null
            ? null
            : NetworkImage(avatarUrl!, headers: avatarHeaders),
        child: avatarUrl == null
            ? Text(
                initial,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              )
            : null,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: _kWhiteSoftShadow,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        boxShadow: _kWhiteSoftShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurface.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.75),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withOpacity(0.24)),
          boxShadow: _kWhiteSoftShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: List.generate(
        4,
        (index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _kWhite3dShadow,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return KCard(
      backgroundColor: Colors.white,
      boxShadow: _kWhite3dShadow,
      child: Column(
        children: [
          Icon(
            Icons.group_off_rounded,
            size: 54,
            color: cs.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 10),
          const Text(
            'No users found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a user to start managing residents and drivers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Create User'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return KCard(
      backgroundColor: Colors.white,
      boxShadow: _kWhite3dShadow,
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 54, color: cs.error),
          const SizedBox(height: 10),
          const Text(
            'Unable to load users',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

List<AdminUser> _applyFilters(
  List<AdminUser> users,
  AdminUserStatusFilter statusFilter,
  AdminUserRoleFilter roleFilter,
  String query,
) {
  var filtered = [...users];
  if (statusFilter == AdminUserStatusFilter.active) {
    filtered = filtered.where((u) => !u.isBanned).toList();
  } else if (statusFilter == AdminUserStatusFilter.banned) {
    filtered = filtered.where((u) => u.isBanned).toList();
  } else if (statusFilter == AdminUserStatusFilter.removed) {
    filtered = [];
  }

  if (roleFilter == AdminUserRoleFilter.adminDrivers) {
    filtered = filtered.where((u) => u.isAdmin).toList();
  } else if (roleFilter == AdminUserRoleFilter.residents) {
    filtered = filtered.where((u) => !u.isAdmin).toList();
  }

  final q = query.trim().toLowerCase();
  if (q.isEmpty) return filtered;

  return filtered.where((u) {
    final haystack = [
      u.name,
      u.email,
      u.society,
      u.building,
      u.apartment,
      u.id,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }).toList();
}

String _formatTime(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

Future<void> _showDetails(
  BuildContext context,
  AdminUser user,
  String? avatarUrl,
  Map<String, String>? avatarHeaders,
) async {
  final cs = Theme.of(context).colorScheme;
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: cs.primary.withOpacity(0.12),
              foregroundImage: avatarUrl == null
                  ? null
                  : NetworkImage(avatarUrl, headers: avatarHeaders),
              child: avatarUrl == null
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              user.email,
              style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Role', value: user.roleLabel),
            _DetailRow(label: 'Phone', value: user.phone),
            _DetailRow(label: 'Society', value: user.society),
            _DetailRow(label: 'Building', value: user.building),
            _DetailRow(label: 'Apartment', value: user.apartment),
            _DetailRow(label: 'Status', value: user.statusLabel),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

enum AdminUserStatusFilter {
  all,
  active,
  banned,
  removed,
}

enum AdminUserRoleFilter {
  all,
  adminDrivers,
  residents,
}
