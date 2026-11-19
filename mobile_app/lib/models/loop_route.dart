/// Closed-loop route preview or generated route for a target distance and sport.
class LoopRoute {
  static const double minDistanceKm = 1.0;
  static const double maxDistanceKm = 30.0;
  static const double defaultDistanceKm = 5.0;

  final double targetDistanceKm;
  final double estimatedDistanceKm;
  final Duration estimatedDuration;
  final String sportType;
  final bool isPreview;

  const LoopRoute({
    required this.targetDistanceKm,
    required this.estimatedDistanceKm,
    required this.estimatedDuration,
    required this.sportType,
    this.isPreview = true,
  });

  /// Clamps [distanceKm] to `[minDistanceKm, maxDistanceKm]`, falling back to
  /// [defaultDistanceKm] when unavailable or non-finite.
  static double clampDistanceKm(double? distanceKm) {
    if (distanceKm == null || !distanceKm.isFinite) {
      return defaultDistanceKm;
    }
    return distanceKm.clamp(minDistanceKm, maxDistanceKm).toDouble();
  }
}
