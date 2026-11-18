import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(find.text('© OpenStreetMap'), findsOneWidget);
    });
  });
}
