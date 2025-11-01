import 'package:kirameki_flutter/data/hianime/models/anime_summary.dart';

class HomeCatalog {
  const HomeCatalog({
    required this.spotlight,
    required this.trending,
    required this.mostPopular,
    required this.genres,
  });

  final List<AnimeSummary> spotlight;
  final List<AnimeSummary> trending;
  final List<AnimeSummary> mostPopular;
  final List<String> genres;

  Map<String, dynamic> toJson() {
    return {
      'spotlight': spotlight.map((e) => e.toJson()).toList(),
      'trending': trending.map((e) => e.toJson()).toList(),
      'mostPopular': mostPopular.map((e) => e.toJson()).toList(),
      'genres': genres,
    };
  }

  factory HomeCatalog.fromJson(Map<String, dynamic> json) {
    return HomeCatalog(
      spotlight: (json['spotlight'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AnimeSummary.fromJson)
          .toList(growable: false),
      trending: (json['trending'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AnimeSummary.fromJson)
          .toList(growable: false),
      mostPopular: (json['mostPopular'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AnimeSummary.fromJson)
          .toList(growable: false),
      genres:
          (json['genres'] as List<dynamic>?)?.whereType<String>().toList() ??
              const [],
    );
  }
}
