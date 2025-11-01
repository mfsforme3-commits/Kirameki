import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirameki_flutter/core/constants/app_sizes.dart';
import 'package:kirameki_flutter/data/hianime/models/episode_stream.dart';
import 'package:kirameki_flutter/data/hianime/models/episode_summary.dart';
import 'package:kirameki_flutter/features/watch/data/watch_providers.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WatchScreenArgs {
  const WatchScreenArgs({
    required this.animeId,
    this.initialEpisodes,
    this.initialStreamType,
    this.initialServer,
  });

  final String animeId;
  final List<EpisodeSummary>? initialEpisodes;
  final String? initialStreamType;
  final String? initialServer;
}

class WatchScreen extends ConsumerStatefulWidget {
  const WatchScreen({
    required this.episodeId,
    this.animeId,
    this.initialEpisodes,
    this.initialStreamType,
    this.initialServer,
    super.key,
  });

  final String episodeId;
  final String? animeId;
  final List<EpisodeSummary>? initialEpisodes;
  final String? initialStreamType;
  final String? initialServer;

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen> {
  final GlobalKey<_VideoPlayerPaneState> _playerKey =
      GlobalKey<_VideoPlayerPaneState>();
  late String _currentEpisodeId;
  late String _animeId;
  late String _streamType;
  late String _server;
  List<EpisodeSummary>? _prefetchedEpisodes;

  static const _availableTypes = ['sub', 'dub'];
  static const _availableServers = ['hd-1', 'hd-2', 'hd-3', 'hd-4'];

  @override
  void initState() {
    super.initState();
    _currentEpisodeId = widget.episodeId;
    _animeId = widget.animeId ?? _deriveAnimeId(widget.episodeId);
    _streamType = widget.initialStreamType ?? 'sub';
    _server = widget.initialServer ?? 'hd-2';
    _prefetchedEpisodes = widget.initialEpisodes;
  }

  @override
  Widget build(BuildContext context) {
    final episodesAsync = ref.watch(episodeListProvider(_animeId));
    final streamRequest = EpisodeStreamRequest(
      episodeId: _currentEpisodeId,
      type: _streamType,
      server: _server,
    );
    final streamAsync = ref.watch(episodeStreamProvider(streamRequest));

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Episode ${_episodeNumberFromId(_currentEpisodeId)}'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Stream type',
            initialValue: _streamType,
            onSelected: (value) => setState(() => _streamType = value),
            itemBuilder: (context) => _availableTypes
                .map((type) => PopupMenuItem(
                      value: type,
                      child: Text(type.toUpperCase()),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                children: [
                  const Icon(Icons.closed_caption),
                  const SizedBox(width: AppSizes.xs),
                  Text(_streamType.toUpperCase()),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Stream server',
            initialValue: _server,
            onSelected: (value) => setState(() => _server = value),
            itemBuilder: (context) => _availableServers
                .map((server) => PopupMenuItem(
                      value: server,
                      child: Text(server.toUpperCase()),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                children: [
                  const Icon(Icons.wifi_tethering),
                  const SizedBox(width: AppSizes.xs),
                  Text(_server.toUpperCase()),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showRail = constraints.maxWidth >= 1100;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xxl,
                    vertical: AppSizes.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      streamAsync.when(
                        data: (stream) => _VideoPlayerPane(
                          key: _playerKey,
                          stream: stream,
                          episodeId: _currentEpisodeId,
                        ),
                        loading: () => const AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stackTrace) => _StreamError(
                          message: error.toString(),
                          onRetry: () => ref
                              .refresh(episodeStreamProvider(streamRequest)),
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      Text(
                        'Playback controls',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      _PlaybackControls(
                        onSkipBack: () =>
                            _playerKey.currentState?.skipRelative(-10),
                        onPlayPause: () =>
                            _playerKey.currentState?.togglePlayPause(),
                        onSkipForward: () =>
                            _playerKey.currentState?.skipRelative(10),
                      ),
                      const SizedBox(height: AppSizes.triple),
                      Text(
                        'Episode details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'Episode $_currentEpisodeId from $_animeId',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSizes.triple),
                      Text(
                        'Key moments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      streamAsync.when(
                        data: (stream) => _TimelineView(stream: stream),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              if (showRail) ...[
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: episodesAsync.when(
                    data: (episodes) {
                      return _EpisodeList(
                        episodes: episodes,
                        currentEpisodeId: _currentEpisodeId,
                        onEpisodeSelected: (episode) {
                          setState(() => _currentEpisodeId = episode.id);
                        },
                      );
                    },
                    loading: () {
                      final prefetched = _prefetchedEpisodes;
                      if (prefetched != null && prefetched.isNotEmpty) {
                        return _EpisodeList(
                          episodes: prefetched,
                          currentEpisodeId: _currentEpisodeId,
                          onEpisodeSelected: (episode) {
                            setState(() => _currentEpisodeId = episode.id);
                          },
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    error: (error, stackTrace) {
                      final prefetched = _prefetchedEpisodes;
                      if (prefetched != null && prefetched.isNotEmpty) {
                        return _EpisodeList(
                          episodes: prefetched,
                          currentEpisodeId: _currentEpisodeId,
                          onEpisodeSelected: (episode) {
                            setState(() => _currentEpisodeId = episode.id);
                          },
                        );
                      }
                      return _EpisodesError(
                        message: error.toString(),
                        onRetry: () =>
                            ref.refresh(episodeListProvider(_animeId)),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _deriveAnimeId(String episodeId) {
    final parts = episodeId.split('::');
    if (parts.length >= 2) {
      return parts.first;
    }
    return episodeId;
  }

  static String _episodeNumberFromId(String episodeId) {
    final match = RegExp(r'ep=(\d+)').firstMatch(episodeId);
    return match?.group(1) ?? episodeId;
  }
}

class _EpisodeList extends StatelessWidget {
  const _EpisodeList({
    required this.episodes,
    required this.currentEpisodeId,
    required this.onEpisodeSelected,
  });

  final List<EpisodeSummary> episodes;
  final String currentEpisodeId;
  final ValueChanged<EpisodeSummary> onEpisodeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.xl),
      itemCount: episodes.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final selected = episode.id == currentEpisodeId;
        return ListTile(
          selected: selected,
          selectedTileColor:
              theme.colorScheme.primary.withValues(alpha: 0.1),
          leading: CircleAvatar(
            backgroundColor: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface.withValues(alpha: 0.3),
            child: Text(episode.number.toString()),
          ),
          title: Text(episode.title),
          subtitle: Text(episode.isFiller ? 'Filler' : 'Canon'),
          onTap: () => onEpisodeSelected(episode),
        );
      },
    );
  }
}

class _VideoPlayerPane extends StatefulWidget {
  const _VideoPlayerPane({
    super.key,
    required this.stream,
    required this.episodeId,
  });

  final EpisodeStream stream;
  final String episodeId;

  @override
  State<_VideoPlayerPane> createState() => _VideoPlayerPaneState();
}

class _VideoPlayerPaneState extends State<_VideoPlayerPane> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;
  WebViewController? _webViewController;
  bool _useWebFallback = false;
  bool _webViewLoading = false;
  String? _webFallbackUrl;
  String? _webFallbackError;
  int? _activeFallbackIndex;
  String? _activeFallbackLabel;
  Uri? _currentFallbackUri;
  int _webViewCrashCount = 0;
  bool _consoleSilenced = false;
  _AlternateStreamSource? _alternateStream;

  static const String _fallbackUserAgent =
      'Mozilla/5.0 (Linux; Android 13; KiramekiApp) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
  static const List<_FallbackEndpoint> _fallbackEndpoints = [
    _FallbackEndpoint(host: 'megaplay.buzz'),
    _FallbackEndpoint(host: 'vidwish.live'),
  ];
  static const String _silenceConsoleScript = '''
    (function() {
      if (!window || !window.console) return;
      const noop = function() {};
      ['log', 'info', 'debug'].forEach(function(level) {
        try {
          window.console[level] = noop;
        } catch (_) {}
      });
      if (typeof window.devtoolsDetector === 'object') {
        try {
          window.devtoolsDetector.addListener = noop;
          window.devtoolsDetector.removeAllListeners = noop;
        } catch (_) {}
      }
    })();
  ''';

  bool get isUsingFallback => _useWebFallback;
  List<WebFallbackSource> get _fallbackSources =>
      widget.stream.webFallbackSources;
  bool get _hasFallbacks => _fallbackSources.isNotEmpty;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initializePlayback);
  }

  @override
  void didUpdateWidget(covariant _VideoPlayerPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream.url != widget.stream.url ||
        oldWidget.stream.webFallbackUrl != widget.stream.webFallbackUrl ||
        oldWidget.episodeId != widget.episodeId) {
      _resetPlayback();
      Future.microtask(_initializePlayback);
    }
  }

  @override
  void dispose() {
    _resetPlayback();
    super.dispose();
  }

  void _resetPlayback() {
    _disposeController();
    _teardownWebFallback();
    _alternateStream = null;
  }

  Future<void> _initializePlayback() async {
    final stream = widget.stream;
    final directUrl = stream.url.trim();
    final canAttemptNative = stream.hasDirectStream && directUrl.isNotEmpty;

    if (canAttemptNative) {
      var uri = Uri.tryParse(directUrl);
      if (uri != null) {
        final candidates = _headerCandidatesFor(directUrl);
        for (final headers in candidates) {
          final ok = await _probeDirectStream(
            uri,
            headers: headers,
          );
          if (ok) {
            await _startNativePlayback(uri, headers);
            return;
          }
        }

        if (_shouldAttemptAlternate(probe.statusCode)) {
          final alternate = await _resolveAlternateStream(uri);
          if (alternate != null) {
            uri = alternate.uri;
            final altHeaders = _headersForUri(uri, refererOverride: alternate.referer);
            final altProbe = await _probeDirectStream(
              uri,
              headers: altHeaders,
            );
            if (altProbe.isOk) {
              _alternateStream = alternate;
              await _startNativePlayback(uri, altHeaders);
              return;
            }
          }
        }
      }
    }

    if (_hasFallbacks || stream.hasWebFallback) {
      _startWebFallback();
    } else {
      setState(() {
        _useWebFallback = true;
        _webFallbackError = 'No playable sources available.';
      });
    }
  }

  Future<_ProbeResult> _probeDirectStream(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .get(
            uri,
            headers: {
              if (headers != null) ...headers,
              'Range': 'bytes=0-1',
            },
          )
          .timeout(const Duration(seconds: 6));
      final ok = response.statusCode == 200 || response.statusCode == 206;
      return _ProbeResult(isOk: ok, statusCode: response.statusCode);
    } catch (_) {
      return const _ProbeResult(isOk: false);
    }
  }

  bool _shouldAttemptAlternate(int? statusCode) {
    if (statusCode == null) return true;
    return statusCode == 401 || statusCode == 403;
  }

  Future<_AlternateStreamSource?> _resolveAlternateStream(Uri uri) async {
    final cached = _alternateStream;
    if (cached != null) {
      return cached;
    }

    final sourceId = _extractSourceId(uri);
    if (sourceId == null) {
      return null;
    }

    for (final endpoint in _fallbackEndpoints) {
      try {
        final response = await http
            .get(
              endpoint.buildUri(sourceId),
              headers: endpoint.headers,
            )
            .timeout(const Duration(seconds: 6));
        if (response.statusCode != 200) {
          continue;
        }
        final payload = jsonDecode(response.body);
        if (payload is! Map<String, dynamic>) {
          continue;
        }
        final sources = payload['sources'];
        final file = sources is Map<String, dynamic>
            ? sources['file'] as String?
            : null;
        if (file == null || file.isEmpty) {
          continue;
        }
        final resolvedUri = Uri.tryParse(file.trim());
        if (resolvedUri == null) {
          continue;
        }
        return _AlternateStreamSource(
          uri: resolvedUri,
          referer: endpoint.referer,
        );
      } catch (_) {
        // Ignore resolution errors and try the next endpoint.
      }
    }

    return null;
  }

  String? _extractSourceId(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length < 2) {
      return null;
    }
    return segments[segments.length - 2];
  }

  Future<void> _startNativePlayback(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final controller = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: headers,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    _initialization = controller.initialize();
    try {
      await _initialization;
      if (!mounted) return;
      controller.addListener(() {
        final value = controller.value;
        if (value.hasError) {
          _handlePlaybackFailureMessage(
              value.errorDescription ?? 'Playback error');
        }
      });
      await controller.play();
      setState(() {
        _useWebFallback = false;
        _webFallbackUrl = null;
        _webFallbackError = null;
        _webViewLoading = false;
      });
    } catch (error) {
      _handlePlaybackError(error, StackTrace.current);
    }
  }

  void _handlePlaybackError(Object error, StackTrace stackTrace) {
    debugPrint('Video playback error: $error\n$stackTrace');
    _handlePlaybackFailureMessage(error.toString());
  }

  void _handlePlaybackFailureMessage(String errorMessage) {
    if (!mounted) return;
    final lower = errorMessage.toLowerCase();
    final authLike = lower.contains('403') ||
        lower.contains('401') ||
        lower.contains('forbidden') ||
        lower.contains('unauthorized') ||
        lower.contains('access') ||
        lower.contains('permission');
    if (!_useWebFallback) {
      final snackText = authLike
          ? 'Direct stream blocked. Switching to fallback player.'
          : 'Playback failed. Switching to fallback player.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackText),
        ),
      );
    }
    _disposeController();
    _startWebFallback();
  }

  void _startWebFallback({
    int? sourceIndex,
    String? explicitUrl,
    bool forceRecreate = false,
  }) {
    if (!mounted) return;

    final sources = _fallbackSources;
    String? resolvedUrl = explicitUrl;
    String? resolvedLabel;
    int? resolvedIndex = sourceIndex;

    if (resolvedUrl == null) {
      if (resolvedIndex != null &&
          resolvedIndex >= 0 &&
          resolvedIndex < sources.length) {
        final source = sources[resolvedIndex];
        resolvedUrl = source.url;
        resolvedLabel = source.label;
      } else if (sources.isNotEmpty) {
        final source = sources.first;
        resolvedUrl = source.url;
        resolvedLabel = source.label;
        resolvedIndex = 0;
      } else {
        resolvedUrl = widget.stream.webFallbackUrl ?? _deriveMegaplayUrl();
        resolvedLabel = 'Fallback';
      }
    } else if (resolvedIndex != null &&
        resolvedIndex >= 0 &&
        resolvedIndex < sources.length) {
        resolvedLabel = sources[resolvedIndex].label;
    }

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      setState(() {
        _useWebFallback = true;
        _webViewController = null;
        _webFallbackUrl = null;
        _webViewLoading = false;
        _webFallbackError =
            'No alternate stream available. Try another server.';
        _activeFallbackIndex = null;
        _activeFallbackLabel = null;
      });
      return;
    }

    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      setState(() {
        _useWebFallback = true;
        _webViewController = null;
        _webFallbackUrl = resolvedUrl;
        _webViewLoading = false;
        _webFallbackError = 'Invalid fallback URL.';
        _activeFallbackIndex = resolvedIndex;
        _activeFallbackLabel = resolvedLabel;
      });
      return;
    }

    _currentFallbackUri = uri;
    _consoleSilenced = false;

    setState(() {
      _useWebFallback = true;
      _webFallbackUrl = resolvedUrl;
      _webViewLoading = true;
      _webFallbackError = null;
      _activeFallbackIndex = resolvedIndex;
      _activeFallbackLabel = resolvedLabel;
      _initialization = null;
    });

    final shouldCreateController = forceRecreate || _webViewController == null;

    if (shouldCreateController) {
      _webViewController?.clearCache();
      final controller = _createWebViewController();
      _webViewController = controller;
      _webViewCrashCount = 0;
      _loadFallbackUri(controller, uri);
    } else {
      _webViewController!.clearCache();
      _loadFallbackUri(_webViewController!, uri);
      _webViewCrashCount = 0;
    }
  }

  void togglePlayPause() {
    if (_useWebFallback) return;
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  void skipRelative(int seconds) {
    if (_useWebFallback) return;
    final controller = _controller;
    if (controller == null) return;
    final current = controller.value.position;
    final target = current + Duration(seconds: seconds);
    final duration = controller.value.duration;
    Duration clamped;
    if (duration <= Duration.zero) {
      clamped = Duration.zero;
    } else if (target < Duration.zero) {
      clamped = Duration.zero;
    } else if (target > duration) {
      clamped = duration;
    } else {
      clamped = target;
    }
    controller.seekTo(clamped);
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _initialization = null;
  }

  void _teardownWebFallback() {
    _webViewController?.clearCache();
    _webViewController = null;
    _webFallbackUrl = null;
    _webFallbackError = null;
    _webViewLoading = false;
    _useWebFallback = false;
    _activeFallbackIndex = null;
    _activeFallbackLabel = null;
    _currentFallbackUri = null;
    _webViewCrashCount = 0;
    _consoleSilenced = false;
  }

  void _switchFallback(int index) {
    _startWebFallback(sourceIndex: index);
  }

  void _switchBackToDirect() {
    _disposeController();
    _teardownWebFallback();
    setState(() {
      _useWebFallback = false;
    });
    _initializePlayback();
  }

  PlatformWebViewControllerCreationParams _createPlatformParams() {
    if (!kIsWeb && Platform.isIOS) {
      return WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    }
    return const PlatformWebViewControllerCreationParams();
  }

  WebViewController _createWebViewController() {
    final controller =
        WebViewController.fromPlatformCreationParams(_createPlatformParams());

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(_fallbackUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _webViewLoading = true;
              _webFallbackError = null;
            });
            _consoleSilenced = false;
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _webViewLoading = false;
              _webFallbackError = null;
            });
            _webViewCrashCount = 0;
            _ensureConsoleSilenced(controller);
          },
          onNavigationRequest: (request) => NavigationDecision.navigate,
          onWebResourceError: _handleWebViewError,
        ),
      )
      ..enableZoom(false);

    final platformController = controller.platform;
    if (platformController is AndroidWebViewController) {
      platformController.setMediaPlaybackRequiresUserGesture(false);
    } else if (platformController is WebKitWebViewController) {
      platformController.setAllowsBackForwardNavigationGestures(false);
    }

    return controller;
  }

