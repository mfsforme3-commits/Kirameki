import 'dart:convert';

import 'package:kirameki_flutter/data/hianime/models/episode_summary.dart';
import 'package:kirameki_flutter/data/hianime/models/home_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiAnimeCache {
  HiAnimeCache(this._prefs);

  final SharedPreferences _prefs;

  static const _homeKey = 'hianime.cache.home';

  String _episodesKey(String animeId) => 'hianime.cache.episodes.$animeId';

  Future<void> saveHome(HomeCatalog catalog) async {
    final payload = {
      'timestamp': DateTime.now().toIso8601String(),
      'catalog': catalog.toJson(),
    };
    await _prefs.setString(_homeKey, jsonEncode(payload));
  }

  CachedHomeCatalog? readHome() {
    final raw = _prefs.getString(_homeKey);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '');
      final data = json['catalog'];
      if (timestamp == null || data is! Map<String, dynamic>) return null;
      final catalog = HomeCatalog.fromJson(data);
      return CachedHomeCatalog(catalog: catalog, timestamp: timestamp);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveEpisodes(
    String animeId,
    List<EpisodeSummary> episodes,
  ) async {
    final limited = episodes.length > 200
        ? episodes.take(200).toList(growable: false)
        : episodes;
    final payload = {
      'timestamp': DateTime.now().toIso8601String(),
      'episodes': limited.map((e) => e.toJson()).toList(),
    };
    await _prefs.setString(_episodesKey(animeId), jsonEncode(payload));
  }

  CachedEpisodes? readEpisodes(String animeId) {
    final raw = _prefs.getString(_episodesKey(animeId));
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '');
      final data = json['episodes'];
      if (timestamp == null || data is! List<dynamic>) return null;
      final episodes = data
          .whereType<Map<String, dynamic>>()
          .map(EpisodeSummary.fromJson)
          .toList(growable: false);
      return CachedEpisodes(episodes: episodes, timestamp: timestamp);
    } catch (_) {
      return null;
    }
  }
}

class CachedHomeCatalog {
  CachedHomeCatalog({required this.catalog, required this.timestamp});

  final HomeCatalog catalog;
  final DateTime timestamp;

  bool isFresh(Duration maxAge) =>
      DateTime.now().difference(timestamp) <= maxAge;
}

class CachedEpisodes {
  CachedEpisodes({required this.episodes, required this.timestamp});

  final List<EpisodeSummary> episodes;
  final DateTime timestamp;

  bool isFresh(Duration maxAge) =>
      DateTime.now().difference(timestamp) <= maxAge;
}
