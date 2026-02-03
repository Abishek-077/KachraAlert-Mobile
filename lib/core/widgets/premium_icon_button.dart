import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium icon button with gradient backgrounds and animations
class PremiumIconButton extends StatefulWidget {
  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.size = 48,
    this.iconSize = 24,
    this.backgroundColor,
    this.foregroundColor,
    this.hasPulse = false,
    this.hasGlow = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool hasPulse;
  final bool hasGlow;
  final String? tooltip;

  @override
  State<PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<PremiumIconButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.hasPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    if (widget.onPressed != null) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final button = AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        Widget buttonWidget = Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              color: widget.gradient == null
                  ? (widget.backgroundColor ?? cs.primary)
                  : null,
              shape: BoxShape.circle,
              boxShadow: widget.hasGlow
                  ? [
                      BoxShadow(
                        color: (widget.backgroundColor ?? cs.primary)
                            .withOpacity(0.4),
                        blurRadius: 16 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.foregroundColor ?? cs.onPrimary,
            ),
          ),
        );

        // Add pulse ring if enabled
        if (widget.hasPulse) {
          buttonWidget = Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Opacity(
                opacity: 1 - (_pulseAnimation.value - 1) / 0.3,
                child: Container(
                  width: widget.size * _pulseAnimation.value,
                  height: widget.size * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.backgroundColor ?? cs.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              buttonWidget,
            ],
          );
        }

        return buttonWidget;
      },
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: widget.tooltip != null
          ? Tooltip(
              message: widget.tooltip!,
              child: button,
            )
          : button,
    );
  }
}
