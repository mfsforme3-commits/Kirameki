# Kirameki Product Specification

## Vision
Deliver a premium, offline-capable anime streaming experience that mirrors the existing Next.js mock while supporting mobile, desktop, and TV platforms with minimal hosting overhead. Users should enjoy curated content, responsive playback, and secure authentication even when the central Supabase backend is offline.

## Target Platforms
- Android (phones, tablets)
- Android TV (Leanback / Google TV)
- iOS & iPadOS
- Windows (WinUI window embedding)
- macOS (desktop app via Flutter)

## Personas
- **Binge Watcher** — wants seamless playback, continue watching, and offline downloads
- **Collector** — curates personal watch list, filters by genre/year/status
- **Family Household** — multiple devices, uses local network pairing, needs kid-safe profiles (future)
- **Traveler** — often offline, relies on cached credentials and downloads

## Core User Journeys
1. **Browse Catalog**
   - Land on home/browse screen with hero carousel
   - Filter by genre, year, and status
   - Toggle between grid/list view
2. **Search & Discover**
   - Typeahead search with suggestions
   - Navigate to anime detail via results or curated sections
3. **View Anime Detail**
   - Read synopsis, metadata, ratings
   - Browse episodes list by season/status
   - Add/remove from My List
4. **Watch Episode**
   - Tap episode → Watch screen opens
   - Choose stream quality/server, toggle subtitles
   - Track playback position for continue watching
5. **Offline Auth & Login**
   - Register locally when Supabase offline → generate secure token
   - Login by decrypting local key with password/biometric
   - Pair new device via QR from logged-in device (no internet)
6. **Sync (When Online)**
   - Twice-daily Supabase windows: upload encrypted credential snapshots and playback progress
   - Resolve conflicts (latest timestamp wins, manual prompt for critical changes)

## Feature Table

| Area | Feature | Priority | Notes |
| --- | --- | --- | --- |
| Browse | Hero carousel, category chips, sort, grid/list toggle | P0 | Must match mock layout/motion |
| Detail | Metadata, episode sections, related shows, My List toggle | P0 | Leverage API `anime/:id` & `episodes/:id` |
| Watch | HLS playback, captions, intro/outro skip, quality/server switch | P0 | Use `stream` endpoint + track intros |
| My List | Add/remove, continue watching, offline persistence | P0 | Cache locally, sync when online |
| Search | Keyword search, suggestion dropdown | P0 | Hit `/search` + `/suggestion` endpoints |
| Auth | Local account create/login, QR pairing, Supabase sync | P0 | See `AUTH_SPEC.md` |
| Downloads | Episode download & playback offline | P1 | Only when permissible; uses offline storage |
| Profiles | Multiple profiles, restrictions | P2 | Defer unless time allows |
| Settings | Theme switch, playback defaults, sync/logging controls | P1 | Align with platform standards |

## UI Parity Requirements
- Match spacing, typography, and color usage from Next.js mock (Tailwind tokens → Flutter theme tokens)
- Maintain animated interactions: hover-to-focus conversions on desktop, focus rings on TV, subtle card lift animations
- Ensure custom cursor effect is replicated where applicable (desktop) or replaced with platform-appropriate focus states

## Non-Functional Requirements
- **Performance**: initial home load < 2s on mid-range mobile with warm cache; scrolling at 60fps on high-end devices
- **Offline**: app must boot and allow browsing cached data + login without internet; downloads playable offline
- **Security**: cryptographic operations use audited libraries; secrets never leave device unencrypted
- **Accessibility**: text scaling to 200%, screen reader labels, DPAD navigation, color contrast ≥ 4.5:1
- **Telemetry**: offline-friendly event queue; opts-in to anonymous metrics; flush during sync windows

## API Dependencies
- HiAnime API base `https://hianime-api-qdks.onrender.com/api/v1`
- Endpoints in use: `/home`, `/animes/*`, `/anime/:id`, `/episodes/:id`, `/servers`, `/stream`, `/search`, `/suggestion`
- Rate limiting unknown → implement client-side throttling and exponential backoff

## Acceptance Criteria
- Feature parity with mock for Browse, Detail, Watch, My List screens
- Offline auth flows validated via integration tests
- Continue watching state synced across 3 devices after scheduled sync window
- Cross-platform builds generated and smoke-tested on physical devices/emulators
