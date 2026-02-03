import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Confetti celebration animation
class ConfettiCelebration extends StatefulWidget {
  const ConfettiCelebration({
    super.key,
    this.particleCount = 50,
  });

  final int particleCount;

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;

  static final List<Color> _colors = [
    const Color(0xFFEF4444),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();

    final random = math.Random();
    _particles = List.generate(widget.particleCount, (index) {
      final angle = (index / widget.particleCount) * math.pi * 2 +
          (random.nextDouble() - 0.5) * 0.5;
      final velocity = 200 + random.nextDouble() * 200;
      
      return _ConfettiParticle(
        color: _colors[random.nextInt(_colors.length)],
        angle: angle,
        velocity: velocity,
        size: 6 + random.nextDouble() * 6,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double angle;
  final double velocity;
  final double size;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.color,
    required this.angle,
    required this.velocity,
    required this.size,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (final particle in particles) {
      final distance = particle.velocity * progress;
      final gravity = 400 * progress * progress;
      
      final x = centerX + math.cos(particle.angle) * distance;
      final y = centerY + math.sin(particle.angle) * distance + gravity;

      final rotation = particle.rotationSpeed * progress;

      // Fade out near the end
      final opacity = progress < 0.8 ? 1.0 : ((1.0 - progress) / 0.2);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Draw rectangle confetti
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 1.5,
          ),
          const Radius.circular(1),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

/// Show confetti overlay
void showConfetti(BuildContext context) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned.fill(
      child: IgnorePointer(
        child: ConfettiCelebration(),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(milliseconds: 2000), () {
    overlayEntry.remove();
  });
}
