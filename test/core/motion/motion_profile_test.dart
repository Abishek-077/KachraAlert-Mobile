import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/motion/motion_profile.dart';

void main() {
  test('resolve uses settings preference when system animations are enabled',
      () {
    final profile = MotionProfile.resolve(
      reduceMotionPreference: true,
      hapticsEnabledPreference: true,
      disableAnimations: false,
    );

    expect(profile.reduceMotion, isTrue);
    expect(profile.durationScale, 0.55);
    expect(profile.hapticsEnabled, isTrue);
  });

  test('resolve prioritizes system disable animations', () {
    final profile = MotionProfile.resolve(
      reduceMotionPreference: false,
      hapticsEnabledPreference: false,
      disableAnimations: true,
    );

    expect(profile.reduceMotion, isTrue);
    expect(profile.durationScale, 0.55);
    expect(profile.hapticsEnabled, isFalse);
  });

  test('scaleMs applies duration scale', () {
    const profile = MotionProfile(
      reduceMotion: false,
      durationScale: 1.0,
      hapticsEnabled: true,
    );

    expect(profile.scaleMs(320), const Duration(milliseconds: 320));

    const reduced = MotionProfile(
      reduceMotion: true,
      durationScale: 0.55,
      hapticsEnabled: true,
    );
    expect(reduced.scaleMs(320), const Duration(milliseconds: 176));
  });
}
