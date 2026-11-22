import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/mock_data_service.dart';
import 'package:mobile_app/widgets/activity_card.dart';

void main() {
  group('Activity serialization', () {
    test('round-trips duration and distance_km via fromJson and toJson', () {
      final original = {
        'id': 42,
        'title': 'Lakeside Tempo Run',
        'type': 'run',
        'user_id': 1,
        'is_public': true,
        'duration': 42.5,
        'distance_km': 8.4,
        'body': 'Steady tempo along Dorigny.',
        'created_at': '2026-11-16T08:00:00Z',
      };

      final activity = Activity.fromJson(original);
      expect(activity.duration, 42.5);
      expect(activity.distanceKm, 8.4);

      final jsonMap = activity.toJson();
      expect(jsonMap['title'], 'Lakeside Tempo Run');
      expect(jsonMap['type'], 'run');
      expect(jsonMap['body'], 'Steady tempo along Dorigny.');
      expect(jsonMap['duration'], 42.5);
      expect(jsonMap['distance_km'], 8.4);
      expect(jsonMap['is_public'], isTrue);

      final reparsed = Activity.fromJson(jsonMap);
      expect(reparsed.duration, 42.5);
      expect(reparsed.distanceKm, 8.4);
    });

    test('falls back to distance_m / 1000 when distance_km is absent', () {
      final activity = Activity.fromJson({
        'id': 43,
        'title': 'Track Session',
        'type': 'run',
        'user_id': 1,
        'is_public': false,
        'duration': 20.0,
        'distance_m': 5000,
        'created_at': '2026-11-16T08:00:00Z',
      });

      expect(activity.distanceKm, 5.0);
    });

    test(
      'parses legacy payloads without distance_km and omits null fields in toJson',
      () {
        final activity = Activity.fromJson({
          'id': 44,
          'title': 'Legacy Walk',
          'type': 'walk',
          'user_id': 1,
          'is_public': false,
          'created_at': '2026-11-16T08:00:00Z',
        });

        expect(activity.duration, isNull);
        expect(activity.distanceKm, isNull);

        final jsonMap = activity.toJson();
        expect(jsonMap.containsKey('duration'), isFalse);
        expect(jsonMap.containsKey('distance_km'), isFalse);
        expect(jsonMap['is_public'], isFalse);
      },
    );
    test(
      'isTypeLocked, isDurationLocked, and isDistanceLocked reflect FIT status',
      () {
        final manual = Activity(
          id: 1,
          title: 'Manual Run',
          type: 'run',
          userId: 1,
          isPublic: false,
          createdAt: DateTime.now(),
          duration: 30,
          distanceKm: 5,
          hasFit: false,
        );
        expect(manual.isTypeLocked, isFalse);
        expect(manual.isDurationLocked, isFalse);
        expect(manual.isDistanceLocked, isFalse);

        final withFit = Activity(
          id: 2,
          title: 'Fit Run',
          type: 'run',
          userId: 1,
          isPublic: false,
          createdAt: DateTime.now(),
          duration: 35,
          distanceKm: 6.2,
          hasFit: true,
        );
        expect(withFit.isTypeLocked, isTrue);
        expect(withFit.isDurationLocked, isTrue);
        expect(withFit.isDistanceLocked, isTrue);

        final fitOtherNoStats = Activity(
          id: 3,
          title: 'Fit Other',
          type: 'other',
          userId: 1,
          isPublic: false,
          createdAt: DateTime.now(),
          hasFit: true,
        );
        expect(fitOtherNoStats.isTypeLocked, isFalse);
        expect(fitOtherNoStats.isDurationLocked, isFalse);
        expect(fitOtherNoStats.isDistanceLocked, isFalse);
      },
    );
  });

  group('ActivityCard formatting helpers', () {
    test('prefers explicit distanceKm over pace estimate', () {
      final activity = Activity(
        id: 1,
        title: 'Custom Distance Run',
        type: 'run',
        userId: 1,
        isPublic: false,
        duration: 30.0,
        distanceKm: 6.4,
        createdAt: DateTime(2026, 11, 16),
      );

      expect(ActivityCard.getActivityDistanceKm(activity), 6.4);
      expect(ActivityCard.getActivityDistanceString(activity), '6.4 km');
      expect(ActivityCard.getActivityDurationString(activity.duration), '30m');
    });

    test('falls back to pace estimate when distanceKm is null', () {
      final cycle = Activity(
        id: 2,
        title: 'Afternoon Cycle',
        type: 'cycle',
        userId: 1,
        isPublic: false,
        duration: 90.0,
        createdAt: DateTime(2026, 11, 16),
      );

      expect(ActivityCard.getActivityDistanceKm(cycle), 30.0);
      expect(ActivityCard.getActivityDistanceString(cycle), '30.0 km');
      expect(ActivityCard.getActivityDurationString(cycle.duration), '1h 30m');
    });

    test('returns placeholder when both distanceKm and duration are null', () {
      final empty = Activity(
        id: 3,
        title: 'Unrecorded Session',
        type: 'other',
        userId: 1,
        isPublic: false,
        createdAt: DateTime(2026, 11, 16),
      );

      expect(ActivityCard.getActivityDistanceKm(empty), isNull);
      expect(ActivityCard.getActivityDistanceString(empty), '--');
      expect(ActivityCard.getActivityDurationString(empty.duration), '--');
    });
  });

  group('MockDataService and ActivityService persistence', () {
    setUp(() {
      ApiService.mockMode = true;
    });

    tearDown(() {
      ApiService.mockMode = false;
    });

    test('POST /activities persists duration and distance_km', () async {
      final mock = MockDataService();
      final response = mock.handlePost('/activities', {
        'title': 'Measured Trail Run',
        'type': 'run',
        'duration': 38.5,
        'distance_km': 7.1,
        'is_public': false,
      });

      expect(response.statusCode, 201);
      final body = json.decode(response.body) as Map<String, dynamic>;
      expect(body['duration'], 38.5);
      expect(body['distance_km'], 7.1);

      final activities = await ActivityService().getActivities();
      final created = activities.firstWhere((a) => a.id == body['id']);
      expect(created.duration, 38.5);
      expect(created.distanceKm, 7.1);

      final exported = created.toJson();
      expect(exported['duration'], 38.5);
      expect(exported['distance_km'], 7.1);
    });

    test(
      'ActivityService.createActivity round-trips duration and distanceKm',
      () async {
        final created = await ActivityService().createActivity(
          Activity(
            id: 0,
            title: 'Campus Loop',
            type: 'run',
            userId: 1,
            isPublic: false,
            duration: 27.0,
            distanceKm: 4.8,
            createdAt: DateTime.now(),
          ),
        );

        expect(created.duration, 27.0);
        expect(created.distanceKm, 4.8);
        expect(created.isPublic, isFalse);

        final allActivities = await ActivityService().getActivities(limit: 100);
        expect(allActivities, isNotEmpty);
        for (final activity in allActivities) {
          final exported = activity.toJson();
          expect(exported['duration'], isNotNull);
          expect(exported['distance_km'], isNotNull);
        }
      },
    );

    test(
      'POST /activities falls back to distance_m when distance_km omitted',
      () {
        final mock = MockDataService();
        final response = mock.handlePost('/activities', {
          'title': 'Track 5k',
          'type': 'run',
          'duration': 22.0,
          'distance_m': 5000,
        });

        expect(response.statusCode, 201);
        final body = json.decode(response.body) as Map<String, dynamic>;
        expect(body['distance_km'], 5.0);
      },
    );
  });
}
