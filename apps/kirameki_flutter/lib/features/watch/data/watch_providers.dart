import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirameki_flutter/data/hianime/hianime_providers.dart';
import 'package:kirameki_flutter/data/hianime/models/episode_stream.dart';
import 'package:kirameki_flutter/data/hianime/models/episode_summary.dart';

final episodeListProvider = FutureProvider.autoDispose
    .family<List<EpisodeSummary>, String>((ref, animeId) async {
  final repository = await ref.watch(hiAnimeRepositoryProvider.future);
  return repository.getEpisodes(animeId);
}, name: 'episodeListProvider');

class EpisodeStreamRequest {
  const EpisodeStreamRequest({
    required this.episodeId,
    required this.type,
    required this.server,
  });

  final String episodeId;
  final String type;
  final String server;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeStreamRequest &&
        other.episodeId == episodeId &&
        other.type == type &&
        other.server == server;
  }

  @override
  int get hashCode => Object.hash(episodeId, type, server);
}

final episodeStreamProvider = FutureProvider.autoDispose
    .family<EpisodeStream, EpisodeStreamRequest>((ref, request) async {
  final repository = await ref.watch(hiAnimeRepositoryProvider.future);
  return repository.getEpisodeStream(
    episodeId: request.episodeId,
    type: request.type,
    server: request.server,
  );
}, name: 'episodeStreamProvider');
