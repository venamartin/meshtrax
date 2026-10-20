# Offline maps: integration roadmap

This file says how traxmap's offline vector maps replace MeshTrax's online raster maps: the screens, the order of work, and how each step is tested. Agreed with Martin on 2026-10-17, 18 and 19. Companion files:

- [`offline-maps.md`](offline-maps.md): decisions, pitfalls and open questions.
- [`park-maps.md`](park-maps.md): park overlays on the app side.
- traxmapmaker's [`FINDINGS.md`](https://github.com/venamartin/traxmapmaker/blob/main/FINDINGS.md) §1: the server contract. Everything the app downloads from `maps.meshtrax.io`, one module per data set (1.1 common, 1.2 regions, 1.3 map packs, 1.4 charts, 1.5 routing, 1.6 overlays).

## Status

Last updated 2026-10-19.

**Data on R2:** traxmapmaker serves a frozen test catalogue at `https://maps.meshtrax.io/dev/`:
- `index.json` with Rhode Island (`osm` 34.1 MB, `base`/USGS 15.8 MB, contours 20 ft 1.7 MB and 10 m 1.0 MB) and the Watsonville test packs;
- `picker.geojson` (version 1, 136 regions).

Not published yet:
- **The root `index.json`:** it returns 404 until the first North America cuts.
- **Charts (1.4):** Puerto Rico and Virgin Islands come first.
- **Routing (1.5).**
- **Overlays (1.6).**

**App:** Phase 1 is in progress on the local branch `feat/offline-maps`. Martin asked for local commits only, for now.

## How we work

### On the Pi

All UI testing is done on the Raspberry Pi as a Linux desktop app, with hot reload. Phones are only used at gates G1 and G2, and for phone-only features: Android 14 UIDT, iOS background transfers, GPS permissions, BRouter.

```sh
flutter run -d linux --dart-define=MAP_INDEX_URL=https://maps.meshtrax.io/dev/index.json
```

- **VS Code:** a local `.vscode/launch.json` (gitignored) with `"deviceId": "linux"` and the same `--dart-define` in `toolArgs`.
- **Reloading:**
  - Hot reload (save, or `r`) covers widget changes.
  - Hot restart (`R`) is needed after changes to `main()`, providers or service start-up.
  - Changing a `--dart-define` needs a full restart.
- **Test data:**
  - Rhode Island: 52.6 MB in total.
  - Watsonville test region: 16.8 MB, with a charts pack.
- **Pause and resume:** home internet is too fast to catch a pause. Use traxmapmaker's throttled server instead: publish locally, run `./viewer/serve.py --rate 8`, and point the app at `--dart-define=MAP_INDEX_URL=http://127.0.0.1:8000/out/published/index.json`.
- **Installed packs on Linux:** `~/.local/share/com.meshtrax.app/maps/`. Delete it for a first-run test.
- **Offline:** `nmcli networking off` / `on`.
- **Radio:** not needed for Offline maps or the no-radio Map. Connect the USB radio (`/dev/ttyACM0`) for node maps, path trace, line of sight and the repeater mini-map.
- **Every change:** `flutter analyze`, then `flutter test` at the root and in `packages/traxmap`.

### With traxmapmaker

The two Claude sessions on the Pi message each other directly. The notes are the durable record:
- **The data contract:** traxmapmaker's FINDINGS §1. MeshTrax reads it but never edits it.
- **The app plan:** this file.

traxmapmaker sends a message:
- before changing anything in §1;
- when the root `index.json` goes live;
- when charts, routing or overlays land on `dev/`.

## Screens

### S0. Scanner screen ⋮ menu

`lib/screens/scanner_screen.dart`. Today the menu has only "Auto-connect on startup". It gains:
- **Offline maps:** download and manage maps before connecting.
- **Map:** the main map in no-radio mode.

Test: auto-connect firing while either of these is open.

### S1. Main map

`lib/screens/map_screen.dart`, "Node Map".

