class Article {
  final String title;
  final String description;
  final String imageUrl;
  final String source;
  final String url;

  Article({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.source,
    required this.url,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'No title',
      description: json['description'] ?? 'No description',
      imageUrl: json['image_url'] ?? '',
      source: json['source'] ?? 'Unknown source',
      url: json['url'] ?? '',
    );
  }
}
