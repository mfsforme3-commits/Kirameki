# Kirameki — Delivery Plan

Goal: Port the existing Next.js mock into a fully functional, offline‑first, cross‑platform anime streaming app (Windows, macOS, Android, Android TV, iOS) using the HiAnime API, with a local-first auth model and optional Supabase sync windows.

## Workstreams Overview
- **WS1 · Product & UX** — lock requirements, accessibility, localization scope, TV ergonomics, mock parity checklist
- **WS2 · Platform Scaffold** — Flutter workspace, CI pipelines, DevOps, shared design system
- **WS3 · Content & Playback** — API integration, caching, streaming pipeline, offline downloads
- **WS4 · Identity & Sync** — local-first auth, cryptography, multi-device flows, Supabase sync windows
- **WS5 · Packaging & QA** — release automation, store checklists, regression suites

## Timeline & Milestones (6 Weeks)

| Week | Milestone | Definition of Done |
| --- | --- | --- |
| 0 | Discovery Complete | Requirements doc, parity checklist, legal review, tech stack ratified |
| 1 | Scaffold Ready | Flutter project baseline, CI smoke build, shared theme + navigation shell |
| 2 | Core Screens Alpha | Browse, Detail, Watch, My List wired to API/cache with mock auth |
| 3 | Offline Auth Beta | Local account lifecycle, QR pairing, sync window stub, security review |
| 4 | Feature Complete | Downloads (where allowed), continue watching sync, TV UX polished |
| 5 | Release Candidate | Multi-platform packages signed, QA exit report, perf thresholds met |

## Phase Breakdown

### Phase 0 — Foundation & Spec (Week 0)
- Validate feature list against budget and licensing constraints
- Confirm device/platform matrix, minimum OS versions, input methods
- Finalize Flutter + supporting stack; capture architecture decisions (ADR)
- Produce Product Spec and UI Parity matrices

### Phase 1 — Scaffold & Core Infrastructure (Week 1)
- Create Flutter workspace with modular structure (app, data, domain, shared UI)
- Implement adaptive theming, typography, spacing tokens, icon strategy
- Add network layer (Dio + interceptors) with typed endpoints for HiAnime API
- Introduce local persistence (Isar or sqflite) with repository abstraction
- Set up background sync scheduler and connectivity observer services

### Phase 2 — UI Porting (Week 2)
- Port Browse UX including search, genre filters, list/grid toggle, hero states
- Implement Anime Detail with related lists, episode tabs, metadata
- Build Watch screen with HLS playback (chewie/video_player + subtitles)
- Migrate My List with offline caching, skeleton states, continue watching tiles
- Ensure motion/animation parity using `flutter_animate` or `rive` where needed

### Phase 3 — Offline‑First Auth (Week 3)
- Design secure local account store (OS keychain + encrypted local DB)
- Implement account creation: password → Argon2id → unwrap device secret
- Build offline login flow with recovery tokens and biometric unlock hooks
- Create QR-based multi-device login: ephemeral handshake + local approval UI
- Develop Supabase sync client triggered during twice-daily online windows

### Phase 4 — Enhancements & Sync (Week 4)
- Implement downloadable episodes (if HLS segments legally cacheable)
- Add device-to-device local network pairing fallback (websocket + QR)
- Sync continue watching + preferences across devices via encrypted blobs
- Polish TV UX: focus states, remote shortcuts, auto-play next episode

### Phase 5 — Packaging & QA (Week 5)
- Build installers/bundles for Android, iOS, macOS, Windows
- Run automated UI tests (Flutter integration tests) and performance traces
- Validate offline scenarios (first-run offline, partial sync, key rotation)
- Prepare store metadata, privacy policy, and release readiness checklist

## Delivery Artifacts
- Flutter app repo under `apps/kirameki_flutter`
- Documentation: `docs/PRODUCT_SPEC.md`, `docs/ARCHITECTURE.md`, `docs/AUTH_SPEC.md`, `docs/UI_PARITY_CHECKLIST.md`
- CI pipelines (GitHub Actions) for build/test, artifact upload per platform
- QA assets: test plans, automated test suites, manual regression matrix

## Risks & Mitigations
- **HLS/DRM variance** — Primary player via `video_player` with platform fallbacks; early device matrix testing
- **API instability** — Typed DTOs with tolerant parsing, response caching, feature flags for fallback data
- **Offline download legality** — Ship disabled flag; require explicit user confirmation and content rights check
- **Supabase downtime** — All critical flows local-first; sync retries with exponential backoff; conflict resolution rules
- **Battery/data usage** — Adaptive sync schedules, user controls, background task limits per OS
