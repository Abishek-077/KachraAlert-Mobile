import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium button with multiple states and animations
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
    this.success = false,
    this.enabled = true,
    this.gradient,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool loading;
  final bool success;
  final bool enabled;
  final Gradient? gradient;
  final IconData? icon;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _scaleController;
  late AnimationController _successController;
  
  late Animation<double> _shimmerAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(PremiumButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.loading && !oldWidget.loading) {
      _shimmerController.repeat();
    } else if (!widget.loading && oldWidget.loading) {
      _shimmerController.stop();
    }

    if (widget.success && !oldWidget.success) {
      _successController.forward();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scaleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.loading && !widget.success) {
      _scaleController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradient = widget.gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.success
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [cs.primary, cs.primary.withOpacity(0.8)],
        );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _successAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.success
                ? (1.0 + _successAnimation.value * 0.1)
                : _scaleAnimation.value,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: gradient,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.success
                              ? const Color(0xFF10B981)
                              : cs.primary)
                          .withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: widget.success ? 2 : 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.enabled && !widget.loading && !widget.success
                        ? widget.onPressed
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Shimmer overlay when loading
                        if (widget.loading)
                          AnimatedBuilder(
                            animation: _shimmerAnimation,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: const [
                                      Colors.transparent,
                                      Colors.white24,
                                      Colors.transparent,
                                    ],
                                    stops: [
                                      (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                                      _shimmerAnimation.value.clamp(0.0, 1.0),
                                      (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
                                    ],
                                  ).createShader(bounds);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        // Content
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: widget.success
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 28,
                                )
                              : widget.loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (widget.icon != null) ...[
                                          Icon(
                                            widget.icon,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          widget.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
