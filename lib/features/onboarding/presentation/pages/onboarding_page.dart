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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kachra Alert',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w700,
                        ),
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const Spacer(),
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.35 : 0.08,
                                  ),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: p.iconBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  p.icon,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cs.outlineVariant,
                              ),
                            ),
                            child: Column(
                              children: p.highlights
                                  .map(
                                    (text) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: cs.primary.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(10),
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
