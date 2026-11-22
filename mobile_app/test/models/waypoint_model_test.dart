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
  });
}
