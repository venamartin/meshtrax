# Offline maps: integration roadmap

This file says how traxmap's offline vector maps replace MeshTrax's online raster maps: the screens, the order of work, and how each step is tested. Agreed with Martin on 2026-10-17, 18 and 19. Companion files:

- [`offline-maps.md`](offline-maps.md): decisions, pitfalls and open questions.
- [`park-maps.md`](park-maps.md): park overlays on the app side.
- traxmapmaker's [`FINDINGS.md`](https://github.com/venamartin/traxmapmaker/blob/main/FINDINGS.md) §1: the server contract. Everything the app downloads from `maps.meshtrax.io`, one module per data set (1.1 common, 1.2 regions, 1.3 map packs, 1.4 charts, 1.5 routing, 1.6 overlays).

## Status

Last updated 2026-10-20, evening. **Resume here.**

**Branch:** `feature/offline-maps`, PR #169. Push only when Martin asks.

**Done:**
- **Phase 1:**
  - docs;
  - traxmap: index v2, `RegionIndex`, versioned pack builds;
  - User-Agent fix, the traxmap dependency, `MapPacksService`, settings;
  - the Offline maps screen (text only, one column, Downloaded tab);
  - the old cache screen deleted;
  - the privacy draft.
- **Phase 2:**
  - T5 view hooks;
  - A5 `AppMap` with the online fallback;
  - T3 combined source.
  - O3 (the picker map) was built, then dropped at Martin's request.
  - G1, the phone performance gate: Martin built the APK and tested on his phone (2026-10-20). Performance seems good.
- **Checked on the Pi** with a throwaway preview app and the real packs from `dev/`:
  - Rhode Island at Providence (vector with contours);
  - Boston (online tiles);
  - Puerto Rico + US Virgin Islands drawn as one map, with the Copernicus notice in the credits.
- **Tests:** the app's 769 and traxmap's 67 pass; `flutter analyze --fatal-infos --fatal-warnings` is clean.

**Next:**
1. **M5 is done (2026-10-20):** the Node Map draws on `AppMap`, with the Online | Offline switch, offline packs and online tiles in the gaps.
   - Nodes, guessed locations, pins, "You" and the highlight pin are `MapMarker`s, labelled from zoom 13 (`MapMarker.label`), so the separate label markers are gone. The path trace is a `MapLine`.
   - Starting camera: the highlight, then the nodes, then the last camera (`UiViewStateService.mapCamera`), then the first downloaded map.
   - B1–B5 are fixed.
   - Checked on the Pi with a fake radio (preview harness); `test/screens/map_screen_test.dart` covers markers, the POI link and B1.
2. **M6 layers sheet: done (2026-10-20).** It's built Google Maps style; desktop +/− is still to do.
   - **Button:** a round Layers button (bottom right) replaces the filter button.
   - **Map type tiles:** greyed with "Not downloaded" when no pack of the style's kinds is installed (`MapPacksService.hasMap`); tapping opens Offline maps.
   - **Toggle tiles:** Contours and Dark map; Repeaters, Chat Nodes, Other Nodes, Pins and Guessed.
   - **Rows:** "More filters" (the old dialog, now last seen, key prefix, discovery contacts and overlaps) and Offline maps with its badge.
   - **Thumbnails:** rendered from our own styles on the Pi, label-free except charts, and bundled as 216 px WebP in `assets/map_layers/` (54 KB).
3. **M5b no-radio map: done (2026-10-20).** The scanner's ⋮ menu has **Map** (`NoRadioMapScreen`).
   - It shows the map, the Online | Offline switch and the layers sheet without Nodes, with no radio actions.
   - It opens where the map was last left, else framed on the latest street or topo map, never further out than its packs draw (`MapPacksService.latestMapFit`, `MapFit.minZoom`).
   - The Node Map uses the same fallback.
   - Auto-connect while it's open: the scanner moves on to Chats only once it's the top screen again.