  Future<void> _loadFallbackUri(WebViewController controller, Uri uri) {
    return controller.loadRequest(
      uri,
      headers: const {
        'Referer': 'https://hianime.to/',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    );
  }

  void _ensureConsoleSilenced(WebViewController controller) {
    if (_consoleSilenced) return;
    controller.runJavaScript(_silenceConsoleScript).then((_) {
      _consoleSilenced = true;
    }).catchError((_) {
      // No-op: ignoring console override failures.
    });
  }

  void _handleWebViewError(WebResourceError error) {
    if (!mounted) return;

    final isRendererCrash = error.errorType ==
            WebResourceErrorType.webContentProcessTerminated ||
        error.errorType == WebResourceErrorType.webViewInvalidated;

    setState(() {
      _webViewLoading = false;
      _webFallbackError = isRendererCrash
          ? 'Fallback player crashed. Retrying...'
          : error.description;
    });

    if (isRendererCrash &&
        _currentFallbackUri != null &&
        _webViewCrashCount < 2) {
      _webViewCrashCount += 1;
      Future.microtask(() {
        if (!mounted) return;
        _startWebFallback(
          sourceIndex: _activeFallbackIndex,
          explicitUrl: _currentFallbackUri!.toString(),
          forceRecreate: true,
        );
      });
    }
  }

  String? _deriveMegaplayUrl() {
    final match = RegExp(r'ep=(\d+)').firstMatch(widget.episodeId);
    if (match == null) return null;
    final episodeNumber = match.group(1);
    if (episodeNumber == null) return null;
    final streamType = widget.stream.streamType.toLowerCase();
    return 'https://megaplay.buzz/stream/s-2/$episodeNumber/$streamType';
  }

  @override
  Widget build(BuildContext context) {
    if (_useWebFallback) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_webViewController != null)
              WebViewWidget(controller: _webViewController!)
            else
              const ColoredBox(color: Colors.black),
            if (widget.stream.hasDirectStream)
              Positioned(
                top: AppSizes.md,
                right: AppSizes.md,
                child: FilledButton.tonal(
                  onPressed: _switchBackToDirect,
                  child: const Text('Try direct stream'),
                ),
              ),
            Positioned(
              top: AppSizes.md,
              left: AppSizes.md,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppSizes.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.xs,
                  ),
                  child: Text(
                    'Web fallback player'
                    '${_activeFallbackLabel != null ? ' · ${_activeFallbackLabel!}' : ''}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            if (_webViewLoading)
              const Center(child: CircularProgressIndicator()),
            if (_webFallbackError != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  margin: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppSizes.md),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        _webFallbackError ?? 'Unknown error',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      if (_webFallbackUrl != null) ...[
                        const SizedBox(height: AppSizes.sm),
                        SelectableText(
                          _webFallbackUrl!,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (_fallbackSources.length > 1)
              Positioned(
                bottom: AppSizes.md,
                left: AppSizes.md,
                right: AppSizes.md,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.xs,
                  children: [
                    for (var i = 0; i < _fallbackSources.length; i++)
                      ChoiceChip(
                        label: Text(_fallbackSources[i].label),
                        selected: _activeFallbackIndex == i,
                        onSelected: (selected) {
                          if (selected) {
                            _switchFallback(i);
                          }
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(color: Colors.black),
      );
    }

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(controller),
              if (_hasFallbacks)
                Positioned(
                  top: AppSizes.md,
                  right: AppSizes.md,
                  child: FilledButton.tonal(
                    onPressed: () => _startWebFallback(),
                    child: const Text('Use fallback player'),
                  ),
                ),
              Positioned(
                left: AppSizes.lg,
                right: AppSizes.lg,
                bottom: AppSizes.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            if (controller.value.isPlaying) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                            setState(() {});
                          },
                          icon: Icon(
                            controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Text(
                          _formatDuration(controller.value.position),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        const Text('/', style: TextStyle(color: Colors.white60)),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          _formatDuration(controller.value.duration),
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  List<Map<String, String>> _headerCandidatesFor(String url) {
    final uniqueReferers = <String>{};
    final candidates = <Map<String, String>>[];

    void addReferer(String? referer) {
      final normalized = _normalizeReferer(referer);
      if (normalized == null) return;
      if (!uniqueReferers.add(normalized)) return;
      final origin = Uri.parse(normalized).origin;
      candidates.add(_buildHeaders(origin, normalized));
    }

    final fallbackSources = _fallbackSources;
    final preferredFallbacks = <String>[];
    final secondaryFallbacks = <String>[];

    for (final source in fallbackSources) {
      final label = source.label.toLowerCase();
      if (label.contains('vidwish')) {
        preferredFallbacks.add(source.url);
      } else {
        secondaryFallbacks.add(source.url);
      }
    }

    for (final referer in preferredFallbacks) {
      addReferer(referer);
    }
    for (final referer in secondaryFallbacks) {
      addReferer(referer);
    }

    addReferer(widget.stream.webFallbackUrl);

    final directUri = Uri.tryParse(url);
    if (directUri != null && directUri.hasScheme && directUri.host.isNotEmpty) {
      addReferer(directUri.origin);
    }

    addReferer('https://hianime.to/');

    return candidates;
  }

  String? _normalizeReferer(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    final hasQuery = uri.hasQuery;
    final base = uri.toString();
    if (hasQuery || base.endsWith('/')) {
      return base;
    }
    return '$base/';
  }

  Map<String, String> _buildHeaders(String origin, String referer) {
    final normalizedOrigin = origin.endsWith('/')
        ? origin.substring(0, origin.length - 1)
        : origin;
    return {
      'Referer': referer,
      'Origin': normalizedOrigin,
      'User-Agent': _fallbackUserAgent,
      'Accept':
          'application/vnd.apple.mpegurl,application/x-mpegurl;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
    };
  }

  String? _inferReferer(Uri? uri) {
    if (uri == null) return null;
    final host = uri.host;
    if (host.contains('dotstream') || host.contains('megaplay')) {
      return 'https://megaplay.buzz/';
    }
    if (host.contains('vidwish') || host.contains('vizcloud') || host.contains('wishfast')) {
      return 'https://vidwish.live/';
    }
    if (host.contains('watching.onl') && _alternateStream != null) {
      return _alternateStream!.referer;
    }
    return null;
  }

  String _originFrom(String referer) {
    try {
      final uri = Uri.parse(referer);
      final buffer = StringBuffer()
        ..write(uri.scheme)
        ..write('://')
        ..write(uri.host);
      if (uri.hasPort && uri.port != 80 && uri.port != 443) {
        buffer
          ..write(':')
          ..write(uri.port);
      }
      return buffer.toString();
    } catch (_) {
      return 'https://hianime.to';
    }
  }
}

class _AlternateStreamSource {
  const _AlternateStreamSource({required this.uri, required this.referer});

  final Uri uri;
  final String referer;
}

class _FallbackEndpoint {
  const _FallbackEndpoint({required this.host});

  final String host;

  Uri buildUri(String id) => Uri.https(host, '/stream/getSources', {'id': id});

  String get referer => 'https://$host/';

  Map<String, String> get headers => {
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': referer,
        'Accept': 'application/json, text/plain, */*',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13; Kirameki) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      };
}

class _ProbeResult {
  const _ProbeResult({required this.isOk, this.statusCode});

  final bool isOk;
  final int? statusCode;
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.onSkipBack,
    required this.onPlayPause,
    required this.onSkipForward,
  });

  final VoidCallback onSkipBack;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipForward;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.lg,
      runSpacing: AppSizes.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: onSkipBack,
          icon: const Icon(Icons.replay_10_rounded),
          label: const Text('10s Back'),
        ),
        FilledButton.icon(
          onPressed: onPlayPause,
          icon: const Icon(Icons.pause_circle_rounded),
          label: const Text('Play/Pause'),
        ),
        FilledButton.icon(
          onPressed: onSkipForward,
          icon: const Icon(Icons.forward_10_rounded),
          label: const Text('10s Forward'),
        ),
      ],
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({required this.stream});

  final EpisodeStream stream;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (stream.intro != null) {
      chips.add('Intro ${stream.intro!.start.toInt()}s - ${stream.intro!.end.toInt()}s');
    }
    if (stream.outro != null) {
      chips.add('Outro ${stream.outro!.start.toInt()}s - ${stream.outro!.end.toInt()}s');
    }
    if (chips.isEmpty) {
      chips.add('No key moments available');
    }

    return Wrap(
      spacing: AppSizes.md,
      runSpacing: AppSizes.sm,
      children: chips.map((label) => Chip(label: Text(label))).toList(),
    );
  }
}

class _StreamError extends StatelessWidget {
  const _StreamError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: AppSizes.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.md),
            FilledButton(onPressed: onRetry, child: const Text('Retry stream')),
          ],
        ),
      ),
    );
  }
}

class _EpisodesError extends StatelessWidget {
  const _EpisodesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: AppSizes.sm),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.md),
          FilledButton(onPressed: onRetry, child: const Text('Retry')), 
        ],
      ),
    );
  }
}
