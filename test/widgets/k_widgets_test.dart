import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/motion/motion_profile.dart';
import 'package:smart_waste_app/core/services/feedback/feedback_service.dart';
import 'package:smart_waste_app/core/widgets/k_bottom_nav_dock.dart';
import 'package:smart_waste_app/core/widgets/k_card.dart';
import 'package:smart_waste_app/core/widgets/k_chip.dart';
import 'package:smart_waste_app/core/widgets/k_icon_circle.dart';

void main() {
  const testMotionProfile = MotionProfile(
    reduceMotion: false,
    durationScale: 1.0,
    hapticsEnabled: false,
  );

  testWidgets('KCard renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MotionProfileScope(
          profile: testMotionProfile,
          child: Scaffold(
            body: KCard(child: Text('Hello')),
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('KCard triggers onTap when provided', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MotionProfileScope(
          profile: testMotionProfile,
          child: Scaffold(
            body: KCard(
              onTap: () => tapped = true,
              child: const Text('Tap'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('KChip shows label and responds to taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MotionProfileScope(
          profile: testMotionProfile,
          child: Scaffold(
            body: KChip(
              label: 'Chip',
              selected: false,
              showDot: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Chip'), findsOneWidget);
    await tester.tap(find.text('Chip'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('KIconCircle shows the configured icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MotionProfileScope(
          profile: testMotionProfile,
          child: Scaffold(
            body: KIconCircle(icon: Icons.camera_alt_outlined),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
  });

  testWidgets('KBottomNavDock reacts to icon taps and home long press',
      (tester) async {
    int? selectedIndex;
    var fabTapped = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedbackServiceProvider
              .overrideWithValue(const FeedbackService(enabled: false)),
        ],
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: KBottomNavDock(
              currentIndex: 0,
              onIndexChanged: (value) => selectedIndex = value,
              onFabTap: () => fabTapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump();
    expect(selectedIndex, 1);

    await tester.longPress(find.byIcon(Icons.home_rounded));
    await tester.pump();
    expect(fabTapped, isTrue);
  });
}
