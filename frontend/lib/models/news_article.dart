class NewsArticle {
  final String title;
  final String? description;
  final String? imageUrl;
  final String? sourceId;
  final String? sourceName;
  final String? link;
  final DateTime? publishedAt;

  const NewsArticle({
    required this.title,
    this.description,
    this.imageUrl,
    this.sourceId,
    this.sourceName,
    this.link,
    this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    DateTime? pubDate;
    try {
      final raw = json['pubDate'] as String?;
      if (raw != null) pubDate = DateTime.parse(raw);
    } catch (_) {}

    return NewsArticle(
      title: (json['title'] as String?) ?? 'Untitled',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sourceId: json['source_id'] as String?,
      sourceName: json['source_name'] as String?,
      link: json['link'] as String?,
      publishedAt: pubDate,
    );
  }
}
