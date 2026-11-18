import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    ApiService.mockMode = true;
    await ApiService().clearToken();
  });

  tearDown(() async {
    await ApiService().clearToken();
    ApiService.mockMode = false;
  });

  group('ActivityService waypoints tests', () {
    test('getWaypoints returns waypoints for activity with track', () async {
      final service = ActivityService();
      final waypoints = await service.getWaypoints(201);

      expect(waypoints, isNotEmpty);
      expect(waypoints.length, greaterThanOrEqualTo(5));
      expect(waypoints.first.latitude, closeTo(46.5190, 0.001));
      expect(waypoints.first.longitude, closeTo(6.5660, 0.001));
    });

    test(
      'getWaypoints returns empty list for activity without track',
      () async {
        final service = ActivityService();
        final waypoints = await service.getWaypoints(203);

        expect(waypoints, isEmpty);
      },
    );
  });
}
