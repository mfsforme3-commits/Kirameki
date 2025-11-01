import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirameki_flutter/core/constants/app_sizes.dart';
import 'package:kirameki_flutter/data/hianime/models/anime_summary.dart';
import 'package:kirameki_flutter/data/hianime/models/home_catalog.dart';
import 'package:kirameki_flutter/features/browse/data/browse_providers.dart';
import 'package:kirameki_flutter/features/watch/data/watch_providers.dart';
import 'package:kirameki_flutter/features/watch/presentation/watch_screen.dart';
import 'package:kirameki_flutter/routes/app_router.dart';
import 'package:kirameki_flutter/shared/widgets/kirameki_badge.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<Set<String>> _selectedGenres = ValueNotifier({});
  final ValueNotifier<String> _sortBy = ValueNotifier('Popularity');

  @override
  void dispose() {
    _searchQuery.dispose();
    _selectedGenres.dispose();
    _sortBy.dispose();
    super.dispose();
  }

  Future<void> _openAnime(AnimeSummary anime) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final episodes = await ref
          .read(episodeListProvider(anime.id).future)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;

      if (episodes.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text('No episodes available for ${anime.title}.')),
        );
        return;
      }

      final targetEpisode = episodes.first;
      final prefetched = episodes.length > 200
          ? episodes.take(200).toList(growable: false)
          : episodes;
      if (!mounted) return;

      context.pushNamed(
        WatchRoute.name,
        pathParameters: {'episodeId': targetEpisode.id},
        extra: WatchScreenArgs(
          animeId: anime.id,
          initialEpisodes: prefetched,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to open ${anime.title}: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(browseHomeCatalogProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF09090B), Color(0xFF111827), Color(0xFF0F172A)],
          ),
        ),
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _BrowseError(
            message: error.toString(),
            onRetry: () => ref.refresh(browseHomeCatalogProvider),
          ),
          data: (catalog) => _buildLoaded(context, catalog),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, HomeCatalog catalog) {
    final hero = catalog.spotlight.isNotEmpty ? catalog.spotlight.first : null;

    final trendingPreviews = catalog.trending
        .asMap()
        .entries
        .map((entry) => _BrowsePreview(
              anime: entry.value,
              palette: _paletteForIndex(entry.key),
              onTap: () => _openAnime(entry.value),
            ))
        .toList(growable: false);

    final library = catalog.mostPopular;
    final availableGenres = catalog.genres;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 90,
          floating: true,
          titleSpacing: AppSizes.xxl,
          title: _BrowseTopBar(
            searchQuery: _searchQuery,
            sortBy: _sortBy,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hero != null)
                  _HeroBanner(
                    anime: hero,
                    palette: _paletteForIndex(0),
                  ),
                const SizedBox(height: AppSizes.triple),
                _SectionHeader(
                  title: 'Trending now',
                  subtitle: 'What the community is watching tonight',
                ),
                const SizedBox(height: AppSizes.lg),
                _TrendingCarousel(items: trendingPreviews),
                const SizedBox(height: AppSizes.triple),
                _SectionHeader(
                  title: 'Browse library',
                  subtitle: 'Filter by genre, release, popularity and more',
                ),
                const SizedBox(height: AppSizes.lg),
                _GenreChips(
                  availableGenres: availableGenres,
                  selectedGenres: _selectedGenres,
                ),
                const SizedBox(height: AppSizes.lg),
              ],
            ),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: _searchQuery,
          builder: (context, query, _) {
            return ValueListenableBuilder<Set<String>>(
              valueListenable: _selectedGenres,
              builder: (context, genres, __) {
                return ValueListenableBuilder<String>(
                  valueListenable: _sortBy,
                  builder: (context, sortBy, ___) {
                    final filtered = _applyFilters(
                      source: library,
                      query: query,
                      genres: genres,
                      sortBy: sortBy,
                    );

                    final previews = filtered
                        .asMap()
                        .entries
                        .map((entry) => _BrowsePreview(
                              anime: entry.value,
                              palette: _paletteForIndex(entry.key + 5),
                              onTap: () => _openAnime(entry.value),
                            ))
                        .toList(growable: false);

                    final crossAxisCount = _resolveCrossAxisCount(context);

                    if (previews.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 48),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                'No titles found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                'Try adjusting your filters or search query.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.xxl,
                        vertical: AppSizes.xxl,
                      ),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final preview = previews[index];
                            return _AnimeCard(preview: preview);
                          },
                          childCount: previews.length,
                        ),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppSizes.lg,
                          mainAxisSpacing: AppSizes.lg,
                          childAspectRatio: 0.68,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  List<AnimeSummary> _applyFilters({
    required List<AnimeSummary> source,
    required String query,
    required Set<String> genres,
    required String sortBy,
  }) {
    Iterable<AnimeSummary> iterable = source;

    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      iterable = iterable.where((anime) {
        return anime.title.toLowerCase().contains(lower) ||
            (anime.alternativeTitle?.toLowerCase().contains(lower) ?? false);
      });
    }

    if (genres.isNotEmpty) {
      iterable = iterable.where((anime) {
        if (anime.genres.isEmpty) return false;
        return anime.genres.any(genres.contains);
      });
    }

    final list = iterable.toList();

    switch (sortBy) {
      case 'Rating':
        list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'A-Z':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Newest':
        list.sort(
          (a, b) => _extractYear(b.aired).compareTo(_extractYear(a.aired)),
        );
        break;
      default:
        // Popularity keeps original ranking order.
        break;
    }

    return list;
  }

  int _resolveCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1600) return 6;
    if (width >= 1300) return 5;
    if (width >= 1000) return 4;
    if (width >= 720) return 3;
    return 2;
  }

  _ColorPalette _paletteForIndex(int index) {
    return _palettes[index % _palettes.length];
  }

  static int _extractYear(String? aired) {
    if (aired == null || aired.isEmpty) return 0;
    final match = RegExp(r'(19|20)\d{2}').firstMatch(aired);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '') ?? 0;
    }
    return 0;
  }
}

