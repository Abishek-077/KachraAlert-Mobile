import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/snackbar.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../data/models/admin_alert_hive_model.dart';
import '../providers/admin_alert_providers.dart';

class AdminAlertFormScreen extends ConsumerStatefulWidget {
  const AdminAlertFormScreen({
    super.key,
    this.existing,
  });

  final AdminAlertHiveModel? existing;

  @override
  ConsumerState<AdminAlertFormScreen> createState() =>
      _AdminAlertFormScreenState();
}

class _AdminAlertFormScreenState extends ConsumerState<AdminAlertFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _messageController = TextEditingController(text: existing?.message ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      if (mounted) {
        AppSnack.show(context, 'Title and message are required', error: true);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existing = widget.existing;
      if (existing == null) {
        await ref.read(adminAlertsProvider.notifier).create(
              title: title,
              message: message,
            );
      } else {
        await ref.read(adminAlertsProvider.notifier).updateAlert(
              id: existing.id,
              title: title,
              message: message,
            );
      }

      if (!mounted) return;

      AppSnack.show(
        context,
        existing == null
            ? 'Alert created successfully'
            : 'Alert updated successfully',
        error: false,
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        AppSnack.show(context, 'Failed to save alert: $e', error: true);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return MotionScaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Alert' : 'Create Alert'),
      ),
      safeAreaBody: true,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Update Alert' : 'Create New Alert',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This alert will be broadcast to all residents',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            enabled: !_isLoading,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g., Important Update',
              prefixIcon: Icon(Icons.title_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            enabled: !_isLoading,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Enter the alert message...',
              prefixIcon: Icon(Icons.message_rounded),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Update Alert' : 'Create Alert'),
          ),
        ],
      ),
    );
  }
}
