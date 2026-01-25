import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../settings/presentation/providers/settings_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _page;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _page = PageController();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).setOnboarded();
    if (mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final page = pages[_index.clamp(0, pages.length - 1)];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [cs.surface, theme.scaffoldBackgroundColor]
                : page.background,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -100,
              top: -40,
              child: _GlowCircle(
                size: 220,
                color: page.accent.withOpacity(isDark ? 0.2 : 0.16),
              ),
            ),
            Positioned(
              left: -90,
              bottom: 60,
              child: _GlowCircle(
                size: 200,
                color: page.accent.withOpacity(isDark ? 0.18 : 0.12),
              ),
            ),
            Positioned(
              right: 40,
              bottom: 140,
              child: _Orb(
                size: 84,
                colors: [
                  page.accent.withOpacity(0.75),
                  page.accent.withOpacity(0.15),
                ],
              ),
            ),
            Positioned(
              left: 30,
              top: 120,
              child: _Orb(
                size: 58,
                colors: [
                  Colors.white.withOpacity(0.65),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: cs.onSurfaceVariant,
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      itemCount: pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final p = pages[i];
                        return _OnboardingSlide(
                          data: p,
                          colorScheme: cs,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                  SmoothPageIndicator(
                    controller: _page,
                    count: pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: cs.primary,
                      dotColor: cs.outlineVariant.withOpacity(0.6),
                      expansionFactor: 3.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: () {
                          if (_index < pages.length - 1) {
                            _page.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                            );
                          } else {
                            _finish();
                          }
                        },
                        icon: Icon(
                          _index == pages.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          _index == pages.length - 1
                              ? 'Get Started'
                              : 'Continue',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_OnboardData> _pages() => const [
      _OnboardData(
        tag: '✨ Smart Alerts',
        icon: Icons.notifications_none_rounded,
        accent: Color(0xFFF59E0B),
        background: [Color(0xFFFFF4E6), Color(0xFFF8F5FF)],
        title: 'Never miss a pickup',
        subtitle:
            'Stay ahead with intelligent reminders for collections, community events, and urgent alerts.',
      ),
      _OnboardData(
        tag: '✨ Real-time',
        icon: Icons.location_on_outlined,
        accent: Color(0xFF3B82F6),
        background: [Color(0xFFEAF4FF), Color(0xFFF0F6FF)],
        title: 'Track every report',
        subtitle:
            'Watch updates in real time. From submission to cleanup, you stay informed at each step.',
      ),
      _OnboardData(
        tag: '✨ Quick Report',
        icon: Icons.camera_alt_outlined,
        accent: Color(0xFF10B981),
        background: [Color(0xFFECFFF5), Color(0xFFF2F7F7)],
        title: 'Report in seconds',
        subtitle:
            'Snap a photo and let AI auto-detect the issue type and severity for faster cleanup.',
      ),
    ];

class _OnboardData {
  final String tag;
  final IconData icon;
  final Color accent;
  final List<Color> background;
  final String title;
  final String subtitle;
  const _OnboardData({
    required this.tag,
    required this.icon,
    required this.accent,
    required this.background,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.data,
    required this.colorScheme,
    required this.isDark,
  });

  final _OnboardData data;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _Orb(
                  size: 220,
                  colors: [
                    data.accent.withOpacity(0.28),
                    Colors.transparent,
                  ],
                ),
                Transform.rotate(
                  angle: -0.08,
                  child: _HeroCard(
                    accent: data.accent,
                    icon: data.icon,
                    isDark: isDark,
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 12,
                  child: _MiniTile(
                    icon: Icons.auto_graph_rounded,
                    label: 'Insights',
                    accent: data.accent,
                    isDark: isDark,
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 16,
                  child: _MiniTile(
                    icon: Icons.shield_rounded,
                    label: 'Verified',
                    accent: data.accent,
                    isDark: isDark,
                    rotate: 0.12,
                  ),
                ),
                Positioned(
                  top: 8,
                  child: _TagPill(
                    label: data.tag,
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InfoPanel(
            title: data.title,
            subtitle: data.subtitle,
            accent: data.accent,
            isDark: isDark,
            colorScheme: colorScheme,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.accent,
    required this.icon,
    required this.isDark,
  });

  final Color accent;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 210,
      height: 210,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface,
            cs.surface.withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.04 : 0.65),
            blurRadius: 24,
            offset: const Offset(-12, -12),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(isDark ? 0.04 : 0.35),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withOpacity(0.95),
              accent.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.3),
              blurRadius: 22,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 56,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.isDark,
    required this.colorScheme,
  });

  final String label;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isDark,
    this.rotate = 0,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool isDark;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Transform.rotate(
      angle: rotate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(isDark ? 0.05 : 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isDark,
    required this.colorScheme,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: accent.withOpacity(isDark ? 0.2 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

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
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.2),
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
    );
  }
}
