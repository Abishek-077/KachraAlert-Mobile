import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/report_providers.dart';
import '../../data/models/report_hive_model.dart';
import '../../../../core/ui/snackbar.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.existing});
  final ReportHiveModel? existing;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  late final TextEditingController _location;
  late final TextEditingController _message;
  String _category = 'Missed Pickup';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _location = TextEditingController(text: e?.location ?? '');
    _message = TextEditingController(text: e?.message ?? '');
    _category = e?.category ?? 'Missed Pickup';
  }

  @override
  void dispose() {
    _location.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    final userId = auth?.session?.userId;

    if (userId == null) {
      if (mounted) {
        AppSnack.show(
          context,
          'You must be logged in to create a report',
          error: true,
        );
      }
      return;
    }

    final loc = _location.text.trim();
    final msg = _message.text.trim();
    if (loc.isEmpty || msg.isEmpty) {
      if (mounted) {
        AppSnack.show(
          context,
          'Location and message are required',
          error: true,
        );
      }
      return;
    }

    try {
      setState(() => _saving = true);
      final e = widget.existing;
      if (e == null) {
        await ref
            .read(reportsProvider.notifier)
            .create(
              userId: userId,
              category: _category,
              location: loc,
              message: msg,
            );
      } else {
        await ref
            .read(reportsProvider.notifier)
            .update(
              e.copyWith(category: _category, location: loc, message: msg),
            );
      }

      if (!mounted) return;

      AppSnack.show(
        context,
        e == null
            ? 'Report created successfully'
            : 'Report updated successfully',
        error: false,
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        AppSnack.show(context, 'Failed to save report: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Report' : 'New Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(
                value: 'Missed Pickup',
                child: Text('Missed Pickup'),
              ),
              DropdownMenuItem(
                value: 'Overflowing Bin',
                child: Text('Overflowing Bin'),
              ),
              DropdownMenuItem(value: 'Bad Smell', child: Text('Bad Smell')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'Missed Pickup'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location (e.g. Ward 10, Baneshwor)',
              prefixIcon: Icon(Icons.place_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Describe the issue',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_saving) ...[
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(isEdit ? 'Save Changes' : 'Submit Report'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
