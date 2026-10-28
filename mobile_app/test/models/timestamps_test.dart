import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/models/event.dart';
import 'package:mobile_app/models/news_item.dart';
import 'package:mobile_app/models/user.dart';

const _utcString = '2026-10-30T17:00:00Z';
final _instant = DateTime.utc(2026, 10, 30, 17);

void _expectLocal(DateTime value) {
  expect(value.isUtc, isFalse);
  expect(value.isAtSameMomentAs(_instant), isTrue);
  expect(value.hour, _instant.toLocal().hour);
}

void main() {
  group('Event', () {
    final json = {
      'id': 1,
      'title': 'Relay run',
      'start_time': _utcString,
      'end_time': '2026-10-30T18:00:00Z',
      'created_at': _utcString,
    };

    test('parses UTC timestamps to local time', () {
      final event = Event.fromJson(json);
      _expectLocal(event.startTime);
      _expectLocal(event.createdAt);
      expect(event.endTime.isUtc, isFalse);
    });

    test('round trip keeps the same instant and sends UTC', () {
      final sent = Event.fromJson(json).toJson();
      expect(sent['start_time'], '2026-10-30T17:00:00.000Z');
      expect(sent['end_time'], '2026-10-30T18:00:00.000Z');

      final reparsed = Event.fromJson(sent);
      _expectLocal(reparsed.startTime);
      expect(
        reparsed.endTime.isAtSameMomentAs(DateTime.utc(2026, 10, 30, 18)),
        isTrue,
      );
    });
  });

  test('NewsItem parses UTC timestamps to local time', () {
    final item = NewsItem.fromJson({
      'published_at': _utcString,
      'created_at': _utcString,
      'updated_at': _utcString,
    });
    _expectLocal(item.publishedAt);
    _expectLocal(item.createdAt);
    _expectLocal(item.updatedAt!);
  });

  test('Activity parses UTC timestamps to local time', () {
    _expectLocal(Activity.fromJson({'created_at': _utcString}).createdAt);
  });

  test('User parses UTC timestamps to local time and sends UTC', () {
    final user = User.fromJson({'created_at': _utcString});
    _expectLocal(user.createdAt);
    expect(user.toJson()['created_at'], '2026-10-30T17:00:00.000Z');
  });
}
