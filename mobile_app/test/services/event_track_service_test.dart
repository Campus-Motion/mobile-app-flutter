import 'dart:convert';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/event_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => ApiService.mockMode = false);
  tearDown(() async {
    ApiService.mockMode = false;
    await ApiService().clearToken();
  });

  group('EventService GPS track and participant distribution', () {
    test('addEventTrack throws exception if bytes are empty', () async {
      await expectLater(
        EventService().addEventTrack(104, []),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'addEventTrack sends multipart request and returns parsed waypoints',
      () async {
        await ApiService().setToken('test-token-456');
        final result = await http.runWithClient(
          () => EventService().addEventTrack(104, [0x0E, 0x10]),
          () => MockClient((request) async {
            expect(request.url.path, '/events/104/import-fit');
            expect(request.headers['Authorization'], 'Bearer test-token-456');
            return http.Response(
              json.encode({
                'inserted': 2,
                'waypoints': [
                  {
                    'id': 10,
                    'sequence_order': 0,
                    'latitude': 46.52,
                    'longitude': 6.57,
                    'altitude_m': 400.0,
                    'recorded_at': '2026-11-17T10:00:00Z',
                  },
                  {
                    'id': 11,
                    'sequence_order': 1,
                    'latitude': 46.53,
                    'longitude': 6.58,
                    'altitude_m': 405.0,
                    'recorded_at': '2026-11-17T10:05:00Z',
                  },
                ],
              }),
              201,
            );
          }),
        );

        expect(result.length, 2);
        expect(result.first.latitude, 46.52);
      },
    );

    test(
      'addEventTrack works in mockMode and distributes activities',
      () async {
        ApiService.mockMode = true;
        final beforeActivities =
            (await ActivityService().getActivities()).length;

        // Event 104 in mock mode has participants
        final waypoints = await EventService().addEventTrack(104, [
          1,
          2,
          3,
        ], filename: 'event.fit');

        expect(waypoints, isNotEmpty);

        // Verify event waypoints can now be fetched
        final fetchedWaypoints = await EventService().getEventWaypoints(104);
        expect(fetchedWaypoints.length, waypoints.length);

        // Verify activity was created in feed
        final afterActivities =
            (await ActivityService().getActivities()).length;
        expect(afterActivities, greaterThan(beforeActivities));
      },
    );

    test('importEventFitFile rejects non-.fit files', () async {
      final badFile = XFile.fromData(
        Uint8List.fromList([1, 2]),
        name: 'test.txt',
        path: 'test.txt',
      );
      await expectLater(
        EventService().importEventFitFile(104, badFile),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Veuillez sélectionner un fichier .fit'),
          ),
        ),
      );
    });

    test('importEventFitFile imports valid XFile ending in .fit', () async {
      ApiService.mockMode = true;
      final file = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'track.FIT',
        path: 'track.FIT',
      );
      final waypoints = await EventService().importEventFitFile(104, file);
      expect(waypoints, isNotEmpty);
    });
  });
}
