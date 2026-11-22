import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/route_map.dart';
import '../helpers/fake_tile_provider.dart';

void main() {
  group('RouteMap widget tests', () {
    testWidgets('shows EmptyState when waypoints are empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RouteMap(waypoints: [])),
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No GPS data'), findsOneWidget);
    });

    testWidgets('renders FlutterMap and markers when waypoints are present', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final waypoints = [
        Waypoint(
          id: 1,
          sequenceOrder: 0,
          recordedAt: DateTime.utc(2026, 11, 17, 8, 0),
          latitude: 46.52,
          longitude: 6.57,
        ),
        Waypoint(
          id: 2,
          sequenceOrder: 1,
          recordedAt: DateTime.utc(2026, 11, 17, 8, 10),
          latitude: 46.53,
          longitude: 6.58,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteMap(
              waypoints: waypoints,
              tileProvider: FakeTileProvider(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
      // Dark style is the default
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('© Esri'), findsOneWidget);
      TileLayer currentTileLayer() =>
          tester.widget<TileLayer>(find.byType(TileLayer));
      expect(currentTileLayer().urlTemplate, contains('World_Dark_Gray_Base'));
      expect(find.text('Pace Scale (min/km)'), findsOneWidget);
      expect(find.text('Workout Summary'), findsNothing);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      // Switch to Standard (OpenStreetMap)
      await tester.tap(find.byTooltip('Map style'));
      await tester.pumpAndSettle();
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Satellite'), findsOneWidget);
      await tester.tap(find.text('Standard').last);
      await tester.pumpAndSettle();
      expect(find.text('© OpenStreetMap'), findsOneWidget);
      expect(
        currentTileLayer().urlTemplate,
        contains('tile.openstreetmap.org'),
      );

      // Tap fullscreen button to open phone-sized fullscreen map
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);

      // Switch to Satellite inside fullscreen map
      await tester.tap(find.byTooltip('Map style').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Satellite').last);
      await tester.pumpAndSettle();

      // Tap exit fullscreen button to return to default view and verify style persisted
      await tester.tap(find.byIcon(Icons.fullscreen_exit));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fullscreen_exit), findsNothing);
      expect(find.text('Satellite'), findsOneWidget);
      expect(find.text('© Esri'), findsOneWidget);
      expect(currentTileLayer().urlTemplate, contains('World_Imagery'));
    });

    testWidgets(
      'adapts pace scale dynamically for fast cycling and slow swimming workouts',
      (tester) async {
        // Fast cycling segments (~36 km/h -> ~1:40 min/km) and (~20 km/h -> ~3:00 min/km)
        final cyclingWaypoints = [
          Waypoint(
            id: 1,
            sequenceOrder: 0,
            recordedAt: DateTime.utc(2026, 11, 17, 8, 0, 0),
            latitude: 46.5200,
            longitude: 6.5700,
          ),
          Waypoint(
            id: 2,
            sequenceOrder: 1,
            recordedAt: DateTime.utc(2026, 11, 17, 8, 0, 30),
            latitude: 46.5227,
            longitude: 6.5700,
          ),
          Waypoint(
            id: 3,
            sequenceOrder: 2,
            recordedAt: DateTime.utc(2026, 11, 17, 8, 1, 30),
            latitude: 46.5254,
            longitude: 6.5700,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RouteMap(
                waypoints: cyclingWaypoints,
                activityType: 'cycle',
                tileProvider: FakeTileProvider(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pace Scale (min/km)'), findsOneWidget);
        // Should not be clamped to 3:30
        expect(find.text('3:30'), findsNothing);
      },
    );

    testWidgets(
      'renders raster heatmap overlay and updates when tracks or discipline change',
      (tester) async {
        final track1 = [
          Waypoint(
            id: 1,
            sequenceOrder: 0,
            recordedAt: DateTime.utc(2026, 11, 17, 8, 0, 0),
            latitude: 46.5180,
            longitude: 6.5650,
          ),
          Waypoint(
            id: 2,
            sequenceOrder: 1,
            recordedAt: DateTime.utc(2026, 11, 17, 8, 0, 10),
            latitude: 46.5183,
            longitude: 6.5653,
          ),
          Waypoint(
            id: 3,
            sequenceOrder: 2,
            recordedAt: DateTime.utc(2026, 11, 17, 8, 0, 20),
            latitude: 46.5186,
            longitude: 6.5656,
          ),
        ];
        final track2 = [
          Waypoint(
            id: 4,
            sequenceOrder: 0,
            recordedAt: DateTime.utc(2026, 11, 18, 9, 0, 0),
            latitude: 46.5180,
            longitude: 6.5650,
          ),
          Waypoint(
            id: 5,
            sequenceOrder: 1,
            recordedAt: DateTime.utc(2026, 11, 18, 9, 0, 10),
            latitude: 46.5183,
            longitude: 6.5653,
          ),
          Waypoint(
            id: 6,
            sequenceOrder: 2,
            recordedAt: DateTime.utc(2026, 11, 18, 9, 0, 20),
            latitude: 46.5186,
            longitude: 6.5656,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RouteMap(
                tracks: [track1, track2],
                routeColor: AppColors.activityRun,
                activityType: 'run',
                tileProvider: FakeTileProvider(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OverlayImageLayer), findsOneWidget);
        expect(find.text('Analyzed workouts'), findsOneWidget);
        expect(find.text('2'), findsWidgets);
        expect(find.text('Min intensity'), findsOneWidget);
        expect(find.text('Max intensity'), findsOneWidget);

        // Update discipline to single track to verify didUpdateWidget recomputation
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RouteMap(
                tracks: [track1],
                routeColor: AppColors.activityWalk,
                activityType: 'walk',
                tileProvider: FakeTileProvider(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OverlayImageLayer), findsOneWidget);
        expect(find.text('Analyzed workouts'), findsOneWidget);
      },
    );
  });
}
