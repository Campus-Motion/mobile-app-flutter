import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/sport_type_selector.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('SportTypeSelector', () {
    testWidgets('renders all seven sport pills with labels and icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SportTypeSelector(selectedType: 'run', onSelected: (_) {})),
      );

      for (final type in SportTypeSelector.sportTypes) {
        final label = SportTypeSelector.getSportLabel(type);
        final icon = ActivityCard.getActivityIcon(type);
        expect(find.text(label), findsOneWidget);
        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    testWidgets('invokes onSelected with tapped sport key', (tester) async {
      String? pickedType;

      await tester.pumpWidget(
        _wrap(
          SportTypeSelector(
            selectedType: 'run',
            onSelected: (type) => pickedType = type,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey<String>('sport_pill_cycle')));
      await tester.pump();
      expect(pickedType, 'cycle');

      final climbingPill = find.byKey(
        const ValueKey<String>('sport_pill_climbing'),
      );
      await tester.ensureVisible(climbingPill);
      await tester.pumpAndSettle();
      await tester.tap(climbingPill);
      await tester.pump();
      expect(pickedType, 'climbing');
    });

    testWidgets('does not invoke onSelected when disabled', (tester) async {
      String? pickedType;

      await tester.pumpWidget(
        _wrap(
          SportTypeSelector(
            selectedType: 'run',
            enabled: false,
            onSelected: (type) => pickedType = type,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey<String>('sport_pill_walk')));
      await tester.pump();
      expect(pickedType, isNull);
    });

    testWidgets('every interactive sport pill meets 48x48 minimum tap target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SportTypeSelector(selectedType: 'run', onSelected: (_) {})),
      );

      for (final type in SportTypeSelector.sportTypes) {
        final pillFinder = find.byKey(ValueKey<String>('sport_pill_$type'));
        final size = tester.getSize(pillFinder);
        expect(
          size.width,
          greaterThanOrEqualTo(48.0),
          reason: '$type pill width should be at least 48',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(48.0),
          reason: '$type pill height should be at least 48',
        );
      }
    });
  });
}
