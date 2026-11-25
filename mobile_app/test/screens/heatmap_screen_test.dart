import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/screens/app/heatmap/index.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/widgets/discipline_stats_card.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/route_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleWaypoints = [
    Waypoint(
      id: 1,
      sequenceOrder: 0,
      latitude: 46.5200,
      longitude: 6.5650,
      altitudeM: 390.0,
      recordedAt: DateTime.utc(2026, 11, 10, 8, 0),
    ),
    Waypoint(
      id: 2,
      sequenceOrder: 1,
      latitude: 46.5220,
      longitude: 6.5680,
      altitudeM: 405.0,
      recordedAt: DateTime.utc(2026, 11, 10, 8, 5),
    ),
  ];

  group('HeatmapScreen widget tests', () {
    testWidgets(
      'renders My Heatmaps & Statistics title, discipline chips, stats, and map',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: HeatmapScreen(loadTracks: (_) async => [sampleWaypoints]),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Heatmaps & Statistics'), findsOneWidget);
        expect(find.text('Running'), findsOneWidget);
        expect(find.text('Cycling'), findsOneWidget);
        expect(find.text('Walking'), findsOneWidget);
        expect(find.text('Hiking'), findsOneWidget);
        expect(find.text('Swimming'), findsOneWidget);
        expect(find.text('Other'), findsOneWidget);
        expect(find.byType(DisciplineStatsCard), findsOneWidget);
        expect(find.text('Total elevation'), findsOneWidget);
        expect(find.text('+15 / -0'), findsOneWidget);
        expect(find.text('Heatmap'), findsOneWidget);
        expect(find.text('Map & Routes'), findsNothing);
        expect(find.byType(RouteMap), findsOneWidget);
      },
    );

    testWidgets('shows EmptyState when discipline has no GPS tracks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: HeatmapScreen(loadTracks: (_) async => [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DisciplineStatsCard), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(
        find.text('No GPS activities recorded for this discipline.'),
        findsOneWidget,
      );
    });

    testWidgets('hides Total elevation when Swimming discipline is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HeatmapScreen(
            loadSummary: (discipline) async => DisciplineSummary(
              activityCount: 3,
              totalDistanceKm: 4.2,
              totalDurationMinutes: 90.0,
              elevationGainLoss: discipline == 'swim' ? null : (50, 50),
              tracks: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total elevation'), findsOneWidget);

      await tester.ensureVisible(find.text('Swimming'));
      await tester.tap(find.text('Swimming'));
      await tester.pumpAndSettle();

      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Total distance'), findsOneWidget);
      expect(find.text('4.2'), findsOneWidget);
      expect(find.text('Total time'), findsOneWidget);
      expect(find.text('1h 30m'), findsOneWidget);
      expect(find.text('Total elevation'), findsNothing);
    });

    testWidgets(
      'shows only activity count for Other discipline and excludes heatmap',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: HeatmapScreen(
              loadSummary: (discipline) async => DisciplineSummary(
                activityCount: discipline == 'other' ? 6 : 1,
                totalDistanceKm: 10.0,
                totalDurationMinutes: 45.0,
                elevationGainLoss: (50, 50),
                tracks: discipline == 'other' ? const [] : [sampleWaypoints],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Other'));
        await tester.tap(find.text('Other'));
        await tester.pumpAndSettle();

        expect(find.text('Activities'), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
        expect(find.text('Total distance'), findsNothing);
        expect(find.text('Total time'), findsNothing);
        expect(find.text('Total elevation'), findsNothing);
        expect(find.text('Heatmap'), findsOneWidget);
        expect(find.text('No heatmap for Other'), findsOneWidget);
      },
    );

    testWidgets(
      'displays higher activityCount than analyzed workouts when .fit files are missing',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: HeatmapScreen(
              loadSummary: (_) async => DisciplineSummary(
                activityCount: 4,
                totalDistanceKm: 22.5,
                totalDurationMinutes: 125.0,
                elevationGainLoss: (15, 0),
                tracks: [sampleWaypoints],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('4'), findsOneWidget);
        expect(find.text('22.5'), findsOneWidget);
        expect(find.text('2h 5m'), findsOneWidget);
        expect(
          find.text('1 of 4 activities include GPS (.fit) data.'),
          findsOneWidget,
        );
        expect(find.text('Analyzed workouts'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('switching discipline chip triggers new tracks load', (
      tester,
    ) async {
      String loadedDiscipline = '';
      await tester.pumpWidget(
        MaterialApp(
          home: HeatmapScreen(
            loadTracks: (discipline) async {
              loadedDiscipline = discipline;
              if (discipline == 'cycle') {
                return [sampleWaypoints];
              }
              return [];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(loadedDiscipline, 'run');

      await tester.tap(find.text('Cycling'));
      await tester.pumpAndSettle();

      expect(loadedDiscipline, 'cycle');
      expect(find.byType(RouteMap), findsOneWidget);
    });

    testWidgets('shows ErrorState on failure and retries when tapped', (
      tester,
    ) async {
      int attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: HeatmapScreen(
            loadTracks: (_) async {
              attempts++;
              if (attempts == 1) {
                throw Exception('Network error');
              }
              return [sampleWaypoints];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Unable to load heatmap.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(RouteMap), findsOneWidget);
      expect(attempts, 2);
    });
  });
}