4. **Online mode is the standard look** (Martin, 2026-10-20). Online, the map draws the standard light map everywhere (`mapIsOnline`), because USGS, charts, contours and dark come from downloaded packs. The layers sheet greys those tiles with "Offline only"; tapping one switches to Offline and applies it. The choices are kept for Offline.
5. **The small maps M1–M4: done (2026-10-20),** plus the chat cards' location map (`MiniMap`, new in #171). Every map in the app now draws through `AppMap`.
   - Checked on the Pi with a fake radio and the production Rhode Island pack; tests cover each screen. The path trace test feeds a fake trace reply.
   - The repeater login mini-map uses `AppMap(compact: true)`: it follows the Online | Offline setting with no switch or "No offline map here" card. It's hidden on web, which has no map packs service.
   - The full-screen ones (message path, path trace, line of sight) show the switch like the Node Map, because the switch is what tells online tiles from offline maps.
   - The Node Map's ⋮ menu has **Offline maps** (2026-10-20, Martin: no other way to the downloads from the map).
   - The map is Light by default, whatever the app's theme (Martin, 2026-10-20; `map_theme` is `light` or `dark`). The Light/Dark choice goes in the layers sheet.
   - **Open: web.** `AppMap` needs `MapPacksService`, which is null on web, so the Node Map has no map there. Either drop web or give web an online-only map.
6. **Phase 6, the Charts tab: done (2026-10-20)** except the chart styles for the rebuilt data. See S3d.
   - `ChartAreaIndex` (traxmap) reads `chart_areas.geojson`. `MapPacksService` fetches and caches it with the catalogue; a 404 keeps the cached copy.
   - The Offline maps screen has three tabs: Maps · Charts · Downloaded.
   - The Charts tab's notice (Martin, 2026-10-20): "Not for navigation. Use official, up-to-date NOAA charts to navigate."
   - Downloaded lists chart areas in their own "NOAA charts" section. App Settings counts them apart: "1 region · 2 chart areas · 1.2 GB".
   - Links:
     - a coastal region's detail says "NOAA charts are picked by coast, in the Charts tab";
     - the layers sheet's Charts tile, when not downloaded, opens the Charts tab;
     - Offline on the Charts map, where nothing is drawn, a card says "No charts here · Download {area} NOAA charts · {size}", or "Zoom in to see your charts" when the area is downloaded.
   - **Charts data is being rebuilt with the real chart content** (Martin, 2026-10-20). Simplified charts were a misunderstanding. The current 9 layers stay. traxmapmaker adds:
     - traffic separation schemes;
     - anchorages;
     - restricted areas;
     - bridges and overhead clearances;
     - caution areas.
     The app's chart styles follow once traxmapmaker sends the schema.
   - **`chart_areas.geojson` republished (2026-10-20, 17:10 PDT):** 42 areas in 9 coasts, with Atlantic before Gulf, Panama under Caribbean and Micronesia at `charts/us/micronesia`. Every area has a pack. `coast_areas` gives the coastline order the app uses (Maine → Florida, then Florida → Texas). `display_bbox` isn't used yet, because the Charts tab has no map. The test fixtures are these live files. Their mock server sends UTF-8 bytes like R2.
   - **Encoding (FINDINGS §1.1, 2026-10-20):** every root JSON file is UTF-8, no BOM, written ASCII-only with `\u` escapes, and served with `charset=utf-8`. The picker and chart_areas.geojson become ASCII on their next publish. Their content is unchanged, but the new ETags make the app fetch both once. The app decodes the body bytes as UTF-8 either way.
