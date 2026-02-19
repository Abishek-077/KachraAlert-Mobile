import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/k_widgets.dart';
import '../providers/admin_alert_providers.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(adminAlertsProvider);

    return MotionScaffold(
      appBar: AppBar(title: const Text('Announcements')),
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
                    Icon(Icons.campaign_outlined, size: 42),
                    SizedBox(height: 10),
                    Text('No announcements yet.'),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = list[i];
              return DelayedReveal(
                delay: Duration(milliseconds: 50 + (i * 40)),
                child: KCard(
                  child: ListTile(
                    leading: const Icon(Icons.campaign_rounded),
                    title: Text(
                      a.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(a.message),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
