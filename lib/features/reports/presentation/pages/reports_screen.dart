import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/k_widgets.dart';
import '../../data/models/report_hive_model.dart';
import '../providers/report_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reportsAsync = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'New Report',
            onPressed: () => context.push('/reports/create'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                KChip(
                  label: 'All',
                  selected: _filter == 'All',
                  onTap: () => setState(() => _filter = 'All'),
                ),
                const SizedBox(width: 10),
                KChip(
                  label: 'Verified',
                  selected: _filter == 'Verified',
                  onTap: () => setState(() => _filter = 'Verified'),
                ),
                const SizedBox(width: 10),
                KChip(
                  label: 'In Progress',
                  selected: _filter == 'In Progress',
                  onTap: () => setState(() => _filter = 'In Progress'),
                ),
                const SizedBox(width: 10),
                KChip(
                  label: 'Cleaned',
                  selected: _filter == 'Cleaned',
                  onTap: () => setState(() => _filter = 'Cleaned'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          reportsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => KCard(
              child: Column(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 46, color: cs.error),
                  const SizedBox(height: 10),
                  Text(
                    'Failed to load reports',
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
                      onPressed: () => ref.read(reportsProvider.notifier).load(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
            data: (all) {
              final list = _applyFilter(all, _filter)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (list.isEmpty) {
                return KCard(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 52, color: cs.onSurface.withOpacity(0.55)),
                      const SizedBox(height: 10),
                      const Text(
                        'No reports found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create a report to keep your neighborhood clean.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurface.withOpacity(0.62)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.push('/reports/create'),
                          child: const Text('Report Waste'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final r in list) ...[
                    _ReportCard(
                      report: r,
                      onTap: () => context.push('/reports/create', extra: r),
                    ),
                    const SizedBox(height: 12),
                  ]
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

List<ReportHiveModel> _applyFilter(List<ReportHiveModel> all, String filter) {
  if (filter == 'All') return [...all];
  if (filter == 'Verified') return all.where((r) => r.status == 'pending').toList();
  if (filter == 'In Progress') return all.where((r) => r.status == 'in_progress').toList();
  if (filter == 'Cleaned') return all.where((r) => r.status == 'resolved').toList();
  return [...all];
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});
  final ReportHiveModel report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ui = _statusUi(report.status, cs);
    final idShort = (report.createdAt % 10000).toString().padLeft(4, '0');

    return KCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined,
                color: cs.primary.withOpacity(0.7)),
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
                        report.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ui.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: ui.border),
                      ),
                      child: Text(
                        ui.label,
                        style: TextStyle(
                          color: ui.fg,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'RPT-$idShort',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place_rounded,
                        size: 16, color: cs.onSurface.withOpacity(0.55)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.location,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.65),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_rounded,
                        size: 16, color: cs.onSurface.withOpacity(0.55)),
                    const SizedBox(width: 6),
                    Text(
                      _timeAgo(report.createdAt),
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.55)),
        ],
      ),
    );
  }
}

_StatusUi _statusUi(String status, ColorScheme cs) {
  switch (status) {
    case 'resolved':
      return _StatusUi(
        label: 'Cleaned',
        bg: const Color(0xFF1ECA92).withOpacity(0.12),
        fg: const Color(0xFF0E6E66),
        border: const Color(0xFF1ECA92).withOpacity(0.25),
      );
    case 'in_progress':
      return _StatusUi(
        label: 'In Progress',
        bg: cs.primary.withOpacity(0.10),
        fg: cs.primary,
        border: cs.primary.withOpacity(0.20),
      );
    case 'pending':
    default:
      return _StatusUi(
        label: 'Verified',
        bg: const Color(0xFF1B8EF2).withOpacity(0.10),
        fg: const Color(0xFF1B8EF2),
        border: const Color(0xFF1B8EF2).withOpacity(0.20),
      );
  }
}

class _StatusUi {
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  const _StatusUi({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });
}

String _timeAgo(int millis) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final diff = Duration(milliseconds: now - millis);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