7. **M6 desktop +/− and M7 My location: done (2026-10-20),** on the Node Map and the no-radio map.
   - **Buttons, bottom right:** +/− (desktop only; phones pinch), then My location, then layers (`MapControls`). The "No offline map here" card sits beside them (`AppMap.controlsWidth`).
   - **My location:**
     - uses the phone's GPS where the user allows it (Android, iOS, macOS, Windows; `PhoneLocationService` over geolocator), else the radio's own position;
     - asks while-in-use on the first tap only;
     - zooms to at least 14;
     - with no position, says why, and offers Settings when location is denied for good.
   - **The phone is its own marker** (Martin): a blue dot, apart from the radio's teal "You".
     - Nothing is read until the user has tapped My location once (remembered). The OS permission alone doesn't count.
     - After that, it follows while a map is open with the app in front.
     - My location is hidden where there's no GPS and no radio position (a radio's 0, 0 counts as none).
   - **Linux (the Pi):** no GPS, so My location uses the radio.
   - **Platform:**
     - Android location permissions no longer stop at Android 11 (BLE scan keeps `neverForLocation`);
     - iOS `NSLocationWhenInUseUsageDescription`;
     - macOS `NSLocationUsageDescription` and the location entitlement;
     - MSIX `location` capability;
     - iOS builds set `BYPASS_PERMISSION_LOCATION_ALWAYS=1` (TESTFLIGHT_GUIDE.md, Podfiles).
   - **Needs Martin:**
     - a phone test of the permission prompt (Android, iOS);
     - review of the privacy-policy changes (My location: read only on tap, never stored or sent), with its "Last updated" date;
     - the store forms: Play Data safety (location permission, used on the device only), App Store privacy labels, and the Microsoft Store listing.
