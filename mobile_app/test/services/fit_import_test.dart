import 'dart:convert';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_app/models/fit_import_exception.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => ApiService.mockMode = false);
  tearDown(() async {
    ApiService.mockMode = false;
    await ApiService().clearToken();
  });

  test(
    'FIT import sends authenticated multipart data and returns a private activity',
    () async {
      await ApiService().setToken('local-test-token');
      final result = await http.runWithClient(
        () => ActivityService().importFit([1, 2, 3]),
        () => MockClient((request) async {
          expect(request.url.path, '/activities/import-fit');
          expect(request.headers['Authorization'], 'Bearer local-test-token');
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data;'),
          );
          expect(
            request.body,
            contains('name="file"; filename="activity.fit"'),
          );
          return http.Response(
            json.encode({
              'id': 9,
              'user_id': 42,
              'is_public': false,
              'type': 'other',
              'title': 'Imported FIT activity',
            }),
            201,
          );
        }),
      );
      expect(result.id, 9);
      expect(result.isPublic, isFalse);
    },
  );

  test(
    'empty or oversized FIT input is rejected before any network operation',
    () async {
      for (final bytes in [<int>[], Uint8List(10 * 1024 * 1024 + 1)]) {
        await expectLater(
          ActivityService().importFit(bytes),
          throwsA(isA<FitImportException>()),
        );
      }
    },
  );

  test('import errors expose only controlled messages', () async {
    for (final status in [400, 422, 413, 401, 503]) {
      await http.runWithClient(
        () async {
          await expectLater(
            ActivityService().importFit([1]),
            throwsA(
              isA<FitImportException>().having(
                (error) => error.message,
                'safe message',
                isNot(contains('private decoder diagnostic')),
              ),
            ),
          );
        },
        () => MockClient(
          (_) async => http.Response('private decoder diagnostic', status),
        ),
      );
    }
  });

  test('demo mode never pretends a real FIT file was imported', () async {
    ApiService.mockMode = true;
    expect(ActivityService().canImportFit, isFalse);
    final before = (await ActivityService().getActivities()).length;
    await expectLater(
      ActivityService().importFit([1]),
      throwsA(isA<FitImportException>()),
    );
    expect((await ActivityService().getActivities()).length, before);
  });

  test(
    'selected files require a FIT extension and reject size before loading bytes',
    () async {
      await expectLater(
        ActivityService().importFitFile(
          XFile.fromData(Uint8List(3), name: 'route.txt', path: 'route.txt'),
        ),
        throwsA(isA<FitImportException>()),
      );
      await expectLater(
        ActivityService().importFitFile(
          XFile.fromData(
            Uint8List(ActivityService.maxFitBytes + 1),
            name: 'route.fit',
            path: 'route.fit',
          ),
        ),
        throwsA(isA<FitImportException>()),
      );
    },
  );

  test('data export includes route arrays and excludes other owners', () async {
    ApiService.mockMode = true;
    final activities = await ActivityService().exportActivities();
    expect(activities, isNotEmpty);
    for (final activity in activities) {
      expect(activity['user_id'], 1);
      expect(activity['waypoints'], isA<List<dynamic>>());
    }
  });

  test(
    'shared multipart helper keeps photo upload field and response handling',
    () async {
      final photo = await http.runWithClient(
        () => UserService().uploadPhoto([1, 2], 'avatar.png'),
        () => MockClient((request) async {
          expect(request.url.path, '/users/me/photo');
          expect(request.body, contains('name="photo"; filename="avatar.png"'));
          return http.Response(
            '{"photo_url":"/uploads/profiles/avatar.png"}',
            200,
          );
        }),
      );
      expect(photo, '/uploads/profiles/avatar.png');
    },
  );
}
