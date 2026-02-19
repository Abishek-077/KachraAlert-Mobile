import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../motion/app_motion.dart';
import '../motion/motion_profile.dart';

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isTickerEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.hero * 15,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldAnimate = !context.motionProfile.reduceMotion;
    if (_isTickerEnabled == shouldAnimate) return;
    _isTickerEnabled = shouldAnimate;
    if (shouldAnimate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0.5;
    }
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
    final orbPrimary = isDark
        ? [
            const Color(0xFF3D5AFE).withValues(alpha: 0.2),
            const Color(0xFF3D5AFE).withValues(alpha: 0.0),
          ]
        : [
            cs.primary.withValues(alpha: 0.45),
            cs.primary.withValues(alpha: 0.05),
          ];
    final orbSecondary = isDark
        ? [
            const Color(0xFF2563EB).withValues(alpha: 0.14),
            const Color(0xFF2563EB).withValues(alpha: 0.0),
          ]
        : [
            cs.secondary.withValues(alpha: 0.35),
            cs.secondary.withValues(alpha: 0.05),
          ];
    final orbTertiary = isDark
        ? [
            const Color(0xFF93C5FD).withValues(alpha: 0.12),
            Colors.transparent,
          ]
        : [
            AppColors.accentGold.withValues(alpha: 0.25),
            Colors.transparent,
          ];

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * 2 * math.pi;
          final dx = _isTickerEnabled ? math.sin(t) * 18 : 0.0;
          final dy = _isTickerEnabled ? math.cos(t) * 18 : 0.0;

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
                  colors: orbPrimary,
                ),
              ),
              Positioned(
                right: -120 - dx,
                top: 120 + dy * 0.4,
                child: _Orb(
                  size: 260,
                  colors: orbSecondary,
                ),
              ),
              Positioned(
                left: 40 + dx * 0.6,
                bottom: -80 + dy,
                child: _Orb(
                  size: 200,
                  colors: orbTertiary,
                ),
              ),
              if (_isTickerEnabled)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: isDark ? 16 : 20,
                      sigmaY: isDark ? 16 : 20,
                    ),
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