8. **Waiting for Martin:**
   - review the privacy-policy draft (`a35a2a6`), which no longer says "no servers";
   - translations: 80+ new strings are English only, and `tools/translate.py` needs Ollama;
   - assumed defaults: Wi‑Fi-only on (phones), time filter "all time";
   - **traxmapmaker's full-data charts** (2026-10-20): Option A, B (its recommendation) or C. MeshTrax measured the style side: arithmetic works and per-class layers are cheap (offline-maps.md, renderer notes).
     - **On hold (Martin, 2026-10-21):** whether NOAA's SCAMIN decluttering applies to today's layers.
     - **Plan (Martin approved):** traxmapmaker builds Puerto Rico test packs, not published, after the contours build:
       - SCAMIN off;
       - SCAMIN on at offset 0 (NOAA's scale on a desktop);
       - SCAMIN on at +1 (on a phone), if it's cheap.
       MeshTrax renders the same views from each (San Juan harbour at z12–14, open water) for Martin to compare;
   - **traxmapmaker's USGS base design** (2026-10-21, `traxmapmaker/experiments/designs/2026-10-20-usgs-base-master.md`), decisions D1–D14:
     - **D1:** hillshade and elevation bands as their own `terrain` kind (`terrain.pmtiles`, z6–13, overzoomed). MeshTrax agreed: OSM maps get relief without the 2–5 GB USGS pack, and it costs the app about half a day. UX to decide with it: a "Hill shading" row in region detail (ticked by default?) and a layers-sheet toggle beside Contours;
     - **D2:** base z14 or z13, compared on the Rhode Island pilot in the app;
     - **D3:** the hillshade highlights appear for the first time, reviewed on the pilot.

**Data on R2** (from traxmapmaker-d3, 2026-10-20):
- **Production only** (Martin): `https://maps.meshtrax.io/index.json` is the one catalogue, and it gets only products from full master builds. `dev/` is retired.
- **On it:** the 73 North America OSM packs, border-complete. Puerto Rico and the US Virgin Islands were rehearsal builds; they return with a full Central America build.
- **Coming, in order:**
  - Mexico split into its 32 states (container `north-america/mexico`, ids like `mexico-nuevo-leon`), replacing `mexico-osm`;
  - the NOAA charts master with `chart_areas.geojson` (§1.4), including Puerto Rico;
  - US contours;
  - the USGS base.
- **Until then:** no charts, contours or USGS packs anywhere. Use the preview folder's local copies for screenshots.
- **Tested 2026-10-20** (on `dev/`, same packs):
  - Every pack's region is in the picker.
  - The Rhode Island update was detected by checksum.
  - RI+CT and VT+QC draw seamlessly across the border.
  - Quebec (1.67 GB): 68 s download, 38 s SHA-256 check, memory flat.
- **Sharing the Pi:** traxmapmaker shares its 4 cores. During its big builds, keep heavy Flutter work (analysis server, full test runs, builds) light. It messages before starting one.

**Known issues:** below.

## How we work

### On the Pi

All UI testing is done on the Raspberry Pi as a Linux desktop app, with hot reload. Phones are only used at gates G1 and G2, and for phone-only features: Android 14 UIDT, iOS background transfers, GPS permissions, BRouter.

```sh
flutter run -d linux
```

- **Catalogue:** production (`https://maps.meshtrax.io/index.json`) for every build. Martin retired `dev/` on 2026-10-20: the server only gets finished products. `--dart-define=MAP_INDEX_URL=…` remains for a local server.
- **VS Code:** a local `.vscode/launch.json` (gitignored) with `"deviceId": "linux"`.
- **Reloading:**
  - Hot reload (save, or `r`) covers widget changes.
  - Hot restart (`R`) is needed after changes to `main()`, providers or service start-up.
  - Changing a `--dart-define` needs a full restart.
- **Test data:** small production packs, e.g. District of Columbia (12 MB) or Rhode Island (37 MB), and the NOAA charts (live 2026-10-20). There are no contours or USGS packs until those builds land. The scratchpad preview folder was lost when a power cut rebooted the Pi (`/tmp`), and with it the `dev/` copies; harnesses download what they need from production.
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
- when charts, routing or overlays land on the server.

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
│ [Online│▐Offline▌]              ┌───────────┐ │  source switch (AppMap)
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

**Source switch, Online | Offline** (Martin, 2026-10-20; replaces the coverage banner):
- **Offline:** downloaded maps only, exactly what works without signal. Where nothing is drawn at the view centre, a card says "No offline map here · Download {region} · {size} ›" (opens S3b) or, inside a downloaded region below the packs' lowest zoom, "Zoom in to see your offline map".
- **Online:** online OSM raster tiles wherever the packs draw nothing. Tiles the packs cover are never fetched (`TileCoverage`). Raster tiles load on demand only, with a disk cache.
- **Both:** a dashed line (pink, `#D81B60`) where each downloaded region ends.
- **Setting `map_source`:** `auto` (online until a street or topo map is downloaded, then offline; charts or contours alone don't count), `online` or `offline`. The switch writes it.

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

**Redesigned 2026-10-20 (Martin): Google Maps style.** A modal bottom sheet opened by a round layers button on the main map. It replaces the planned plain-text map selector in App Settings.
- **Map type:** square tiles with a caption, the selected one outlined.
- **Map details and Nodes:** toggle tiles.
- **Map theme:** in the sheet, Light or Dark; the default is Light, whatever the app's theme (done: `map_theme`).
- **Node types** (Martin): repeaters, chat nodes, rooms etc. toggle here. These are the existing `mapShow*` settings from the filter dialog. The finer filters (last seen, key prefix, discovery contacts, overlaps) stay in that dialog, reached from the sheet.

```
│ Map type                                   ✕ │
│  ┏━━━━━━┓      ┌──────┐      ┌──────┐        │
│  ┃ OSM  ┃      │ USGS │      │ NOAA │        │  tiles; greyed + "Not downloaded" when
│  ┗━━━━━━┛      └──────┘      └──────┘        │  their packs aren't installed (charts: Phase 6)
│  Standard      USGS topo     Charts          │
│ ──────────────────────────────────────────── │
│ Map details                                  │
│  ┏━━━━━━┓      ┌──────┐                      │
│  ┃ ≋≋≋  ┃      │  ☾   │                      │  Contours (20 ft / 10 m by units), Dark map;
│  ┗━━━━━━┛      └──────┘                      │  later National parks etc. (Phase 8)
│  Contours      Dark map                      │
│ ──────────────────────────────────────────── │
│ Nodes                                        │
│  ┏━━━━┓  ┏━━━━┓  ┏━━━━┓  ┏━━━━┓  ┌────┐     │
│  ┃ ⌂  ┃  ┃ 👤 ┃  ┃ 🚪 ┃  ┃ ⚑  ┃  │ ?  │     │  mapShowRepeaters, mapShowChatNodes,
│  ┗━━━━┛  ┗━━━━┛  ┗━━━━┛  ┗━━━━┛  └────┘     │  mapShowOtherNodes, mapShowMarkers,
│ Repeaters Chat  Rooms&    Pins   Guessed     │  mapShowGuessedLocations
│                 sensors                      │
│ More filters (last seen, key prefix…)      › │  the existing filter dialog
│ ⬇ Offline maps                         (2) › │  badge = downloads + updates
```

### S3. Offline maps screen

New `lib/screens/offline_maps_screen.dart`. It replaces `map_cache_screen.dart`.
- **Reached from:** the scanner ⋮ menu (S0), App Settings (S4), the map's "No offline map here" card (S1) and the layers sheet (S2).
- **App bar:** centred title, a ⟳ refresh button, and the tabs **Maps · Charts · Downloaded**.
  - Downloaded shows a badge for active downloads plus available updates.
  - The screen opens on Downloaded once anything is installed, otherwise on Maps.
  - Charts arrives in Phase 6.
- **Layout:** one column on every screen size, centred at 720 px. Tapping a region opens its detail in place of the list, with "‹ Parent" to go back (Martin, 2026-10-19: the side panel looked like a copy of Downloaded).
- **Look:** follows traxmapmaker's regions mockup, in MeshTrax's Material 3 theme. The mapping table is in the traxmap README, "MeshTrax integration".

**S3a. Maps tab** (text only; the picker map was dropped 2026-10-19):
```
│ World › North America › United States        │  breadcrumb TextButtons with ›
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

**S3d. Charts tab (Phase 6; built 2026-10-20, text only):** Martin chose a coast list with ticks, areas alphabetical until `coast_areas` gives coastline order.
```
│ ▍Not for navigation. …                       │  always-on orange callout
│ ┌──────────────────────────────────────────┐ │
│ │ ☐ Rhode Island                  12.3 MB  │ │  Suggested: the area at the radio's position
│ │   Suggested · Atlantic Coast             │ │
│ └──────────────────────────────────────────┘ │
│ Chart areas by coast                         │
│ ┌──────────────────────────────────────────┐ │
│ │ Atlantic Coast                         ▾ │ │  ExpansionTile per coast, server order
│ │ 15 areas · 1.4 GB · 1 downloaded · 2 sel… │ │
│ │                            [Select all]  │ │  Clear when all are ticked
│ │ ☑ Florida                      310 MB    │ │
│ │   Also in Gulf Coast                     │ │  one tick for both coasts
│ │ ☐ Maine                         96 MB    │ │
│ ├──────────────────────────────────────────┤ │
│ │ Gulf Coast                             ▸ │ │
│ └──────────────────────────────────────────┘ │
│ NOAA Office of Coast Survey                  │  the file's attribution
├──────────────────────────────────────────────┤
│ 2 areas                           406 MB     │
│ [            Download 406 MB               ] │  FilledButton; large-download callout ≥ 1 GB
```
- The ticks belong to the screen, so they survive switching tabs. They're keyed by pack region, so Florida is one tick under Atlantic and Gulf.
- An area whose pack isn't in the index is greyed: "Not available yet".
- Deep link: `OfflineMapsScreen(initialChartArea:)` opens the Charts tab with that area ticked and its coast open.

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

Credits, the source switch and the online fallback come through `AppMap`.

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
- the Online | Offline switch, raster `baseLayers` in the gaps, the dashed region edges and the offline card;
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
| A3 | `MapPacksService`.<br>• Cached catalogue revalidated with ETags.<br>• A 404 means "unavailable".<br>• Pack status (available, queued, running, paused, retrying, verifying, failed, installed, update available), default selection, updates and badge.<br>• Download, pause, resume, cancel and delete region.<br>• Follows the Wi‑Fi setting.<br>• Not created on the web. |
| A4 | "Download maps on Wi‑Fi only" setting (default on). Fixes B6: the time filter now defaults to 0 (all time) everywhere. Map type, family, contours and theme arrive with `AppMap` (A5), the first code that reads them. |
| O1 | Offline maps shell, tabs, badge and Downloaded tab (storage, updates, downloads, regions, other files, clear the online tile cache).<br>• Scanner ⋮ "Offline maps".<br>• Settings rows: Offline maps, and Wi‑Fi only on phones.<br>• Translated notification titles.<br>• **Deleted:** the map cache screen, the prefetch, and their settings and strings (all locales).<br>• `formatBytes`. |
| O2 | Maps tab list (breadcrumb, Suggested from the radio position, chips, picker credit, every catalogue state) and region detail (rows with every status, contour interval, Download, Update, Delete; beside the list at ≥ 880 px).<br>• `integration_test/pack_download_test.dart`, against `dev/` by default: passed on the Pi 2026-10-19 (Rhode Island map, paused at 71%, resumed by range request, verified, installed). |

### Phase 2: map foundations and the picker map

**Milestone:** Rhode Island drawn as vector tiles on the Pi, with online tiles around it.

| Task | Change |
| --- | --- |
| T3 | **Done 2026-10-19.** traxmap combined source per kind (`CompositePmTilesProvider`, `StyleContext.packsByKind`, `ovm:urls`), with a cache key that changes when packs change. Checked on the Pi with Puerto Rico + US Virgin Islands from `dev/`: one seamless map, and the Copernicus notice reaches `MapStyleState.notices`. |
| T5 | traxmap view hooks: `baseLayers`, `onCoverageChanged`, rendering with no packs, `StyleInfo.requiredKinds`, the `labels` slot tag, polygon holes.<br>• `MapStyleState.notices`: licence notices from the packs in use (e.g. Copernicus' liability sentence), for the app to show with the credits. |
| A5 | `AppMap` (`lib/widgets/app_map.dart`): style from settings (map type, theme following the app, contours), installed packs, units; online OSM tiles in `baseLayers`; credits chip (plus the OSM credit while online tiles show, plus pack notices) and the chart disclaimer. Settings `map_type`, `map_contours`, `map_theme`. `MapPacksService` shares one style registry. 2026-10-20: the Online \| Offline switch, the gap-only online tiles (`TileCoverage`), the dashed region edges and the offline card replaced the planned coverage banner. |
| O3 | **Dropped for now** (Martin, 2026-10-19: "I don't like the map selector … let's just use text for now"). The picker map was built and checked on the Pi, then removed. The Maps tab stays text only (breadcrumb, Suggested, chips), and the Geofabrik credit stays under the list. `AppMap` itself stays: the map screens use it. |
| G1 | **Gate on real phones:** frame time, memory, cold start, tile resolution. Go or no-go before the main map. |

### Phase 3: migrate the map views

| Task | Change |
| --- | --- |
| M1 | Repeater login mini-map. |
| M2 | Channel message path (fixes B7). |
| M3 | Path trace (fixes B8). |
| M4 | Line of sight. |
| M5 | Main map core (after G1). Fixes B1–B5. |
| M5b | No-radio map: scanner ⋮ "Map", no-radio mode, back rule. `main()` already loads the contact cache at start-up, so the last-known nodes may be cheap to show; decide when building it. |

### Phase 4: layers and GPS

| Task | Change |
| --- | --- |
| M6 | Layers button and sheet (S2, Google Maps style, 2026-10-20): map type, contours, light/dark, node types; desktop +/−. **Done.** |
| M7 | Phone GPS (geolocator): My location and the phone's own marker, plus the privacy and platform updates. On the Pi it uses the radio fallback. **Done** (2026-10-20); the permission prompt and the store forms need Martin's phone and accounts. |

### Phase 5: cleanup and release gate

**C1:**
- Docs and store text.
- Remove unused strings.
- Switch the default index to the root once it's live.

**G2:** a pass on Android, iOS, Windows and macOS. Includes updating a pack on Windows while the map is open.

### Phase 6: Charts

Needs traxmapmaker 1.4.
- `ChartAreaIndex`. **Done** (CH1).
- The Charts tab (S3d), and charts in Downloaded. **Done** (CH2).
- Links from the layers sheet, region detail and the Charts map's "No charts here" card. **Done.**
- Chart styles for the rebuilt charts data (TSS, anchorages, restricted areas, bridges and clearances, caution areas). **Waiting** for traxmapmaker's schema.

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
- World base map: from traxmapmaker, downloaded with the catalogue, built last (see Known issues)
- Offline line-of-sight elevation
- Cutting areas on the device
- Online vector tiles streamed from R2
- Per-park toggles
- Label priority overrides
- Brochure extraction
- Showing the last radio's nodes in no-radio mode

## Known issues

- **Peak labels had a box before the name on the Pi** ("▯ Bare Rock"). The styles put "▲" before the name, and the renderer draws labels in the platform's default font, which lacks it on Linux. Fixed 2026-10-20 by dropping the "▲" (`tool/make_styles.py`). A proper peak icon comes with sprites (T9); a font for labels needs the font hook (T12).
- **Offline mode is empty when zoomed far out.** Packs start at MapLibre zoom 6 (zoom 5 drawn stretched), so below that only the dashed outlines and the "Zoom in" card show.
  - The world base map will fill it: traxmapmaker builds it last and MeshTrax downloads it with the catalogue (decision 2026-10-20).
  - App side, when it lands: `PackKind.world`; a `world` source and layers in all six styles up to zoom 6; downloaded with `index.json` and kept outside `installed`; the offline card hidden below zoom 6.
- **The offline map ends at tile edges, not at the region outline.** Border tiles are complete, so the vector map runs a little past the dashed line in rectangular blocks. Further out the blocks get large: at zoom 5, the Rhode Island and Connecticut packs draw most of New England.

## Bugs to fix along the way

| # | Bug | Where | Fixed in |
| --- | --- | --- | --- |
| B1 | Radar button force-unwraps `selfLatitude!` | `map_screen.dart` | M5, done: the trace starts without a radio position |
| B2 | Unawaited message reload on every build | `map_screen.dart` `_collectSharedMarkers` | M5, done: reload on a new channel message or a contact's newer message |
| B3 | Dead `_isSelectingPoi` branches | `map_screen.dart` | M5, done: removed |
| B4 | A map opened from a chat POI has no back button while connected | `map_screen.dart` | M5, done: back button, no quick-switch bar |
| B5 | `highlightLabel` is never shown | `map_screen.dart` | M5, done: the pin's label |
| B6 | `mapTimeFilterHours` defaults to 48 in the constructor but 0 in `fromJson` | `app_settings.dart` | A4 |
| B7 | `selfLatitude!` force-unwraps | `channel_message_path_screen.dart` | M2, done: the line just leaves out the radio's position |
| B8 | `selfLatitude!` force-unwrap | `path_trace_map.dart` | M3, done: the line starts at the first hop instead |
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
- No first-run prompt.
- Windows uses the radio's position.
- The label "Trail routing".
- Time-filter default 0 (all time).
