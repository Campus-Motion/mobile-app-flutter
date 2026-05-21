class Activity {
  final int id;
  final String title;
  final String type;
  final int userId;
  final bool isPublic;
  final DateTime createdAt;
  final double? duration; // In minutes, hours, or seconds depending on frontend representation
  final String? body;

  Activity({
    required this.id,
    required this.title,
    required this.type,
    required this.userId,
    required this.isPublic,
    required this.createdAt,
    this.duration,
    this.body,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      userId: json['user_id'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      duration: json['duration'] != null ? double.tryParse(json['duration'].toString()) : null,
      body: json['body'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      if (body != null) 'body': body,
      'is_public': isPublic,
      if (duration != null) 'duration': duration,
    };
  }
}
