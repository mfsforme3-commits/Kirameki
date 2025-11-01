class EpisodeStream {
  const EpisodeStream({
    required this.url,
    required this.streamType,
    required this.server,
    required this.subtitles,
    this.intro,
    this.outro,
    this.webFallbackUrl,
    this.webFallbackSources = const [],
  });

  final String url;
  final String streamType;
  final String server;
  final List<SubtitleTrack> subtitles;
  final EpisodeMarker? intro;
  final EpisodeMarker? outro;
  final String? webFallbackUrl;
  final List<WebFallbackSource> webFallbackSources;

  bool get hasDirectStream => url.isNotEmpty;
  bool get hasWebFallback =>
      webFallbackSources.isNotEmpty ||
      (webFallbackUrl != null && webFallbackUrl!.trim().isNotEmpty);

  factory EpisodeStream.fromJson(Map<String, dynamic> json) {
    final link = json['link'] as Map<String, dynamic>?;
    final streamingLink = json['streamingLink'];

    String url = link?['file'] as String? ?? '';
    String streamType =
        link?['type'] as String? ?? (json['type'] as String? ?? 'hls');
    String server = (json['server'] as String? ??
            json['servers'] as String? ??
            'unknown')
        .toString();

    final tracks = <SubtitleTrack>[
      ...(json['tracks'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SubtitleTrack.fromJson),
    ];

    EpisodeMarker? intro;
    EpisodeMarker? outro;
    String? fallbackUrl;
    final fallbackSources = <WebFallbackSource>[];

    if (streamingLink is Map<String, dynamic>) {
      final linkData = streamingLink['link'];
      if (linkData is Map<String, dynamic>) {
        url = url.isEmpty ? linkData['file'] as String? ?? '' : url;
        streamType = linkData['type'] as String? ?? streamType;
      } else if (linkData is String && url.isEmpty) {
        url = linkData;
      }

      final iframe = streamingLink['iframe'] as String?;
      if (iframe != null && iframe.isNotEmpty) {
        fallbackSources.add(WebFallbackSource(label: 'Embed', url: iframe));
        fallbackUrl ??= iframe;
      }

      final streamingTracks =
          (streamingLink['tracks'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(SubtitleTrack.fromJson)
              .toList();
      if (streamingTracks.isNotEmpty) {
        tracks
          ..clear()
          ..addAll(streamingTracks);
      }

      if (streamingLink['intro'] is Map<String, dynamic>) {
        intro = EpisodeMarker.fromJson(
            streamingLink['intro'] as Map<String, dynamic>);
      }
      if (streamingLink['outro'] is Map<String, dynamic>) {
        outro = EpisodeMarker.fromJson(
            streamingLink['outro'] as Map<String, dynamic>);
      }

      final streamingServer = streamingLink['server'] as String? ??
          streamingLink['servers'] as String?;
      if (streamingServer != null) {
        server = streamingServer;
      }
    } else if (streamingLink is String) {
      fallbackUrl = streamingLink;
      fallbackSources
          .add(WebFallbackSource(label: 'MegaPlay', url: streamingLink));
    }

    intro ??= json['intro'] is Map<String, dynamic>
        ? EpisodeMarker.fromJson(json['intro'] as Map<String, dynamic>)
        : null;
    outro ??= json['outro'] is Map<String, dynamic>
        ? EpisodeMarker.fromJson(json['outro'] as Map<String, dynamic>)
        : null;

    fallbackUrl ??= _deriveMegaplayUrl(
      json['id'] as String?,
      (json['type'] as String? ?? streamType),
    );
    if (fallbackUrl != null) {
      fallbackSources.add(
        WebFallbackSource(label: 'MegaPlay', url: fallbackUrl),
      );
    }

    final vidWishUrl = _deriveVidwishUrl(
      json['id'] as String?,
      (json['type'] as String? ?? streamType),
    );
    if (vidWishUrl != null) {
      fallbackSources.add(
        WebFallbackSource(label: 'VidWish', url: vidWishUrl),
      );
    }

    return EpisodeStream(
      url: server.toLowerCase() == 'hd-4' ? '' : url,
      streamType: streamType,
      server: server,
      subtitles: tracks,
      intro: intro,
      outro: outro,
      webFallbackUrl: fallbackUrl,
      webFallbackSources: _dedupeFallbacks(fallbackSources),
    );
  }

  static String? _deriveMegaplayUrl(String? episodeId, String? type) {
    if (episodeId == null) return null;
    final match = RegExp(r'ep=(\d+)').firstMatch(episodeId);
    if (match == null) return null;
    final episodeNumber = match.group(1);
    if (episodeNumber == null) return null;
    final qualityType = (type ?? 'sub').toLowerCase();
    return 'https://megaplay.buzz/stream/s-2/$episodeNumber/$qualityType';
  }

  static String? _deriveVidwishUrl(String? episodeId, String? type) {
    if (episodeId == null) return null;
    final match = RegExp(r'ep=(\d+)').firstMatch(episodeId);
    if (match == null) return null;
    final episodeNumber = match.group(1);
    if (episodeNumber == null) return null;
    final qualityType = (type ?? 'sub').toLowerCase();
    return 'https://vidwish.live/stream/s-2/$episodeNumber/$qualityType';
  }

  static List<WebFallbackSource> _dedupeFallbacks(
    List<WebFallbackSource> sources,
  ) {
    final seen = <String>{};
    final result = <WebFallbackSource>[];
    for (final source in sources) {
      final key = source.url.trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(source);
    }
    return result;
  }
}

class WebFallbackSource {
  const WebFallbackSource({required this.label, required this.url});

  final String label;
  final String url;
}

class SubtitleTrack {
  const SubtitleTrack({
    required this.file,
    required this.label,
    required this.kind,
    required this.isDefault,
  });

  final String file;
  final String label;
  final String kind;
  final bool isDefault;

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    return SubtitleTrack(
      file: json['file'] as String? ?? '',
      label: json['label'] as String? ?? 'Subtitle',
      kind: json['kind'] as String? ?? 'captions',
      isDefault: json['default'] as bool? ?? false,
    );
  }

  bool get isCaption => kind == 'captions' || kind == 'subtitles';
}

class EpisodeMarker {
  const EpisodeMarker({required this.start, required this.end});

  final double start;
  final double end;

  factory EpisodeMarker.fromJson(Map<String, dynamic> json) {
    return EpisodeMarker(
      start: (json['start'] as num?)?.toDouble() ?? 0,
      end: (json['end'] as num?)?.toDouble() ?? 0,
    );
  }
}
