import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/widgets/k_bottom_nav_dock.dart';
import 'package:smart_waste_app/core/widgets/k_card.dart';
import 'package:smart_waste_app/core/widgets/k_chip.dart';
import 'package:smart_waste_app/core/widgets/k_icon_circle.dart';

void main() {
  testWidgets('KCard renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KCard(child: Text('Hello')),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('KCard triggers onTap when provided', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KCard(
            onTap: () => tapped = true,
            child: const Text('Tap'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('KChip shows label and responds to taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KChip(
            label: 'Chip',
            selected: false,
            showDot: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Chip'), findsOneWidget);
    await tester.tap(find.text('Chip'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('KIconCircle shows the configured icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KIconCircle(icon: Icons.camera_alt_outlined),
        ),
      ),
    );

    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
  });

  testWidgets('KBottomNavDock reacts to taps', (tester) async {
    int? selectedIndex;
    var fabTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: KBottomNavDock(
            currentIndex: 0,
            onIndexChanged: (value) => selectedIndex = value,
            onFabTap: () => fabTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Schedule'));
    await tester.pump();
    expect(selectedIndex, 1);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(fabTapped, isTrue);
  });
}