class _BrowseError extends StatelessWidget {
  const _BrowseError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56),
          const SizedBox(height: AppSizes.lg),
          Text(
            'Unable to load anime feed',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSizes.xl),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _BrowseTopBar extends StatelessWidget {
  const _BrowseTopBar({
    required this.searchQuery,
    required this.sortBy,
  });

  final ValueNotifier<String> searchQuery;
  final ValueNotifier<String> sortBy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        const KiramekiBadge(size: 44),
        const SizedBox(width: AppSizes.lg),
        Expanded(
          child: TextField(
            onChanged: (value) => searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Search anime, genres or studios…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () {},
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.lg),
        ValueListenableBuilder<String>(
          valueListenable: sortBy,
          builder: (context, current, _) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: current,
                    icon: const Icon(Icons.arrow_drop_down),
                    onChanged: (value) {
                      if (value != null) sortBy.value = value;
                    },
                    items: const [
                      DropdownMenuItem(value: 'Popularity', child: Text('Popularity')),
                      DropdownMenuItem(value: 'Rating', child: Text('Rating')),
                      DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.anime, required this.palette});

  final AnimeSummary anime;
  final _ColorPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary,
            palette.primary.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Transform.rotate(
              angle: -math.pi / 12,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: [
                      palette.primary.withValues(alpha: 0.05),
                      palette.accent.withValues(alpha: 0.25),
                      palette.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(320),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.triple),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spotlight',
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 2,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  anime.title,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Wrap(
                  spacing: AppSizes.md,
                  runSpacing: AppSizes.xs,
                  children: anime.genres
                      .take(6)
                      .map((genre) => Chip(label: Text(genre)))
                      .toList(),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  anime.synopsis ?? 'No synopsis available yet.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSizes.xl),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Continue watching'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingCarousel extends StatelessWidget {
  const _TrendingCarousel({required this.items});

  final List<_BrowsePreview> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          final anime = item.anime;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                width: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      item.palette.primary,
                      colorScheme.surface.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        anime.synopsis ?? 'Tap for details and episodes.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.amber.shade400, size: 20),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            anime.rating != null
                                ? anime.rating!.toStringAsFixed(1)
                                : 'NR',
                          ),
                          const SizedBox(width: AppSizes.md),
                          Text(
                            [
                              if (anime.yearLabel.isNotEmpty) anime.yearLabel,
                              if (anime.totalEpisodes != null)
                                '${anime.totalEpisodes} eps',
                            ].join(' • '),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.lg),
        itemCount: items.length,
      ),
    );
  }
}

