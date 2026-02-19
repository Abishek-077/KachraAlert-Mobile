import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/app_motion.dart';
import '../motion/motion_profile.dart';

enum PressHaptic {
  none,
  selection,
  light,
  medium,
  heavy,
}

class KPressable extends StatefulWidget {
  const KPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.overlayColor,
    this.glowColor,
    this.pressedScale = 0.98,
    this.haptic = PressHaptic.light,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final BorderRadius borderRadius;
  final Color? overlayColor;
  final Color? glowColor;
  final double pressedScale;
  final PressHaptic haptic;

  @override
  State<KPressable> createState() => _KPressableState();
}

class _KPressableState extends State<KPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  MotionProfile? _lastProfile;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.quick,
      reverseDuration: AppMotion.quick,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _hapticFeedback(MotionProfile profile) async {
    if (!profile.hapticsEnabled) return;
    switch (widget.haptic) {
      case PressHaptic.none:
        return;
      case PressHaptic.selection:
        await HapticFeedback.selectionClick();
        return;
      case PressHaptic.light:
        await HapticFeedback.lightImpact();
        return;
      case PressHaptic.medium:
        await HapticFeedback.mediumImpact();
        return;
      case PressHaptic.heavy:
        await HapticFeedback.heavyImpact();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.motionProfile;
    if (_lastProfile != profile) {
      _lastProfile = profile;
      _controller.duration = AppMotion.scaled(profile, AppMotion.quick);
      _controller.reverseDuration = AppMotion.scaled(profile, AppMotion.quick);
      if (profile.reduceMotion && _controller.value != 0) {
        _controller.value = 0;
      }
    }

    final glow = widget.glowColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.18);

    final enableAnimations = !profile.reduceMotion && widget.enabled;
    final effectiveScale =
        enableAnimations ? _scale : const AlwaysStoppedAnimation<double>(1.0);
    final enabled =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);

    return AnimatedBuilder(
      animation: effectiveScale,
      builder: (context, child) {
        final pressed = enableAnimations && _controller.value > 0;
        return Transform.scale(
          scale: effectiveScale.value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: pressed
                  ? [
                      BoxShadow(
                        color: glow,
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          overlayColor: WidgetStatePropertyAll(
            widget.overlayColor ??
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          ),
          onTap: enabled
              ? () async {
                  await _hapticFeedback(profile);
                  widget.onTap?.call();
                }
              : null,
          onLongPress: enabled
              ? () async {
                  await _hapticFeedback(profile);
                  widget.onLongPress?.call();
                }
              : null,
          onTapDown:
              enabled && enableAnimations ? (_) => _controller.forward() : null,
          onTapUp:
              enabled && enableAnimations ? (_) => _controller.reverse() : null,
          onTapCancel: enabled && enableAnimations ? _controller.reverse : null,
          child: widget.child,
        ),
      ),
    );
  }
}
