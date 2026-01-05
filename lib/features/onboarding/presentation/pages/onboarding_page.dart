// lib/features/onboarding/presentation/pages/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:kachra_alert/features/onboarding/presentation/widgets/onboarding_page_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  OnboardingPageWidget(
                    icon: Icons.notifications_active_rounded,
                    title: 'Never Miss Your Garbage Collection',
                    description:
                        'Get timely alerts and manage schedules efficiently',
                  ),
                  OnboardingPageWidget(
                    icon: Icons.schedule_rounded,
                    title: 'Smart Schedule Management',
                    description:
                        'Track collection times and never miss a pickup',
                  ),
                  OnboardingPageWidget(
                    icon: Icons.eco_rounded,
                    title: 'Contribute to Cleaner Environment',
                    description:
                        'Join us in making waste management effortless',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF2DD4BF)
                              : const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 33),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DD4BF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage < 2 ? 'Next' : 'Get Started',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
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
