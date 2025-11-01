import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirameki_flutter/core/logging/app_logger.dart';
import 'package:kirameki_flutter/core/logging/provider_logger.dart';

typedef AppBuilder = FutureOr<Widget> Function();

Future<void> bootstrap(AppBuilder builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.e('Flutter error', details.exception, details.stack);
  };

  runZonedGuarded(
    () async {
      final app = await builder();
      runApp(
        ProviderScope(
          observers: [if (!kReleaseMode) ProviderLogger()],
          child: app,
        ),
      );
    },
    (error, stackTrace) =>
        AppLogger.e('Uncaught zone error', error, stackTrace),
  );
}
