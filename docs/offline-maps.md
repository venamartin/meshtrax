# Offline maps in MeshTrax

Working notes for replacing MeshTrax's online raster maps with offline vector
maps. They hold everything the app side needs, gathered on 2026-10-17 when
traxmap moved into this repository.

## Where things live

- **Map package:** [`packages/traxmap/`](../packages/traxmap/). It renders map
  packs (PMTiles, vector tiles) with bundled styles, manages and downloads
  packs, and has no screens.
  - **Integration plan:** its README section "MeshTrax integration" has the
    API mapping, zoom conversion, migration order, the Offline maps screen
    design and what MeshTrax can delete.
  - **History notes:** [`HISTORY.md`](../packages/traxmap/HISTORY.md), with the
    removed example's downloads page and the download integration test.
- **Pack builder:** [traxmapmaker](https://github.com/venamartin/traxmapmaker), a separate repository. It runs on
  the Pi 5 and publishes packs to Cloudflare R2. Its
  [`SCHEMA.md`](https://github.com/venamartin/traxmapmaker/blob/main/SCHEMA.md) is the contract the styles are
  written against. Its [`FINDINGS.md`](https://github.com/venamartin/traxmapmaker/blob/main/FINDINGS.md) keeps the
  data-side record: sources, measurements, server layout and build design.
- **Pack server:** `https://maps.meshtrax.io` (Cloudflare R2). traxmapmaker's
  FINDINGS §1 is the contract. A frozen test catalogue lives under `dev/`;
  the root `index.json` returns 404 until the first real publish.
- **Integration roadmap:** [`offline-maps-roadmap.md`](offline-maps-roadmap.md)
  covers the screens, phases, how to test on the Pi, and coordination with
  traxmapmaker.
- **Park overlays:** [`park-maps.md`](park-maps.md).
- **Status (2026-10-19):** Phase 1 (the download screen) is in progress on
  the local branch `feat/offline-maps`.

## Decisions that shape the app

| Date | Decision |
| --- | --- |
| 2026-10-15 | **Renderer: flutter_map + flutter_map_vector_tiles.** It runs on every platform, including Linux. The phone comparison against maplibre_gl is still open, so treat the renderer as provisional. |
| 2026-10-15 | **Zoom numbers follow MapLibre's 512 px convention** everywhere; flutter_map's zoom is one higher. The renderer converts. |
| 2026-10-16 | **traxmap has no screens or chrome.** MeshTrax owns every screen. Credits (`MapStyleState.credits`, required by the licences) and the chart disclaimer ("Not for navigation") reach the app as data, and the app must show them. `core.dart` is pure Dart (a test enforces it). |
| 2026-10-16 | **API: generic package types plus an escape hatch.** `OfflineMapController`, `MapFit`, `MapMarker`/`MapLine`/`MapPolygon`, map `onTap`/`onLongPress`; `extraLayers` takes raw flutter_map layers during migration. Web is out of scope. |
| 2026-10-16 | **Maps: the user picks OSM, USGS or NOAA Charts, plus light or dark.** Contours on/off and ft/m are app settings for all three. Units pick the contours variant (20 ft vs 10 m lines) as well as the labels. Six bundled styles, `<map>-light/dark`. |
| 2026-10-16 | **Download model:** the user picks a region, then downloads Map (OSM, everywhere, required) + Contours (everywhere, density choice, on by default). In the US there are also optional USGS topo detail and NOAA charts (coastal). A style whose packs are missing is hidden or greyed out. |
| 2026-10-16 | **OSM covers the whole world.** USGS and NOAA packs are US-only extras. First release: USA by state, Canada by province, Mexico, UK. |
| 2026-10-16 | **The region picker is a native MeshTrax "Offline maps" screen** (replacing `map_cache_screen.dart`), as close to the web mockup as possible in MeshTrax's own style. It draws on a small bundled world pack (z0–6), and fetches simplified outlines (`picker.geojson`) from R2. Design in the traxmap README. |
| 2026-10-16 | **Pack downloads use background_downloader**, not Android's DownloadManager: scoped tasks, Android 14+ UIDT, range-request resume, restore at launch, SHA-256 check, then `PackManager.install(move: true)`. |
| 2026-10-16 | **Offline routing (trails, dirt roads or a mix) with the BRouter library embedded in MeshTrax, Android only.** See "Routing" below. |
| 2026-10-17 | **Routing is an opt-in download, off by default** (Android only). |
| 2026-10-17 | **Online OSM raster tiles where no pack is installed.** They load on demand only, from a disk cache of tiles already viewed. The bulk "Offline Map Cache" prefetch goes (it breaks OSM's tile policy), the User-Agent becomes `com.vena.meshtrax`, and "© OpenStreetMap contributors" shows whenever raster tiles do. The bundled world pack is deferred. Martin: about 95% of users are online. |
| 2026-10-17 | **Phone GPS** (geolocator, when-in-use, asked on the first tap of centre-on-me) arrives with the main map. The radio's position is the fallback, and the only source on Linux. privacy.md and the store forms change in the same step. |
| 2026-10-17 | **Offline maps screen: three tabs, Maps · Charts · Downloaded,** plus a layers button on the main map (mirrored in App Settings). |
| 2026-10-17 | **Order:** the download screen and the map migration first, then charts, then routing, then park overlays. |
| 2026-10-18 | **Park maps are overlays** in a generic level model: per region and per source (NPS first). See [`park-maps.md`](park-maps.md). |
| 2026-10-18 | **The server data is modular:** one module per data set (traxmapmaker FINDINGS §1). Routing and overlays stay separate. |
| 2026-10-19 | **Maps work without a radio.** The scanner's ⋮ menu gets Offline maps and Map; with no radio, the map shows no nodes and hides radio-only actions. |
| 2026-10-19 | **List-first:** the Offline maps list, region detail and downloads come before any map-rendering work. |
| 2026-10-19 | **The Pi is the test bench** (Linux desktop, hot reload). Phones only at the release gates and for phone-only features. |
| 2026-10-19 | **A 404 on `index.json` means "no catalogue yet"**: an empty state, not an error. |

## Pitfalls already found

### Pack downloads (background_downloader, 2026-10-16)

Tested on the Pi (Linux desktop) against traxmapmaker's dev server at 8 MB/s; Android and iOS still need a phone.

- **Resuming needs `Accept-Ranges: bytes` and a strong `ETag` on the first, full response.** Without them the plugin decides the download can't resume: `pause()` turns into a retry, and the download starts over from byte 0, while still reporting progress from the pause point. traxmapmaker's dev server (`viewer/serve.py`) now sends both. R2 does. A rebuilt pack has a new ETag, so the download restarts, and the SHA-256 check guards the install either way.
- **Scoped downloaders don't track custom groups.** `FileDownloader.scoped('traxmap').start()` tracks only `traxmap.default`. Tasks in our `packs` group were never written to the database, so nothing could be restored after a kill. Fix: `trackTasksInGroup('packs')` before `start()`.
- **The 5-second `rescheduleKilledTasks` timer in `start()`** re-queued the task, but its updates never reached our listener. `restore()` now calls `start(doRescheduleKilledTasks: false)` and then `rescheduleKilledTasks()` itself.
- **Measured (90.6 MB charts pack):** pause at 32%, resume with one 206 range request, then verify and install in 21 s. The integration test was `traxmap/example/integration_test/pack_download_test.dart`; it left with the example app, and its source is kept in MeshTrax's `packages/traxmap/HISTORY.md`.
- **Hard kill on desktop:** the download restarts from 0% on the next launch, then finishes and installs (checksum identical). The plugin leaves its partial file (85–130 MB per kill) in `/tmp`; it's cleared on reboot. Phones should keep the transfer in the OS, except after a swipe-away; still to measure.
- **SHA-256 of a 207 MB pack** took about 10 s on the Pi in Dart. Phones may need it off the UI isolate for multi-GB packs.
- **No Android SDK on the Pi,** so the Android build (Kotlin 2.4, POST_NOTIFICATIONS, UIDT) is untested.

### Flutter and the renderer (2026-10-15/16)

- flutter_map_vector_tiles (2.9.1, Oct 2026):
  - It **detects gzipped tiles and inflates them on worker isolates**, so a provider should hand back raw compressed blobs.
  - Set `cacheBytesToDisk => false` for local packs, or it copies them into its disk cache.
  - It draws labels with Flutter's own text, so **no glyph `.pbf` files are needed**; `text-font` only matters in the browser.
  - Hillshade raster layers are skipped, which doesn't matter because terrain is vector.
  - Legacy filters (`["==","$type","Point"]`), `step`, `match`, `interpolate` and `circle-stroke` all work.
- **Zoom offset:** flutter_map zoom = MapLibre zoom + 1 for the same view. The renderer converts; nothing outside it should see flutter_map zooms.
- **Pack lists compare by content.** `OfflineMapView` compares `packs` by id and file path (fixed 2026-10-16), so apps may rebuild the list in `build()`. Before the fix, a new list object reloaded the style every frame.
- **flutter_map hit-testing swallows map gestures.** A `PolylineLayer`/`PolygonLayer` with a hit notifier counts every line as a hit, so a `GestureDetector` around it eats taps and long-presses meant for the map. The renderer puts overlays without handlers in passive layers with no hit testing, and forwards a gesture an overlay doesn't handle to the map's `onTap`/`onLongPress`. Without this, MeshTrax's line-of-sight long-press would break.
- **flutter_map `Marker.alignment` is the opposite of an anchor.** `Alignment.topCenter` puts the marker box *above* the point. The package's `MapMarker.anchor` uses the MapLibre meaning (the point of the marker that sits on the position) and converts with `Alignment(-x, -y)`.
- **Tiles look soft just below each whole zoom (fixed 2026-10-16).** flutter_map_vector_tiles draws each tile once into a bitmap at `floor(zoom)` and stretches it up to 2× until the next level; labels stay sharp because they're drawn every frame. The renderer now gives the tile layer a higher `devicePixelRatio` through `MediaQuery` (default 2× the screen density, capped at 4; `OfflineMapView.tileResolution` overrides it). Measured on the Pi at z13.9, edge sharpness rose from 105 to 184 (z13.0 is 238). Cost: tile bitmap memory and raster time grow with the square of the factor. Check frame times and memory on phones in Phase 2.
- **Report the starting camera.** flutter_map's `onPositionChanged` doesn't fire until the user moves. The renderer reports the camera once the map is ready (after the frame), so zoom-derived UI is right from the start.
- **Two `LatLng`s and the latlong2 range.** MeshTrax pins `latlong2 ^0.9.1`; the package accepts `>=0.9.1 <0.11.0`, as do flutter_map 8.3 and flutter_map_vector_tiles 2.9. The package's own `LatLng` clashes by name: import `package:traxmap/traxmap.dart` with `hide LatLng, LatLngBounds` where latlong2 is used, and convert with `package:traxmap/latlong2.dart` (`toOvm()`, `toLatLong2()`).
- **What the renderer can't do** (2026-10-18). This shapes the styles and the park overlays; the full list is in traxmapmaker FINDINGS §4, "App renderer limits for style authors".
  - **No `within`:** the parser rejects it.
  - **Fonts:** `text-font` only picks weight and italic. There's no font family, and no glyph PBFs are used.
  - **Sprites:** one `SpriteAtlas` per layer, so icon sheets must be merged. Sprites, `line-pattern` and every `*-opacity` do work, but traxmap doesn't load sprites yet.
  - **Tapping features:** there's no query API for vector features.
- `RandomAccessFile` allows one pending operation at a time, so local tile reads need serializing.
- **Test hang:** `rootBundle` caches asset futures. A future created inside one `testWidgets` fake-async zone never completes when awaited from another. Load assets in plain `test()` with `TestWidgetsFlutterBinding.ensureInitialized()`.
- A bundled pack copied into app storage goes stale after a pipeline rebuild. Compare size plus the first 16 KiB, and reinstall when they differ.
- `flutter create --platforms ...` on an existing app re-adds the default counter `widget_test.dart`.
- macOS builds are sandboxed by default, so "install pack from a typed path" will fail outside the sandbox. Phase 4 downloads, or a file picker, avoid this.

### During the migration

- During the transition, `emptyState` can show the old raster map when no pack is installed. A raster `TileLayer` in `extraLayers` would cover the vector map, so don't use that.
- **background_downloader needs host-app setup** once MeshTrax depends on
  traxmap: Android `INTERNET` and `POST_NOTIFICATIONS`, and the macOS
  `com.apple.security.network.client` entitlement. The plugin's native code
  is built into the app as soon as traxmap is in `pubspec.yaml`, so add the
  setup in the same PR.

### Noticed in MeshTrax while planning the migration (not map issues)

- `_isSelectingPoi` is never set to true, so the POI-selection tap mode in `map_screen.dart` is dead code.
- `_collectSharedMarkers` starts an unawaited message-store reload on every build of the main map (which rebuilds on every connector notify).
- The "radar" path-trace button force-unwraps `selfLatitude!`.

## Routing (Android only; planned, nothing built)

**Engine:** the BRouter library (MIT), run in Android-native code.
- **Where:** recommended as a small separate Flutter plugin (`packages/traxroute`,
  method channel), keeping traxmap map-only. Still to confirm.
- **Other platforms:** routing is hidden on iOS and desktop.
- **Result:** a polyline with elevation per point, distance and ascent,
  drawn as a `MapLine`. GPX export and an elevation profile come free.

**Data:** BRouter `.rd5` files, 5°×5° tiles named by their south-west corner.
- **Built by traxmapmaker** from the same OSM extracts as the maps, with 3DEP
  or Copernicus elevation.
- **brouter.de's files are for testing only.** Their CGIAR elevation can't
  be re-hosted without permission.

**On R2:**
- **Tile storage:** one shared copy per tile at `routing/l11/<tile>.rd5`
  (`l11` = BRouter's `lookupversion`). That's 2.4 GB for the first release.
- **Index:** a separate top-level `routing` section in `index.json`, never in
  `packs`. Today's app parses unknown kinds as `PackKind.unknown` and would
  list them. Shape:
  `{"routing": {"lookup_version": 11, "tiles": {"W125_N35": {bytes, sha256, build_date, url}}, "regions": {"<region path>": ["W125_N35", …]}}}`.

**In the app:**
- **Opt-in, off by default:** a "Routing (trails & dirt roads)" checkbox
  after Map and Contours, shown only on Android.
- **Sizes:** the median region adds 139 MB (NorCal 146, SoCal 192). The app
  shows only tiles not yet installed, since neighbours share tiles.
- **Download, install, delete, update:**
  - downloads go through `PackDownloader` (resume, SHA-256) into a `routing/`
    folder that BRouter reads;
  - deleting a region removes only tiles no other installed region uses;
  - a changed sha256 in the index offers an update.
- **Profiles:** bundled with the matching `lookups.dat`: hiking, trekking
  and MTB, plus a MeshTrax profile with per-request "prefer dirt / avoid
  paved / max `sac_scale`" variables.

**Measured on the Pi (2026-10-16):** routes take 0.4–0.8 s, and the route
server runs in 128 MB. On Mt Diablo, hiking used 90% trails, MTB 88% dirt
roads, and gravel mostly dirt and minor roads. Elevation changes the chosen
route, not just the stats.

**Next:** try the embedded library on a real Android phone, measuring route
time, memory and APK size.

## Open questions for the app

Each item now has a task in the [roadmap](offline-maps-roadmap.md).

- **Renderer on phones** (gate G1): measure frame time, memory and cold start
  on real Android and iOS phones, and compare with maplibre_gl. Check the
  tile resolution factor (2× screen density, capped at 4) there too.
- **Combined multi-pack source per kind** (task T3): each tile should come
  from whichever installed pack has it (e.g. Lake Tahoe across California
  and Nevada). Today `StyleContext` maps one pack per kind. This is needed
  as soon as users install neighbouring regions.
- **`StyleInfo` lists the pack kinds a style needs** (task T5), so the
  layers sheet can grey out maps whose packs aren't installed.
- **Offline maps screen:**
  - `RegionIndex` in `core.dart` (task T2);
  - `picker.geojson`: done, served by traxmapmaker on `dev/`;
  - the bundled world pack is deferred, because the picker draws on online
    tiles (decided 2026-10-17).
- **Charts get their own picker,** by coastal state (Phase 6).
- **Night style** (red on black, for night vision) and **SDF icons** (buoys,
  peaks, trailheads). Sprites come with task T9.
