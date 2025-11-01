import 'package:collection/collection.dart';

class AnimeSummary {
  const AnimeSummary({
    required this.id,
    required this.title,
    required this.poster,
    this.alternativeTitle,
    this.type,
    this.duration,
    this.synopsis,
    this.aired,
    this.rank,
    this.rating,
    this.totalEpisodes,
    this.genres = const [],
  });

  final String id;
  final String title;
  final String poster;
  final String? alternativeTitle;
  final String? type;
  final String? duration;
  final String? synopsis;
  final String? aired;
  final int? rank;
  final double? rating;
  final int? totalEpisodes;
  final List<String> genres;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster': poster,
      'alternativeTitle': alternativeTitle,
      'type': type,
      'duration': duration,
      'synopsis': synopsis,
      'aired': aired,
      'rank': rank,
      'rating': rating,
      'totalEpisodes': totalEpisodes,
      'genres': genres,
    };
  }

  factory AnimeSummary.fromJson(Map<String, dynamic> json) {
    return AnimeSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown title',
      poster: json['poster'] as String? ?? '',
      alternativeTitle: json['alternativeTitle'] as String?,
      type: json['type'] as String?,
      duration: json['duration'] as String?,
      synopsis: json['synopsis'] as String?,
      aired: json['aired'] as String?,
      rank: (json['rank'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      totalEpisodes: _parseEpisodes(json['totalEpisodes'] ?? json['episodes']),
      genres: (json['genres'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
    );
  }

  factory AnimeSummary.fromSpotlight(Map<String, dynamic> json) {
    return AnimeSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown title',
      alternativeTitle: json['alternativeTitle'] as String?,
      poster: json['poster'] as String? ?? '',
      rank: (json['rank'] as num?)?.toInt(),
      type: json['type'] as String?,
      duration: json['duration'] as String?,
      synopsis: json['synopsis'] as String?,
      aired: json['aired'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      totalEpisodes: _parseEpisodes(json['episodes']),
      genres: (json['genres'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
    );
  }

  factory AnimeSummary.fromSimpleList(Map<String, dynamic> json) {
    return AnimeSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown title',
      alternativeTitle: json['alternativeTitle'] as String?,
      poster: json['poster'] as String? ?? '',
      rank: (json['rank'] as num?)?.toInt(),
      type: json['type'] as String?,
      duration: json['duration'] as String?,
    );
  }

  factory AnimeSummary.fromMostPopular(Map<String, dynamic> json) {
    return AnimeSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown title',
      alternativeTitle: json['alternativeTitle'] as String?,
      poster: json['poster'] as String? ?? '',
      type: json['type'] as String?,
      duration: json['duration'] as String?,
      totalEpisodes: _parseEpisodes(json['episodes']),
    );
  }

  AnimeSummary copyWith({
    String? id,
    String? title,
    String? poster,
    String? alternativeTitle,
    String? type,
    String? duration,
    String? synopsis,
    String? aired,
    int? rank,
    double? rating,
    int? totalEpisodes,
    List<String>? genres,
  }) {
    return AnimeSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      poster: poster ?? this.poster,
      alternativeTitle: alternativeTitle ?? this.alternativeTitle,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      synopsis: synopsis ?? this.synopsis,
      aired: aired ?? this.aired,
      rank: rank ?? this.rank,
      rating: rating ?? this.rating,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      genres: genres ?? this.genres,
    );
  }

  static int? _parseEpisodes(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is Map<String, dynamic>) {
      final eps = value.entries
          .map((entry) => entry.value)
          .whereType<num>()
          .map((e) => e.toInt())
          .sorted((a, b) => b.compareTo(a));
      return eps.isEmpty ? null : eps.first;
    }

    return null;
  }
}