```
┌──────────────────────────────────────────────┐
│ ‹(POI/no-radio)  Node Map      ⦿radar  LOS  ⋮ │  radar and ⋮ hidden in no-radio mode
├──────────────────────────────────────────────┤
│ ☁ Online map · Download Rhode Island ›      ✕│  coverage banner (only when not covered)
│                                ┌───────────┐ │
│   vector map  /  online raster │ 12 nodes ▾│ │  legend card (hidden in no-radio mode)
│      ● teal "You" (radio)      └───────────┘ │
│            ◉ blue dot + accuracy (phone GPS) │
│                                         [≋]  │  layers → S2
│                                         [◎]  │  centre on me
│                                         [+]  │  desktop only
│                                         [−]  │  desktop only
│ ▍Not for navigation  (charts only)       [⚲] │  filter FAB (hidden in no-radio mode)
│ © OpenStreetMap contributors · USGS…    (chip)│  credits chip, tap to expand
├──────────────────────────────────────────────┤
│           [ Chats ]        [ Map ]           │  QuickSwitchBar (hidden: POI link, no-radio)
└──────────────────────────────────────────────┘
```

**Map surface:** vector tiles where an installed pack covers the view centre, and online OSM raster tiles elsewhere. Raster tiles load on demand only, with a disk cache.

**Coverage banner:**
- Online: "Online map · Download {region} ›", which opens that region's detail (S3b).
- Offline: "No offline map here · Offline maps ›".
- ✕ hides the banner for the session.

**Centre-on-me:**

| State | Behaviour |
| --- | --- |
| Not asked yet | `my_location` icon. The first tap asks for permission. |
| Searching | `location_searching` icon |
| Denied | `location_disabled` icon, and a SnackBar with a Settings action |
| Linux, or no phone fix | Centres on the radio's position. Disabled if there's none. |

**No-radio mode** (opened from the scanner, or after the radio disconnects):
- Hidden: nodes, the legend, the filter, path trace, the ⋮ menu and the QuickSwitchBar.
- **Back:** pops if there's a screen to return to, otherwise replaces the map with the scanner.
- **Long-press:** only "Route here" (Phase 7, Android).

**Starting camera,** first available of:
1. the highlight position;
2. a fit around the node positions;
3. the last camera (saved in `UiViewStateService`);
4. the first installed region;
5. the whole world at zoom 2.

**Disclaimer:** the chart styles show the localized "Not for navigation".

### S2. Layers sheet

New: a modal bottom sheet opened by the layers button. It shares one `MapLayerSettings` widget with App Settings (S4).

```
│ Map layers                                   │
│ ◉ OpenStreetMap   Style [Standard | Park]    │  Park family (Phase 8)
│ ○ USGS topo        Not downloaded  [Download]│  greyed when its pack kinds aren't installed
│ ○ NOAA charts      Not downloaded  [Download]│  Phase 6
│ Layers                                       │
│ Contours            20 ft lines        [●━]  │
│ National parks                         [●━]  │  Phase 8: one per installed overlay id
│   Opacity  ───────●────                      │
│ Theme          [ Auto | Light | Dark ]       │
│ ⬇ Offline maps…                        (2) › │  badge = downloads + updates
```

### S3. Offline maps screen

New `lib/screens/offline_maps_screen.dart`. It replaces `map_cache_screen.dart`.
- **Reached from:** the scanner ⋮ menu (S0), App Settings (S4), the map banner (S1) and the layers sheet (S2).
- **App bar:** centred title, a ⟳ refresh button, and the tabs **Maps · Charts · Downloaded**.
  - Downloaded shows a badge for active downloads plus available updates.
  - The screen opens on Downloaded once anything is installed, otherwise on Maps.
  - Charts arrives in Phase 6.
- **Wide (≥ 880 px):** content plus a 340 px `Card.outlined` panel.
- **Phone:** the picker map above a `DraggableScrollableSheet`. Until O3 adds the map, it's a plain list.
- **Look:** follows traxmapmaker's regions mockup, in MeshTrax's Material 3 theme. The mapping table is in the traxmap README, "MeshTrax integration".

