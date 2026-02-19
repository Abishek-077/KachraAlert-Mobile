import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../motion/motion_profile.dart';
import 'delayed_reveal.dart';

class StaggeredRevealList extends StatelessWidget {
  const StaggeredRevealList({
    super.key,
    required this.children,
    this.baseDelayMs = 40,
    this.stepDelayMs = 50,
    this.axis = Axis.vertical,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final List<Widget> children;
  final int baseDelayMs;
  final int stepDelayMs;
  final Axis axis;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final profile = context.motionProfile;
    final widgets = List<Widget>.generate(children.length, (index) {
      final child = children[index];
      return DelayedReveal(
        delay: AppMotion.scaledMs(profile, baseDelayMs + index * stepDelayMs),
        duration: AppMotion.scaled(profile, AppMotion.medium),
        offset: axis == Axis.vertical
            ? const Offset(0, 0.10)
            : const Offset(0.10, 0),
        child: child,
      );
    });

    if (axis == Axis.horizontal) {
      return Row(
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: widgets,
      );
    }

    return Column(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: widgets,
    );
  }
}