class _AnimeCard extends StatelessWidget {
  const _AnimeCard({required this.preview});

  final _BrowsePreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final anime = preview.anime;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius * 1.5),
        onTap: preview.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius * 1.5),
            gradient: LinearGradient(
              colors: [
                preview.palette.primary,
                colorScheme.surface.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            preview.palette.primary.withValues(alpha: 0.7),
                            preview.palette.accent.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color:
                                  Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.md,
                                vertical: AppSizes.xs,
                              ),
                              child: Text(
                                _episodeLabel(anime),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  anime.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  anime.synopsis ?? 'No synopsis yet. Tap for more details.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(anime.type ?? 'Unknown'),
                    Text(anime.yearLabel),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _episodeLabel(AnimeSummary anime) {
    if (anime.totalEpisodes != null) {
      return '${anime.totalEpisodes} eps';
    }
    if (anime.duration != null) {
      return anime.duration!;
    }
    return 'Streaming';
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({
    required this.availableGenres,
    required this.selectedGenres,
  });

  final List<String> availableGenres;
  final ValueNotifier<Set<String>> selectedGenres;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: selectedGenres,
      builder: (context, current, _) {
        if (availableGenres.isEmpty) {
          return const SizedBox.shrink();
        }

        return Wrap(
          spacing: AppSizes.md,
          runSpacing: AppSizes.sm,
          children: availableGenres.map((genre) {
            final isSelected = current.contains(genre);
            return FilterChip(
              label: Text(genre),
              selected: isSelected,
              onSelected: (selected) {
                final next = Set<String>.from(current);
                if (selected) {
                  next.add(genre);
                } else {
                  next.remove(genre);
                }
                selectedGenres.value = next;
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _BrowsePreview {
  const _BrowsePreview({
    required this.anime,
    required this.palette,
    required this.onTap,
  });

  final AnimeSummary anime;
  final _ColorPalette palette;
  final VoidCallback onTap;
}

class _ColorPalette {
  const _ColorPalette(this.primary, this.accent);

  final Color primary;
  final Color accent;
}

extension on AnimeSummary {
  String get yearLabel {
    if (aired == null || aired!.isEmpty) return '';
    final match = RegExp(r'(19|20)\d{2}').firstMatch(aired!);
    return match?.group(0) ?? '';
  }
}

const _palettes = <_ColorPalette>[
  _ColorPalette(Color(0xFFDC2626), Color(0xFFF97316)),
  _ColorPalette(Color(0xFF1D4ED8), Color(0xFF38BDF8)),
  _ColorPalette(Color(0xFF10B981), Color(0xFFF472B6)),
  _ColorPalette(Color(0xFF7C3AED), Color(0xFFA855F7)),
  _ColorPalette(Color(0xFFF97316), Color(0xFFFACC15)),
  _ColorPalette(Color(0xFF0EA5E9), Color(0xFF38BDF8)),
  _ColorPalette(Color(0xFF6366F1), Color(0xFF60A5FA)),
  _ColorPalette(Color(0xFFEF4444), Color(0xFFF97316)),
  _ColorPalette(Color(0xFF0F172A), Color(0xFF22D3EE)),
];
