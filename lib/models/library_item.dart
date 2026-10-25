import 'manhua.dart';

class UserLibrary {
  final String id;
  final String userId;
  final int canonicalManhuaId;
  final int currentChapter;
  final bool isFavorite;
  final int customOrder;
  final int updatedAt;
  final CanonicalManhua? canonicalManhua;

  UserLibrary({
    required this.id,
    required this.userId,
    required this.canonicalManhuaId,
    required this.currentChapter,
    required this.isFavorite,
    required this.customOrder,
    required this.updatedAt,
    this.canonicalManhua,
  });

  factory UserLibrary.fromJson(Map<String, dynamic> json) {
    return UserLibrary(
      id: json['id'] as String,
      userId: json['userId'] as String,
      canonicalManhuaId: json['canonicalManhuaId'] is int
          ? json['canonicalManhuaId'] as int
          : int.parse(json['canonicalManhuaId'].toString()),
      currentChapter: json['currentChapter'] as int,
      isFavorite: json['isFavorite'] as bool,
      customOrder: json['customOrder'] as int,
      updatedAt: json['updatedAt'] is int
          ? json['updatedAt'] as int
          : int.parse(json['updatedAt'].toString()),
      canonicalManhua: json['canonicalManhua'] != null
          ? CanonicalManhua.fromJson(json['canonicalManhua'] as Map<String, dynamic>)
          : null,
    );
  }
}
