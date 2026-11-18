<<<<<<< Updated upstream
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/heatmap.dart';
import 'package:mobile_app/screens/app/heatmap/index.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/heatmap_view.dart';
import 'package:mobile_app/widgets/loading_state.dart';

void main() {
  setUp(() => ApiService.mockMode = true);
  tearDown(() => ApiService.mockMode = false);

  testWidgets(
    'loading then empty explains missing GPS without repeated requests',
    (tester) async {
      final result = Completer<HeatmapData?>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: HeatmapScreen(
            loadHeatmap: () {
              calls++;
              return result.future;
=======
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
>>>>>>> Stashed changes
            },
          ),
        ),
      );
<<<<<<< Updated upstream
      expect(find.byType(LoadingState), findsOneWidget);
      result.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('No GPS routes yet'), findsOneWidget);
      expect(calls, 1);
    },
  );

  testWidgets('error hides raw details and retry renders the heatmap', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HeatmapScreen(
          loadHeatmap: () {
            if (calls++ == 0) {
              return Future.error(Exception('private GPS details'));
            }
            return ActivityService().getHeatmap();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.textContaining('private GPS details'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(HeatmapView), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('leaving during loading does not update a disposed screen', (
    tester,
  ) async {
    final result = Completer<HeatmapData?>();
    await tester.pumpWidget(
      MaterialApp(home: HeatmapScreen(loadHeatmap: () => result.future)),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    result.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
=======
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
>>>>>>> Stashed changes
  });
}
