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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [cs.surface, theme.scaffoldBackgroundColor]
                : [const Color(0xFFE6F7EF), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: -20,
              child: _GlowCircle(
                size: 220,
                color: cs.primary.withOpacity(isDark ? 0.2 : 0.12),
              ),
            ),
            Positioned(
              left: -70,
              bottom: 120,
              child: _GlowCircle(
                size: 180,
                color: cs.secondary.withOpacity(isDark ? 0.18 : 0.1),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kachra Alert',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              'Onboarding ${_index + 1} of ${pages.length}',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: cs.onSurfaceVariant,
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / pages.length,
                        minHeight: 6,
                        backgroundColor: cs.outlineVariant.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      itemCount: pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final p = pages[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const Spacer(),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      p.iconBg.withOpacity(0.92),
                                      p.iconBg.withOpacity(0.72),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: p.iconBg.withOpacity(
                                        isDark ? 0.4 : 0.28,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        p.icon,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      p.title,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      p.subtitle,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: cs.outlineVariant,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        isDark ? 0.2 : 0.08,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: p.highlights
                                      .map(
                                        (text) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color:
                                                      cs.primary.withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  color: cs.primary,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  text,
                                                  style: TextStyle(
                                                    color: cs.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
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
                      dotColor: cs.outlineVariant,
                      expansionFactor: 3.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
        icon: Icons.eco_outlined,
        iconBg: Color(0xFF12B76A),
        title: 'Smarter Waste Pickup',
        subtitle: 'A cleaner city starts with better coordination.',
        highlights: [
          'Real-time waste pickup alerts for your area.',
          'Personalized schedules tailored to your community.',
          'Trusted notifications from city operators.',
        ],
      ),
      _OnboardData(
        icon: Icons.camera_alt_outlined,
        iconBg: Color(0xFF2DD4BF),
        title: 'Report in Seconds',
        subtitle: 'Snap, tag, and send waste reports instantly.',
        highlights: [
          'Attach location and photos in one tap.',
          'Track report status with clear updates.',
          'Help keep neighborhoods spotless.',
        ],
      ),
      _OnboardData(
        icon: Icons.notifications_none_rounded,
        iconBg: Color(0xFF16A34A),
        title: 'Never Miss a Pickup',
        subtitle: 'Stay informed with smart reminders.',
        highlights: [
          'Daily, weekly, and holiday schedules.',
          'Instant alerts for route changes.',
          'Optional reminders before pickup time.',
        ],
      ),
    ];

class _OnboardData {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final List<String> highlights;
  const _OnboardData({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.highlights,
  });
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
