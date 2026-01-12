// lib/features/admin/presentation/pages/admin_schedule_manage_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_waste_app/app/theme/app_colors.dart';

import '../../../schedule/data/models/schedule_hive_model.dart';
import '../../../schedule/presentation/providers/schedule_providers.dart';

class AdminScheduleManageScreen extends ConsumerWidget {
  const AdminScheduleManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, existing: null),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No schedules yet. Tap + to add.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = list[i];
              final dateStr =
                  '${s.date.day.toString().padLeft(2, '0')}-${s.date.month.toString().padLeft(2, '0')}-${s.date.year}';

              return Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    // ✅ removed explicit color (you asked to remove it)
                    child: const Icon(Icons.event_available_rounded),
                  ),
                  title: Text(
                    '${s.area} • ${s.shift}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '$dateStr • ${s.note.isEmpty ? 'No note' : s.note}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        _openForm(context, existing: s);
                        return;
                      }

                      if (v == 'toggle') {
                        await ref
                            .read(schedulesProvider.notifier)
                            .update(s.copyWith(isActive: !s.isActive));
                        return;
                      }

                      if (v == 'delete') {
                        await ref.read(schedulesProvider.notifier).delete(s.id);
                        return;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(s.isActive ? 'Deactivate' : 'Activate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {ScheduleHiveModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ScheduleFormSheet(existing: existing),
    );
  }
}

class _ScheduleFormSheet extends ConsumerStatefulWidget {
  const _ScheduleFormSheet({this.existing});
  final ScheduleHiveModel? existing;

  @override
  ConsumerState<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends ConsumerState<_ScheduleFormSheet> {
  late DateTime _date;
  late TextEditingController _area;
  late TextEditingController _note;
  String _shift = 'Morning';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now().add(const Duration(days: 1));
    _area = TextEditingController(text: e?.area ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _shift = e?.shift ?? 'Morning';
  }

  @override
  void dispose() {
    _area.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    // ✅ mounted check right after await (correct lint fix)
    if (!mounted) return;

    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.existing;
    final isEdit = e != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEdit ? 'Edit Schedule' : 'Add Schedule',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    '${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  // ✅ FIX: 'value' deprecated -> use initialValue
                  initialValue: _shift,
                  decoration: const InputDecoration(labelText: 'Shift'),
                  items: const [
                    DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                    DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                  ],
                  onChanged: (v) => setState(() => _shift = v ?? 'Morning'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _area,
            decoration: const InputDecoration(
              labelText: 'Area (e.g. Ward 10, Baneshwor)',
              prefixIcon: Icon(Icons.place_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                // ✅ capture messenger & navigator BEFORE await
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                final area = _area.text.trim();
                final note = _note.text.trim();

                if (area.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Area is required')),
                  );
                  return;
                }

                if (!isEdit) {
                  await ref
                      .read(schedulesProvider.notifier)
                      .create(
                        date: _date,
                        area: area,
                        shift: _shift,
                        note: note,
                      );
                } else {
                  await ref
                      .read(schedulesProvider.notifier)
                      .update(
                        e.copyWith(
                          dateMillis: DateTime(
                            _date.year,
                            _date.month,
                            _date.day,
                          ).millisecondsSinceEpoch,
                          area: area,
                          shift: _shift,
                          note: note,
                        ),
                      );
                }

                if (!mounted) return;

                // ✅ no context read after await
                navigator.pop();
              },
              child: Text(isEdit ? 'Save Changes' : 'Publish Schedule'),
            ),
          ),
        ],
      ),
    );
  }
}
