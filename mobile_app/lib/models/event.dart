class Event {
  final int id;
  final String title;
  final String body;
  final DateTime startTime;
  final DateTime endTime;
  final double? distanceM;
  final int participantCount;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.body,
    required this.startTime,
    required this.endTime,
    this.distanceM,
    required this.participantCount,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final startTime = json['start_time'] != null
        ? DateTime.tryParse(json['start_time'] as String) ?? DateTime.now()
        : DateTime.now();
    
    final endTime = json['end_time'] != null
        ? DateTime.tryParse(json['end_time'] as String) ?? startTime.add(const Duration(hours: 1))
        : startTime.add(const Duration(hours: 1));

    return Event(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      startTime: startTime,
      endTime: endTime,
      distanceM: json['distance_m'] != null ? double.tryParse(json['distance_m'].toString()) : null,
      participantCount: json['participant_count'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (distanceM != null) 'distance_m': distanceM,
    };
  }
}
