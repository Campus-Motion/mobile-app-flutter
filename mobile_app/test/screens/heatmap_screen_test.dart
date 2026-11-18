import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/screens/app/heatmap/index.dart';
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
      recordedAt: DateTime.utc(2026, 11, 10, 8, 0),
    ),
    Waypoint(
      id: 2,
      sequenceOrder: 1,
      latitude: 46.5220,
      longitude: 6.5680,
      recordedAt: DateTime.utc(2026, 11, 10, 8, 5),
    ),
  ];

  group('HeatmapScreen widget tests', () {
    testWidgets('renders title, subtitle, and 4 discipline filter chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HeatmapScreen(loadTracks: (_) async => [sampleWaypoints]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mes Heatmaps'), findsOneWidget);
      expect(find.text('Course à pied'), findsOneWidget);
      expect(find.text('Cyclisme'), findsOneWidget);
      expect(find.text('Marche'), findsOneWidget);
      expect(find.text('Randonnée'), findsOneWidget);
      expect(find.byType(RouteMap), findsOneWidget);
    });

    testWidgets('shows EmptyState when discipline has no GPS tracks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: HeatmapScreen(loadTracks: (_) async => [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(
        find.text('Aucune sortie GPS enregistrée pour cette discipline.'),
        findsOneWidget,
      );
    });

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

      // Tap 'Cyclisme'
      await tester.tap(find.text('Cyclisme'));
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
      expect(find.text('Impossible de charger la heatmap.'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(RouteMap), findsOneWidget);
      expect(attempts, 2);
    });
  });
}
