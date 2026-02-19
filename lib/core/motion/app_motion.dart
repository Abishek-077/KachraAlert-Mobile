import 'package:flutter/material.dart';

import 'motion_profile.dart';

class AppMotion {
  AppMotion._();

  static const Duration quick = Duration(milliseconds: 140);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration long = Duration(milliseconds: 520);
  static const Duration hero = Duration(milliseconds: 800);

  static const Curve entryCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve emphasisCurve = Curves.easeOutBack;

  static Duration scaled(MotionProfile profile, Duration duration) {
    return Duration(
      milliseconds: (duration.inMilliseconds * profile.durationScale)
          .round()
          .clamp(1, 99999),
    );
  }

  static Duration scaledMs(MotionProfile profile, int milliseconds) {
    return profile.scaleMs(milliseconds);
  }
}
