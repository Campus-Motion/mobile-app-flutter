class User {
  final int id;
  final String username;
  final String? email;
  final String? photoUrl;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    this.email,
    this.photoUrl,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: (json['username'] ?? json['display_name']) as String? ?? '',
      email: json['email'] as String?,
      photoUrl: json['photo_url'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photo_url': photoUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String? get fullPhotoUrl {
    if (photoUrl == null) return null;
    if (photoUrl!.startsWith('http')) return photoUrl;
    return 'https://api.campusmotion.ch$photoUrl';
  }
}
