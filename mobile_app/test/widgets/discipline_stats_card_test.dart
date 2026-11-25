import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/discipline_stats_card.dart';

void main() {
  group('DisciplineStatsCard widget tests', () {
    testWidgets(
      'renders 4 stats including elevation when showElevation is true',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DisciplineStatsCard(
                activityCount: 5,
                totalDistanceKm: 32.4,
                totalDurationMinutes: 185.0,
                elevationGainLoss: (420, 410),
                showElevation: true,
                accentColor: AppColors.activityRun,
                analyzedCount: 5,
              ),
            ),
          ),
        );

        expect(find.text('Activities'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('Total distance'), findsOneWidget);
        expect(find.text('32.4'), findsOneWidget);
        expect(find.text('km'), findsOneWidget);
        expect(find.text('Total time'), findsOneWidget);
        expect(find.text('3h 5m'), findsOneWidget);
        expect(find.text('Total elevation'), findsOneWidget);
        expect(find.text('+420 / -410'), findsOneWidget);
        expect(find.text('m'), findsOneWidget);
        expect(find.textContaining('GPS (.fit) data'), findsNothing);
      },
    );

    testWidgets('hides elevation when showElevation is false (swimming)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisciplineStatsCard(
              activityCount: 3,
              totalDistanceKm: 4.5,
              totalDurationMinutes: 95.0,
              elevationGainLoss: (10, 10),
              showElevation: false,
              accentColor: AppColors.activitySwim,
            ),
          ),
        ),
      );

      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Total distance'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('Total time'), findsOneWidget);
      expect(find.text('1h 35m'), findsOneWidget);
      expect(find.text('Total elevation'), findsNothing);
    });

    testWidgets(
      'shows GPS (.fit) coverage note when activityCount exceeds analyzedCount and survives 320px width',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DisciplineStatsCard(
                activityCount: 4,
                totalDistanceKm: 18.0,
                totalDurationMinutes: 110.0,
                elevationGainLoss: null,
                showElevation: true,
                analyzedCount: 2,
              ),
            ),
          ),
        );

        expect(find.text('4'), findsOneWidget);
        expect(find.text('--'), findsOneWidget);
        expect(
          find.text('2 of 4 activities include GPS (.fit) data.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows only activity count when showCountOnly is true (Other)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DisciplineStatsCard(
                activityCount: 7,
                totalDistanceKm: 12.0,
                totalDurationMinutes: 60.0,
                elevationGainLoss: (100, 100),
                showCountOnly: true,
                accentColor: AppColors.activityDefault,
                analyzedCount: 0,
              ),
            ),
          ),
        );

        expect(find.text('Activities'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(find.text('Total distance'), findsNothing);
        expect(find.text('Total time'), findsNothing);
        expect(find.text('Total elevation'), findsNothing);
        expect(find.textContaining('GPS (.fit) data'), findsNothing);
      },
    );
  });
}
