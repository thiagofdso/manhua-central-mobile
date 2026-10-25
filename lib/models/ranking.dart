import 'manhua.dart';

class RankedManhua {
  final int rank;
  final double score;
  final CanonicalManhua canonical;

  RankedManhua({
    required this.rank,
    required this.score,
    required this.canonical,
  });

  factory RankedManhua.fromJson(Map<String, dynamic> json) {
    return RankedManhua(
      rank: json['rank'] as int,
      score: (json['score'] as num).toDouble(),
      canonical: CanonicalManhua.fromJson(json['canonical'] as Map<String, dynamic>),
    );
  }
}