**S3a. Maps tab:**
```
│ World › North America › United States        │  breadcrumb TextButtons with ›
│ ┌ picker map (O3) ─────────────────────────┐ │  regions as MapPolygons over online tiles; tinted by size,
│ │                                          │ │  downloaded = primary fill, selected = thick stroke
│ └──────────────────────────────────────────┘ │
│ ■<100 MB ■100–500 MB ■0.5–1 GB ■>1 GB ■Downloaded │  legend strip (O3)
│ ⌖ Suggested  Rhode Island          52.6 MB ›  │  phone fix → radio → last camera
│ Regions in United States                     │
│ [● Alabama 210 MB] [California · 2 inside ›] [● Rhode Island 52.6 MB ✓] … │
│ Region outlines © Geofabrik GmbH, OpenStreetMap contributors (ODbL) │  picker credit (required)
```
- **Region size:** the sum of the index's packs for that region. A region with no packs shows "—" and is disabled.
- **States:**

  | State | Shown |
  | --- | --- |
  | Loading | "Loading available maps…" |
  | Network or server error | "Can't reach the map server" with [Retry] |
  | Index returns 404 | "No maps are available yet": an empty state, not an error |
  | Offline with a cached list | The cached list, with "from {date}" |
  | Index or picker newer than the app | "Update MeshTrax to get the newest maps" |

**S3b. Region detail** (in the sheet on phones, in the panel on wide screens):
```
│ ‹ United States                              │
│ Rhode Island                                 │
│ North America › United States                │
│ ┌──────────────────────────────────────────┐ │  Card.outlined rows, sizes monospace
│ │ ☑ Map                           34.1 MB  │ │  "OpenStreetMap streets, trails, places"
│ │ ☑ Contours  [20 ft ▾]            1.7 MB  │ │  variants from the index; default by units
│ │ ☐ USGS topo map                 15.8 MB  │ │  outside the US: disabled, "United States only"
│ │ ☐ Trail routing                 +46 MB   │ │  Phase 7, Android only, opt-in
│ │ Overlays                                 │ │  Phase 8: rows from the overlays catalog
│ │ ☑ National parks                   6 MB  │ │
│ └──────────────────────────────────────────┘ │
│ NOAA charts are picked by coast, in the Charts tab. │  Phase 6
│ Download                            35.8 MB  │
│ ▍Large download (1.2 GB). Use Wi‑Fi…         │  orange callout, only when > 1 GB
│ [            Download 35.8 MB              ] │  FilledButton
```
- **Row states:**

  | State | Shown |
  | --- | --- |
  | Waiting | "Waiting…" or "Waiting for Wi‑Fi" |
  | Running | Progress bar, "16 of 34 MB", ⏸ and ✕ |
  | Paused | ▶ and ✕ |
  | Verifying | "Checking download…" |
  | Failed | Retry ("Not enough storage" where it applies) |
  | Installed | "Downloaded {date}" |
  | Update available | "Update available" |
  | Not in the index | Disabled |
- **Footer actions:** Download {newly checked}, Update {size}, Delete region.
- **Delete dialog:** "Delete Rhode Island? This frees 35.8 MB."
- **First Download tap:** asks for the Android notification permission (a no-op elsewhere).

**S3c. Downloaded tab:**
```
│ 35.8 MB of offline maps on this device       │
│ Updates (1)                [Update all 34 MB] │
│ ┌ Downloading ─ Rhode Island · Map ▓▓▓░ 16 of 34 MB ⏸ ✕ ┐
│ ┌ Rhode Island ──────────────────── 35.8 MB ┐ │  one Card.outlined per region (tap → S3b)
│ │ Map · Contours 20 ft                     │ │
│ │ Downloaded 19 Oct · Update available     │ │
│ │                      [Update]  [Delete]  │ │
│ ┌ Other map files ─────────────────────────┐ │  packs whose region isn't in the catalogue
```
When nothing is installed: "No offline maps yet", with [Find maps].

