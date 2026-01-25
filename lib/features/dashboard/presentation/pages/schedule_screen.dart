import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/k_widgets.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../schedule/presentation/providers/schedule_providers.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authStateProvider).asData?.value;
    final isAdmin = auth?.isAdmin ?? false;

    final schedulesAsync = ref.watch(schedulesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(schedulesProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            children: [
              Row(
                children: [
                  const Text(
                    'Schedule',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  if (isAdmin)
                    IconButton(
                      tooltip: 'Manage Schedule',
                      onPressed: () => context.push('/admin/schedule'),
                      icon: const Icon(Icons.edit_calendar_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              schedulesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => KCard(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 46),
                      const SizedBox(height: 10),
                      Text(
                        'Failed to load schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$e',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              ref.read(schedulesProvider.notifier).load(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return KCard(
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 52),
                          const SizedBox(height: 10),
                          const Text(
                            'No schedule published yet',
                            style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Admin will publish collection dates soon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => context.push('/admin/schedule'),
                                child: const Text('Create Schedule'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final s in list) ...[
                        _ScheduleCard(
                          title: '${s.waste} • ${s.timeLabel}',
                          dateISO: s.dateISO,
                          status: s.status,
                        ),
                        const SizedBox(height: 12),
                      ]
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.title,
    required this.dateISO,
    required this.status,
  });

  final String title;
  final String dateISO;
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final parsedDate = DateTime.tryParse(dateISO);
    final dateStr = parsedDate == null
        ? dateISO
        : '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}';
    final isUpcoming = status.toLowerCase() == 'upcoming';

    return KCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          KIconCircle(
            icon: Icons.local_shipping_rounded,
            background: cs.primary.withOpacity(0.10),
            foreground: cs.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  '$dateStr  •  $status',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            isUpcoming
                ? Icons.access_time_rounded
                : Icons.check_circle_rounded,
            color: isUpcoming
                ? cs.secondary
                : const Color(0xFF1ECA92),
          ),
        ],
      ),
    );
  }
}
