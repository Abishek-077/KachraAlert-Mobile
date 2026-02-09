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
    final currentDisplayName = _displayName(
      auth?.session?.email ?? '',
      fallback: l10n.guestUser,
    );
    final currentProfilePhotoUrl =
        resolveMediaUrl(apiBase, auth?.session?.profilePhotoUrl);
    final stats = _ReportStats.from(reportsAsync.valueOrNull ?? const []);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
      body: Stack(
        children: [
          const AmbientBackground(),
          RefreshIndicator(
            onRefresh: () => ref.read(reportsProvider.notifier).load(),
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 108, 16, 120),
              children: [
                DelayedReveal(
                  delay: const Duration(milliseconds: 80),
                  child: _ReportsHeroCard(
                    total: stats.total,
                    open: stats.open,
                    inProgress: stats.inProgress,
                    resolved: stats.resolved,
                    l10n: l10n,
                  ),
                ),
                const SizedBox(height: 16),
                DelayedReveal(
                  delay: const Duration(milliseconds: 130),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        KChip(
                          label: l10n.reportFiltersAll,
                          selected: _filter == ReportFilter.all,
                          onTap: () =>
                              setState(() => _filter = ReportFilter.all),
                        ),
                        const SizedBox(width: 10),
                        KChip(
                          label: l10n.reportFiltersVerified,
                          selected: _filter == ReportFilter.verified,
                          onTap: () =>
                              setState(() => _filter = ReportFilter.verified),
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
                          onTap: () =>
                              setState(() => _filter = ReportFilter.cleaned),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      Text(
                        l10n.choice('Recent Reports', 'हालका रिपोर्टहरू'),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${stats.total}',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                reportsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => KCard(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 46, color: cs.error),
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
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.66)),
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
                                size: 52,
                                color: cs.onSurface.withValues(alpha: 0.55)),
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
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.62)),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () =>
                                    context.push('/reports/create'),
                                icon: const Icon(Icons.add_rounded),
                                label: Text(l10n.reportWaste),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (var i = 0; i < list.length; i++) ...[
                          DelayedReveal(
                            delay: Duration(
                              milliseconds: 60 + (i < 6 ? i * 45 : 270),
                            ),
                            child: _ReportCard(
                              report: list[i],
                              attachmentUrl: resolveMediaUrl(
                                  apiBase, list[i].attachmentUrl),
                              attachmentHeaders: token?.isNotEmpty == true
                                  ? {'Authorization': 'Bearer $token'}
                                  : null,
                              reporterPhotoHeaders: token?.isNotEmpty == true
                                  ? {'Authorization': 'Bearer $token'}
                                  : null,
                              reporterName: _resolveReporterName(
                                report: list[i],
                                currentUserId: currentUserId,
                                currentDisplayName: currentDisplayName,
                                fallbackName: l10n.communityMember,
                              ),
                              reporterPhotoUrl: _resolveReporterPhotoUrl(
                                report: list[i],
                                currentUserId: currentUserId,
                                currentProfilePhotoUrl: currentProfilePhotoUrl,
                                apiBase: apiBase,
                              ),
                              reporterLabel: l10n.reportedBy(
                                _resolveReporterName(
                                  report: list[i],
                                  currentUserId: currentUserId,
                                  currentDisplayName: currentDisplayName,
                                  fallbackName: l10n.communityMember,
                                ),
                              ),
                              onTap: () => _showReportDetails(
                                report: list[i],
                                attachmentUrl: resolveMediaUrl(
                                    apiBase, list[i].attachmentUrl),
                                attachmentHeaders: token?.isNotEmpty == true
                                    ? {'Authorization': 'Bearer $token'}
                                    : null,
                                reporterName: _resolveReporterName(
                                  report: list[i],
                                  currentUserId: currentUserId,
                                  currentDisplayName: currentDisplayName,
                                  fallbackName: l10n.communityMember,
                                ),
                                reporterPhotoUrl: _resolveReporterPhotoUrl(
                                  report: list[i],
                                  currentUserId: currentUserId,
                                  currentProfilePhotoUrl:
                                      currentProfilePhotoUrl,
                                  apiBase: apiBase,
                                ),
                                reporterPhotoHeaders: token?.isNotEmpty == true
                                    ? {'Authorization': 'Bearer $token'}
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetails({
    required ReportHiveModel report,
    required String? attachmentUrl,
    required Map<String, String>? attachmentHeaders,
    required String reporterName,
    required String? reporterPhotoUrl,
    required Map<String, String>? reporterPhotoHeaders,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _ReportDetailsSheet(
        report: report,
        attachmentUrl: attachmentUrl,
        attachmentHeaders: attachmentHeaders,
        reporterName: reporterName,
        reporterPhotoUrl: reporterPhotoUrl,
        reporterLabel: AppLocalizations.of(context).reportedBy(reporterName),
        reporterPhotoHeaders: reporterPhotoHeaders,
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
      return all
          .where((r) => _normalizeStatusCode(r.status) == 'pending')
          .toList();
    case ReportFilter.inProgress:
      return all
          .where((r) => _normalizeStatusCode(r.status) == 'in_progress')
          .toList();
    case ReportFilter.cleaned:
      return all
          .where((r) => _normalizeStatusCode(r.status) == 'resolved')
          .toList();
  }
}

class _ReportsHeroCard extends StatelessWidget {
  const _ReportsHeroCard({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.resolved,
    required this.l10n,
  });

  final int total;
  final int open;
  final int inProgress;
  final int resolved;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? cs.primary.withValues(alpha: 0.64)
                : cs.primary.withValues(alpha: 0.96),
            isDark ? const Color(0xFF113641) : const Color(0xFF156764),
            isDark
                ? cs.secondary.withValues(alpha: 0.44)
                : cs.secondary.withValues(alpha: 0.86),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.32),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.choice('CLEAN CITY TRACKER', 'सफा सहर ट्र्याकर'),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.choice('Report Impact', 'रिपोर्ट प्रभाव'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStatPill(
                  value: '$total',
                  label: l10n.choice('Total', 'जम्मा'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStatPill(
                  value: '$open',
                  label: l10n.choice('Open', 'खुला'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStatPill(
                  value: '$inProgress',
                  label: l10n.choice('Active', 'प्रगतिमा'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStatPill(
                  value: '$resolved',
                  label: l10n.resolved,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailsSheet extends StatelessWidget {
  const _ReportDetailsSheet({
    required this.report,
    required this.attachmentUrl,
    required this.attachmentHeaders,
    required this.reporterName,
    required this.reporterPhotoUrl,
    required this.reporterLabel,
    required this.reporterPhotoHeaders,
  });

  final ReportHiveModel report;
  final String? attachmentUrl;
  final Map<String, String>? attachmentHeaders;
  final String reporterName;
  final String? reporterPhotoUrl;
  final String reporterLabel;
  final Map<String, String>? reporterPhotoHeaders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final statusUi = _statusUi(report.status, cs, l10n);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _localizedCategory(report.category, l10n),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusUi.bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusUi.border),
                  ),
                  child: Text(
                    statusUi.label,
                    style: TextStyle(
                      color: statusUi.fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: 190,
                color: cs.primary.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: attachmentUrl == null
                    ? Icon(
                        Icons.image_search_rounded,
                        size: 56,
                        color: cs.primary.withValues(alpha: 0.70),
                      )
                    : Image.network(
                        attachmentUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        headers: attachmentHeaders,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image_outlined,
                          size: 56,
                          color: cs.primary.withValues(alpha: 0.70),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            _DetailInfoRow(icon: Icons.badge_outlined, text: _publicId(report)),
            const SizedBox(height: 8),
            _DetailInfoRow(icon: Icons.place_outlined, text: report.location),
            const SizedBox(height: 8),
            _DetailInfoRow(
              icon: Icons.access_time_rounded,
              text: timeAgo(report.createdAt),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ReporterAvatar(
                  name: reporterName,
                  photoUrl: reporterPhotoUrl,
                  photoHeaders: reporterPhotoHeaders,
                  radius: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _usernameHandle(reporterName),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reporterLabel,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.74),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.details,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _previewMessage(report.message, l10n),
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/reports/create');
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.newReport),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final ui = _statusUi(report.status, cs, l10n);
    final publicId = _publicId(report);
    final secondaryColor = cs.onSurface.withValues(alpha: isDark ? 0.76 : 0.62);
    final bodyColor = cs.onSurface.withValues(alpha: isDark ? 0.84 : 0.72);
    final metaColor = cs.onSurface.withValues(alpha: isDark ? 0.76 : 0.66);
    final iconColor = cs.onSurface.withValues(alpha: isDark ? 0.68 : 0.5);

    return KCard(
      backgroundColor: isDark ? cs.surfaceContainerHigh : Colors.white,
      boxShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ]
          : const [
              BoxShadow(
                color: Color(0x1A0B1E16),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
              BoxShadow(
                color: Color(0xE6FFFFFF),
                blurRadius: 10,
                offset: Offset(-3, -3),
              ),
            ],
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: attachmentUrl == null
                        ? Icon(
                            Icons.image_outlined,
                            color: cs.primary.withValues(alpha: 0.74),
                            size: 28,
                          )
                        : Image.network(
                            attachmentUrl!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            headers: attachmentHeaders,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: cs.primary.withValues(alpha: 0.74),
                              size: 28,
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
                          _ReporterAvatar(
                            name: reporterName,
                            photoUrl: reporterPhotoUrl,
                            photoHeaders: reporterPhotoHeaders,
                            radius: 12,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _usernameHandle(reporterName),
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  reporterName,
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: ui.bg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: ui.border),
                            ),
                            child: Text(
                              ui.label,
                              style: TextStyle(
                                color: ui.fg,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _previewMessage(report.message, l10n),
                        style: TextStyle(
                          color: bodyColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              publicId,
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, color: iconColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.42 : 0.22),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.place_rounded,
                          size: 16,
                          color: cs.onSurface.withValues(
                            alpha: isDark ? 0.68 : 0.55,
                          )),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          report.location,
                          style: TextStyle(
                            color: metaColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo(report.createdAt),
                  style: TextStyle(
                    color: metaColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_StatusUi _statusUi(String status, ColorScheme cs, AppLocalizations l10n) {
  switch (_normalizeStatusCode(status)) {
    case 'resolved':
      return _StatusUi(
        label: l10n.reportFiltersCleaned,
        bg: const Color(0xFF1ECA92).withValues(alpha: 0.12),
        fg: const Color(0xFF0E6E66),
        border: const Color(0xFF1ECA92).withValues(alpha: 0.25),
      );
    case 'in_progress':
      return _StatusUi(
        label: l10n.reportFiltersInProgress,
        bg: cs.primary.withValues(alpha: 0.10),
        fg: cs.primary,
        border: cs.primary.withValues(alpha: 0.20),
      );
    case 'pending':
    default:
      return _StatusUi(
        label: l10n.reportFiltersVerified,
        bg: const Color(0xFF1B8EF2).withValues(alpha: 0.10),
        fg: const Color(0xFF1B8EF2),
        border: const Color(0xFF1B8EF2).withValues(alpha: 0.20),
      );
  }
}

String _normalizeStatusCode(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.contains('progress')) return 'in_progress';
  if (value.contains('resolved') || value.contains('clean')) return 'resolved';
  return 'pending';
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

String _displayName(String email, {String fallback = 'User'}) {
  final cleaned = email.trim();
  if (cleaned.isEmpty) return fallback;
  final name = cleaned.split('@').first;
  if (name.isEmpty) return fallback;
  return name
      .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .map((part) =>
          part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _usernameHandle(String name) {
  final cleaned = name.trim().toLowerCase();
  if (cleaned.isEmpty) return '@user';
  final compact = cleaned.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  if (compact.isEmpty) return '@user';
  return '@$compact';
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
    case 'Overflow':
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
    this.radius = 12,
  });

  final String name;
  final String? photoUrl;
  final Map<String, String>? photoHeaders;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'U';
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primary.withValues(alpha: 0.12),
      foregroundImage: photoUrl == null
          ? null
          : NetworkImage(photoUrl!, headers: photoHeaders),
      child: photoUrl == null
          ? Text(
              initial,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w900,
                fontSize: radius * 0.62,
              ),
            )
          : null,
    );
  }
}

class _ReportStats {
  const _ReportStats({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.resolved,
  });

  final int total;
  final int open;
  final int inProgress;
  final int resolved;

  factory _ReportStats.from(List<ReportHiveModel> reports) {
    var open = 0;
    var inProgress = 0;
    var resolved = 0;

    for (final report in reports) {
      switch (_normalizeStatusCode(report.status)) {
        case 'in_progress':
          inProgress++;
          break;
        case 'resolved':
          resolved++;
          break;
        case 'pending':
        default:
          open++;
          break;
      }
    }

    return _ReportStats(
      total: reports.length,
      open: open,
      inProgress: inProgress,
      resolved: resolved,
    );
  }
}

String _previewMessage(String message, AppLocalizations l10n) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) {
    return l10n.choice(
      'Issue reported from Kachra Alert app.',
      'कचरा अलर्ट एपबाट समस्या रिपोर्ट गरिएको छ।',
    );
  }
  return trimmed;
}

String _publicId(ReportHiveModel report) {
  final year = DateTime.fromMillisecondsSinceEpoch(report.createdAt).year;
  final numeric = report.id.replaceAll(RegExp(r'[^0-9]'), '');
  final seed = numeric.isNotEmpty ? numeric : report.createdAt.toString();
  final suffix =
      seed.length >= 4 ? seed.substring(seed.length - 4) : seed.padLeft(4, '0');
  return 'RPT-$year-$suffix';
}
