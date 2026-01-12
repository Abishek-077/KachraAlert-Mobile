import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_alert_providers.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(adminAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign_rounded),
                  title: Text(
                    a.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(a.message),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
