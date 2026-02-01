import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/k_widgets.dart';
import '../../../../core/utils/media_permissions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/report_providers.dart';
import '../../data/models/report_hive_model.dart';
import '../../../../core/ui/snackbar.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

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
  Uint8List? _attachmentBytes;
  String? _attachmentName;

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
              attachmentBytes: _attachmentBytes,
              attachmentName: _attachmentName,
            );
      } else {
        await ref
            .read(reportsProvider.notifier)
            .updateReport(
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

  Future<void> _selectAttachment() async {
    await MediaPermissions.requestPhotoVideoAccess(context);
    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _attachmentBytes = bytes;
      _attachmentName = picked.name;
    });
  }

  void _removeAttachment() {
    setState(() {
      _attachmentBytes = null;
      _attachmentName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;

    final categories = const <String>[
      'Missed Pickup',
      'Overflowing Bin',
      'Bad Smell',
      'Other',
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
          children: [
            Row(
              children: [
                Text(
                  isEdit ? 'Edit Report' : 'New Report',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Category chips
            Text(
              'CATEGORY',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in categories) ...[
                    KChip(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                    const SizedBox(width: 10),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location
            Text(
              'LOCATION',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            KCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  KIconCircle(
                    icon: Icons.place_rounded,
                    background: cs.primary.withOpacity(0.10),
                    foreground: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _location,
                      decoration: InputDecoration(
                        hintText: 'e.g. Ward 10, Baneshwor',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.45)),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'DETAILS',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            KCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KIconCircle(
                    icon: Icons.edit_note_rounded,
                    background: cs.primary.withOpacity(0.10),
                    foreground: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _message,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe the issue (what, where, how urgent)',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.45)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Photo attachment (optional)
            KCard(
              padding: const EdgeInsets.all(14),
              onTap: _selectAttachment,
              child: _attachmentBytes == null
                  ? Row(
                      children: [
                        KIconCircle(
                          icon: Icons.photo_camera_outlined,
                          background: cs.onSurface.withOpacity(0.06),
                          foreground: cs.onSurface.withOpacity(0.65),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add photo (optional)',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Attach an image to help the team verify the issue.',
                                style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.memory(
                              _attachmentBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.attachment_rounded, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _attachmentName ?? 'Attached photo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove attachment',
                              onPressed: _removeAttachment,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
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
                Text(
                  isEdit ? 'Save Changes' : 'Submit Report',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(width: 10),
                Icon(isEdit ? Icons.check_rounded : Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
