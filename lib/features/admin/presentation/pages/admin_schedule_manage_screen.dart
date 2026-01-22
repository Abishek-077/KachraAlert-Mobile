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
              final parsedDate = DateTime.tryParse(s.dateISO);
              final dateStr = parsedDate == null
                  ? s.dateISO
                  : '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}';

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
                    '${s.waste} • ${s.timeLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '$dateStr • ${s.status}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        _openForm(context, existing: s);
                        return;
                      }

                      if (v == 'delete') {
                        await ref.read(schedulesProvider.notifier).delete(s.id);
                        return;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
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
  late TextEditingController _timeLabel;
  String _waste = 'Biodegradable';
  String _status = 'Upcoming';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date =
        DateTime.tryParse(e?.dateISO ?? '') ??
        DateTime.now().add(const Duration(days: 1));
    _timeLabel = TextEditingController(text: e?.timeLabel ?? 'Morning');
    _waste = e?.waste ?? 'Biodegradable';
    _status = e?.status ?? 'Upcoming';
  }

  @override
  void dispose() {
    _timeLabel.dispose();
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
                child: TextField(
                  controller: _timeLabel,
                  decoration: const InputDecoration(
                    labelText: 'Time label (e.g. Morning)',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _waste,
            decoration: const InputDecoration(labelText: 'Waste type'),
            items: const [
              DropdownMenuItem(
                value: 'Biodegradable',
                child: Text('Biodegradable'),
              ),
              DropdownMenuItem(value: 'Dry Waste', child: Text('Dry Waste')),
              DropdownMenuItem(value: 'Plastic', child: Text('Plastic')),
              DropdownMenuItem(value: 'Glass', child: Text('Glass')),
              DropdownMenuItem(value: 'Metal', child: Text('Metal')),
            ],
            onChanged: (v) =>
                setState(() => _waste = v ?? 'Biodegradable'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming')),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              DropdownMenuItem(value: 'Missed', child: Text('Missed')),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'Upcoming'),
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

                final timeLabel = _timeLabel.text.trim();

                if (timeLabel.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Time label is required')),
                  );
                  return;
                }

                if (!isEdit) {
                  await ref
                      .read(schedulesProvider.notifier)
                      .create(
                        date: _date,
                        timeLabel: timeLabel,
                        waste: _waste,
                        status: _status,
                      );
                } else {
                  await ref
                      .read(schedulesProvider.notifier)
                      .update(
                        e.copyWith(
                          dateISO: DateTime(
                            _date.year,
                            _date.month,
                            _date.day,
                          ).toIso8601String(),
                          timeLabel: timeLabel,
                          waste: _waste,
                          status: _status,
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
