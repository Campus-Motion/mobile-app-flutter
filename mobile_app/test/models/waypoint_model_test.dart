import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/waypoint.dart';

void main() {
  group('Waypoint Model Tests', () {
    test('parses full JSON correctly', () {
      final json = {
        'id': 42,
        'sequence_order': 3,
        'latitude': '46.5197',
        'longitude': 6.6323,
        'altitude_m': 395.5,
        'recorded_at': '2026-03-26T08:01:00Z',
      };

      final wp = Waypoint.fromJson(json);

      expect(wp.id, 42);
      expect(wp.sequenceOrder, 3);
      expect(wp.latitude, closeTo(46.5197, 0.0001));
      expect(wp.longitude, closeTo(6.6323, 0.0001));
      expect(wp.altitudeM, closeTo(395.5, 0.01));
      expect(
        wp.recordedAt.isUtc ? wp.recordedAt : wp.recordedAt.toUtc(),
        DateTime.parse('2026-03-26T08:01:00Z'),
      );
    });

    test('handles missing or null optional fields safely', () {
      final json = <String, dynamic>{};
      final wp = Waypoint.fromJson(json);

      expect(wp.id, 0);
      expect(wp.sequenceOrder, 0);
      expect(wp.latitude, 0.0);
      expect(wp.longitude, 0.0);
      expect(wp.altitudeM, isNull);
      expect(wp.recordedAt, isNotNull);
    });

    test('toJson round-trips correctly', () {
      final wp = Waypoint(
        id: 10,
        sequenceOrder: 1,
        recordedAt: DateTime.utc(2026, 11, 17, 10, 30),
        latitude: 46.52,
        longitude: 6.57,
        altitudeM: 400.0,
      );

      final json = wp.toJson();

      expect(json['id'], 10);
      expect(json['sequence_order'], 1);
      expect(json['latitude'], 46.52);
      expect(json['longitude'], 6.57);
      expect(json['altitude_m'], 400.0);
      expect(json['recorded_at'], '2026-11-17T10:30:00.000Z');
    });

    test('calculateTotalElevationGainLoss sums per-track gain and loss', () {
      final track1 = [
        Waypoint(
          id: 1,
          sequenceOrder: 0,
          recordedAt: DateTime.utc(2026, 11, 17, 8, 0),
          latitude: 46.520,
          longitude: 6.565,
          altitudeM: 400.0,
        ),
        Waypoint(
          id: 2,
          sequenceOrder: 1,
          recordedAt: DateTime.utc(2026, 11, 17, 8, 5),
          latitude: 46.521,
          longitude: 6.566,
          altitudeM: 415.0,
        ),
        Waypoint(
          id: 3,
          sequenceOrder: 2,
          recordedAt: DateTime.utc(2026, 11, 17, 8, 10),
          latitude: 46.522,
          longitude: 6.567,
          altitudeM: 410.0,
        ),
      ];
      final track2 = [
        Waypoint(
          id: 4,
          sequenceOrder: 0,
          recordedAt: DateTime.utc(2026, 11, 18, 9, 0),
          latitude: 46.530,
          longitude: 6.570,
          altitudeM: 500.0,
        ),
        Waypoint(
          id: 5,
          sequenceOrder: 1,
          recordedAt: DateTime.utc(2026, 11, 18, 9, 10),
          latitude: 46.532,
          longitude: 6.572,
          altitudeM: 525.0,
        ),
      ];

      expect(Waypoint.calculateElevationGainLoss(track1), (15, 5));
      expect(Waypoint.calculateTotalElevationGainLoss([track1, track2]), (
        40,
        5,
      ));
      expect(Waypoint.calculateTotalElevationGainLoss(const []), isNull);
      expect(Waypoint.trackDistanceKm(track1), greaterThan(0.2));
    });
  });
}
