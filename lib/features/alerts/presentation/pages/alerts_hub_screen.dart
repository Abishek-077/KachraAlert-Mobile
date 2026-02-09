import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../admin/presentation/providers/admin_alert_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final apiBase = ref.watch(apiBaseUrlProvider);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final token = auth?.session?.accessToken;
    final adminPhotoHeaders =
        token?.isNotEmpty == true ? {'Authorization': 'Bearer $token'} : null;
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
                  Text(
                    l10n.choice('Alerts',
                        '\u0938\u0942\u091a\u0928\u093e\u0939\u0930\u0942'),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900),
                  ),
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
                    label: _localizedFilter(_filters[i], l10n),
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
                error: (e, _) => Center(
                  child: Text(
                    l10n.choice(
                      'Failed to load alerts: $e',
                      '\u0938\u0942\u091a\u0928\u093e \u0932\u094b\u0921 \u0917\u0930\u094d\u0928 \u0938\u0915\u093f\u090f\u0928: $e',
                    ),
                  ),
                ),
                data: (alerts) {
                  final dynamicAlerts = alerts.map((a) {
                    final type = _inferType(a.title, a.message);
                    final adminName = a.adminName?.trim().isNotEmpty == true
                        ? a.adminName!.trim()
                        : l10n.choice(
                            'Municipal Office',
                            '\u0928\u0917\u0930\u092a\u093e\u0932\u093f\u0915\u093e \u0915\u093e\u0930\u094d\u092f\u093e\u0932\u092f',
                          );
                    return _AlertItem(
                      type: type,
                      title: a.title,
                      message: a.message,
                      meta: adminName,
                      timeAgo: _timeAgo(context, a.createdAt),
                      adminName: adminName,
                      adminPhotoUrl: resolveMediaUrl(apiBase, a.adminPhotoUrl),
                      adminPhotoHeaders: adminPhotoHeaders,
                    );
                  }).toList();

                  final filtered = dynamicAlerts.where((a) {
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
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 46,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.choice(
                                'No alerts',
                                '\u0915\u0941\u0928\u0948 \u0938\u0942\u091a\u0928\u093e \u091b\u0948\u0928',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.choice(
                                'You are all caught up.',
                                '\u0924\u092a\u093e\u0908\u0901 \u0938\u092c\u0948 \u0905\u092a\u0921\u0947\u091f\u092e\u093e \u0939\u0941\u0928\u0941\u0939\u0941\u0928\u094d\u091b\u0964',
                              ),
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.62),
                              ),
                            ),
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
  final String adminName;
  final String? adminPhotoUrl;
  final Map<String, String>? adminPhotoHeaders;
  late final Color accent;
  late final IconData icon;
  late final LinearGradient lineGradient;

  _AlertItem({
    required this.type,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.meta,
    required this.adminName,
    required this.adminPhotoUrl,
    required this.adminPhotoHeaders,
  }) {
    final ui = _typeUi(type);
    accent = ui.accent;
    icon = ui.icon;
    lineGradient = _rgbLineGradient('$title|$message|$timeAgo');
  }
}

({Color accent, IconData icon}) _typeUi(String type) {
  switch (type) {
    case 'Urgent':
      return (
        accent: const Color(0xFFEF4444),
        icon: Icons.warning_amber_rounded
      );
    case 'Pickup':
      return (
        accent: const Color(0xFF1ECA92),
        icon: Icons.local_shipping_outlined
      );
    case 'Weather':
      return (accent: const Color(0xFF1B8EF2), icon: Icons.water_drop_outlined);
    case 'Community':
    default:
      return (
        accent: const Color(0xFF0E6E66),
        icon: Icons.people_outline_rounded
      );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.item});
  final _AlertItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? cs.outlineVariant.withValues(alpha: 0.45)
              : const Color(0xFFE5EBEF),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x1A0B1E16),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0xE6FFFFFF),
                  blurRadius: 10,
                  offset: Offset(-3, -3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 116,
            decoration: BoxDecoration(
              gradient: item.lineGradient,
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
                  _AdminAlertAvatar(item: item),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: cs.onSurface.withOpacity(0.45)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.62),
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              item.timeAgo,
                              style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.50),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                            Text('|',
                                style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.35))),
                            const SizedBox(width: 10),
                            Text(
                              item.meta,
                              style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.50),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.open_in_new_rounded,
                                size: 14,
                                color: cs.onSurface.withOpacity(0.45)),
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

class _AdminAlertAvatar extends StatelessWidget {
  const _AdminAlertAvatar({required this.item});
  final _AlertItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: item.accent.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      child: item.adminPhotoUrl == null
          ? Icon(item.icon, color: item.accent)
          : Image.network(
              item.adminPhotoUrl!,
              fit: BoxFit.cover,
              headers: item.adminPhotoHeaders,
              errorBuilder: (_, __, ___) => Icon(item.icon, color: item.accent),
            ),
    );
  }
}

LinearGradient _rgbLineGradient(String seed) {
  final hash = seed.hashCode.abs();
  final c1 = _rgbColorFromSeed(hash);
  final c2 = _rgbColorFromSeed(hash * 31 + 17);
  final c3 = _rgbColorFromSeed(hash * 131 + 73);
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [c1, c2, c3],
  );
}

Color _rgbColorFromSeed(int seed) {
  final hue = (seed % 360).toDouble();
  final saturation = 0.82 + ((seed % 11) / 100);
  const value = 0.94;
  return HSVColor.fromAHSV(1, hue, saturation.clamp(0.82, 0.93), value)
      .toColor();
}

String _inferType(String title, String message) {
  final t = '${title.toLowerCase()} ${message.toLowerCase()}';
  if (t.contains('urgent') ||
      t.contains('illegal') ||
      t.contains('hazard') ||
      t.contains('danger')) {
    return 'Urgent';
  }
  if (t.contains('pickup') ||
      t.contains('collection') ||
      t.contains('schedule') ||
      t.contains('tomorrow')) {
    return 'Pickup';
  }
  if (t.contains('rain') ||
      t.contains('storm') ||
      t.contains('weather') ||
      t.contains('monsoon')) {
    return 'Weather';
  }
  return 'Community';
}

String _timeAgo(BuildContext context, int millis) {
  final l10n = AppLocalizations.of(context);
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) {
    return l10n.choice(
      '${diff.inMinutes} min ago',
      '${diff.inMinutes} \u092e\u093f\u0928\u0947\u091f \u0905\u0918\u093f',
    );
  }
  if (diff.inHours < 24) {
    return l10n.choice(
      '${diff.inHours}h ago',
      '${diff.inHours} \u0918\u0923\u094d\u091f\u093e \u0905\u0918\u093f',
    );
  }
  return l10n.choice(
    '${diff.inDays}d ago',
    '${diff.inDays} \u0926\u093f\u0928 \u0905\u0918\u093f',
  );
}

String _localizedFilter(String filter, AppLocalizations l10n) {
  switch (filter) {
    case 'Urgent':
      return l10n.choice('Urgent', '\u0924\u0924\u094d\u0915\u093e\u0932');
    case 'Pickup':
      return l10n.choice('Pickup', '\u0938\u0902\u0915\u0932\u0928');
    case 'Weather':
      return l10n.choice('Weather', '\u092e\u094c\u0938\u092e');
    case 'Community':
      return l10n.choice('Community', '\u0938\u092e\u0941\u0926\u093e\u092f');
    case 'All':
    default:
      return l10n.reportFiltersAll;
  }
}
