import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../admin/presentation/providers/admin_alert_providers.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../../../reports/data/models/report_hive_model.dart';

class AlertsHubScreen extends ConsumerStatefulWidget {
  const AlertsHubScreen({super.key});

  @override
  ConsumerState<AlertsHubScreen> createState() => _AlertsHubScreenState();
}

class _AlertsHubScreenState extends ConsumerState<AlertsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = auth?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Announcements'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _AnnouncementsTab(isAdmin: isAdmin),
          _ReportsAlertsTab(isAdmin: isAdmin, userId: auth?.session?.userId),
        ],
      ),
    );
  }
}

class _AnnouncementsTab extends ConsumerWidget {
  const _AnnouncementsTab({required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(adminAlertsProvider);

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/alerts/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Alert'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminAlertsProvider.notifier).load(),
        child: alerts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline_rounded, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to load announcements\n$e',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.notifications_none_rounded, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    isAdmin
                        ? 'No announcements yet'
                        : 'No announcements from admin',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            }

            final sorted = [...list]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = sorted[i];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.campaign_rounded),
                    title: Text(
                      a.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.message),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(a.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: isAdmin
                        ? PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                // no async gap needed here
                                context.push('/alerts/create', extra: a);
                              }

                              if (v == 'delete') {
                                _confirmDeleteAlert(context, ref, a.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDeleteAlert(BuildContext context, WidgetRef ref, String id) {
    // Capture navigator & messenger so we don't rely on context after await
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Alert?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => nav.pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              nav.pop(); // close dialog first (no context needed later)

              try {
                await ref.read(adminAlertsProvider.notifier).delete(id);
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Alert deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (_) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete alert'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ReportsAlertsTab extends ConsumerWidget {
  const _ReportsAlertsTab({required this.isAdmin, this.userId});

  final bool isAdmin;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return Scaffold(
      floatingActionButton: (!isAdmin && userId != null)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/reports/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Report'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(reportsProvider.notifier).load(),
        child: reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline_rounded, size: 40),
              const SizedBox(height: 12),
              Text('Failed to load reports\n$e', textAlign: TextAlign.center),
            ],
          ),
          data: (allReports) {
            final reports = isAdmin
                ? allReports
                : (userId == null)
                ? <ReportHiveModel>[]
                : allReports.where((r) => r.userId == userId).toList();

            if (reports.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.report_problem_rounded, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    'No reports yet',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (!isAdmin) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Create a report to help keep your area clean',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              );
            }

            reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final report = reports[i];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.report_problem_rounded),
                    title: Text(
                      report.category,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.location),
                        const SizedBox(height: 4),
                        Text(
                          report.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ReportStatusChip(status: report.status),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (isAdmin) {
                              if (v == 'status') {
                                _showStatusUpdateDialog(context, ref, report);
                              }
                            } else {
                              if (v == 'edit') {
                                context.push('/reports/create', extra: report);
                              }
                              if (v == 'delete') {
                                _confirmDeleteReport(context, ref, report.id);
                              }
                            }
                          },
                          itemBuilder: (_) {
                            if (isAdmin) {
                              return const [
                                PopupMenuItem(
                                  value: 'status',
                                  child: Row(
                                    children: [
                                      Icon(Icons.update, size: 18),
                                      SizedBox(width: 8),
                                      Text('Update Status'),
                                    ],
                                  ),
                                ),
                              ];
                            }
                            return const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    ReportHiveModel report,
  ) {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Report Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select new status:'),
            const SizedBox(height: 16),
            ...['pending', 'in_progress', 'resolved'].map((status) {
              final label =
                  status[0].toUpperCase() +
                  status.substring(1).replaceAll('_', ' ');

              return ListTile(
                title: Text(label),
                trailing: report.status == status
                    ? const Icon(Icons.check)
                    : null,
                onTap: () async {
                  nav.pop(); // close first

                  try {
                    await ref
                        .read(reportsProvider.notifier)
                        .adminUpdateStatus(report.id, status);

                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text('Status updated'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (_) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text('Failed to update status'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(onPressed: () => nav.pop(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _confirmDeleteReport(BuildContext context, WidgetRef ref, String id) {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => nav.pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              nav.pop(); // close first

              try {
                await ref.read(reportsProvider.notifier).delete(id);
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Report deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (_) {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete report'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ReportStatusChip extends StatelessWidget {
  const _ReportStatusChip({required this.status});
  final String status;

  Color _getColor() {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label =
        status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
    final c = _getColor();

    return Chip(
      label: Text(label),
      backgroundColor: c.withAlpha(45),
      labelStyle: TextStyle(color: c, fontWeight: FontWeight.w700),
      visualDensity: VisualDensity.compact,
    );
  }
}
