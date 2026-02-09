import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_waste_app/core/api/api_client.dart';
import 'package:smart_waste_app/core/localization/app_localizations.dart';
import 'package:smart_waste_app/core/utils/media_url.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../../core/widgets/stats_ring.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/animated_gradient_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final token = auth?.session?.accessToken;
    final apiBase = ref.watch(apiBaseUrlProvider);
    final reportsAsync = ref.watch(reportsProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final mediaHeaders =
        token?.isNotEmpty == true ? {'Authorization': 'Bearer $token'} : null;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              children: [
                DelayedReveal(
                  delay: const Duration(milliseconds: 80),
                  child: _DashboardHero(
                    location: l10n.choice('Kathmandu', 'काठमाडौं'),
                    onBellTap: () => context.go('/alerts'),
                  ),
                ),
                const SizedBox(height: 20),

                // Cleanliness score card - PREMIUM UPGRADE
                DelayedReveal(
                  delay: const Duration(milliseconds: 160),
                  child: KCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        StatsRing(
                          value: 73,
                          maxValue: 100,
                          size: 110,
                          strokeWidth: 10,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF199A70), Color(0xFFC9E265)],
                          ),
                          label: l10n.choice('SCORE', 'स्कोर'),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded,
                                      size: 16, color: Color(0xFF199A70)),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.choice('CITY SCORE', 'सहर स्कोर'),
                                    style: TextStyle(
                                      color: cs.onSurface.withOpacity(0.5),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.choice('Kathmandu', 'काठमाडौं'),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.trending_up_rounded,
                                      size: 18, color: Color(0xFF199A70)),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '+5% ',
                                    style: TextStyle(
                                      color: Color(0xFF199A70),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    l10n.choice('this week', 'यो हप्ता'),
                                    style: TextStyle(
                                      color: cs.onSurface.withOpacity(0.4),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Next pickup
                DelayedReveal(
                  delay: const Duration(milliseconds: 240),
                  child: settingsAsync.when(
                    loading: () => _PickupCard(
                      enabled: true,
                      l10n: l10n,
                      onChanged: (_) {},
                    ),
                    error: (_, __) => _PickupCard(
                      enabled: true,
                      l10n: l10n,
                      onChanged: (_) {},
                    ),
                    data: (s) => _PickupCard(
                      enabled: s.pickupRemindersEnabled,
                      l10n: l10n,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setPickupReminders(v),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                DelayedReveal(
                  delay: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        label: l10n.choice('Quick Actions', 'छिटो कामहरू'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.photo_camera_outlined,
                              label: l10n.choice('Report', 'रिपोर्ट'),
                              highlighted: true,
                              onTap: () => context.push('/reports/create'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.assignment_outlined,
                              label: l10n.reports,
                              onTap: () => context.push('/reports'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.calendar_month_outlined,
                              label: l10n.choice('Schedule', 'तालिका'),
                              onTap: () => context.go('/schedule'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.payments_outlined,
                              label: l10n.payments,
                              onTap: () => context.push('/payments'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                if (auth?.isAdmin ?? false) ...[
                  DelayedReveal(
                    delay: const Duration(milliseconds: 360),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          label:
                              l10n.choice('Admin Control', 'एडमिन नियन्त्रण'),
                        ),
                        const SizedBox(height: 12),
                        AnimatedGradientCard(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cs.primary.withOpacity(0.18),
                              cs.secondary.withOpacity(0.08),
                            ],
                          ),
                          onTap: () => context.push('/admin/users'),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: AppColors.tealEmeraldGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.supervisor_account_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.choice('User Management',
                                          'प्रयोगकर्ता व्यवस्थापन'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.choice(
                                        'Manage residents and admin drivers',
                                        'बसोबासकर्ता र एडमिन ड्राइभर व्यवस्थापन गर्नुहोस्',
                                      ),
                                      style: TextStyle(
                                        color: cs.onSurface.withOpacity(0.65),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: cs.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ],

                DelayedReveal(
                  delay: const Duration(milliseconds: 420),
                  child: Row(
                    children: [
                      _SectionTitle(
                        label:
                            l10n.choice('Recent Reports', 'हालका रिपोर्टहरू'),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => context.push('/reports'),
                        icon: Text(l10n.choice('View All', 'सबै हेर्नुहोस्')),
                        label:
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                reportsAsync.when(
                  loading: () => const ShimmerLoading(
                    child: Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Column(
                        children: [
                          ListItemSkeleton(),
                          SizedBox(height: 12),
                          ListItemSkeleton(),
                          SizedBox(height: 12),
                          ListItemSkeleton(),
                        ],
                      ),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      l10n.choice(
                        'Failed to load reports: $e',
                        'रिपोर्ट लोड गर्न सकिएन: $e',
                      ),
                    ),
                  ),
                  data: (all) {
                    final list = [...all];
                    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    final recent = list.take(5).toList();

                    if (recent.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: KCard(
                          child: Column(
                            children: [
                              const SizedBox(height: 6),
                              Icon(Icons.inbox_rounded,
                                  size: 46,
                                  color: cs.onSurface.withOpacity(0.55)),
                              const SizedBox(height: 10),
                              Text(
                                l10n.choice(
                                    'No reports yet', 'अहिलेसम्म रिपोर्ट छैन'),
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.choice(
                                  'Report waste to help keep your neighborhood clean.',
                                  'आफ्नो वरपर सफा राख्न फोहोर रिपोर्ट गर्नुहोस्।',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.62)),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () =>
                                      context.push('/reports/create'),
                                  child: Text(
                                    l10n.choice('Report Waste',
                                        'फोहोर रिपोर्ट गर्नुहोस्'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final r in recent) ...[
                          _ReportRow(
                            title: _localizedCategory(r.category, l10n),
                            code: 'RPT-${r.createdAt % 10000}'.padLeft(4, '0'),
                            location: r.location,
                            time: _timeAgo(context, r.createdAt),
                            status: r.status,
                            l10n: l10n,
                            attachmentUrl:
                                resolveMediaUrl(apiBase, r.attachmentUrl),
                            attachmentHeaders: mediaHeaders,
                            onTap: () => context.push('/reports'),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.location,
    required this.onBellTap,
  });

  final String location;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              size: 22, color: Color(0xFF199A70)),
          const SizedBox(width: 8),
          Text(
            location,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: cs.onSurface.withOpacity(0.4),
          ),
          const Spacer(),
          _BellButton(
            hasDot: true,
            onTap: onBellTap,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: cs.onSurface.withOpacity(0.55),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
        fontSize: 12,
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasDot, required this.onTap});
  final bool hasDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              offset: const Offset(0, 12),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                color: cs.onSurface.withOpacity(0.72)),
            if (hasDot)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cs.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  const _PickupCard({
    required this.enabled,
    required this.onChanged,
    required this.l10n,
  });
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return KCard(
      backgroundColor: isDark ? cs.surfaceContainerHigh : null,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? cs.primary.withValues(alpha: 0.16)
                  : const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: Color(0xFF199A70), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.choice('NEXT PICKUP', 'अर्को संकलन'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  l10n.choice('Tomorrow, 7:00 AM', 'भोलि, बिहान ७:०० बजे'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 18, color: cs.onSurface.withOpacity(0.3)),
              const SizedBox(width: 4),
              Text(
                '14h',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = highlighted
        ? cs.primary.withValues(alpha: isDark ? 0.22 : 0.12)
        : (isDark ? cs.surfaceContainerHighest : const Color(0xFFF1F5F9));
    final fg = highlighted
        ? cs.primary
        : (isDark ? cs.onSurface : const Color(0xFF475569));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? cs.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: fg, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.title,
    required this.code,
    required this.location,
    required this.time,
    required this.status,
    required this.attachmentUrl,
    required this.attachmentHeaders,
    required this.onTap,
    required this.l10n,
  });

  final String title;
  final String code;
  final String location;
  final String time;
  final String status;
  final String? attachmentUrl;
  final Map<String, String>? attachmentHeaders;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'verified':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'in progress':
      case 'in_progress':
        statusColor = const Color(0xFF10B981);
        break;
      case 'cleaned':
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
    }

    return KCard(
      backgroundColor: isDark ? cs.surfaceContainerHigh : null,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? cs.surface : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: attachmentUrl == null
                ? const Icon(Icons.image_outlined, color: Color(0xFF94A3B8))
                : Image.network(
                    attachmentUrl!,
                    fit: BoxFit.cover,
                    headers: attachmentHeaders,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: cs.onSurface.withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time_rounded,
                        size: 14, color: cs.onSurface.withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _localizedStatus(status, l10n),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withOpacity(0.2)),
            ],
          ),
        ],
      ),
    );
  }
}

String _timeAgo(BuildContext context, int millis) {
  final l10n = AppLocalizations.of(context);
  try {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return l10n.choice(
        '${diff.inMinutes}m ago',
        '${diff.inMinutes} मिनेट अघि',
      );
    }
    if (diff.inHours < 24) {
      return l10n.choice(
        '${diff.inHours}h ago',
        '${diff.inHours} घण्टा अघि',
      );
    }
    return l10n.choice(
      '${diff.inDays}d ago',
      '${diff.inDays} दिन अघि',
    );
  } catch (e) {
    return l10n.choice('some time ago', 'केही समय अघि');
  }
}

String _localizedCategory(String category, AppLocalizations l10n) {
  switch (category.trim().toLowerCase()) {
    case 'missed pickup':
      return l10n.missedPickup;
    case 'overflow':
    case 'overflowing bin':
      return l10n.overflowingBin;
    case 'bad smell':
      return l10n.badSmell;
    case 'other':
      return l10n.other;
    default:
      return category;
  }
}

String _localizedStatus(String raw, AppLocalizations l10n) {
  final status = raw.trim().toLowerCase().replaceAll(' ', '_');
  switch (status) {
    case 'verified':
      return l10n.reportFiltersVerified;
    case 'in_progress':
      return l10n.reportFiltersInProgress;
    case 'cleaned':
    case 'resolved':
      return l10n.reportFiltersCleaned;
    case 'pending':
    default:
      return l10n.choice('Pending', 'पेन्डिङ');
  }
}
