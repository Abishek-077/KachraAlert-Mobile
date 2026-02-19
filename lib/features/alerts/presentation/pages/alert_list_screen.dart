import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/k_widgets.dart';
import '../providers/alert_providers.dart';

class AlertListScreen extends ConsumerWidget {
  const AlertListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);

    return MotionScaffold(
      appBar: AppBar(title: const Text('Waste Alerts')),
      safeAreaBody: true,
      body: alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: KCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.notifications_off_outlined, size: 44),
                    SizedBox(height: 10),
                    Text(
                      'No alerts yet. Create one to get started.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              final a = list[i];
              return DelayedReveal(
                delay: Duration(milliseconds: 60 + (i * 45)),
                child: KCard(
                  child: ListTile(
                    title: Text(
                      a.wasteType,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(a.note),
                    trailing: Chip(label: Text(a.status)),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: list.length,
          );
        },
      ),
    );
  }
}
