import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kirameki_flutter/features/browse/presentation/browse_screen.dart';
import 'package:kirameki_flutter/features/my_list/presentation/my_list_screen.dart';
import 'package:kirameki_flutter/features/settings/presentation/settings_screen.dart';
import 'package:kirameki_flutter/features/shell/presentation/home_shell.dart';
import 'package:kirameki_flutter/features/splash/presentation/splash_screen.dart';
import 'package:kirameki_flutter/features/watch/presentation/watch_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashRoute {
  static const path = '/';
  static const name = 'splash';
}

class BrowseRoute {
  static const path = '/home/browse';
  static const name = 'browse';
}

class MyListRoute {
  static const path = '/home/my-list';
  static const name = 'my-list';
}

class SettingsRoute {
  static const path = '/home/settings';
  static const name = 'settings';
}

class WatchRoute {
  static const path = '/watch/:episodeId';
  static const name = 'watch';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    initialLocation: SplashRoute.path,
    navigatorKey: rootKey,
    routes: [
      GoRoute(
        path: SplashRoute.path,
        name: SplashRoute.name,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: BrowseRoute.path,
                name: BrowseRoute.name,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BrowseScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MyListRoute.path,
                name: MyListRoute.name,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MyListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: SettingsRoute.path,
                name: SettingsRoute.name,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: WatchRoute.path,
        name: WatchRoute.name,
        builder: (context, state) {
          final episodeId = state.pathParameters['episodeId'] ?? '';
          final args = state.extra is WatchScreenArgs
              ? state.extra as WatchScreenArgs
              : null;
          return WatchScreen(
            episodeId: episodeId,
            animeId: args?.animeId,
            initialEpisodes: args?.initialEpisodes,
            initialStreamType: args?.initialStreamType,
            initialServer: args?.initialServer,
          );
        },
      ),
    ],
  );
});
