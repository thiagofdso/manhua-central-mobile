class CanonicalManhua {
  final int id;
  final String slug;
  final String title;
  final String? alternativeTitles;
  final String? synopsis;
  final String? coverUrl;
  final String primaryDomain;
  final String urlTemplate;
  final int? lastChapter;
  final int? updateDay;
  final bool isHiatus;
  final double bayesianRating;
  final int totalVotes;
  final int totalViews;

  CanonicalManhua({
    required this.id,
    required this.slug,
    required this.title,
    this.alternativeTitles,
    this.synopsis,
    this.coverUrl,
    required this.primaryDomain,
    required this.urlTemplate,
    this.lastChapter,
    this.updateDay,
    this.isHiatus = false,
    this.bayesianRating = 0.0,
    this.totalVotes = 0,
    this.totalViews = 0,
  });

  factory CanonicalManhua.fromJson(Map<String, dynamic> json) {
    return CanonicalManhua(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      slug: json['slug'] as String,
      title: json['title'] as String,
      alternativeTitles: json['alternativeTitles'] as String?,
      synopsis: json['synopsis'] as String?,
      coverUrl: json['coverUrl'] as String?,
      primaryDomain: json['primaryDomain'] as String? ?? '',
      urlTemplate: json['urlTemplate'] as String? ?? '',
      lastChapter: json['lastChapter'] as int?,
      updateDay: json['updateDay'] as int?,
      isHiatus: json['isHiatus'] as bool? ?? false,
      bayesianRating: (json['bayesianRating'] as num?)?.toDouble() ?? 0.0,
      totalVotes: json['totalVotes'] as int? ?? 0,
      totalViews: json['totalViews'] is int
          ? json['totalViews'] as int
          : (json['totalViews'] as num?)?.toInt() ?? 0,
    );
  }
}
