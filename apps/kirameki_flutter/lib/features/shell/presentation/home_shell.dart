import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kirameki_flutter/core/constants/app_sizes.dart';
import 'package:kirameki_flutter/routes/app_router.dart';
import 'package:kirameki_flutter/shared/widgets/kirameki_badge.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
}

class _HomeShellState extends State<HomeShell> {
  static const _destinations = <_Destination>[
    _Destination(
      label: 'Browse',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      route: BrowseRoute.path,
    ),
    _Destination(
      label: 'My List',
      icon: Icons.playlist_add_check,
      activeIcon: Icons.playlist_add_check_rounded,
      route: MyListRoute.path,
    ),
    _Destination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      route: SettingsRoute.path,
    ),
  ];

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final showRail = size.width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (showRail)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: NavigationRail(
                  selectedIndex: widget.navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.selected,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
                    child: KiramekiBadge(size: 52),
                  ),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.activeIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.85),
                      colorScheme.surface.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: widget.navigationShell,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showRail
          ? null
          : NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.activeIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }
}
