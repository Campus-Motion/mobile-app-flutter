import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/activity_type_filter_bar.dart';
import 'package:mobile_app/widgets/activity_type_filter_dropdown.dart';

void main() {
  group('ActivityTypeFilterDropdown widget tests', () {
    testWidgets(
      'opens vertical menu of 6 activity types, toggles multiple selections, and shows active count',
      (tester) async {
        final selected = Set<String>.from(ActivityTypeFilterBar.allTypeKeys);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Align(
                    alignment: Alignment.topRight,
                    child: ActivityTypeFilterDropdown(
                      selectedTypes: selected,
                      onToggle: (key) {
                        setState(() {
                          if (selected.contains(key)) {
                            selected.remove(key);
                          } else {
                            selected.add(key);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Filter'), findsOneWidget);

        await tester.tap(find.text('Filter'));
        await tester.pumpAndSettle();

        expect(find.text('Running'), findsOneWidget);
        expect(find.text('Cycling'), findsOneWidget);
        expect(find.text('Walking'), findsOneWidget);
        expect(find.text('Hiking'), findsOneWidget);
        expect(find.text('Swimming'), findsOneWidget);
        expect(find.text('Other'), findsOneWidget);

        // Sober black checkmarks on white background (no colored Checkbox fill)
        expect(find.byType(Checkbox), findsNothing);
        expect(find.byIcon(Icons.check), findsNWidgets(6));

        // Toggle two types while menu stays open
        await tester.tap(find.text('Running'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cycling'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsNWidgets(4));
        expect(selected.contains('run'), isFalse);
        expect(selected.contains('cycle'), isFalse);
        expect(selected.contains('walk'), isTrue);
        expect(find.text('Filter (4/6)'), findsOneWidget);
      },
    );
  });
}
