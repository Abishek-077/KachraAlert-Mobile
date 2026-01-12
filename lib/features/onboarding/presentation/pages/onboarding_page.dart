import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_waste_app/core/theme/app_colors.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardData(
      icon: Icons.notifications_active_rounded,
      title: 'Never Miss Your Garbage\nCollection',
      subtitle: 'Get timely alerts and manage schedules efficiently',
    ),
    _OnboardData(
      icon: Icons.schedule_rounded,
      title: 'Smart Schedule\nManagement',
      subtitle: 'Track collection times and never miss a pickup',
    ),
    _OnboardData(
      icon: Icons.eco_rounded,
      title: 'Contribute to Cleaner\nEnvironment',
      subtitle: 'Join us in making waste management effortless',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).setOnboarded();
    if (mounted) context.go('/auth/login');
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _OnboardPage(data: _pages[i]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _next,
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: TextStyle(color: AppColors.subText),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OnboardData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.data});

  final _OnboardData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(data.icon, size: 46, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.subText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
