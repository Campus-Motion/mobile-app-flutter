import 'dart:math' as math;

class Waypoint {
  final int id;
  final int sequenceOrder;
  final DateTime recordedAt;
  final double latitude;
  final double longitude;
  final double? altitudeM;

  const Waypoint({
    required this.id,
    required this.sequenceOrder,
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
    this.altitudeM,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      id: json['id'] as int? ?? 0,
      sequenceOrder: json['sequence_order'] as int? ?? 0,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'].toString())?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      altitudeM: json['altitude_m'] != null
          ? double.tryParse(json['altitude_m'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequence_order': sequenceOrder,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      if (altitudeM != null) 'altitude_m': altitudeM,
    };
  }

  /// Computes positive and negative elevation change `(ascentM, descentM)`
  /// across consecutive waypoints, or `null` if no pair has altitude data.
  static (int, int)? calculateElevationGainLoss(List<Waypoint> waypoints) {
    return calculateTotalElevationGainLoss([waypoints]);
  }

  /// Sums positive and negative elevation change `(ascentM, descentM)` across
  /// multiple tracks without bridging between separate tracks, or returns
  /// `null` when no track contains consecutive altitude pairs.
  static (int, int)? calculateTotalElevationGainLoss(
    Iterable<List<Waypoint>> tracks,
  ) {
    double ascent = 0.0;
    double descent = 0.0;
    bool hasAltitude = false;
    for (final waypoints in tracks) {
      for (int i = 0; i < waypoints.length - 1; i++) {
        final alt1 = waypoints[i].altitudeM;
        final alt2 = waypoints[i + 1].altitudeM;
        if (alt1 != null && alt2 != null) {
          hasAltitude = true;
          final diff = alt2 - alt1;
          if (diff > 0) {
            ascent += diff;
          } else {
            descent += diff.abs();
          }
        }
      }
    }
    if (!hasAltitude) return null;
    return (ascent.round(), descent.round());
  }

  /// Computes total great-circle distance in kilometres along [waypoints].
  static double trackDistanceKm(List<Waypoint> waypoints) {
    if (waypoints.length < 2) return 0.0;
    const double earthRadiusKm = 6371.0;
    double totalKm = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      final dLat =
          (waypoints[i + 1].latitude - waypoints[i].latitude) *
          (math.pi / 180.0);
      final dLon =
          (waypoints[i + 1].longitude - waypoints[i].longitude) *
          (math.pi / 180.0);
      final lat1 = waypoints[i].latitude * (math.pi / 180.0);
      final lat2 = waypoints[i + 1].latitude * (math.pi / 180.0);
      final sinDLat = math.sin(dLat / 2.0);
      final sinDLon = math.sin(dLon / 2.0);
      final a =
          sinDLat * sinDLat +
          math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
      final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(math.max(0.0, 1 - a)));
      totalKm += earthRadiusKm * c;
    }
    return totalKm;
  }
}
