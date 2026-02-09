import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_waste_app/core/localization/app_localizations.dart';

import '../../../../core/widgets/k_widgets.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../schedule/presentation/providers/schedule_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
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
                  Text(
                    l10n.choice(
                        'Schedule', '\u0924\u093e\u0932\u093f\u0915\u093e'),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  if (isAdmin)
                    IconButton(
                      tooltip: l10n.choice('Manage Schedule',
                          '\u0924\u093e\u0932\u093f\u0915\u093e \u0935\u094d\u092f\u0935\u0938\u094d\u0925\u093e\u092a\u0928'),
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
                        l10n.choice(
                          'Failed to load schedule',
                          '\u0924\u093e\u0932\u093f\u0915\u093e \u0932\u094b\u0921 \u0917\u0930\u094d\u0928 \u0938\u0915\u093f\u090f\u0928',
                        ),
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
                          label: Text(l10n.retry),
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
                          Text(
                            l10n.choice(
                              'No schedule published yet',
                              '\u0905\u0939\u093f\u0932\u0947\u0938\u092e\u094d\u092e \u0924\u093e\u0932\u093f\u0915\u093e \u092a\u094d\u0930\u0915\u093e\u0936\u093f\u0924 \u0917\u0930\u093f\u090f\u0915\u094b \u091b\u0948\u0928',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.choice(
                              'Admin will publish collection dates soon.',
                              '\u090f\u0921\u092e\u093f\u0928\u0932\u0947 \u091b\u093f\u091f\u094d\u091f\u0948 \u0938\u0902\u0915\u0932\u0928 \u092e\u093f\u0924\u093f\u0939\u0930\u0942 \u092a\u094d\u0930\u0915\u093e\u0936\u093f\u0924 \u0917\u0930\u094d\u0928\u0947\u091b\u0928\u094d\u0964',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: cs.onSurface.withOpacity(0.65)),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () =>
                                    context.push('/admin/schedule'),
                                child: Text(
                                  l10n.choice(
                                    'Create Schedule',
                                    '\u0924\u093e\u0932\u093f\u0915\u093e \u092c\u0928\u093e\u0909\u0928\u0941\u0939\u094b\u0938\u094d',
                                  ),
                                ),
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
                          title: '${s.waste} | ${s.timeLabel}',
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
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final parsedDate = DateTime.tryParse(dateISO);
    final dateStr = parsedDate == null
        ? dateISO
        : '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}';
    final isUpcoming = status.toLowerCase() == 'upcoming';
    final localizedStatus = isUpcoming
        ? l10n.choice('upcoming', '\u0906\u0909\u0901\u0926\u0948\u091b')
        : l10n.choice('completed', '\u0938\u092e\u093e\u092a\u094d\u0924');

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
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  '$dateStr | $localizedStatus',
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
            isUpcoming ? Icons.access_time_rounded : Icons.check_circle_rounded,
            color: isUpcoming ? cs.secondary : const Color(0xFF1ECA92),
          ),
        ],
      ),
    );
  }
}
