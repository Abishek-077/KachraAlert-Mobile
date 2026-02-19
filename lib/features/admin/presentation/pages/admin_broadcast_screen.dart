import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/k_widgets.dart';
import '../providers/admin_alert_providers.dart';
import '../widgets/admin_side_panel.dart';

class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  ConsumerState<AdminBroadcastScreen> createState() =>
      _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends ConsumerState<AdminBroadcastScreen> {
  final _title = TextEditingController();
  final _msg = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(adminAlertsProvider);

    return MotionScaffold(
      drawer: const AdminSidePanel(currentRoute: '/admin/broadcast'),
      appBar: AppBar(title: const Text('Admin Broadcast')),
      safeAreaBody: true,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KCard(
            child: Column(
              children: [
                const Text(
                  'Send alert to residents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msg,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Broadcast'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      final title = _title.text.trim();
                      final message = _msg.text.trim();

                      if (title.isEmpty || message.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Title and message are required'),
                          ),
                        );
                        return;
                      }

                      await ref
                          .read(adminAlertsProvider.notifier)
                          .broadcast(title: title, message: message);

                      if (!mounted) return;

                      _title.clear();
                      _msg.clear();

                      messenger.showSnackBar(
                        const SnackBar(content: Text('Broadcast sent')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Previous broadcasts',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          alerts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (list) {
              if (list.isEmpty) return const Text('No broadcasts yet.');
              return Column(
                children: list
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: KCard(
                          child: ListTile(
                            title: Text(
                              a.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(a.message),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