**S3d. Charts tab (Phase 6):**
- **Map:** chart-area coverage.
- **Coast groups:** multi-select `FilterChip`s, with "Select all" per group.
- **Panel:**
  - the selected areas as `InputChip`s;
  - "{n} areas · {cells} cells · {size}";
  - an always-on orange "Not for navigation…" callout;
  - a Download button.

### S4. App Settings → Map Display

`lib/screens/app_settings_screen.dart`. The existing rows stay; Units gets the subtitle "Imperial (20 ft contours)".

New rows:
- Map (with Style)
- Contours
- Map theme
- "Download maps on Wi‑Fi only"
- Overlay switches (Phase 8)

"Offline Map Cache" becomes "Offline maps", with a subtitle such as "1 region · 35.8 MB".

### S5. Secondary maps

Credits and the online fallback come through `AppMap`. These maps get no banner.

| View | Changes |
| --- | --- |
| `lib/widgets/repeater_login_dialog.dart` | `AppMap(compact: true)`, 180 px, cell_tower marker |
| `lib/screens/channel_message_path_screen.dart` | `MapLine`, hop labels from zoom 7.5, `MapFit.points(maxZoom: 15)` |
| `lib/screens/path_trace_map.dart` | Same pattern; `centerTitle: true` |
| `lib/screens/line_of_sight_map_screen.dart` | `MapLine` segments; long-press passes through lines; elevation stays online |

### S6. Trail route planner (Phase 7, Android only)

```
│ ←                  Trail route               │
│ ● Start  My location                   [⌖]   │  phone fix → radio → long-press
│ ◆ End    Southern Peak trailhead       [⌖]   │  "Route here" from long-press, node dialog, S7
│ Profile [Hiking ▾]                      ⚙    │  Hiking, Trekking, MTB, MeshTrax
│ ┌ AppMap + route MapLine + pins ───────────┐ │
│ ├────────────── ─── ───────────────────────┤ │
│ │ 12.4 km    ↑ 820 m    ↓ 790 m    ~4 h 10  │ │
│ │ ╱‾‾╲__╱‾‾‾╲___  elevation profile        │ │
│ │ [Export GPX]                   [Clear]   │ │
```
- **⚙ options:** Prefer dirt, Avoid paved, Max trail difficulty (SAC T1–T6).
- **Naming:** "Trail routing" in the UI, and `trailRoute_` l10n keys, because `routing_*` already means mesh routing.

### S7. Overlay feature sheet (Phase 8)

Shown when a park POI is tapped. Its fields come from the overlays catalog's `popup` keys. See [`park-maps.md`](park-maps.md).

## App architecture

**`MapPacksService`** (new `lib/services/map_packs_service.dart`, a `ChangeNotifier` created in `main()` and provided with the other services):
- **Owns:**
  - `PackManager(<support>/maps/packs)`;
  - a `BackgroundPackDownloader`, subscribed to its updates before `restore()`;
  - one shared `StyleRegistry`;
  - the cached `index.json` and `picker.geojson`;
  - the parsed index and region tree;
  - installed packs and downloads.
- **Index URL:** `String.fromEnvironment('MAP_INDEX_URL', defaultValue: 'https://maps.meshtrax.io/index.json')`.
  - `picker.geojson` resolves next to the index.
  - The hostname is compiled in and must stay.
- **Refreshing:**
  - When Offline maps opens, and on ⟳.
  - A daily update check, only when packs are installed.
  - Requests send `If-None-Match`; a 304 keeps the cache.
  - Uses the `http` package.
- **Web:** does nothing.

**`AppMap`** (new `lib/widgets/app_map.dart`) wraps `OfflineMapView` for all seven map views. It handles:
- style, family and overlays from settings;
- units and contours;
- the credits chip and disclaimer;
- raster `baseLayers` while not covered;
- the banner;
- `compact` mode.

It doesn't use `extraLayers`, so a renderer change stays inside traxmap.

