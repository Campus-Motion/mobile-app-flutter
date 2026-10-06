import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/stat_item.dart';
import 'package:mobile_app/widgets/activity_card.dart';

void main() {
  group('Design System Primitives Tests', () {
    testWidgets('AppCard renders child and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      await tester.tap(find.text('Test Content'));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton renders text and triggers callback', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Save',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.text('Save'));
      expect(pressed, isTrue);
    });

    testWidgets('StatItem renders value, unit, and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatItem(
              value: '12.5',
              unit: 'km',
              label: 'Total Distance',
            ),
          ),
        ),
      );

      expect(find.text('12.5'), findsOneWidget);
      expect(find.text('km'), findsOneWidget);
      expect(find.text('Total Distance'), findsOneWidget);
    });

    testWidgets('ActivityCard renders activity details', (tester) async {
      final sampleActivity = Activity(
        id: 1,
        title: 'Morning Run',
        type: 'run',
        userId: 10,
        isPublic: false,
        duration: 35.0,
        createdAt: DateTime(2026, 4, 15),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: sampleActivity,
            ),
          ),
        ),
      );

      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('35 min'), findsOneWidget);
      expect(find.text('RUN'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });
}
