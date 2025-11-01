import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirameki_flutter/core/logging/app_logger.dart';

class ProviderLogger extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    AppLogger.d('Provider added: ${provider.name ?? provider.runtimeType}');
    super.didAddProvider(provider, value, container);
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    AppLogger.d('Provider updated: ${provider.name ?? provider.runtimeType}');
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    AppLogger.d('Provider disposed: ${provider.name ?? provider.runtimeType}');
    super.didDisposeProvider(provider, container);
  }
}
