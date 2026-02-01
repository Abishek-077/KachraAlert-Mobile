import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_spacing.dart';
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
  bool _formValid = false;
  Uint8List? _attachmentBytes;
  String? _attachmentName;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _location = TextEditingController(text: e?.location ?? '');
    _message = TextEditingController(text: e?.message ?? '');
    _category = e?.category ?? 'Missed Pickup';
    _location.addListener(_updateValidity);
    _message.addListener(_updateValidity);
    _updateValidity();
  }

  @override
  void dispose() {
    _location.removeListener(_updateValidity);
    _message.removeListener(_updateValidity);
    _location.dispose();
    _message.dispose();
    super.dispose();
  }

  void _updateValidity() {
    final valid =
        _location.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;
    if (valid != _formValid) {
      setState(() => _formValid = valid);
    }
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

    return AppScaffold(
      padding: AppSpacing.screenInsets.copyWith(bottom: 140),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              Text(
                isEdit ? 'Edit Report' : 'New Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          const SectionHeader(label: 'Category'),
          const SizedBox(height: AppSpacing.labelSpacing),
          Wrap(
            spacing: AppSpacing.labelSpacing,
            runSpacing: AppSpacing.labelSpacing,
            children: [
              for (final c in categories)
                ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          SectionHeader(
            label: 'Location',
            action: Text(
              'Auto-filled',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.labelSpacing),
          TextField(
            controller: _location,
            decoration: InputDecoration(
              hintText: 'e.g. Ward 10, Baneshwor',
              prefixIcon: const Icon(Icons.place_outlined),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          const SectionHeader(label: 'Details'),
          const SizedBox(height: AppSpacing.labelSpacing),
          TextField(
            controller: _message,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe the issue (what, where, how urgent).',
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          Row(
            children: [
              Icon(Icons.photo_camera_outlined,
                  size: 20, color: cs.onSurface.withOpacity(0.6)),
              const SizedBox(width: AppSpacing.labelSpacing),
              Expanded(
                child: Text(
                  'Add a photo (optional) to help verify the report.',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                ),
              ),
              TextButton(
                onPressed: _selectAttachment,
                child: const Text('Upload'),
              ),
            ],
          ),
          if (_attachmentBytes != null) ...[
            const SizedBox(height: AppSpacing.labelSpacing),
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
            const SizedBox(height: AppSpacing.labelSpacing),
            Row(
              children: [
                const Icon(Icons.attachment_rounded, size: 18),
                const SizedBox(width: AppSpacing.labelSpacing),
                Expanded(
                  child: Text(
                    _attachmentName ?? 'Attached photo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: AppSpacing.bottomBarInsets,
        child: PrimaryButton(
          label: isEdit ? 'Save Changes' : 'Submit Report',
          icon: isEdit ? Icons.check_rounded : Icons.arrow_forward_rounded,
          isLoading: _saving,
          onPressed: _saving || !_formValid ? null : _save,
        ),
      ),
    );
  }
}
