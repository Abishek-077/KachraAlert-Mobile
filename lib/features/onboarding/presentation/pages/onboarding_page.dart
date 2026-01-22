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
        accent: Color(0xFFF5A524),
        background: [Color(0xFFEFF9F4), Color(0xFFF7F8F9)],
        title: 'Never miss pickup',
        subtitle:
            'Get timely reminders about collection schedules, community events, and urgent updates.',
      ),
      _OnboardData(
        tag: '✨ Real-time',
        icon: Icons.location_on_outlined,
        accent: Color(0xFF3B82F6),
        background: [Color(0xFFEAF4FF), Color(0xFFF7F8FB)],
        title: 'Track everything',
        subtitle:
            'See your reports progress live. From submission to cleanup, stay informed every step.',
      ),
      _OnboardData(
        tag: '✨ Quick Report',
        icon: Icons.camera_alt_outlined,
        accent: Color(0xFF10B981),
        background: [Color(0xFFEBFAF2), Color(0xFFF7F9F8)],
        title: 'Report in seconds',
        subtitle:
            'Capture waste issues with your camera. Our AI auto-detects the problem type and severity.',
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
          const Spacer(),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 180,
                height: 180,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: data.accent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    data.icon,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              Positioned(
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    data.tag,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
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
