import 'package:flutter/material.dart';

class KIconCircle extends StatelessWidget {
  const KIconCircle({
    super.key,
    required this.icon,
    this.size = 48,
    this.iconSize = 22,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = background ?? cs.primary.withOpacity(0.10);
    final fg = foreground ?? cs.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}
