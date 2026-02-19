import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/feedback/feedback_service.dart';
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
  AppLocalizations get _l10n => AppLocalizations.of(context);
  ColorScheme get _cs => Theme.of(context).colorScheme;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

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
    await ref.read(feedbackServiceProvider).selection();
    if (!mounted) return;
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
    final l10n = _l10n;
    if (_saving) return;
    final auth = ref.read(authStateProvider).valueOrNull;
    final userId = auth?.session?.userId;
    if (userId == null) {
      AppSnack.show(
        context,
        l10n.choice(
          'Please log in to submit a report.',
          'रिपोर्ट पठाउन कृपया लगइन गर्नुहोस्।',
        ),
        error: true,
      );
      return;
    }
    if (!_hasPhoto) {
      setState(() => _step = 0);
      AppSnack.show(
        context,
        l10n.choice(
          'Please add a photo before continuing.',
          'अगाडि बढ्न अघि फोटो थप्नुहोस्।',
        ),
        error: true,
      );
      return;
    }
    if (_isEdit) {
      AppSnack.show(
        context,
        l10n.choice(
          'Editing existing reports is temporarily unavailable. Please submit a new report instead.',
          'हाल रिपोर्ट सम्पादन बन्द छ। कृपया नयाँ रिपोर्ट पठाउनुहोस्।',
        ),
        error: true,
      );
      return;
    }

    final notes = _notes.text.trim();
    final landmark = _landmark.text.trim();
    final location =
        landmark.isEmpty ? _baseLocation : '$_baseLocation, $landmark';
    final message = notes.isEmpty
        ? l10n.choice(
            'Issue reported from Kachra Alert app.',
            'कचरा अलर्ट एपबाट समस्या रिपोर्ट गरिएको छ।',
          )
        : notes;

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
        AppSnack.show(
          context,
          l10n.choice(
            'Failed to submit report: $e',
            'रिपोर्ट पठाउन सकिएन: $e',
          ),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final cs = _cs;
    final isDark = _isDark;
    final stepTitle = switch (_step) {
      0 => l10n.choice('Step 1: Photo & Category', 'चरण १: फोटो र श्रेणी'),
      1 =>
        l10n.choice('Step 2: Severity & Details', 'चरण २: प्राथमिकता र विवरण'),
      _ => l10n.choice('Step 3: Location', 'चरण ३: स्थान'),
    };
    final mainLabel = _step == _totalSteps - 1
        ? (_saving
            ? l10n.choice('Submitting...', 'पठाउँदै...')
            : l10n.submitReport)
        : l10n.choice('Continue', 'जारी राख्नुहोस्');
    final mainIcon = _step == _totalSteps - 1
        ? Icons.auto_awesome_rounded
        : Icons.chevron_right_rounded;
    final canPress = _canGoNext && !_saving;

    return MotionScaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFF6F8F7),
      useAmbientBackground: false,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.choice(
                                  'Report Issue', 'समस्या रिपोर्ट गर्नुहोस्'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.choice(
                                'Clear details help teams clean faster',
                                'स्पष्ट विवरणले टोलीलाई छिटो सफा गर्न मद्दत गर्छ',
                              ),
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.72),
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
                              color: isDark
                                  ? cs.surfaceContainerHigh.withValues(
                                      alpha: 0.86,
                                    )
                                  : Colors.white.withValues(alpha: 0.84),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: isDark ? 0.45 : 0.8,
                                ),
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
                                              ? cs.primary
                                              : cs.outlineVariant.withValues(
                                                  alpha: 0.45,
                                                ),
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
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_step + 1}/$_totalSteps',
                                      style: TextStyle(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.72,
                                        ),
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
                              color: isDark
                                  ? cs.surfaceContainerHigh.withValues(
                                      alpha: 0.92,
                                    )
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: isDark ? 0.5 : 0.8,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.36)
                                      : const Color(0x14000000),
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
                                      color: isDark
                                          ? cs.errorContainer.withValues(
                                              alpha: 0.36,
                                            )
                                          : const Color(0xFFFFF4E5),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? cs.error.withValues(alpha: 0.5)
                                            : const Color(0xFFFFE0B2),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.choice(
                                        'Editing reports is currently disabled by the server. Submit a new report below.',
                                        'रिपोर्ट सम्पादन अहिले सर्भरबाट बन्द छ। तल नयाँ रिपोर्ट पठाउनुहोस्।',
                                      ),
                                      style: TextStyle(
                                        color: isDark
                                            ? cs.onErrorContainer
                                            : const Color(0xFF8A4B07),
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
                            child: Text(
                              l10n.choice('Back', 'फिर्ता'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
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
    final l10n = _l10n;
    final cs = _cs;
    final isDark = _isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(
                l10n.choice('Add Photo', 'Add Photo'),
                Icons.photo_camera_outlined,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.choice(
                  'Capture a clear photo so cleanup teams can identify the issue quickly.',
                  'Capture a clear photo so cleanup teams can identify the issue quickly.',
                ),
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _photoCard(
                      l10n.choice('Camera', 'Camera'),
                      Icons.photo_camera_outlined,
                      _attachmentSource == ImageSource.camera && _hasPhoto,
                      _saving ? null : () => _pickPhoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _photoCard(
                      l10n.choice('Gallery', 'Gallery'),
                      Icons.ios_share_outlined,
                      _attachmentSource == ImageSource.gallery && _hasPhoto,
                      _saving ? null : () => _pickPhoto(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (_hasPhoto) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: isDark ? 0.24 : 0.12),
                        cs.secondary.withValues(alpha: isDark ? 0.14 : 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: isDark ? 0.42 : 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _attachmentBytes!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.check_circle_rounded, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _attachmentName ??
                              l10n.choice('Photo selected', 'Photo selected'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
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
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _panelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.category,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 190),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: isDark ? 0.28 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _categoryLabel(_category, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 420 ? 2 : 1;
                  const spacing = 10.0;
                  final width =
                      (constraints.maxWidth - ((columns - 1) * spacing)) /
                          columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final c in _categories)
                        SizedBox(
                          width: width,
                          child: _categoryTile(
                            label: _categoryLabel(c.$1, l10n),
                            icon: c.$2,
                            accent: c.$3,
                            selected: _category == c.$1,
                            onTap: _saving
                                ? null
                                : () => setState(() => _category = c.$1),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepTwo() {
    final l10n = _l10n;
    final cs = _cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(
                l10n.choice('Severity Level', 'Severity Level'),
                Icons.info_outline_rounded,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.choice(
                  'Set urgency so crews can prioritize correctly.',
                  'Set urgency so crews can prioritize correctly.',
                ),
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width > 700
                      ? 3
                      : width > 440
                          ? 2
                          : 1;
                  const spacing = 10.0;
                  final cardWidth =
                      (width - ((columns - 1) * spacing)) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final s in _severities)
                        SizedBox(
                          width: cardWidth,
                          child: _severityTile(
                            level: s.$1,
                            accent: s.$3,
                            selected: _severity == s.$1,
                            onTap: _saving
                                ? null
                                : () => setState(() => _severity = s.$1),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _panelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.choice('Additional Notes', 'Additional Notes'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_notes.text.length}/$_maxChars',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                enabled: !_saving,
                minLines: 4,
                maxLines: 5,
                maxLength: _maxChars,
                onChanged: (_) => setState(() {}),
                decoration: _input(
                  l10n.choice(
                    'Describe the issue in detail (optional)',
                    'Describe the issue in detail (optional)',
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.choice(
                  '${_notes.text.length}/$_maxChars characters',
                  '${_notes.text.length}/$_maxChars characters',
                ),
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panelCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(14, 14, 14, 14),
  }) {
    final cs = _cs;
    final isDark = _isDark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? cs.surfaceContainerHigh : Colors.white)
                .withValues(alpha: 0.94),
            (isDark ? cs.surfaceContainerHighest : const Color(0xFFF5F9FC))
                .withValues(alpha: isDark ? 0.86 : 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.62),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.28)
                : const Color(0x140B1E16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.55),
              blurRadius: 10,
              offset: const Offset(-3, -3),
            ),
        ],
      ),
      child: child,
    );
  }

  Widget _categoryTile({
    required String label,
    required IconData icon,
    required Color accent,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final cs = _cs;
    final isDark = _isDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      accent.withValues(alpha: isDark ? 0.34 : 0.18),
                      cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                    ],
                  )
                : null,
            color: selected
                ? null
                : (isDark
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.68)
                    : const Color(0xFFF2F5F7)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: isDark ? 0.78 : 0.45)
                  : cs.outlineVariant.withValues(alpha: isDark ? 0.36 : 0.6),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.2 : 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: selected ? 1 : 0,
                child:
                    Icon(Icons.check_circle_rounded, color: accent, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _severityTile({
    required String level,
    required Color accent,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final l10n = _l10n;
    final cs = _cs;
    final isDark = _isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent,
                      accent.withValues(alpha: isDark ? 0.82 : 0.9),
                    ],
                  )
                : null,
            color: selected
                ? null
                : (isDark
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.74)
                    : const Color(0xFFF2F5F7)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: isDark ? 0.95 : 0.55)
                  : cs.outlineVariant.withValues(alpha: isDark ? 0.42 : 0.6),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.28 : 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : accent.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _severityIcon(level),
                  color: selected ? Colors.white : accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _severityLabel(level, l10n),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _severityDescription(level, l10n),
                      style: TextStyle(
                        fontSize: 14,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.92)
                            : cs.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? Colors.white
                    : cs.onSurface.withValues(alpha: isDark ? 0.4 : 0.28),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepThree() {
    final l10n = _l10n;
    final cs = _cs;
    final isDark = _isDark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section(l10n.location, Icons.location_on_outlined),
      const SizedBox(height: 12),
      Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHighest.withValues(alpha: 0.8)
                : const Color(0xFFDDE7E2),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.2),
            ),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary,
              ),
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
          color: isDark
              ? cs.surfaceContainerHigh.withValues(alpha: 0.9)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : const Color(0x14000000),
              blurRadius: 20,
              offset: const Offset(0, 6),
            )
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.choice(
                      'Using Current Location', 'हालको स्थान प्रयोग गर्दै'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _baseLocation,
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface.withValues(alpha: 0.74),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 30),
        ]),
      ),
      const SizedBox(height: 26),
      Text(
        l10n.choice('Nearby Landmark', 'नजिकको चिन्ह'),
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
          controller: _landmark,
          enabled: !_saving,
          decoration: _input(
            l10n.choice(
              'e.g., Near Pulchowk Campus gate',
              'जस्तै: पुल्चोक क्याम्पस गेट नजिक',
            ),
          )),
      const SizedBox(height: 10),
      Text(
        l10n.choice(
          'Adding a landmark helps workers find the location faster',
          'चिन्ह थप्दा कामदारले स्थान छिटो भेट्टाउँछन्',
        ),
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.62),
          fontWeight: FontWeight.w500,
        ),
      ),
    ]);
  }

  Widget _iconBtn(IconData icon, VoidCallback? onTap) {
    final cs = _cs;
    final isDark = _isDark;
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.88),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.2),
          ),
        ),
        child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Icon(icon, color: cs.onSurface, size: 28)),
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    final cs = _cs;
    return Row(children: [
      Icon(icon, color: cs.primary, size: 22),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          )),
    ]);
  }

  Widget _photoCard(
      String label, IconData icon, bool selected, VoidCallback? onTap) {
    final cs = _cs;
    final isDark = _isDark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 188,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withValues(alpha: isDark ? 0.3 : 0.15),
                      cs.secondary.withValues(alpha: isDark ? 0.18 : 0.1),
                    ],
                  )
                : null,
            color: selected
                ? null
                : (isDark
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.72)
                    : const Color(0xFFF3F5F7)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: isDark ? 0.58 : 0.35)
                  : cs.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
              width: 1.3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Selected',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary.withValues(alpha: isDark ? 0.25 : 0.15)
                      : (isDark
                          ? cs.surfaceContainerHigh.withValues(alpha: 0.9)
                          : const Color(0xFFE8ECF1)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.7),
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selected ? 'Ready' : 'Tap to select',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.58),
                ),
              ),
              const Spacer(),
            ],
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
    final cs = _cs;
    final isDark = _isDark;
    final disabledText = cs.onSurface.withValues(alpha: isDark ? 0.56 : 0.72);
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [cs.primary, cs.secondary.withValues(alpha: 0.8)],
                )
              : LinearGradient(
                  colors: [
                    cs.surfaceContainerHighest,
                    cs.surfaceContainerHighest.withValues(alpha: 0.9),
                  ],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: enabled ? 0 : 0.35),
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
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
                    style: TextStyle(
                      color: enabled ? Colors.white : disabledText,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(width: 8),
                Icon(icon,
                    color: enabled ? Colors.white : disabledText, size: 21),
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
        fillColor: _isDark
            ? _cs.surfaceContainerHighest.withValues(alpha: 0.72)
            : const Color(0xFFF0F4F7),
        hintStyle: TextStyle(
          color: _cs.onSurface.withValues(alpha: 0.55),
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: _cs.outlineVariant.withValues(alpha: _isDark ? 0.5 : 0.2),
            )),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: _cs.primary, width: 1.3),
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

