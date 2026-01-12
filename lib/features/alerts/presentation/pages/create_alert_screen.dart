import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/alert_providers.dart';

class CreateAlertScreen extends ConsumerStatefulWidget {
  const CreateAlertScreen({super.key});

  @override
  ConsumerState<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends ConsumerState<CreateAlertScreen> {
  final _note = TextEditingController();
  String _type = 'Mixed';
  double _lat = 27.7172; // default Kathmandu
  double _lng = 85.3240;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Alert')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
                      DropdownMenuItem(
                        value: 'Plastic',
                        child: Text('Plastic'),
                      ),
                      DropdownMenuItem(
                        value: 'Organic',
                        child: Text('Organic'),
                      ),
                      DropdownMenuItem(value: 'Glass', child: Text('Glass')),
                      DropdownMenuItem(
                        value: 'E-Waste',
                        child: Text('E-Waste'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'Mixed'),
                    decoration: const InputDecoration(labelText: 'Waste Type'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _note,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Describe the waste / landmark / urgency...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Lat'),
                          controller: TextEditingController(
                            text: _lat.toStringAsFixed(6),
                          ),
                          onChanged: (v) => _lat = double.tryParse(v) ?? _lat,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Lng'),
                          controller: TextEditingController(
                            text: _lng.toStringAsFixed(6),
                          ),
                          onChanged: (v) => _lng = double.tryParse(v) ?? _lng,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.notification_add),
                      label: const Text('Create Alert'),
                      onPressed: () async {
                        await ref
                            .read(alertsProvider.notifier)
                            .createAlert(
                              wasteType: _type,
                              note: _note.text.trim(),
                              lat: _lat,
                              lng: _lng,
                            );
                        if (mounted) Navigator.pop(context);
                      },
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
