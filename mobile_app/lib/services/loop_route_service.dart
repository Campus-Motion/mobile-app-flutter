import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/models/loop_route.dart';

/// Service hook for generating closed-loop routes around a target distance.
///
/// Operates locally in preview mode without third-party network calls; the
/// upcoming graph-based loop-routing module will plug into [generateLoop].
class LoopRouteService {
  static final LoopRouteService _instance = LoopRouteService._internal();
  factory LoopRouteService() => _instance;
  LoopRouteService._internal();

  /// Generates a preview loop for [targetDistanceKm] and [sportType].
  Future<LoopRoute> generateLoop({
    required double targetDistanceKm,
    required String sportType,
  }) async {
    final clampedDistance = LoopRoute.clampDistanceKm(targetDistanceKm);
    final speedKmh = Activity.defaultSpeedKmh(sportType);
    final durationSeconds = ((clampedDistance / speedKmh) * 3600).round();

    return LoopRoute(
      targetDistanceKm: clampedDistance,
      estimatedDistanceKm: clampedDistance,
      estimatedDuration: Duration(seconds: durationSeconds),
      sportType: sportType,
      isPreview: true,
    );
  }
}
