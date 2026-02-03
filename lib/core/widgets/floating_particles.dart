import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Floating particles background animation
class FloatingParticles extends StatefulWidget {
  const FloatingParticles({
    super.key,
    this.particleCount = 25,
    this.minSize = 4,
    this.maxSize = 12,
    this.color,
  });

  final int particleCount;
  final double minSize;
  final double maxSize;
  final Color? color;

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (index) => _Particle(
        size: widget.minSize +
            math.Random().nextDouble() * (widget.maxSize - widget.minSize),
        startX: math.Random().nextDouble(),
        startY: math.Random().nextDouble(),
        speedX: (math.Random().nextDouble() - 0.5) * 0.02,
        speedY: -math.Random().nextDouble() * 0.03 - 0.01,
        opacity: math.Random().nextDouble() * 0.3 + 0.1,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final particleColor = widget.color ?? cs.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            particles: _particles,
            progress: _controller.value,
            color: particleColor,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  final double size;
  final double startX;
  final double startY;
  final double speedX;
  final double speedY;
  final double opacity;

  _Particle({
    required this.size,
    required this.startX,
    required this.startY,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = ((particle.startX + particle.speedX * progress) % 1.0) * size.width;
      final y = ((particle.startY + particle.speedY * progress) % 1.0) * size.height;

      final paint = Paint()
        ..color = color.withOpacity(particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) => true;
}
