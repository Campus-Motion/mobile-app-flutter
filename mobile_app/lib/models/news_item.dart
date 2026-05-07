class NewsItem {
  final int id;
  final String title;
  final String body;
  final String? photoUrl;
  final int authorId;
  final bool isPublished;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.body,
    this.photoUrl,
    required this.authorId,
    required this.isPublished,
    required this.publishedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      photoUrl: json['photo_url'] as String?,
      authorId: json['author_id'] as int,
      isPublished: json['is_published'] as bool,
      publishedAt: DateTime.parse(json['published_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  // Helper method to get the full image URL
  String? get fullPhotoUrl {
    if (photoUrl == null) return null;
    if (photoUrl!.startsWith('http')) return photoUrl;
    return 'https://api.campusmotion.ch$photoUrl';
  }
}
