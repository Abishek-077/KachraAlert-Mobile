// lib/features/onboarding/presentation/widgets/onboarding_page_widget.dart

import 'package:flutter/material.dart';

class OnboardingPageWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingPageWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large Icon with background circle
          Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE), // Light teal background
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 100, color: const Color(0xFF2DD4BF)),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
