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
  });

  /// Default cruising speed in km/h for a sport type, used when estimating
  /// activity distance or preview loop duration.
  static double defaultSpeedKmh(String type) {
    switch (type.toLowerCase()) {
      case 'run':
        return 10.0;
      case 'walk':
        return 5.0;
      case 'cycle':
        return 20.0;
      case 'hike':
        return 4.0;
      case 'swim':
        return 2.0;
      default:
        return 5.0;
    }
  }

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
    };
  }
}
