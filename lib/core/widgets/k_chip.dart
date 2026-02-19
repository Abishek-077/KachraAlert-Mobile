import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../motion/motion_profile.dart';
import 'k_pressable.dart';

class KChip extends StatelessWidget {
  const KChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = context.motionProfile;

    final bg = selected ? cs.primary : cs.surface;
    final fg = selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.7);
    final border = cs.outlineVariant.withValues(alpha: 0.4);

    return KPressable(
      borderRadius: BorderRadius.circular(999),
      haptic: PressHaptic.selection,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.scaled(profile, AppMotion.short),
        curve: profile.entryCurve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    cs.primary,
                    cs.primary.withValues(alpha: 0.8),
                    cs.secondary.withValues(alpha: 0.7),
                  ],
                )
              : null,
          color: selected ? null : bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? Colors.transparent : border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    color: cs.primary.withValues(alpha: 0.22),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: selected ? cs.onPrimary : cs.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
