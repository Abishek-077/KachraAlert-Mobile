import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/k_widgets.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/report_hive_model.dart';
import '../providers/report_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportFilter _filter = ReportFilter.all;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final reportsAsync = ref.watch(reportsProvider);
    final apiBase = ref.watch(apiBaseUrlProvider);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final token = auth?.session?.accessToken;
    final currentUserId = auth?.session?.userId;
    final currentDisplayName = _displayName(auth?.session?.email ?? '');
    final currentProfilePhotoUrl =
        resolveMediaUrl(apiBase, auth?.session?.profilePhotoUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        actions: [
          IconButton(
            tooltip: l10n.newReport,
            onPressed: () => context.push('/reports/create'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                KChip(
                  label: l10n.reportFiltersAll,
                  selected: _filter == ReportFilter.all,
                  onTap: () => setState(() => _filter = ReportFilter.all),
                ),
                const SizedBox(width: 10),
                KChip(
                  label: l10n.reportFiltersVerified,
                  selected: _filter == ReportFilter.verified,
                  onTap: () => setState(() => _filter = ReportFilter.verified),
                ),
                const SizedBox(width: 10),
                KChip(
                  label: l10n.reportFiltersInProgress,
                  selected: _filter == ReportFilter.inProgress,
                  onTap: () =>
                      setState(() => _filter = ReportFilter.inProgress),
                ),
                const SizedBox(width: 10),
                KChip(
                  label: l10n.reportFiltersCleaned,
                  selected: _filter == ReportFilter.cleaned,
                  onTap: () => setState(() => _filter = ReportFilter.cleaned),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          reportsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => KCard(
              child: Column(
                children: [
                  Icon(Icons.error_outline_rounded, size: 46, color: cs.error),
                  const SizedBox(height: 10),
                  Text(
                    l10n.failedLoadReports,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          ref.read(reportsProvider.notifier).load(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retry),
                    ),
                  ),
                ],
              ),
            ),
            data: (all) {
              final list = _applyFilter(all, _filter)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (list.isEmpty) {
                return KCard(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 52, color: cs.onSurface.withOpacity(0.55)),
                      const SizedBox(height: 10),
                      Text(
                        l10n.noReportsFound,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.createReportHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurface.withOpacity(0.62)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.push('/reports/create'),
                          child: Text(l10n.reportWaste),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final r in list) ...[
                    _ReportCard(
                      report: r,
                      attachmentUrl: resolveMediaUrl(apiBase, r.attachmentUrl),
                      attachmentHeaders: token?.isNotEmpty == true
                          ? {'Authorization': 'Bearer $token'}
                          : null,
                      reporterPhotoHeaders: token?.isNotEmpty == true
                          ? {'Authorization': 'Bearer $token'}
                          : null,
                      reporterName: _resolveReporterName(
                        report: r,
                        currentUserId: currentUserId,
                        currentDisplayName: currentDisplayName,
                        fallbackName: l10n.communityMember,
                      ),
                      reporterPhotoUrl: _resolveReporterPhotoUrl(
                        report: r,
                        currentUserId: currentUserId,
                        currentProfilePhotoUrl: currentProfilePhotoUrl,
                        apiBase: apiBase,
                      ),
                      reporterLabel: l10n.reportedBy(
                        _resolveReporterName(
                          report: r,
                          currentUserId: currentUserId,
                          currentDisplayName: currentDisplayName,
                          fallbackName: l10n.communityMember,
                        ),
                      ),
                      onTap: () => context.push('/reports/create', extra: r),
                    ),
                    const SizedBox(height: 12),
                  ]
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

List<ReportHiveModel> _applyFilter(
  List<ReportHiveModel> all,
  ReportFilter filter,
) {
  switch (filter) {
    case ReportFilter.all:
      return [...all];
    case ReportFilter.verified:
      return all.where((r) => r.status == 'pending').toList();
    case ReportFilter.inProgress:
      return all.where((r) => r.status == 'in_progress').toList();
    case ReportFilter.cleaned:
      return all.where((r) => r.status == 'resolved').toList();
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onTap,
    required this.attachmentUrl,
    required this.attachmentHeaders,
    required this.reporterName,
    required this.reporterPhotoUrl,
    required this.reporterLabel,
    required this.reporterPhotoHeaders,
  });
  final ReportHiveModel report;
  final VoidCallback onTap;
  final String? attachmentUrl;
  final Map<String, String>? attachmentHeaders;
  final String reporterName;
  final String? reporterPhotoUrl;
  final String reporterLabel;
  final Map<String, String>? reporterPhotoHeaders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final ui = _statusUi(report.status, cs, l10n);
    final idShort = (report.createdAt % 10000).toString().padLeft(4, '0');

    return KCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: attachmentUrl == null
                  ? Icon(
                      Icons.image_outlined,
                      color: cs.primary.withOpacity(0.7),
                    )
                  : Image.network(
                      attachmentUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      headers: attachmentHeaders,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: cs.primary.withOpacity(0.7),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _localizedCategory(report.category, l10n),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ui.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: ui.border),
                      ),
                      child: Text(
                        ui.label,
                        style: TextStyle(
                          color: ui.fg,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.reportId(idShort),
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ReporterAvatar(
                      name: reporterName,
                      photoUrl: reporterPhotoUrl,
                      photoHeaders: reporterPhotoHeaders,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reporterLabel,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.75),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.reported,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place_rounded,
                        size: 16, color: cs.onSurface.withOpacity(0.55)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.location,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.65),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_rounded,
                        size: 16, color: cs.onSurface.withOpacity(0.55)),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo(report.createdAt),
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.55)),
        ],
      ),
    );
  }
}

