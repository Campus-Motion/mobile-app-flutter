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
}
