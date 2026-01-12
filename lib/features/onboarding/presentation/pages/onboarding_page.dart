import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _page,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final p = pages[i];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.bgTop, p.bgBottom],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: _finish,
                          child: Text('Skip', style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.70),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 28,
                              offset: const Offset(0, 18),
                              color: Colors.black.withOpacity(0.12),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: p.iconBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Icon(p.icon, color: Colors.white, size: 34),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        p.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          p.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurface.withOpacity(0.55), fontWeight: FontWeight.w600, fontSize: 16, height: 1.45),
                        ),
                      ),
                      const Spacer(),

                      // Page dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (d) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            width: d == _index ? 28 : 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: d == _index ? const Color(0xFF0E6E66) : Colors.black.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E6E66),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () {
                              if (_index < pages.length - 1) {
                                _page.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
                              } else {
                                _finish();
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_index == pages.length - 1 ? 'Get Started' : 'Continue', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                const SizedBox(width: 10),
                                Icon(_index == pages.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

List<_OnboardData> _pages() => const [
      _OnboardData(
        bgTop: Color(0xFF0F7B73),
        bgBottom: Color(0xFF0B5D56),
        icon: Icons.eco_outlined,
        iconBg: Color(0xFF1ECA92),
        title: 'Kachra Alert',
        subtitle: 'Cleaner streets. Smarter city.',
      ),
      _OnboardData(
        bgTop: Color(0xFFD8FFF1),
        bgBottom: Color(0xFFF3FFFA),
        icon: Icons.camera_alt_outlined,
        iconBg: Color(0xFF1ECA92),
        title: 'Report Waste Instantly',
        subtitle: 'Snap a photo, mark the location, and help keep your neighborhood clean. It takes just 30 seconds.',
      ),
      _OnboardData(
        bgTop: Color(0xFFD3E9FF),
        bgBottom: Color(0xFFF5FBFF),
        icon: Icons.notifications_none_rounded,
        iconBg: Color(0xFF1B8EF2),
        title: 'Stay Informed',
        subtitle: 'Get alerts about pickup schedules, weather warnings, and community updates. Never miss a collection day.',
      ),
    ];

class _OnboardData {
  final Color bgTop;
  final Color bgBottom;
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  const _OnboardData({
    required this.bgTop,
    required this.bgBottom,
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
}
