import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/k_widgets.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../schedule/presentation/providers/schedule_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = auth?.isAdmin ?? false;

    final schedulesAsync = ref.watch(schedulesProvider);

    return AppScaffold(
      padding: AppSpacing.screenInsets.copyWith(bottom: 120),
      child: RefreshIndicator(
        onRefresh: () => ref.read(schedulesProvider.notifier).load(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Row(
              children: [
                Text('Schedule', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                if (isAdmin)
                  IconButton(
                    tooltip: 'Manage Schedule',
                    onPressed: () => context.push('/admin/schedule'),
                    icon: const Icon(Icons.edit_calendar_rounded),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
            schedulesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sectionSpacing),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => CivicCard(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 46),
                    const SizedBox(height: AppSpacing.labelSpacing),
                    Text(
                      'Failed to load schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.labelSpacing),
                    Text(
                      '$e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    PrimaryButton(
                      label: 'Retry',
                      icon: Icons.refresh_rounded,
                      onPressed: () =>
                          ref.read(schedulesProvider.notifier).load(),
                    ),
                  ],
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return CivicCard(
                    child: Column(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 52),
                        const SizedBox(height: AppSpacing.labelSpacing),
                        const Text(
                          'No schedule published yet',
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.labelSpacing),
                        Text(
                          'Admin will publish collection dates soon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: AppSpacing.sectionSpacing),
                          PrimaryButton(
                            label: 'Create Schedule',
                            onPressed: () => context.push('/admin/schedule'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final upcoming = list
                    .where((s) => s.status.toLowerCase() == 'upcoming')
                    .toList();
                final completed = list
                    .where((s) => s.status.toLowerCase() != 'upcoming')
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(label: 'Upcoming pickups'),
                    const SizedBox(height: AppSpacing.labelSpacing),
                    if (upcoming.isEmpty)
                      Text(
                        'No upcoming pickups scheduled.',
                        style:
                            TextStyle(color: cs.onSurface.withOpacity(0.6)),
                      ),
                    for (final s in upcoming) ...[
                      const SizedBox(height: AppSpacing.itemSpacing),
                      CivicCard(
                        child: ListRow(
                          icon: Icons.local_shipping_outlined,
                          title: '${s.waste} • ${s.timeLabel}',
                          subtitle: _formatDate(s.dateISO),
                          trailing: _ScheduleStatus(status: s.status),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: const SectionHeader(label: 'Completed'),
                      initiallyExpanded: false,
                      children: [
                        for (final s in completed) ...[
                          const SizedBox(height: AppSpacing.itemSpacing),
                          CivicCard(
                            child: ListRow(
                              icon: Icons.check_circle_outline,
                              title: '${s.waste} • ${s.timeLabel}',
                              subtitle: _formatDate(s.dateISO),
                              trailing: _ScheduleStatus(status: s.status),
                            ),
                          ),
                        ],
                      ],
                    ),
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

class _ScheduleStatus extends StatelessWidget {
  const _ScheduleStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isUpcoming = normalized == 'upcoming';
    final icon = isUpcoming ? Icons.access_time_rounded : Icons.check_circle;
    final label = isUpcoming ? 'Upcoming' : 'Completed';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: AppSpacing.labelSpacing),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}

String _formatDate(String dateISO) {
  final parsedDate = DateTime.tryParse(dateISO);
  if (parsedDate == null) return dateISO;
  final day = parsedDate.day.toString().padLeft(2, '0');
  final month = parsedDate.month.toString().padLeft(2, '0');
  return '$day-$month-${parsedDate.year}';
}
