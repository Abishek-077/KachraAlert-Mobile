import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../motion/motion_profile.dart';
import 'k_pressable.dart';

/// A premium soft card used across the app.
/// Matches the rounded, low-elevation look in the reference UI.
class KCard extends StatelessWidget {
  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.backgroundColor,
    this.boxShadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = context.motionProfile;
    final surface = backgroundColor ?? cs.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = AnimatedContainer(
      duration: AppMotion.scaled(profile, AppMotion.short),
      curve: profile.entryCurve,
      decoration: BoxDecoration(
        gradient: backgroundColor == null && !isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  surface,
                  cs.surfaceVariant.withValues(alpha: 0.45),
                ],
              )
            : null,
        color: backgroundColor ?? surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.35),
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                blurRadius: 26,
                spreadRadius: 0,
                offset: const Offset(0, 12),
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              ),
              if (!isDark)
                BoxShadow(
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(-6, -6),
                  color: Colors.white.withValues(alpha: 0.6),
                ),
            ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return KPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      haptic: PressHaptic.light,
      child: card,
    );
  }
}
