import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/loop_route.dart';
import 'package:mobile_app/services/loop_route_service.dart';

void main() {
  group('LoopRoute.clampDistanceKm', () {
    test('returns default distance for null or non-finite values', () {
      expect(LoopRoute.clampDistanceKm(null), LoopRoute.defaultDistanceKm);
      expect(
        LoopRoute.clampDistanceKm(double.nan),
        LoopRoute.defaultDistanceKm,
      );
      expect(
        LoopRoute.clampDistanceKm(double.infinity),
        LoopRoute.defaultDistanceKm,
      );
    });

    test('clamps values to supported range', () {
      expect(LoopRoute.clampDistanceKm(0.2), LoopRoute.minDistanceKm);
      expect(LoopRoute.clampDistanceKm(12.5), 12.5);
      expect(LoopRoute.clampDistanceKm(50.0), LoopRoute.maxDistanceKm);
    });
  });

  group('LoopRouteService', () {
    test(
      'generates preview loops with sport-specific estimated duration',
      () async {
        final service = LoopRouteService();

        final runLoop = await service.generateLoop(
          targetDistanceKm: 5.0,
          sportType: 'run',
        );
        expect(runLoop.targetDistanceKm, 5.0);
        expect(runLoop.estimatedDistanceKm, 5.0);
        expect(runLoop.estimatedDuration, const Duration(minutes: 30));
        expect(runLoop.sportType, 'run');
        expect(runLoop.isPreview, isTrue);

        final cycleLoop = await service.generateLoop(
          targetDistanceKm: 10.0,
          sportType: 'cycle',
        );
        expect(cycleLoop.estimatedDuration, const Duration(minutes: 30));

        final clampedLoop = await service.generateLoop(
          targetDistanceKm: 45.0,
          sportType: 'walk',
        );
        expect(clampedLoop.targetDistanceKm, LoopRoute.maxDistanceKm);
        expect(clampedLoop.estimatedDuration, const Duration(hours: 6));
      },
    );
  });
}
