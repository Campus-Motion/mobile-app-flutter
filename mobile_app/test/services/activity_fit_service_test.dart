import 'dart:convert';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => ApiService.mockMode = false);
  tearDown(() async {
    ApiService.mockMode = false;
    await ApiService().clearToken();
  });

  group('ActivityService FIT import & discipline tracks', () {
    test('importFit throws exception if bytes are empty', () async {
      await expectLater(
        ActivityService().importFit([]),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'importFit sends multipart request and parses created activity',
      () async {
        await ApiService().setToken('test-token-123');
        final result = await http.runWithClient(
          () => ActivityService().importFit([0x0E, 0x10, 0x47]),
          () => MockClient((request) async {
            expect(request.url.path, '/activities/import-fit');
            expect(request.headers['Authorization'], 'Bearer test-token-123');
            expect(
              request.headers['content-type'],
              startsWith('multipart/form-data;'),
            );
            return http.Response(
              json.encode({
                'id': 301,
                'user_id': 1,
                'title': 'Imported FIT activity',
                'type': 'other',
                'duration': 40.0,
                'distance_km': 5.0,
                'is_public': false,
                'created_at': '2026-11-17T12:00:00Z',
              }),
              201,
            );
          }),
        );

        expect(result.id, 301);
        expect(result.title, 'Imported FIT activity');
        expect(result.type, 'other');
        expect(result.duration, 40.0);
      },
    );

    test('importFit works seamlessly in mockMode offline', () async {
      ApiService.mockMode = true;
      final beforeCount = (await ActivityService().getActivities()).length;

      final activity = await ActivityService().importFit([
        1,
        2,
        3,
        4,
        5,
      ], filename: 'my_run.fit');

      expect(activity.id, greaterThan(200));
      expect(activity.title, 'Imported FIT activity');
      expect(activity.type, 'other');

      // Check waypoints were populated in mock mode
      final waypoints = await ActivityService().getWaypoints(activity.id);
      expect(waypoints, isNotEmpty);

      final afterCount = (await ActivityService().getActivities()).length;
      expect(afterCount, beforeCount + 1);
    });

    test('getDisciplineTracks excludes "other" discipline', () async {
      ApiService.mockMode = true;
      final tracks = await ActivityService().getDisciplineTracks('other');
      expect(tracks, isEmpty);
    });

    test('getDisciplineTracks returns valid tracks with length >= 2', () async {
      ApiService.mockMode = true;
      final runTracks = await ActivityService().getDisciplineTracks('run');
      expect(runTracks, isNotEmpty);
      for (final track in runTracks) {
        expect(track.length, greaterThanOrEqualTo(2));
        expect(track.first, isA<Waypoint>());
      }
    });

    test('importFitFile rejects non-.fit files', () async {
      final badFile = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'test.gpx',
        path: 'test.gpx',
      );
      await expectLater(
        ActivityService().importFitFile(badFile),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Veuillez sélectionner un fichier .fit'),
          ),
        ),
      );
    });

    test('importFitFile imports valid XFile ending in .fit', () async {
      ApiService.mockMode = true;
      final file = XFile.fromData(
        Uint8List.fromList([1, 2, 3, 4]),
        name: 'track.FIT',
        path: 'track.FIT',
      );
      final activity = await ActivityService().importFitFile(file);
      expect(activity.id, greaterThan(200));
    });
  });
}
