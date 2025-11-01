import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirameki_flutter/core/providers/shared_prefs_provider.dart';
import 'package:kirameki_flutter/data/hianime/hianime_cache.dart';
import 'package:kirameki_flutter/data/hianime/hianime_client.dart';
import 'package:kirameki_flutter/data/hianime/hianime_repository.dart';

final hiAnimeDioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  return dio;
}, name: 'hiAnimeDioProvider');

final hiAnimeRepositoryProvider = FutureProvider<HiAnimeRepository>((ref) async {
  final dio = ref.watch(hiAnimeDioProvider);
  final client = HiAnimeApiClient(dio: dio);
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final cache = HiAnimeCache(prefs);
  return HiAnimeRepository(client: client, cache: cache);
}, name: 'hiAnimeRepositoryProvider');
