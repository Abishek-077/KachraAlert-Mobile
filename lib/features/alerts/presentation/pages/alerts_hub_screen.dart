import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Text('Alerts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  _CircleIcon(icon: Icons.search_rounded, onTap: () {}),
                  const SizedBox(width: 12),
                  _CircleIcon(icon: Icons.filter_alt_outlined, onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Filter chips
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, i) {
                  return KChip(
                    label: _filters[i],
                    selected: i == _filterIndex,
                    showDot: _filters[i] == 'Urgent',
                    onTap: () => setState(() => _filterIndex = i),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: _filters.length,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: alertsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load alerts: $e')),
                data: (alerts) {
                  // Seeded “reference-like” alerts at top
                  final seeded = _seededAlerts();
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

                  final combined = [...seeded, ...dynamicAlerts];
                  final filtered = combined.where((a) {
                    final f = _filters[_filterIndex];
                    if (f == 'All') return true;
                    return a.type == f;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: KCard(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 46, color: cs.onSurface.withOpacity(0.55)),
                            const SizedBox(height: 12),
                            const Text('No alerts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text('You’re all caught up.', style: TextStyle(color: cs.onSurface.withOpacity(0.62))),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _AlertCard(item: item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
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
        child: Icon(icon, color: cs.onSurface.withOpacity(0.72)),
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

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 116,
            decoration: BoxDecoration(
              color: item.accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                bottomLeft: Radius.circular(22),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.accent.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.accent),
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
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.45)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: cs.onSurface.withOpacity(0.62), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              item.timeAgo,
                              style: TextStyle(color: cs.onSurface.withOpacity(0.50), fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                            Text('•', style: TextStyle(color: cs.onSurface.withOpacity(0.35))),
                            const SizedBox(width: 10),
                            Text(
                              item.meta,
                              style: TextStyle(color: cs.onSurface.withOpacity(0.50), fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.open_in_new_rounded, size: 14, color: cs.onSurface.withOpacity(0.45)),
                          ],
                        ),
                      ],
                    ),
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

List<_AlertItem> _seededAlerts() {
  return [
    _AlertItem(
      type: 'Urgent',
      title: 'Illegal Dumping Reported',
      message: 'Large waste pile near Ratnapark area requires immediate attention. Avoid the area if possible.',
      timeAgo: '15 min ago',
      meta: 'Municipal Office',
    ),
    _AlertItem(
      type: 'Pickup',
      title: "Tomorrow's Collection",
      message: 'Regular waste collection scheduled for Zone A (Thamel, New Road, Ason). Please place bins outside by 6:30 AM.',
      timeAgo: '1h ago',
      meta: 'KMC Waste Dept',
    ),
    _AlertItem(
      type: 'Weather',
      title: 'Heavy Rain Expected',
      message: 'Monsoon rains expected this afternoon. Secure your waste bins to prevent overflow and water contamination.',
      timeAgo: '3h ago',
      meta: 'Met Department',
    ),
    _AlertItem(
      type: 'Community',
      title: 'Community Cleanup Drive',
      message: 'Join us this Saturday at Tundikhel for a city-wide cleanup initiative. Volunteers welcome! Refreshments provided.',
      timeAgo: '5h ago',
      meta: 'Clean Kathmandu',
    ),
    _AlertItem(
      type: 'Community',
      title: 'Road Closure Notice',
      message: 'Durbar Marg closed for maintenance work. Waste trucks will use alternate route via Putalisadak. Expect slight delays.',
      timeAgo: '1d ago',
      meta: 'Traffic Police',
    ),
  ];
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
