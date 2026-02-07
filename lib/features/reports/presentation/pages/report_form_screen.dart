import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/ui/snackbar.dart';
import '../../../../core/utils/media_permissions.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/report_hive_model.dart';
import '../providers/report_providers.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.existing, this.isUrgent = false});
  final ReportHiveModel? existing;
  final bool isUrgent;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  static const _totalSteps = 3;
  static const _maxChars = 500;
  static const _baseLocation = 'Pulchowk, Lalitpur';

  final _categories = const [
    ('Garbage Pile', Icons.delete_outline_rounded, Color(0xFFF59E0B)),
    ('Overflowing Bin', Icons.delete_forever_outlined, Color(0xFFEF4444)),
    ('Illegal Dumping', Icons.error_outline_rounded, Color(0xFFEF4444)),
    ('Blocked Drain', Icons.water_drop_outlined, Color(0xFF3B82F6)),
    ('Burning Waste', Icons.local_fire_department_outlined, Color(0xFFF97316)),
  ];

  final _severities = const [
    ('Low', 'Minor issue', Color(0xFF12B886)),
    ('Medium', 'Needs attention', Color(0xFFF59E0B)),
    ('High', 'Urgent action', Color(0xFFEF4444)),
  ];

  late final TextEditingController _notes;
  late final TextEditingController _landmark;
  late String _category;
  late String _severity;
  int _step = 0;
  bool _saving = false;
  Uint8List? _attachmentBytes;
  String? _attachmentName;
  ImageSource? _attachmentSource;

  bool get _isEdit => widget.existing != null;
  bool get _hasPhoto =>
      _attachmentBytes != null && _attachmentBytes!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _category = widget.existing == null
        ? _categories.first.$1
        : _normalizeCategory(widget.existing?.category);
    _severity = widget.isUrgent ? 'High' : 'Medium';
    _notes = TextEditingController(text: widget.existing?.message ?? '');
    _landmark = TextEditingController(
      text: _extractLandmark(widget.existing?.location ?? ''),
    );
  }

  @override
  void dispose() {
    _notes.dispose();
    _landmark.dispose();
    super.dispose();
  }

  bool get _canGoNext {
    if (_step == 0) return _category.isNotEmpty && _hasPhoto;
    return true;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    HapticFeedback.selectionClick();
    await MediaPermissions.requestPhotoVideoAccess(context);
    if (!mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _attachmentBytes = bytes;
      _attachmentName = picked.name;
      _attachmentSource = source;
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    final userId = auth?.session?.userId;
    if (userId == null) {
      AppSnack.show(context, 'Please log in to submit a report.', error: true);
      return;
    }
    if (!_hasPhoto) {
      setState(() => _step = 0);
      AppSnack.show(context, 'Please add a photo before continuing.',
          error: true);
      return;
    }
    if (_isEdit) {
      AppSnack.show(
        context,
        'Editing existing reports is temporarily unavailable. Please submit a new report instead.',
        error: true,
      );
      return;
    }

    final notes = _notes.text.trim();
    final landmark = _landmark.text.trim();
    final location =
        landmark.isEmpty ? _baseLocation : '$_baseLocation, $landmark';
    final message =
        notes.isEmpty ? 'Issue reported from Kachra Alert app.' : notes;

    try {
      setState(() => _saving = true);
      final created = await ref.read(reportsProvider.notifier).create(
            userId: userId,
            category: _category,
            location: location,
            message: message,
            severity: _severity,
            attachmentBytes: _attachmentBytes,
            attachmentName: _attachmentName,
          );
      if (!mounted) return;
      context.go('/reports/success/${_publicId(created)}');
    } catch (e) {
      if (mounted) {
        AppSnack.show(context, 'Failed to submit report: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepTitle = switch (_step) {
      0 => 'Step 1: Photo & Category',
      1 => 'Step 2: Severity & Details',
      _ => 'Step 3: Location',
    };
    final mainLabel = _step == _totalSteps - 1
        ? (_saving ? 'Submitting...' : 'Submit Report')
        : 'Continue';
    final mainIcon = _step == _totalSteps - 1
        ? Icons.auto_awesome_rounded
        : Icons.chevron_right_rounded;
    final canPress = _canGoNext && !_saving;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      _iconBtn(Icons.close_rounded,
                          _saving ? null : () => context.pop()),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report Issue',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Clear details help teams clean faster',
                              style: TextStyle(
                                color: Color(0xFF5D697C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DelayedReveal(
                          delay: const Duration(milliseconds: 70),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.84),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFE5EBEF),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(_totalSteps, (i) {
                                    return Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            right:
                                                i == _totalSteps - 1 ? 0 : 10),
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: i <= _step
                                              ? const Color(0xFF12B886)
                                              : const Color(0xFFE3E8EB),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      stepTitle,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_step + 1}/$_totalSteps',
                                      style: const TextStyle(
                                        color: Color(0xFF596175),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DelayedReveal(
                          delay: const Duration(milliseconds: 120),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE5EBEF),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isEdit) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4E5),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFFFE0B2),
                                      ),
                                    ),
                                    child: const Text(
                                      'Editing reports is currently disabled by the server. Submit a new report below.',
                                      style: TextStyle(
                                        color: Color(0xFF8A4B07),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_step == 0) _stepOne(),
                                if (_step == 1) _stepTwo(),
                                if (_step == 2) _stepThree(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      if (_step > 0) ...[
                        SizedBox(
                          width: 88,
                          child: TextButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _step -= 1),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF141B2C),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: _mainButton(
                          label: mainLabel,
                          icon: mainIcon,
                          enabled: canPress,
                          onTap: _step == _totalSteps - 1
                              ? _submit
                              : () => setState(() => _step += 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepOne() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('Add Photo', Icons.photo_camera_outlined),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _photoCard(
            'Camera',
            Icons.photo_camera_outlined,
            _attachmentSource == ImageSource.camera && _hasPhoto,
            _saving ? null : () => _pickPhoto(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _photoCard(
            'Gallery',
            Icons.ios_share_outlined,
            _attachmentSource == ImageSource.gallery && _hasPhoto,
            _saving ? null : () => _pickPhoto(ImageSource.gallery),
          ),
        ),
      ]),
      if (_hasPhoto) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCFE9DF)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _attachmentBytes!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _attachmentName ?? 'Photo selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF294554)),
              ),
            ),
            IconButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        _attachmentBytes = null;
                        _attachmentName = null;
                        _attachmentSource = null;
                      }),
              icon: const Icon(Icons.close_rounded),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 18),
      const Text('Category',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _categories.map((c) {
          final selected = _category == c.$1;
          return Material(
            color: selected ? const Color(0xFFE8F6F1) : const Color(0xFFF0F3F6),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _saving ? null : () => setState(() => _category = c.$1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: selected
                          ? const Color(0xFF9CD9C4)
                          : const Color(0xFFF0F3F6)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(c.$2, color: c.$3, size: 21),
                  const SizedBox(width: 10),
                  Text(c.$1,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _stepTwo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('Severity Level', Icons.info_outline_rounded),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width < 380
              ? 1
              : width < 560
                  ? 2
                  : 3;
          final spacing = 12.0;
          final cardWidth = (width - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: _severities.map((s) {
              final selected = _severity == s.$1;
              return SizedBox(
                width: cardWidth,
                child: Material(
                  color: selected ? s.$3 : const Color(0xFFF1F4F7),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap:
                        _saving ? null : () => setState(() => _severity = s.$1),
                    child: Container(
                      height: 112,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? s.$3.withValues(alpha: 0.1)
                              : const Color(0xFFE4E9EE),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _severityIcon(s.$1),
                            color: selected
                                ? Colors.white
                                : const Color(0xFF2C3547),
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.$1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF141B2C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.$2,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : const Color(0xFF5F6778),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      const SizedBox(height: 22),
      const Text('Additional Notes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      TextField(
        controller: _notes,
        enabled: !_saving,
        minLines: 4,
        maxLines: 5,
        maxLength: _maxChars,
        onChanged: (_) => setState(() {}),
        decoration: _input('Describe the issue in detail (optional)'),
      ),
      const SizedBox(height: 4),
      Text('${_notes.text.length}/$_maxChars characters',
          style: const TextStyle(
              color: Color(0xFF6E7688), fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _stepThree() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('Location', Icons.location_on_outlined),
      const SizedBox(height: 12),
      Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
            color: const Color(0xFFDDE7E2),
            borderRadius: BorderRadius.circular(22)),
        child: Center(
          child: Stack(alignment: Alignment.center, children: [
            Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withValues(alpha: 0.12))),
            Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withValues(alpha: 0.18))),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF0F766E)),
              child:
                  const Icon(Icons.location_on_outlined, color: Colors.white),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6))
          ],
        ),
        child: Row(children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
                color: const Color(0xFF12B886).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.near_me_outlined,
                color: Color(0xFF12B886), size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Using Current Location',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF131A2A))),
              SizedBox(height: 4),
              Text(_baseLocation,
                  style: TextStyle(fontSize: 16, color: Color(0xFF5E6676))),
            ]),
          ),
          const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 30),
        ]),
      ),
      const SizedBox(height: 26),
      const Text('Nearby Landmark',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      TextField(
          controller: _landmark,
          enabled: !_saving,
          decoration: _input('e.g., Near Pulchowk Campus gate')),
      const SizedBox(height: 10),
      const Text('Adding a landmark helps workers find the location faster',
          style:
              TextStyle(color: Color(0xFF6E7688), fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _iconBtn(IconData icon, VoidCallback? onTap) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Icon(icon, color: const Color(0xFF1A2233), size: 28)),
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF12B886), size: 22),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    ]);
  }

  Widget _photoCard(
      String label, IconData icon, bool selected, VoidCallback? onTap) {
    return Material(
      color: selected ? const Color(0xFFE7F6F0) : const Color(0xFFF3F5F7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 188,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? const Color(0xFF89DCC2)
                    : const Color(0xFFDCE1E8),
                width: 1.3),
          ),
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFD8F0E7)
                      : const Color(0xFFE8ECF1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon,
                    color: selected
                        ? const Color(0xFF10B981)
                        : const Color(0xFF667185),
                    size: 34),
              ),
              const SizedBox(height: 14),
              Text(label,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5C6678))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _mainButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF17A87C), Color(0xFF155A66)])
              : const LinearGradient(
                  colors: [Color(0xFF87BDB8), Color(0xFF7DABB0)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x3310A57A),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onTap : null,
            child: Center(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_saving) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 21),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF0F4F7),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF17A77B), width: 1.3),
        ),
      );

  IconData _severityIcon(String level) {
    switch (level) {
      case 'Low':
        return Icons.radio_button_checked_rounded;
      case 'High':
        return Icons.priority_high_rounded;
      case 'Medium':
      default:
        return Icons.schedule_rounded;
    }
  }
}

String _normalizeCategory(String? raw) {
  final value = (raw ?? '').trim();
  if (value == 'Overflow' || value == 'Overflowing Bin') {
    return 'Overflowing Bin';
  }
  if (value == 'Illegal Dumping') {
    return 'Illegal Dumping';
  }
  if (value == 'Blocked Drain') {
    return 'Blocked Drain';
  }
  if (value == 'Burning Waste') {
    return 'Burning Waste';
  }
  return 'Garbage Pile';
}

String _extractLandmark(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value == _ReportFormScreenState._baseLocation) return '';
  const prefix = '${_ReportFormScreenState._baseLocation}, ';
  if (value.startsWith(prefix)) return value.substring(prefix.length).trim();
  return value;
}

String _publicId(ReportHiveModel report) {
  final year = DateTime.fromMillisecondsSinceEpoch(report.createdAt).year;
  final numeric = report.id.replaceAll(RegExp(r'[^0-9]'), '');
  final seed = numeric.isNotEmpty ? numeric : report.createdAt.toString();
  final suffix =
      seed.length >= 4 ? seed.substring(seed.length - 4) : seed.padLeft(4, '0');
  return 'RPT-$year-$suffix';
}
