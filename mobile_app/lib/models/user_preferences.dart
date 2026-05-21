class UserPreferences {
  final int? userId;
  final List<String> preferredSports;
  final String intensity;
  final String goal;
  final String level;
  final bool openToGroups;
  final bool openToNewSports;
  final double maxDistanceKm;

  UserPreferences({
    this.userId,
    required this.preferredSports,
    required this.intensity,
    required this.goal,
    required this.level,
    required this.openToGroups,
    required this.openToNewSports,
    required this.maxDistanceKm,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id'] as int?,
      preferredSports: List<String>.from(json['preferred_sports'] as List? ?? []),
      intensity: json['intensity'] as String? ?? 'moderate',
      goal: json['goal'] as String? ?? 'stay_active',
      level: json['level'] as String? ?? 'intermediate',
      openToGroups: json['open_to_groups'] as bool? ?? true,
      openToNewSports: json['open_to_new_sports'] as bool? ?? false,
      maxDistanceKm: (json['max_distance_km'] as num? ?? 25.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferred_sports': preferredSports,
      'intensity': intensity,
      'goal': goal,
      'level': level,
      'open_to_groups': openToGroups,
      'open_to_new_sports': openToNewSports,
      'max_distance_km': maxDistanceKm,
    };
  }

  factory UserPreferences.empty() {
    return UserPreferences(
      preferredSports: [],
      intensity: 'moderate',
      goal: 'stay_active',
      level: 'intermediate',
      openToGroups: true,
      openToNewSports: false,
      maxDistanceKm: 25.0,
    );
  }
}
