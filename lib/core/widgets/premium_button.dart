import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion/app_motion.dart';
import '../motion/motion_profile.dart';
import '../services/feedback/feedback_service.dart';

/// Premium button with multiple states and animations.
class PremiumButton extends ConsumerStatefulWidget {
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
  ConsumerState<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends ConsumerState<PremiumButton>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _scaleController;
  late final AnimationController _successController;

  late Animation<double> _shimmerAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _successAnimation;
  MotionProfile? _lastProfile;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: AppMotion.hero,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: AppMotion.quick,
      vsync: this,
    );

    _successController = AnimationController(
      duration: AppMotion.long,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.motionProfile;
    if (_lastProfile == profile) return;
    _lastProfile = profile;

    _shimmerController.duration = AppMotion.scaled(profile, AppMotion.hero);
    _scaleController.duration = AppMotion.scaled(profile, AppMotion.quick);
    _successController.duration = AppMotion.scaled(profile, AppMotion.long);

    if (profile.reduceMotion) {
      _shimmerController.stop();
      _shimmerController.value = 0;
      _scaleController.value = 0;
      if (widget.loading) {
        _successController.value = 0;
      }
    } else if (widget.loading) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(PremiumButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final profile = context.motionProfile;

    if (widget.loading && !oldWidget.loading && !profile.reduceMotion) {
      _shimmerController.repeat();
    } else if (!widget.loading && oldWidget.loading) {
      _shimmerController.stop();
      _shimmerController.value = 0;
    }

    if (widget.success && !oldWidget.success) {
      _successController.forward(from: 0);
      ref.read(feedbackServiceProvider).mediumImpact();
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
    final profile = context.motionProfile;
    if (!widget.enabled || widget.loading || widget.success) return;

    if (!profile.reduceMotion) {
      _scaleController.forward();
    }
    ref.read(feedbackServiceProvider).lightImpact();
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
    final profile = context.motionProfile;
    final gradient = widget.gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.success
              ? const [Color(0xFF10B981), Color(0xFF059669)]
              : [cs.primary, cs.primary.withValues(alpha: 0.8)],
        );

    final switchDuration = AppMotion.scaled(profile, AppMotion.short);

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
          final scaleValue = profile.reduceMotion
              ? 1.0
              : (widget.success
                  ? (1.0 + _successAnimation.value * 0.1)
                  : _scaleAnimation.value);
          return Transform.scale(
            scale: scaleValue,
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
                          .withValues(alpha: 0.3),
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
                        if (widget.loading && !profile.reduceMotion)
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
                                      (_shimmerAnimation.value - 1)
                                          .clamp(0.0, 1.0),
                                      _shimmerAnimation.value.clamp(0.0, 1.0),
                                      (_shimmerAnimation.value + 1)
                                          .clamp(0.0, 1.0),
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
                        AnimatedSwitcher(
                          duration: switchDuration,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
