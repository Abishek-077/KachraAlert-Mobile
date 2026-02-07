import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * 2 * math.pi;
          final dx = math.sin(t) * 18;
          final dy = math.cos(t) * 18;

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkPrimaryGradient
                      : AppColors.backgroundGradient,
                ),
              ),
              Positioned(
                left: -80 + dx,
                top: -60 + dy,
                child: _Orb(
                  size: 220,
                  colors: [
                    cs.primary.withOpacity(0.45),
                    cs.primary.withOpacity(0.05),
                  ],
                ),
              ),
              Positioned(
                right: -120 - dx,
                top: 120 + dy * 0.4,
                child: _Orb(
                  size: 260,
                  colors: [
                    cs.secondary.withOpacity(0.35),
                    cs.secondary.withOpacity(0.05),
                  ],
                ),
              ),
              Positioned(
                left: 40 + dx * 0.6,
                bottom: -80 + dy,
                child: _Orb(
                  size: 200,
                  colors: [
                    AppColors.accentGold.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.size,
    required this.colors,
  });

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
          center: const Alignment(-0.4, -0.3),
          colors: colors,
        ),
      ),
    );
  }
}
