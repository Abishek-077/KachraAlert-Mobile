import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../admin/presentation/providers/admin_alert_providers.dart';

class AlertsHubScreen extends ConsumerStatefulWidget {
  const AlertsHubScreen({super.key});

  @override
  ConsumerState<AlertsHubScreen> createState() => _AlertsHubScreenState();
}

class _AlertsHubScreenState extends ConsumerState<AlertsHubScreen> {
  int _filterIndex = 0;

  final _filters = const ['All', 'Urgent', 'Pickup', 'Weather', 'Community'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final alertsAsync = ref.watch(adminAlertsProvider);

    return AppScaffold(
      padding: AppSpacing.screenInsets.copyWith(bottom: 0),
      child: Column(
        children: [
          Row(
            children: [
              Text('Alerts', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.labelSpacing),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Filters',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurface.withOpacity(0.55)),
            ),
          ),
          const SizedBox(height: AppSpacing.labelSpacing),
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return ChoiceChip(
                  label: Text(_filters[i]),
                  selected: i == _filterIndex,
                  onSelected: (_) => setState(() => _filterIndex = i),
                );
              },
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.labelSpacing),
              itemCount: _filters.length,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load alerts: $e')),
              data: (alerts) {
                final dynamicAlerts = alerts.map((a) {
                  final type = _inferType(a.title, a.message);
                  return _AlertItem(
                    type: type,
                    title: a.title,
                    message: a.message,
                    meta: 'Municipal Office',
                    timeAgo: _timeAgo(a.createdAt),
                  );
                }).toList();

                final filtered = dynamicAlerts.where((a) {
                  final f = _filters[_filterIndex];
                  if (f == 'All') return true;
                  return a.type == f;
                }).toList();

                if (filtered.isEmpty) {
                  return CivicCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 46,
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                        const SizedBox(height: AppSpacing.labelSpacing),
                        const Text(
                          'No alerts',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.labelSpacing),
                        Text(
                          'You’re all caught up.',
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.62),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final recent = filtered
                    .where((a) => a.timeAgo.contains('min') || a.timeAgo.contains('h'))
                    .toList();
                final older = filtered
                    .where((a) => !recent.contains(a))
                    .toList();

                return ListView(
                  padding: AppSpacing.screenInsetsBottom.copyWith(top: 0),
                  children: [
                    const SectionHeader(label: 'Recent'),
                    const SizedBox(height: AppSpacing.labelSpacing),
                    if (recent.isEmpty)
                      Text(
                        'No recent alerts.',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                      ),
                    for (final item in recent) ...[
                      const SizedBox(height: AppSpacing.itemSpacing),
                      _AlertCard(item: item),
                    ],
                    if (older.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      const SectionHeader(label: 'Earlier'),
                      const SizedBox(height: AppSpacing.labelSpacing),
                      for (final item in older) ...[
                        const SizedBox(height: AppSpacing.itemSpacing),
                        _AlertCard(item: item),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem {
  final String type; // Urgent | Pickup | Weather | Community
  final String title;
  final String message;
  final String timeAgo;
  final String meta;
  late final Color accent;
  late final IconData icon;

  _AlertItem({
    required this.type,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.meta,
  }) {
    final ui = _typeUi(type);
    accent = ui.accent;
    icon = ui.icon;
  }
}

({Color accent, IconData icon}) _typeUi(String type) {
  switch (type) {
    case 'Urgent':
      return (accent: const Color(0xFFEF4444), icon: Icons.warning_amber_rounded);
    case 'Pickup':
      return (accent: const Color(0xFF1ECA92), icon: Icons.local_shipping_outlined);
    case 'Weather':
      return (accent: const Color(0xFF1B8EF2), icon: Icons.water_drop_outlined);
    case 'Community':
    default:
      return (accent: const Color(0xFF0E6E66), icon: Icons.people_outline_rounded);
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.item});
  final _AlertItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final urgent = item.type == 'Urgent';

    return CivicCard(
      padding: const EdgeInsets.all(AppSpacing.componentPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: urgent
                  ? AppColors.error.withOpacity(0.12)
                  : item.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: urgent ? AppColors.error : item.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.itemSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (urgent)
                      const StatusChip(
                        label: 'Urgent',
                        tone: StatusTone.urgent,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.labelSpacing),
                Text(
                  item.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.62),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 14, color: cs.onSurface.withOpacity(0.5)),
                    const SizedBox(width: AppSpacing.labelSpacing),
                    Text(
                      item.timeAgo,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.itemSpacing),
                    Text(
                      '•',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.35)),
                    ),
                    const SizedBox(width: AppSpacing.itemSpacing),
                    Icon(Icons.apartment_outlined,
                        size: 14, color: cs.onSurface.withOpacity(0.5)),
                    const SizedBox(width: AppSpacing.labelSpacing),
                    Text(
                      item.meta,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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

String _inferType(String title, String message) {
  final t = '${title.toLowerCase()} ${message.toLowerCase()}';
  if (t.contains('urgent') || t.contains('illegal') || t.contains('hazard') || t.contains('danger')) {
    return 'Urgent';
  }
  if (t.contains('pickup') || t.contains('collection') || t.contains('schedule') || t.contains('tomorrow')) {
    return 'Pickup';
  }
  if (t.contains('rain') || t.contains('storm') || t.contains('weather') || t.contains('monsoon')) {
    return 'Weather';
  }
  return 'Community';
}

String _timeAgo(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
