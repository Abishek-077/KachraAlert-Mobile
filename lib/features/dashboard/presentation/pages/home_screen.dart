import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../../core/widgets/stats_ring.dart';
import '../../../../core/widgets/floating_action_card.dart';
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
    final auth = ref.watch(authStateProvider).valueOrNull;
    final userId = auth?.session?.userId;
    final reportsAsync = ref.watch(reportsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: [
            _DashboardHero(
              location: 'Kathmandu',
              onBellTap: () => context.go('/alerts'),
            ),
            const SizedBox(height: 20),

            // Cleanliness score card - PREMIUM UPGRADE
            AnimatedGradientCard(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surface,
                  cs.primary.withOpacity(0.05),
                ],
              ),
              child: Row(
                children: [
                  // Animated stats ring with gradient
                  StatsRing(
                    value: 73,
                    maxValue: 100,
                    size: 100,
                    strokeWidth: 10,
                    gradient: AppColors.tealEmeraldGradient,
                    label: 'score',
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppColors.tealEmeraldGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CITY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CLEANLINESS',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kathmandu Metro',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withOpacity(0.15),
                                cs.primary.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up_rounded, size: 18, color: cs.primary),
                              const SizedBox(width: 6),
                              Text(
                                '+5% ',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'this week',
                                style: TextStyle(
                                  color: cs.primary.withOpacity(0.7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Next pickup
            settingsAsync.when(
              loading: () => _PickupCard(
                enabled: true,
                onChanged: (_) {},
              ),
              error: (_, __) => _PickupCard(
                enabled: true,
                onChanged: (_) {},
              ),
              data: (s) => _PickupCard(
                enabled: s.pickupRemindersEnabled,
                onChanged: (v) => ref.read(settingsProvider.notifier).setPickupReminders(v),
              ),
            ),

            const SizedBox(height: 18),

            _SectionTitle(label: 'Quick Actions'),
            const SizedBox(height: 12),

            // PREMIUM QUICK ACTIONS
            Row(
              children: [
                Expanded(
                  child: FloatingActionCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Report\nWaste',
                    isEmphasized: true,
                    gradient: AppColors.tealEmeraldGradient,
                    onTap: () => context.push('/reports/create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FloatingActionCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Schedule',
                    onTap: () => context.go('/schedule'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FloatingActionCard(
                    icon: Icons.description_rounded,
                    label: 'My\nReports',
                    onTap: () => context.push('/reports'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FloatingActionCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Alerts',
                    badgeCount: 3,
                    onTap: () => context.go('/alerts'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                const _SectionTitle(label: 'Recent Reports'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/reports'),
                  icon: const Text('View All'),
                  label: const Icon(Icons.arrow_forward_rounded, size: 18),
                ),
              ],
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
                child: Text('Failed to load reports: $e'),
              ),
              data: (all) {
                final mine = (userId == null)
                    ? <dynamic>[]
                    : all.where((r) => r.userId == userId).toList();

                final list = mine.isEmpty ? all : mine;
                list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final recent = list.take(3).toList();

                if (recent.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: KCard(
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          Icon(Icons.inbox_rounded, size: 46, color: cs.onSurface.withOpacity(0.55)),
                          const SizedBox(height: 10),
                          const Text(
                            'No reports yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Report waste to help keep your neighborhood clean.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurface.withOpacity(0.62)),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => context.push('/reports/create'),
                              child: const Text('Report Waste'),
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
                        title: r.category,
                        code: 'RPT-${r.createdAt % 10000}'.padLeft(4, '0'),
                        location: r.location,
                        time: _timeAgo(r.createdAt),
                        status: r.status,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.18),
            cs.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: cs.primary.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            offset: const Offset(0, 18),
            color: cs.primary.withOpacity(0.18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -10,
            child: _HeroOrb(
              size: 86,
              colors: [
                cs.primary.withOpacity(0.45),
                cs.primary.withOpacity(0.05),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    location,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                  const Spacer(),
                  _BellButton(
                    hasDot: true,
                    onTap: onBellTap,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Good morning',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.68),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Let’s keep Kathmandu clean today.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Clean City',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
            Icon(Icons.notifications_none_rounded, color: cs.onSurface.withOpacity(0.72)),
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

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.2),
          colors: colors,
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 86,
      height: 86,
      child: CustomPaint(
        painter: _RingPainter(
          progress: (score.clamp(0, 100)) / 100,
          color: color,
          trackColor: cs.outlineVariant.withOpacity(0.35),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text('score', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.6), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.trackColor});
  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final track = Paint()
      ..color = trackColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final prog = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2, false, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2 * progress, false, prog);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.trackColor != trackColor;
}

class _PickupCard extends StatelessWidget {
  const _PickupCard({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return KCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          KIconCircle(
            icon: Icons.calendar_month_outlined,
            background: cs.primary.withOpacity(0.10),
            foreground: cs.primary,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT PICKUP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
                SizedBox(height: 6),
                Text('Tomorrow, 7:00 AM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('in 14 hours', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
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
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = primary ? cs.primary : cs.surface;
    final fg = primary ? cs.onPrimary : cs.onSurface.withOpacity(0.78);
    final accent = primary ? cs.primary : cs.primary.withOpacity(0.12);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              primary ? bg.withOpacity(0.9) : cs.surfaceVariant.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: primary ? Colors.white.withOpacity(0.2) : cs.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              offset: const Offset(0, 12),
              color: Colors.black.withOpacity(primary ? 0.12 : 0.08),
            ),
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(-6, -6),
              color: Colors.white.withOpacity(primary ? 0.16 : 0.5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12, height: 1.15),
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
    required this.onTap,
  });

  final String title;
  final String code;
  final String location;
  final String time;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final statusUi = _statusUi(status, cs);

    return KCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined, color: cs.primary.withOpacity(0.7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusUi.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusUi.color.withOpacity(0.18)),
                      ),
                      child: Text(
                        statusUi.label,
                        style: TextStyle(color: statusUi.color, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.45)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: TextStyle(color: cs.onSurface.withOpacity(0.45), fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: cs.onSurface.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.onSurface.withOpacity(0.62), fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_rounded, size: 14, color: cs.onSurface.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(color: cs.onSurface.withOpacity(0.62), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

({String label, Color color}) _statusUi(String status, ColorScheme cs) {
  switch (status) {
    case 'resolved':
      return (label: 'Cleaned', color: const Color(0xFF1ECA92));
    case 'in_progress':
      return (label: 'In Progress', color: const Color(0xFF0E6E66));
    case 'pending':
    default:
      return (label: 'Verified', color: const Color(0xFF1B8EF2));
  }
}

String _timeAgo(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
