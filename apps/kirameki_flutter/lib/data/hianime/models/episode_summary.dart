class EpisodeSummary {
  const EpisodeSummary({
    required this.id,
    required this.number,
    required this.title,
    required this.isFiller,
  });

  final String id;
  final int number;
  final String title;
  final bool isFiller;

  factory EpisodeSummary.fromJson(Map<String, dynamic> json) {
    return EpisodeSummary(
      id: json['id'] as String? ?? '',
      number: (json['episodeNumber'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled episode',
      isFiller: json['isFiller'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'episodeNumber': number,
      'title': title,
      'isFiller': isFiller,
    };
  }
}
