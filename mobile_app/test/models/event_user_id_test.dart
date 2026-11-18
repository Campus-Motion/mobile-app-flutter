import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/event.dart';

void main() {
  group('Event user_id / organizer tests', () {
    test('parses user_id from json', () {
      final event = Event.fromJson({
        'id': 104,
        'title': 'Campus 5k',
        'body': 'Fun run',
        'start_time': '2026-11-10T10:00:00Z',
        'end_time': '2026-11-10T11:00:00Z',
        'distance_m': 5000.0,
        'participant_count': 12,
        'created_at': '2026-11-01T10:00:00Z',
        'user_id': 42,
      });

      expect(event.userId, 42);
      expect(event.toJson()['user_id'], 42);
    });

    test('handles missing user_id safely', () {
      final event = Event.fromJson({
        'id': 105,
        'title': 'Open Ride',
        'body': 'Cycling',
        'start_time': '2026-11-10T10:00:00Z',
        'end_time': '2026-11-10T11:00:00Z',
        'participant_count': 3,
        'created_at': '2026-11-01T10:00:00Z',
      });

      expect(event.userId, isNull);
      expect(event.toJson().containsKey('user_id'), isFalse);
    });
  });
}
