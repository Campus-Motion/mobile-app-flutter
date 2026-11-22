class Activity {
  final int id;
  final String title;
  final String type;
  final int userId;
  final bool isPublic;
  final DateTime createdAt;
  final double?
  duration; // In minutes, hours, or seconds depending on frontend representation
  final double? distanceKm;
  final String? body;
  final bool hasFit;
  final bool isFromEvent;

  Activity({
    required this.id,
    required this.title,
    required this.type,
    required this.userId,
    required this.isPublic,
    required this.createdAt,
    this.duration,
    this.distanceKm,
    this.body,
    this.hasFit = false,
    this.isFromEvent = false,
  });

  static double? _parseDistanceKm(Map<String, dynamic> json) {
    final km = json['distance_km'] != null
        ? double.tryParse(json['distance_km'].toString())
        : null;
    if (km != null) return km;
    final meters = json['distance_m'] != null
        ? double.tryParse(json['distance_m'].toString())
        : null;
    return meters != null ? meters / 1000.0 : null;
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      userId: json['user_id'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      duration: json['duration'] != null
          ? double.tryParse(json['duration'].toString())
          : null,
      distanceKm: _parseDistanceKm(json),
      body: json['body'] as String?,
      hasFit: json['has_fit'] as bool? ?? (json['hasFit'] as bool? ?? false),
      isFromEvent:
          json['is_from_event'] as bool? ??
          (json['isFromEvent'] as bool? ?? (json['event_id'] != null)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      if (body != null) 'body': body,
      if (duration != null) 'duration': duration,
      if (distanceKm != null) 'distance_km': distanceKm,
      'is_public': isPublic,
      if (hasFit) 'has_fit': hasFit,
      if (isFromEvent) 'is_from_event': isFromEvent,
    };
  }

  /// Returns whether the sport type is locked (i.e. auto-detected by FIT and not 'other').
  bool get isTypeLocked => hasFit && type.toLowerCase() != 'other';

  /// Returns whether the duration is locked (i.e. auto-detected by FIT and > 0).
  bool get isDurationLocked => hasFit && (duration != null && duration! > 0);

  /// Returns whether the distance is locked (i.e. auto-detected by FIT and > 0).
  bool get isDistanceLocked =>
      hasFit && (distanceKm != null && distanceKm! > 0);
}
