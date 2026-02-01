import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/k_widgets.dart';
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

    return AppScaffold(
      padding: AppSpacing.screenInsets.copyWith(bottom: 120),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HomeHeader(onBellTap: () => context.go('/alerts')),
          const SizedBox(height: AppSpacing.sectionSpacing),
          settingsAsync.when(
            loading: () => const _NextPickupCard(enabled: true),
            error: (_, __) => const _NextPickupCard(enabled: true),
            data: (s) => _NextPickupCard(
              enabled: s.pickupRemindersEnabled,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setPickupReminders(v),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          PrimaryButton(
            label: 'Report Issue',
            icon: Icons.add_circle_outline,
            onPressed: () => context.push('/reports/create'),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          SecondaryButton(
            label: 'View Pickup Schedule',
            icon: Icons.calendar_month_outlined,
            onPressed: () => context.go('/schedule'),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          const SectionHeader(label: 'City score'),
          const SizedBox(height: AppSpacing.labelSpacing),
          const _CityScoreCard(),
          const SizedBox(height: AppSpacing.sectionSpacing),
          SectionHeader(
            label: 'Recent reports',
            action: TextButton(
              onPressed: () => context.push('/reports'),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: AppSpacing.labelSpacing),
          reportsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sectionSpacing),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.labelSpacing),
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
                return CivicCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 44,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.55),
                      ),
                      const SizedBox(height: AppSpacing.labelSpacing),
                      const Text(
                        'No reports yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.labelSpacing),
                      Text(
                        'Report an issue to keep your neighborhood clean.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      PrimaryButton(
                        label: 'Report issue',
                        onPressed: () => context.push('/reports/create'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final r in recent) ...[
                    CivicCard(
                      onTap: () => context.push('/reports'),
                      child: ListRow(
                        icon: Icons.report_outlined,
                        title: r.category,
                        subtitle:
                            '${_timeAgo(r.createdAt)} • ${r.location}',
                        trailing: _statusChipFor(r.status),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.itemSpacing),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onBellTap});

  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kathmandu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.labelSpacing),
            Text(
              'City services dashboard',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: onBellTap,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _NextPickupCard extends StatelessWidget {
  const _NextPickupCard({required this.enabled, this.onChanged});

  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CivicCard(
      padding: const EdgeInsets.all(AppSpacing.componentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(label: 'Next pickup'),
          const SizedBox(height: AppSpacing.labelSpacing),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tomorrow, 7:00 AM',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.labelSpacing),
          Text(
            'Reminder in 14 hours',
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityScoreCard extends StatelessWidget {
  const _CityScoreCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CivicCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '73',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.itemSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kathmandu Metro',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.labelSpacing),
                Text(
                  'City score this week',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const StatusChip(label: '+5%', tone: StatusTone.success),
        ],
      ),
    );
  }
}

StatusChip _statusChipFor(String status) {
  switch (status) {
    case 'resolved':
      return const StatusChip(label: 'Resolved', tone: StatusTone.success);
    case 'in_progress':
      return const StatusChip(label: 'In progress', tone: StatusTone.warning);
    case 'pending':
    default:
      return const StatusChip(label: 'Pending', tone: StatusTone.neutral);
  }
}

String _timeAgo(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
