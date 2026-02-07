import 'package:flutter/material.dart';

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
    final surface = backgroundColor ?? cs.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      decoration: BoxDecoration(
        gradient: backgroundColor == null && !isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  surface,
                  cs.surfaceVariant.withOpacity(0.45),
                ],
              )
            : null,
        color: backgroundColor ?? surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(isDark ? 0.2 : 0.35),
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                blurRadius: 26,
                spreadRadius: 0,
                offset: const Offset(0, 12),
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
              ),
              if (!isDark)
                BoxShadow(
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(-6, -6),
                  color: Colors.white.withOpacity(0.6),
                ),
            ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
