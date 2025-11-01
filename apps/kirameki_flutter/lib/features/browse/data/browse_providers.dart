import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirameki_flutter/data/hianime/hianime_providers.dart';
import 'package:kirameki_flutter/data/hianime/models/home_catalog.dart';

final browseHomeCatalogProvider = FutureProvider<HomeCatalog>((ref) async {
  final repository = await ref.watch(hiAnimeRepositoryProvider.future);
  return repository.getHomeCatalog();
}, name: 'browseHomeCatalogProvider');
