import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_waste_app/core/theme/app_colors.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../schedule/presentation/providers/schedule_providers.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = auth?.isAdmin ?? false;

    final schedulesAsync = ref.watch(schedulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Schedule'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Manage Schedule',
              onPressed: () => context.push('/admin/schedule'),
              icon: const Icon(Icons.edit_calendar_rounded),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(schedulesProvider.notifier).load(),
        child: schedulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _NiceCard(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      'Failed to load schedule.\n$e',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(schedulesProvider.notifier).load(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _NiceCard(
                    child: Column(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 46),
                        const SizedBox(height: 10),
                        const Text(
                          'No schedule published yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Admin will publish collection dates soon.',
                          textAlign: TextAlign.center,
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              onPressed: () => context.push('/admin/schedule'),
                              child: const Text('Create Schedule'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = list[i];
                final dateStr =
                    '${s.date.day.toString().padLeft(2, '0')}-${s.date.month.toString().padLeft(2, '0')}-${s.date.year}';

                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      // ✅ FIX: remove const because AppColors.primary is not const-safe here
                      child: Icon(
                        Icons.local_shipping_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      '${s.area} • ${s.shift}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '$dateStr\n${s.note.isEmpty ? 'No note' : s.note}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: s.isActive
                        ? const Icon(Icons.check_circle_rounded)
                        : const Icon(Icons.pause_circle_filled_rounded),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NiceCard extends StatelessWidget {
  const _NiceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