String _categoryLabel(String value, AppLocalizations l10n) {
  switch (value) {
    case 'Garbage Pile':
      return l10n.choice('Garbage Pile', 'फोहोरको थुप्रो');
    case 'Overflowing Bin':
      return l10n.overflowingBin;
    case 'Illegal Dumping':
      return l10n.choice('Illegal Dumping', 'अवैध फोहोर फाल्ने');
    case 'Blocked Drain':
      return l10n.choice('Blocked Drain', 'अवरोधित नाला');
    case 'Burning Waste':
      return l10n.choice('Burning Waste', 'फोहोर बाल्ने');
    default:
      return value;
  }
}

String _severityLabel(String value, AppLocalizations l10n) {
  switch (value) {
    case 'Low':
      return l10n.choice('Low', 'कम');
    case 'Medium':
      return l10n.choice('Medium', 'मध्यम');
    case 'High':
      return l10n.choice('High', 'उच्च');
    default:
      return value;
  }
}

String _severityDescription(String value, AppLocalizations l10n) {
  switch (value) {
    case 'Low':
      return l10n.choice('Minor issue', 'सानो समस्या');
    case 'Medium':
      return l10n.choice('Needs attention', 'ध्यान आवश्यक');
    case 'High':
      return l10n.choice('Urgent action', 'तत्काल कार्य');
    default:
      return value;
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
