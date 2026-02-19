import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/motion/motion_profile.dart';
import 'package:smart_waste_app/core/widgets/ambient_background.dart';
import 'package:smart_waste_app/core/widgets/delayed_reveal.dart';
import 'package:smart_waste_app/core/widgets/motion_scaffold.dart';

Widget _wrapWithProfile({
  required MotionProfile profile,
  required Widget child,
}) {
  return MaterialApp(
    home: MotionProfileScope(
      profile: profile,
      child: child,
    ),
  );
}

void main() {
  const fullProfile = MotionProfile(
    reduceMotion: false,
    durationScale: 1.0,
    hapticsEnabled: true,
  );

  const reducedProfile = MotionProfile(
    reduceMotion: true,
    durationScale: 0.55,
    hapticsEnabled: true,
  );

  testWidgets('DelayedReveal animates in full-motion mode', (tester) async {
    await tester.pumpWidget(
      _wrapWithProfile(
        profile: fullProfile,
        child: const Scaffold(
          body: DelayedReveal(
            delay: Duration(milliseconds: 100),
            duration: Duration(milliseconds: 200),
            child: Text('hello'),
          ),
        ),
      ),
    );

    final fadeFinder = find.descendant(
      of: find.byType(DelayedReveal),
      matching: find.byType(FadeTransition),
    );
    final initialFade = tester.widget<FadeTransition>(fadeFinder);
    expect(initialFade.opacity.value, equals(0));

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 250));
    final finalFade = tester.widget<FadeTransition>(fadeFinder);
    expect(finalFade.opacity.value, greaterThan(0.95));
  });

  testWidgets('DelayedReveal jumps to visible in reduced-motion mode',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithProfile(
        profile: reducedProfile,
        child: const Scaffold(
          body: DelayedReveal(
            delay: Duration(milliseconds: 100),
            duration: Duration(milliseconds: 200),
            child: Text('hello'),
          ),
        ),
      ),
    );

    final fadeFinder = find.descendant(
      of: find.byType(DelayedReveal),
      matching: find.byType(FadeTransition),
    );
    final fade = tester.widget<FadeTransition>(fadeFinder);
    expect(fade.opacity.value, equals(1));
  });

  testWidgets('MotionScaffold includes ambient background in full mode',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithProfile(
        profile: fullProfile,
        child: const MotionScaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byType(AmbientBackground), findsOneWidget);
  });

  testWidgets('MotionScaffold removes ambient background in reduced mode',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithProfile(
        profile: reducedProfile,
        child: const MotionScaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byType(AmbientBackground), findsNothing);
  });
}
