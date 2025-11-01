# Kirameki Architecture Overview

## Technology Choices
- **Flutter 3.x** — single codebase with mature support across mobile, desktop, and embedded; strong community for TV UX
- **Dart** — language for Flutter with sound null safety and isolates (background work)
- **State Management** — `riverpod` for dependency injection + state; `freezed` for immutable models
- **Networking** — `dio` with interceptors, caching, retry policies
- **Persistence** — `isar` (high performance NoSQL) for offline cache + watchlist, `shared_preferences` for lightweight flags
- **Secure Storage** — `flutter_secure_storage` (Keychain/KeyStore) for master keys, plus OS biometrics
- **Video Playback** — `video_player` + `chewie` for HLS; fallback to `better_player` if DRM variants emerge
- **Background Tasks** — `workmanager` (Android), `bg_app_refresh` (iOS), custom scheduling for desktop
- **Dependency Injection** — `riverpod` providers; modular service locators per feature
- **Testing** — `flutter_test`, `integration_test`, golden tests with `alchemist`

## Layered Architecture

```
presentation/
  features/
    browse/
    detail/
    watch/
    my_list/
  widgets/
  themes/
domain/
  models/
  repositories/
  usecases/
data/
  sources/
    remote/ (HiAnime client)
    local/ (Isar, secure storage)
  repositories_impl/
  dto/
shared/
  utils/
  services/ (auth manager, sync engine, connectivity)
  platform/
```

### Presentation Layer
- Uses declarative UI via Flutter widgets
- Feature modules follow MVU-style pattern with Riverpod state notifiers
- Responsive layouts with `LayoutBuilder` and `Breakpoints`
- TV support via focusable widgets and `FocusTraversalGroup`

### Domain Layer
- Defines `Anime`, `Episode`, `UserAccount`, `DeviceToken`, `PlaybackSession` entities
- `UseCase` classes execute business logic (e.g., `FetchPopularAnimeUseCase`, `StartOfflineLoginUseCase`)
- Interface-driven repos allow mocking in tests

### Data Layer
- Remote data sources wrap HiAnime endpoints with typed DTOs and request builders
- Local data sources expose local caches, downloads manager, key vault
- Repository implementations merge remote + local, applying caching and conflict policies

## Offline-First Data Flow
1. UI requests data via domain use case
2. Repository returns cached copy immediately
3. Concurrently triggers remote fetch (if online)
4. On success, updates cache and emits new domain models
5. Sync engine tracks dirty entities (watchlist, playback) for eventual upload

## Authentication & Sync Components
- `AuthController` (presentation) interacts with `AuthUseCases`
- `CredentialService` handles key generation and secure storage
- `SyncCoordinator` orchestrates scheduled Supabase sync windows, using HTTP client when connection available
- `QrLinkService` spawns local HTTP/WebSocket server on device and generates ephemeral QR payloads

## Platform Abstractions
- `PlatformConfig` for platform-specific toggles (TV layout, pointer vs DPAD)
- `VideoPlatformAdapter` to handle HLS capabilities, DRM checks
- `StorageQuotaManager` to enforce download limits per platform

## CI/CD Pipeline
- GitHub Actions or Codemagic for builds
- Matrix build jobs: `android-apk`, `android-appbundle`, `ios-ipa`, `macos-dmg`, `windows-msix`
- Automated tests run on pull requests; integration tests on nightly schedule
- Artifacts uploaded to release channel or internal distribution

## Telemetry & Logging
- Local log buffer via `logger` package
- Telemetry events queued into SQLite table, flushed on sync
- Crash reporting via optional Sentry integration (configurable, can be disabled offline)

## Internationalization Strategy
- Use Flutter `intl` package; default locale English
- Resource files per locale; fallback to EN
- Support right-to-left (future) with `Directionality`

## Accessibility Considerations
- Focus order definitions for TV remote
- Semantic labels for cards, buttons, playback controls
- Support platform text scaling and dark/light contrast

## Extensibility
- Additional content providers can be added via new remote data sources adhering to `ContentProvider` interface
- DRM-protected streams can integrate with platform-specific players via `PlatformInterface`
- Future features (profiles, parental controls) extend domain layer without touching core UI modules
