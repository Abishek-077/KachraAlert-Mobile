import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../extensions/async_value_extensions.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';
import 'app_motion.dart';

@immutable
class MotionProfile {
  const MotionProfile({
    required this.reduceMotion,
    required this.durationScale,
    required this.hapticsEnabled,
  });

  final bool reduceMotion;
  final double durationScale;
  final bool hapticsEnabled;

  Duration scaleMs(int milliseconds) {
    return Duration(
      milliseconds: (milliseconds * durationScale).round().clamp(1, 99999),
    );
  }

  Curve get entryCurve => AppMotion.entryCurve;
  Curve get exitCurve => AppMotion.exitCurve;
  Curve get emphasisCurve => AppMotion.emphasisCurve;

  static MotionProfile resolve({
    required bool reduceMotionPreference,
    required bool hapticsEnabledPreference,
    required bool disableAnimations,
  }) {
    final reduceMotion = reduceMotionPreference || disableAnimations;
    return MotionProfile(
      reduceMotion: reduceMotion,
      durationScale: reduceMotion ? 0.55 : 1.0,
      hapticsEnabled: hapticsEnabledPreference,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MotionProfile &&
        other.reduceMotion == reduceMotion &&
        other.durationScale == durationScale &&
        other.hapticsEnabled == hapticsEnabled;
  }

  @override
  int get hashCode => Object.hash(reduceMotion, durationScale, hapticsEnabled);
}

final motionPreferenceProvider = Provider<MotionProfile>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  return MotionProfile(
    reduceMotion: settings?.reduceMotion ?? false,
    durationScale: (settings?.reduceMotion ?? false) ? 0.55 : 1.0,
    hapticsEnabled: settings?.hapticsEnabled ?? true,
  );
});

class MotionProfileScope extends InheritedWidget {
  const MotionProfileScope({
    super.key,
    required this.profile,
    required super.child,
  });

  final MotionProfile profile;

  static MotionProfile of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<MotionProfileScope>();
    return scope?.profile ??
        const MotionProfile(
          reduceMotion: false,
          durationScale: 1.0,
          hapticsEnabled: true,
        );
  }

  @override
  bool updateShouldNotify(MotionProfileScope oldWidget) {
    return oldWidget.profile != profile;
  }
}

extension MotionProfileX on BuildContext {
  MotionProfile get motionProfile => MotionProfileScope.of(this);
}
