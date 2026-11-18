import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/route_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTrack1 = [
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

  final sampleTrack2 = [
    Waypoint(
      id: 3,
      sequenceOrder: 0,
      latitude: 46.5180,
      longitude: 6.5620,
      recordedAt: DateTime.utc(2026, 11, 11, 8, 0),
    ),
    Waypoint(
      id: 4,
      sequenceOrder: 1,
      latitude: 46.5190,
      longitude: 6.5640,
      recordedAt: DateTime.utc(2026, 11, 11, 8, 6),
    ),
  ];

  group('RouteMap tracks multi-route tests', () {
    testWidgets('shows EmptyState when tracks is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RouteMap(tracks: [])),
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No GPS data'), findsOneWidget);
    });

    testWidgets('renders FlutterMap and polylines when tracks are present', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RouteMap(tracks: [sampleTrack1, sampleTrack2])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.text('© OpenStreetMap'), findsOneWidget);
    });
  });
}
