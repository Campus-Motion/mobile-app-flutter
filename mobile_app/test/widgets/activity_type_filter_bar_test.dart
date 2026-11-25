import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/activity_type_filter_bar.dart';

void main() {
  group('ActivityTypeFilterBar & sport color tests', () {
    test('sport colors match cycle purple, swim blue, and other grey', () {
      expect(ActivityCard.getActivityColor('cycle'), AppColors.activityCycle);
      expect(AppColors.activityCycle, Colors.purple);
      expect(ActivityCard.getActivityColor('swim'), AppColors.activitySwim);
      expect(AppColors.activitySwim, Colors.blue);
      expect(ActivityCard.getActivityColor('other'), AppColors.activityDefault);
      expect(AppColors.activityDefault, const Color(0xFF757575));
    });

    test('normalizeType maps unknown values to other', () {
      expect(ActivityTypeFilterBar.normalizeType('RUN'), 'run');
      expect(ActivityTypeFilterBar.normalizeType('swim'), 'swim');
      expect(ActivityTypeFilterBar.normalizeType('climbing'), 'other');
      expect(ActivityTypeFilterBar.normalizeType(''), 'other');
    });

    testWidgets(
      'renders all 6 chips, toggles multiple selections, and survives 320px width',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final selected = Set<String>.from(ActivityTypeFilterBar.allTypeKeys);
        String? lastToggled;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return ActivityTypeFilterBar(
                    selectedTypes: selected,
                    onToggle: (key) {
                      setState(() {
                        lastToggled = key;
                        if (selected.contains(key)) {
                          selected.remove(key);
                        } else {
                          selected.add(key);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );

        expect(find.byType(FilterChip), findsNWidgets(6));
        for (final chip in tester.widgetList<FilterChip>(
          find.byType(FilterChip),
        )) {
          expect(chip.selected, isTrue);
          expect(chip.showCheckmark, isTrue);
        }

        await tester.tap(find.text('Running'));
        await tester.pumpAndSettle();

        expect(lastToggled, 'run');
        expect(selected.contains('run'), isFalse);
        expect(selected.contains('cycle'), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