**Tile service** (`lib/services/map_tile_cache_service.dart`):
- keeps on-demand cached raster tiles (same cache key) and gains an `online` notifier;
- the bulk prefetch is removed.

**`PhoneLocationService`** (Phase 4): geolocator, when-in-use permission.

**Settings** (`lib/models/app_settings.dart`):
- New: `map_type`, `map_family`, `map_contours`, `map_theme`, `map_downloads_wifi_only`.
- Later: `map_overlays` (Phase 8) and `trail_route_*` (Phase 7).
- `map_cache_*` goes.
- The last map camera lives in `UiViewStateService`.

**Storage:** `<support>/maps/{packs, routing/l11, index.json, picker.geojson}`, excluded from backups.

**l10n prefixes:** `offlineMaps_`, `mapLayers_`, `map_`, `appSettings_`, `scanner_`, `trailRoute_`, `overlay_`. Region, overlay and POI names and the picker credit come from the data and aren't translated.

## Phases

**Order:** the core (Phases 1–5), then Charts, then Routing, then Parks.

### Phase 1: the download screen, list-first

**Milestone:** download Rhode Island on the Pi through the real screen, with no radio connected.

| Task | Change |
| --- | --- |
| D0 | These docs. |
| T1 | traxmap index model v2.<br>• `PackIndexEntry` gains `region`, `variant`, `units`, `interval` and `intervalUnit`, round-tripped (so restored downloads keep them).<br>• `PackIndex` gains `generated`, `schemaVersion`, `usable` and `needsNewerApp`.<br>• Tolerant parsing.<br>• The real `dev/index.json` as the test fixture.<br>• The `routing` and `overlays` sections, and the entries' `level` and `overlay` fields, wait for Phases 7 and 8, when their data exists. |
| T2 | traxmap `RegionIndex` (core).<br>• Parses `picker.geojson`: its members, tree and levels.<br>• `regionAt(LatLng)`: the smallest downloadable region containing the point.<br>• Pairing with packs through `PackIndex.forRegion(path)`. |
| T4 | traxmap pack lifecycle.<br>• Versioned file names `<id>@<sha12>.pmtiles` (update detection, reload, Windows-safe swap).<br>• `Pack.isBuild`, `region` and `buildDate`; `level` and `overlayId` wait for Phase 8.<br>• SHA-256 off the UI isolate.<br>• Runtime Wi‑Fi-only setting.<br>• Localizable notification strings. |
| A1 | Map tile User-Agent → `com.vena.meshtrax`. |
| A2 | traxmap dependency, `flutter_map ^8.3.2`, SDK `^3.13.5`.<br>• Android backup rules exclude `files/maps/`.<br>• A CI job builds a debug APK.<br>• iOS backup exclusion moves to G2: it needs native code and a Mac to test. |
| A3 | `MapPacksService`. |
| A4 | Settings fields, and fix the time-filter default mismatch. |
| O1 | Offline maps shell, tabs, badge and Downloaded tab.<br>• Scanner ⋮ "Offline maps".<br>• Settings row and Wi‑Fi switch.<br>• **Delete** the map cache screen, the prefetch, and their settings and strings.<br>• `formatBytes`.<br>• privacy.md map-server section. |
| O2 | Maps tab list (breadcrumb, Suggested, chips, picker credit, every state) and region detail with downloads.<br>• The download integration test moves to `integration_test/pack_download_test.dart`. |

### Phase 2: map foundations and the picker map

**Milestone:** Rhode Island drawn as vector tiles on the Pi, with online tiles around it.

| Task | Change |
| --- | --- |
| T3 | traxmap combined source per kind (neighbouring regions), and a cache key that changes when packs change. |
| T5 | traxmap view hooks: `baseLayers`, `onCoverageChanged`, rendering with no packs, `StyleInfo.requiredKinds`, the `labels` slot tag, polygon holes. |
| A5 | `AppMap` and the online fallback. |
| O3 | Picker map: region polygons over online tiles, size tint, tap to select, legend, phone sheet or wide panel. |
| G1 | **Gate on real phones:** frame time, memory, cold start, tile resolution. Go or no-go before the main map. |

