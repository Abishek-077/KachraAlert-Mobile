import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enhanced circular progress ring with gradient stroke and animations
class StatsRing extends StatefulWidget {
  const StatsRing({
    super.key,
    required this.value,
    required this.maxValue,
    this.size = 120,
    this.strokeWidth = 12,
    this.gradient,
    this.backgroundColor,
    this.showLabel = true,
    this.label = '',
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  final double value;
  final double maxValue;
  final double size;
  final double strokeWidth;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool showLabel;
  final String label;
  final Duration animationDuration;

  @override
  State<StatsRing> createState() => _StatsRingState();
}

class _StatsRingState extends State<StatsRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<int> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    final targetValue = (widget.value / widget.maxValue).clamp(0.0, 1.0);
    _progressAnimation = Tween<double>(begin: 0.0, end: targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _counterAnimation = IntTween(
      begin: 0,
      end: widget.value.toInt(),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(StatsRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final targetValue = (widget.value / widget.maxValue).clamp(0.0, 1.0);
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: targetValue,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      _counterAnimation = IntTween(
        begin: _counterAnimation.value,
        end: widget.value.toInt(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      _controller.forward(from: 0);
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

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: _progressAnimation.value,
              strokeWidth: widget.strokeWidth,
              gradient: widget.gradient ??
                  LinearGradient(
                    colors: [cs.primary, cs.secondary],
                  ),
              backgroundColor: widget.backgroundColor ??
                  cs.outlineVariant.withOpacity(0.3),
            ),
            child: widget.showLabel
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_counterAnimation.value}',
                          style: TextStyle(
                            fontSize: widget.size * 0.22,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        if (widget.label.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: widget.size * 0.1,
                              color: cs.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Gradient gradient;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2,
      false,
      trackPaint,
    );

    // Progress gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      gradientPaint,
    );

    // Glow effect at progress end
    if (progress > 0) {
      final glowAngle = -math.pi / 2 + (math.pi * 2 * progress);
      final glowX = center.dx + radius * math.cos(glowAngle);
      final glowY = center.dy + radius * math.sin(glowAngle);

      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            gradient.colors.last.withOpacity(0.6),
            gradient.colors.last.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(glowX, glowY),
          radius: strokeWidth * 2,
        ))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(glowX, glowY), strokeWidth, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.backgroundColor != backgroundColor;
}
