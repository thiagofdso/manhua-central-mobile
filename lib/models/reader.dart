class ChapterImage {
  final int index;
  final String url;
  final String proxyUrl;

  ChapterImage({
    required this.index,
    required this.url,
    required this.proxyUrl,
  });

  factory ChapterImage.fromJson(Map<String, dynamic> json) {
    return ChapterImage(
      index: json['index'] as int,
      url: json['url'] as String,
      proxyUrl: json['proxyUrl'] as String? ?? json['url'] as String,
    );
  }
}

class ChapterImagesResponse {
  final String slug;
  final String title;
  final int chapter;
  final int? lastChapter;
  final List<ChapterImage> images;

  ChapterImagesResponse({
    required this.slug,
    required this.title,
    required this.chapter,
    this.lastChapter,
    required this.images,
  });

  factory ChapterImagesResponse.fromJson(Map<String, dynamic> json) {
    final imgs = json['images'] as List<dynamic>? ?? [];
    return ChapterImagesResponse(
      slug: json['slug'] as String,
      title: json['title'] as String,
      chapter: json['chapter'] as int,
      lastChapter: json['lastChapter'] as int?,
      images: imgs.map((e) => ChapterImage.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