_StatusUi _statusUi(String status, ColorScheme cs, AppLocalizations l10n) {
  switch (status) {
    case 'resolved':
      return _StatusUi(
        label: l10n.reportFiltersCleaned,
        bg: const Color(0xFF1ECA92).withOpacity(0.12),
        fg: const Color(0xFF0E6E66),
        border: const Color(0xFF1ECA92).withOpacity(0.25),
      );
    case 'in_progress':
      return _StatusUi(
        label: l10n.reportFiltersInProgress,
        bg: cs.primary.withOpacity(0.10),
        fg: cs.primary,
        border: cs.primary.withOpacity(0.20),
      );
    case 'pending':
    default:
      return _StatusUi(
        label: l10n.reportFiltersVerified,
        bg: const Color(0xFF1B8EF2).withOpacity(0.10),
        fg: const Color(0xFF1B8EF2),
        border: const Color(0xFF1B8EF2).withOpacity(0.20),
      );
  }
}

class _StatusUi {
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  const _StatusUi({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });
}

enum ReportFilter {
  all,
  verified,
  inProgress,
  cleaned,
}

String _displayName(String email) {
  final cleaned = email.trim();
  if (cleaned.isEmpty) return 'User';
  final name = cleaned.split('@').first;
  if (name.isEmpty) return 'User';
  return name
      .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .map((part) =>
          part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _resolveReporterName({
  required ReportHiveModel report,
  required String? currentUserId,
  required String currentDisplayName,
  required String fallbackName,
}) {
  final reporterName = report.reporterName?.trim();
  if (reporterName != null && reporterName.isNotEmpty) {
    return reporterName;
  }
  if (currentUserId != null && report.userId == currentUserId) {
    return currentDisplayName;
  }
  return fallbackName;
}

String? _resolveReporterPhotoUrl({
  required ReportHiveModel report,
  required String? currentUserId,
  required String? currentProfilePhotoUrl,
  required String apiBase,
}) {
  if (currentUserId != null && report.userId == currentUserId) {
    return currentProfilePhotoUrl;
  }
  return resolveMediaUrl(apiBase, report.reporterPhotoUrl);
}

String _localizedCategory(String category, AppLocalizations l10n) {
  switch (category) {
    case 'Missed Pickup':
      return l10n.missedPickup;
    case 'Overflowing Bin':
      return l10n.overflowingBin;
    case 'Bad Smell':
      return l10n.badSmell;
    case 'Other':
      return l10n.other;
    default:
      return category;
  }
}

class _ReporterAvatar extends StatelessWidget {
  const _ReporterAvatar({
    required this.name,
    this.photoUrl,
    this.photoHeaders,
  });

  final String name;
  final String? photoUrl;
  final Map<String, String>? photoHeaders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'U';
    return CircleAvatar(
      radius: 12,
      backgroundColor: cs.primary.withOpacity(0.12),
      foregroundImage: photoUrl == null
          ? null
          : NetworkImage(photoUrl!, headers: photoHeaders),
      child: photoUrl == null
          ? Text(
              initial,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            )
          : null,
    );
  }
}
