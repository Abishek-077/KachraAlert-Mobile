import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final displayId = _normalizeReportId(reportId);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFF6F8F7),
      body: Stack(
        children: [
          const _SuccessBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 360,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerHigh.withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(
                          alpha: isDark ? 0.5 : 0.45,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.35)
                              : const Color(0x1A000000),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 124,
                          height: 124,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF10B981).withValues(alpha: 0.20),
                                const Color(0xFF10B981).withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF1BAA7F), Color(0xFF166B6A)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x441BAA7F),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Report Submitted!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your issue has been logged and sent to the cleanup team.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: cs.onSurface.withValues(alpha: 0.74),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? cs.primary.withValues(alpha: 0.2)
                                : const Color(0xFFD5EEE5),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            displayId,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark ? cs.primary : const Color(0xFF059669),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Track progress from the reports list as your request moves from open to resolved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.66),
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primary,
                            cs.secondary.withValues(alpha: 0.8)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => context.go('/home'),
                          child: const Center(
                            child: Text(
                              'Back to Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.go('/reports'),
                      child: Text(
                        'View All Reports',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
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

class _SuccessBackground extends StatelessWidget {
  const _SuccessBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? cs.surface : const Color(0xFFE9F8F3),
            isDark
                ? cs.surfaceContainerHigh.withValues(alpha: 0.9)
                : const Color(0xFFF7FBFA),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -30,
            left: -60,
            child: _SuccessOrb(
              size: 220,
              color: (isDark ? cs.primary : const Color(0xFF7EE6C5))
                  .withValues(alpha: isDark ? 0.26 : 0.45),
            ),
          ),
          Positioned(
            right: -80,
            top: 150,
            child: _SuccessOrb(
              size: 250,
              color: (isDark ? cs.secondary : const Color(0xFF8CD6F4))
                  .withValues(alpha: isDark ? 0.2 : 0.36),
            ),
          ),
          Positioned(
            left: 40,
            bottom: -100,
            child: _SuccessOrb(
              size: 240,
              color: (isDark ? cs.tertiary : const Color(0xFFB2EFD6))
                  .withValues(alpha: isDark ? 0.16 : 0.28),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessOrb extends StatelessWidget {
  const _SuccessOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

String _normalizeReportId(String raw) {
  final id = raw.trim();
  if (id.toUpperCase().startsWith('RPT-')) {
    return id.toUpperCase();
  }
  final year = DateTime.now().year;
  final digitsOnly = id.replaceAll(RegExp(r'[^0-9]'), '');
  final fallback = DateTime.now().millisecondsSinceEpoch.toString();
  final seed = digitsOnly.isNotEmpty ? digitsOnly : fallback;
  final suffix =
      seed.length >= 4 ? seed.substring(seed.length - 4) : seed.padLeft(4, '0');
  return 'RPT-$year-$suffix';
}
