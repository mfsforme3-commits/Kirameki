import 'package:kirameki_flutter/data/hianime/hianime_cache.dart';
import 'package:kirameki_flutter/data/hianime/hianime_client.dart';
import 'package:kirameki_flutter/data/hianime/models/episode_stream.dart';
import 'package:kirameki_flutter/data/hianime/models/episode_summary.dart';
import 'package:kirameki_flutter/data/hianime/models/home_catalog.dart';

class HiAnimeRepository {
  HiAnimeRepository({
    required this.client,
    required this.cache,
    this.homeCacheDuration = const Duration(hours: 6),
    this.episodesCacheDuration = const Duration(hours: 12),
  });

  final HiAnimeApiClient client;
  final HiAnimeCache cache;
  final Duration homeCacheDuration;
  final Duration episodesCacheDuration;

  Future<HomeCatalog> getHomeCatalog() async {
    final cached = cache.readHome();
    if (cached != null && cached.isFresh(homeCacheDuration)) {
      return cached.catalog;
    }

    try {
      final remote = await client.fetchHomeCatalog();
      await cache.saveHome(remote);
      return remote;
    } catch (error) {
      if (cached != null) {
        return cached.catalog;
      }
      rethrow;
    }
  }

  Future<List<EpisodeSummary>> getEpisodes(String animeId) async {
    final cached = cache.readEpisodes(animeId);
    if (cached != null && cached.isFresh(episodesCacheDuration)) {
      return cached.episodes;
    }

    try {
      final remote = await client.fetchEpisodes(animeId);
      await cache.saveEpisodes(animeId, remote);
      return remote;
    } catch (error) {
      if (cached != null) {
        return cached.episodes;
      }
      rethrow;
    }
  }

  Future<EpisodeStream> getEpisodeStream({
    required String episodeId,
    String type = 'sub',
    String server = 'hd-2',
  }) {
    return client.fetchEpisodeStream(
      episodeId: episodeId,
      type: type,
      server: server,
    );
  }
}