### Phase 3: migrate the map views

| Task | Change |
| --- | --- |
| M1 | Repeater login mini-map. |
| M2 | Channel message path (fixes B7). |
| M3 | Path trace (fixes B8). |
| M4 | Line of sight. |
| M5 | Main map core (after G1). Fixes B1–B5. |
| M5b | No-radio map: scanner ⋮ "Map", no-radio mode, back rule. |

### Phase 4: layers and GPS

| Task | Change |
| --- | --- |
| M6 | Layers button and sheet (S2), the Settings rows, desktop +/−. |
| M7 | Phone GPS (geolocator), plus the privacy, platform and store updates. On the Pi it uses the radio fallback; the permission flow needs a phone. |

### Phase 5: cleanup and release gate

**C1:**
- Docs and store text.
- Remove unused strings.
- Switch the default index to the root once it's live.

**G2:** a pass on Android, iOS, Windows and macOS. Includes updating a pack on Windows while the map is open.

### Phase 6: Charts

Needs traxmapmaker 1.4.
- `ChartAreaIndex`.
- The Charts tab (S3d), and charts in Downloaded.
- Links from the layers sheet and region detail.

### Phase 7: trail routing (Android only)

Needs traxmapmaker 1.5.
- Generic downloads with a pluggable installer for `.rd5` files.
- A `packages/traxroute` plugin (BRouter).
- **Gate:** route time, memory and APK size on a phone.
- The routing store, the "Trail routing" row, and the planner (S6).

### Phase 8: Parks and overlays

Needs traxmapmaker 1.6. See [`park-maps.md`](park-maps.md).

### Later

- Night style
- Bundled world pack
- Offline line-of-sight elevation
- Cutting areas on the device
- Online vector tiles streamed from R2
- Per-park toggles
- Label priority overrides
- Brochure extraction
- Showing the last radio's nodes in no-radio mode

## Bugs to fix along the way

| # | Bug | Where | Fixed in |
| --- | --- | --- | --- |
| B1 | Radar button force-unwraps `selfLatitude!` | `map_screen.dart` | M5 |
| B2 | Unawaited message reload on every build | `map_screen.dart` `_collectSharedMarkers` | M5 |
| B3 | Dead `_isSelectingPoi` branches | `map_screen.dart` | M5 |
| B4 | A map opened from a chat POI has no back button while connected | `map_screen.dart` | M5 |
| B5 | `highlightLabel` is never shown | `map_screen.dart` | M5 |
| B6 | `mapTimeFilterHours` defaults to 48 in the constructor but 0 in `fromJson` | `app_settings.dart` | A4 |
| B7 | `selfLatitude!` force-unwraps | `channel_message_path_screen.dart` | M2 |
| B8 | `selfLatitude!` force-unwrap | `path_trace_map.dart` | M3 |
| B9 | Tile User-Agent is `com.meshcore.open`; bulk prefetch breaks OSM's tile policy | `map_tile_cache_service.dart` | A1, O1 |

## Risks and gates

| Risk | Handled by |
| --- | --- |
| The renderer is unproven on phones | G1 before M5 |
| Hashing multi-GB packs on the UI isolate | T4 |
| A pack updated in place shows stale tiles, and the update fails on Windows | T3, T4, G2 |
| Root index 404 until the first real publish | "No maps available yet" state; `dev/` via `--dart-define` meanwhile |
| Auto-connect replacing a screen opened from the scanner | M5b test |
| Testing on the Pi only hides phone behaviour | G1, G2, phone-only checks |
| BRouter build and APK size | Phase 7 gate |

## Still to confirm (defaults assumed)

- Wi‑Fi-only downloads on by default (the setting has no effect on Linux).
- The banner can be dismissed for the session.
- No first-run prompt.
- Windows uses the radio's position.
- The label "Trail routing".
- Time-filter default 0 (all time).
