import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating action card with 3D transforms and gradient backgrounds
class FloatingActionCard extends StatefulWidget {
  const FloatingActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient,
    this.isEmphasized = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;
  final bool isEmphasized;
  final int badgeCount;

  @override
  State<FloatingActionCard> createState() => _FloatingActionCardState();
}

class _FloatingActionCardState extends State<FloatingActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 12.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                gradient: widget.isEmphasized
                    ? (widget.gradient ??
                        LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                        ))
                    : null,
                color: widget.isEmphasized ? null : cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isEmphasized
                      ? Colors.white.withValues(alpha: 0.2)
                      : cs.outlineVariant.withValues(alpha: 0.5),
                  width: widget.isEmphasized ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isEmphasized
                        ? cs.primary.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: _elevationAnimation.value * 2,
                    offset: Offset(0, _elevationAnimation.value),
                  ),
                  if (widget.isEmphasized)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(-4, -4),
                    ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.isEmphasized
                              ? Colors.white.withValues(alpha: 0.2)
                              : cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.isEmphasized
                              ? Colors.white
                              : cs.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.isEmphasized
                              ? Colors.white
                              : cs.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // Badge
                  if (widget.badgeCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
