import 'package:flutter/material.dart';
import 'package:kirameki_flutter/core/constants/app_sizes.dart';

class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key});

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen>
    with SingleTickerProviderStateMixin {
  bool _showGrid = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF05060A), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xxl,
                    vertical: AppSizes.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Library',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                'Continue where you left off, even offline.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.grid_view_rounded),
                              ),
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.view_agenda_outlined),
                              ),
                            ],
                            selected: {_showGrid},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              setState(() => _showGrid = selection.first);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xxl),
                      Text(
                        'Continue watching',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      _ContinueWatchingStrip(items: _continueWatching),
                      const SizedBox(height: AppSizes.triple),
                      Text(
                        'Saved titles',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xxl,
                  vertical: AppSizes.xxl,
                ),
                sliver: _SliverResponsiveList(
                  showGrid: _showGrid,
                  items: _savedLibrary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverResponsiveList extends StatelessWidget {
  const _SliverResponsiveList({
    required this.showGrid,
    required this.items,
  });

  final bool showGrid;
  final List<_MyListEntry> items;

  @override
  Widget build(BuildContext context) {
    if (!showGrid) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _MyListListTile(entry: items[index]),
          childCount: items.length,
        ),
      );
    }

    final crossAxisCount = _resolveCrossAxisCount(context);
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _MyListGridCard(entry: items[index]),
        childCount: items.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSizes.lg,
        mainAxisSpacing: AppSizes.lg,
        childAspectRatio: 0.7,
      ),
    );
  }

  int _resolveCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1500) return 5;
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 640) return 2;
    return 1;
  }
}

class _ContinueWatchingStrip extends StatelessWidget {
  const _ContinueWatchingStrip({required this.items});

  final List<_ContinueWatchingEntry> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (items.isEmpty) {
      return Text(
        'No active sessions yet.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.lg),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  item.accent.withValues(alpha: 0.25),
                  colorScheme.surface.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    item.episode,
                    style: theme.textTheme.labelLarge,
                  ),
                  const Spacer(),
                  LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor:
                        colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MyListGridCard extends StatelessWidget {
  const _MyListGridCard({required this.entry});

  final _MyListEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius * 1.5),
        onTap: () {},
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius * 1.5),
            gradient: LinearGradient(
              colors: [
                entry.accent.withValues(alpha: 0.85),
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
                            entry.accent.withValues(alpha: 0.65),
                            entry.accent.withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  entry.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                LinearProgressIndicator(
                  value: entry.progress,
                  backgroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyListListTile extends StatelessWidget {
  const _MyListListTile({required this.entry});

  final _MyListEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.lg),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: entry.accent.withValues(alpha: 0.2),
          child: Text(
            entry.title.isNotEmpty
                ? entry.title.substring(0, 1).toUpperCase()
                : '?',
            style: theme.textTheme.titleMedium,
          ),
        ),
        title: Text(entry.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.xs),
            Text(entry.status),
            const SizedBox(height: AppSizes.xs),
            LinearProgressIndicator(
              value: entry.progress,
              backgroundColor:
                  colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {},
        ),
      ),
    );
  }
}

class _ContinueWatchingEntry {
  const _ContinueWatchingEntry({
    required this.title,
    required this.episode,
    required this.progress,
    required this.accent,
  });

  final String title;
  final String episode;
  final double progress;
  final Color accent;
}

class _MyListEntry {
  const _MyListEntry({
    required this.title,
    required this.status,
    required this.progress,
    required this.accent,
  });

  final String title;
  final String status;
  final double progress;
  final Color accent;
}

const _continueWatching = [
  _ContinueWatchingEntry(
    title: 'Blue Lock',
    episode: 'Episode 16 — Monster',
    progress: 0.65,
    accent: Color(0xFF0EA5E9),
  ),
  _ContinueWatchingEntry(
    title: 'One Piece',
    episode: 'Episode 214 — Pirate Hunter',
    progress: 0.32,
    accent: Color(0xFFF97316),
  ),
  _ContinueWatchingEntry(
    title: 'Frieren: Beyond Journey’s End',
    episode: 'Episode 12 — Daybreak',
    progress: 0.82,
    accent: Color(0xFF6366F1),
  ),
];

const _savedLibrary = [
  _MyListEntry(
    title: 'Steins;Gate',
    status: 'Episode 18 • 14m remaining',
    progress: 0.78,
    accent: Color(0xFF0F172A),
  ),
  _MyListEntry(
    title: 'Violet Evergarden',
    status: 'Completed • Rewatch ready',
    progress: 1.0,
    accent: Color(0xFF6366F1),
  ),
  _MyListEntry(
    title: 'Chainsaw Man',
    status: 'Episode 9 • Offline download',
    progress: 0.42,
    accent: Color(0xFFEF4444),
  ),
  _MyListEntry(
    title: 'Haikyuu!!',
    status: 'Episode 4 • Continue watching',
    progress: 0.22,
    accent: Color(0xFFF97316),
  ),
  _MyListEntry(
    title: 'Spy x Family',
    status: 'Episode 7 • Download expires in 2d',
    progress: 0.58,
    accent: Color(0xFF10B981),
  ),
  _MyListEntry(
    title: 'Fullmetal Alchemist: Brotherhood',
    status: 'Episode 46 • Resume on TV',
    progress: 0.71,
    accent: Color(0xFF7C3AED),
  ),
];
