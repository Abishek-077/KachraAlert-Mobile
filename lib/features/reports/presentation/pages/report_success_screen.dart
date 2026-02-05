import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../../../core/widgets/floating_particles.dart';

class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background particles for polish
          Positioned.fill(
            child: FloatingParticles(
              particleCount: 20,
              color: const Color(0xFF10B981).withOpacity(0.2),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Circular success indicator with glow and animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3 * value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 80 * value,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Report Submitted!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thank you for keeping our city clean.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Report ID Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reportId.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "You'll receive notifications as your report progresses through verification and cleanup.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  PremiumButton(
                    label: 'Back to Home',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF134E4A)],
                    ),
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
