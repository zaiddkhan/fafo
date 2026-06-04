class BlogResponse {
  const BlogResponse({
    required this.id,
    required this.city,
    required this.title,
    this.subtitle,
    required this.body,
    this.imageUrl,
    this.readTime,
    required this.published,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String city;
  final String title;
  final String? subtitle;
  final String body;
  final String? imageUrl;
  final String? readTime;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BlogResponse.fromJson(Map<String, dynamic> json) {
    return BlogResponse(
      id: json['id'] as String,
      city: json['city'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      readTime: json['read_time'] as String?,
      published: json['published'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
