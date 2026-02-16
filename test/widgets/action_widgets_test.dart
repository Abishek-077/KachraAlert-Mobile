import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/widgets/feature_card.dart';
import 'package:smart_waste_app/core/widgets/gradient_button.dart';

void main() {
  group('Action widgets', () {
    testWidgets('GradientButton renders text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(text: 'Continue', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('GradientButton invokes onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(text: 'Submit', onPressed: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('GradientButton shows loader while loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GradientButton(text: 'Send', isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Send'), findsNothing);
    });

    testWidgets('GradientButton ignores taps while loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              text: 'Busy',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GradientButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('GradientButton renders custom icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              text: 'Login',
              icon: const Icon(Icons.login, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('GradientButton uses provided height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(text: 'Size', height: 70, onPressed: () {}),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints, isNull);
      expect(container.height, 70);
    });

    testWidgets('FeatureCard renders label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureCard(icon: Icons.map, label: 'Track'),
          ),
        ),
      );

      expect(find.text('Track'), findsOneWidget);
    });

    testWidgets('FeatureCard renders icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureCard(icon: Icons.notifications, label: 'Alerts'),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('FeatureCard has vertical layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureCard(icon: Icons.home, label: 'Home'),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('FeatureCard supports long labels', (tester) async {
      const longLabel = 'Very long feature label for residents';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureCard(icon: Icons.info, label: longLabel),
          ),
        ),
      );

      expect(find.text(longLabel), findsOneWidget);
    });
  });
}
