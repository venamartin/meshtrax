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
| 2026-10-20 | **An Online \| Offline switch on the map, replacing the coverage banner.** Martin: online tiles that look like the offline map make people think they have it offline. **Offline** draws downloaded maps only: exactly what works without signal, with a "No offline map here · Download {region} ›" card where nothing is drawn. **Online** draws online OSM tiles everywhere the packs don't (only those tiles are fetched). Both modes draw a dashed line where the downloaded regions end. Setting `map_source`: `auto` (online until the first street or topo map download, then offline; charts or contours alone don't count, because the standard map would have nothing to draw), `online` or `offline`. |
| 2026-10-20 | **A world base map from traxmapmaker, downloaded with the catalogue.** It's a simple world map for Offline mode when zoomed out or outside downloaded regions: land and water, country and state/province lines worldwide, and country, state and major-city names, from Natural Earth. traxmapmaker builds it **last** (after Mexico, the charts master, contours and USGS) and lists it in `index.json`. MeshTrax fetches it with the catalogue and updates it by checksum. It isn't embedded, so it matches the downloadable regions. Until then an empty world is fine. |
| 2026-10-20 | **One catalogue: production.** The server publishes only products from full master builds to `https://maps.meshtrax.io/index.json`; the `dev/` test catalogue is retired. Every build uses the production catalogue. |
| 2026-10-20 | **A Google-Maps-style layers sheet** on the main map: map type tiles (OSM, USGS, NOAA), map details (contours, dark map) and node types (repeaters, chat, rooms…). It replaces the plain-text map selector. **The map is light by default**, whatever the app's theme. |
| 2026-10-20 | **The Charts tab is a coast list with ticks.** Coasts as the file lists them; areas alphabetical until `coast_areas` gives coastline order; Download takes every ticked area. Text only, one column, like the Maps tab. |
| 2026-10-21 | **Charts get NOAA's navigational set (Option B, Martin).** Today's 9 layers stay as they are. New layers, grouped by role, each carry the S-57 class:
  - routes;
  - regulated areas;
  - overhead clearances;
  - cables and pipelines;
  - harbour structures and facilities;
  - seabed;
  - tide and current;
  - extra aids (fog signals, daymarks, racons, virtual AIS);
  - landmarks;
  - magnetic variation.
  About 1.2–1.3 GB for the 42 areas. |
| 2026-10-22 | **Chart styles follow paper-chart conventions within the renderer's limits** (Martin approved from renders):
  - magenta dashed limits;
  - INT-1 abbreviations;
  - clearances never overstated;
  - restrictions worded exactly;
  - buoy names as the chart's number ("2") below z15.
  Symbols that need icons (arrows, anchors, T-ticks, topmarks) wait for sprites rather than being faked. |
| 2026-10-22 | **A world base map is bundled with the app** (Martin, with traxmapmaker). Natural Earth at z0–5 (4.2 MB, OpenMapTiles layer names), in traxmap's assets, copied next to the packs on first run and after an update. Offline maps draw it in every style up to zoom 6, where region packs take over; Online, the online tiles show the world. Where no region is downloaded, the map stops zooming in at 6 (or stays where it was, if already deeper) and the card reads "Download a region for detail". Maps zoom out to 2, about a continent on a phone (Martin; zoom 4 would show only a few states). |
| 2026-10-22 | **Hill shading is its own download, ticked by default, with a switch** (Martin). Each region offers "Hill shading" (the terrain pack) next to Contours, ticked like them: it's under 1 MB in gentle country and tens to a couple of hundred MB in mountain states, shown on the row. The map layers sheet gets a Hill shading switch beside Contours (setting `map_hill_shading`, on by default). Both base maps draw it; the USGS topo map no longer carries relief. |
| 2026-10-22 | **Chart symbols follow US Chart No. 1** (Martin, from renders of the Rhode Island pack). Buoys lean, with a small circle at the position; light flares are magenta whatever the light's colour, because a coloured flare merges into a buoy of its colour and the label gives the colour ("Fl G 4s"). Beacons on stakes and piles are daybeacons: square on the port hand, triangle on the starboard hand, a diamond otherwise. T-ticks mark entry-restricted areas and military practice areas; the other regulated areas keep dashed limits. Lit wind turbines keep their turbine symbol. Area limits come from traxmapmaker's `area_limit` lines (charts_revision 3), which leave out the shore and the chart-cell edges that split areas; packs without them keep drawing outlines (`limit_lines` marks the areas that have lines). |
| 2026-10-22 | **Depths in feet never read deeper than charted** (Martin). traxmapmaker's `depth_ft` keeps `round` for feet- and fathom-charted depths, which recovers the chart's figure exactly, and rounds down for metre-charted ones. It decides the units per feature, because NOAA cells don't flag units and mix them. It lands in the next charts rebuild; the app's styles keep reading `depth_ft`. |
| 2026-10-22 | **"Not for navigation" is a dialog that says why,** not a label always on the map (Martin). It opens the first time the map draws charts in each app run, with "Don't show this again". The Charts tab's line "Not for navigation · Why?" opens it any time, and can undo that choice. The reasons: charts go out of date (a download changes only when updated), leave things out (symbols, light sectors, notes; labels hidden until zoomed in), positions can be wrong or old, and MeshTrax isn't a certified chart plotter. |
| 2026-10-22 | **Downloaded areas: a teal outline of what the map showing draws** (Martin). Standard outlines the regions with a street map, USGS topo those with a USGS pack, and Charts the downloaded NOAA chart areas; Online it's the street map's. It's filled only Online, where it sets downloads apart from the online tiles: Offline everything drawn is downloaded, so a fill would tint the whole map. None on small maps (chat cards, mini maps). A **Downloaded areas** tile under Map details turns it off (setting `map_downloaded_areas`, on by default). Replaces the dashed pink region edges. |
| 2026-10-21 | **Charts follow NOAA's decluttering (SCAMIN) on every layer, at NOAA's standard-screen scale** (variant C, Martin, chosen from side-by-side renders of Puerto Rico test packs). Each feature appears from round(log2(279,541,132 × cos(lat) / SCAMIN)), at the earliest from its band's minzoom. In harbours, soundings come in one step after buoys and lights. |
| 2026-10-20 | **Charts carry the real NOAA content,** not a simplified view (Martin). traxmapmaker rebuilds the charts with traffic separation schemes, anchorages, restricted areas, bridges and overhead clearances, and caution areas. The current 9 layers stay. |
| 2026-10-20 | **My location: the phone's GPS where allowed, else the radio's position.** It asks while-in-use on the first tap. The phone is **its own marker** (Martin), a blue dot apart from the radio's "You". Nothing is read until the user has used My location once (remembered), and then only while a map is open with the app in front. Linux has no GPS and uses the radio. Desktop gets +/− buttons; phones pinch. |
| 2026-10-19 | **Copernicus GLO-30 is approved** for contours outside the US (Canada, Mexico, UK). A contours pack's `attribution` is then "USGS 3DEP", the Copernicus credit, or both, joined with "; ". The licence also requires redistributors to show: "The organisations in charge of the Copernicus programme by law or by delegation do not incur any liability for any use of the Copernicus WorldDEM-30." The app shows that alongside the credits wherever such a pack is in use, as it does the charts' "Not for navigation". **Agreed with traxmapmaker (SCHEMA.md "Pack metadata", FINDINGS §1.1):**<br>• Packs carry an optional plain-text `notice` metadata key, present only when a licence requires one.<br>• Several notices in one pack are joined by newlines.<br>• The key is in pack metadata only, not in `index.json`.<br>• The app shows every distinct notice of the packs in use (T5, `MapStyleState.notices`), and never matches on "Copernicus".<br>• First data: the Puerto Rico and US Virgin Islands contours. Two of their blocks have no 3DEP tile and use GLO-30. |

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
  - **Sprites:** one `SpriteAtlas` per layer, so icon sheets must be merged. traxmap bundles one sheet per palette (`assets/sprites/light@2x`, `dark@2x`, drawn by `tool/make_sprites.py`); a style names its sheet as `{sprite}/light` and the renderer loads it from the asset bundle. Sprites, `line-pattern` and every `*-opacity` work. Each icon family shares one box and one position point, so `icon-anchor: top-left` with a negative `icon-offset` puts it on the feature at any size and rotation.
  - **Tapping features:** there's no query API for vector features.
- **Style arithmetic and style cost, measured on real chart tiles** (2026-10-20, for traxmapmaker's full-data charts proposal; traxmapmaker's local Puerto Rico test packs, the real 2.9.1 pipeline in `flutter test`):
  - **Arithmetic works:**
    - `["to-string",["round",["*",["get","depth_m"],3.28084]]]` matched the pack's `depth_ft` on 3,446 of 3,446 soundings;
    - `concat` builds "142 ft";
    - `to-string` drops a whole number's ".0";
    - one decimal is `["/",["round",["*",x,10]],10]`.
  - **Guard optional numbers:** a missing attribute makes `*` null, and `to-string` makes that "", so a label reads "VC  ft". Use `["case",["has","clearance_m"],…,""]`.
  - **List attributes:** `in` against a string is a substring test ("restricted" matches "entry_restricted"). For an exact match, wrap both in commas: `["in",",entry_restricted,",["concat",",",["get","restrictions"],","]]`.
  - **Cost** ≈ (style layers on a source layer) × (its features in the tile), at about 0.5–1 µs per filter evaluation, paid once per tile when it's rasterized.
    - 96 per-class layers added 0.5–1.2 ms per dense Puerto Rico harbour tile, where today's depth layers cost 2–20 ms.
    - In big harbours (structure about 2k features per tile), draw the dense layers with a few `match`-driven layers, not one layer per class.
- **Phone location (geolocator 14, 2026-10-20):**
  - **The OS permission is no opt-in.** Android 11 and below grant location for every Bluetooth scan, and on Windows `checkPermission` *is* `RequestAccessAsync`, which can show the consent prompt. So `PhoneLocationService` reads nothing until My location has been tapped once.
  - **Location off:** with Location off, following (`getPositionStream`) makes Android pop Google's "turn on location" dialog by itself. Check `isLocationServiceEnabled` first.
  - **Stream errors don't close the stream.** Cancel the subscription on error, or a later tap can't start following again.
  - **Never asked reads as `denied`** on Android and iOS, not "unknown", so asking again on `denied` is what shows the prompt.
  - **iOS builds** need `BYPASS_PERMISSION_LOCATION_ALWAYS=1` in the environment (Swift Package Manager; the Podfile sets it for CocoaPods), or the binary references Always location (ITMS-90683).
- **Headless previews with real fonts, no native build** (2026-10-21): `flutter --show-test-device run -d flutter-tester -t <app.dart>` runs an app in the test engine without `flutter test`'s box-glyph test fonts and without the Linux desktop build. That build couldn't finish in 25 minutes on the busy Pi. Capture with `RepaintBoundary.toImage` and `exit(0)` when done. Inside `flutter test`, map labels always draw as boxes: the label painter names no font family, and `--use-test-fonts` is hard-wired.
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

- **Widget tests and real file I/O deadlock.** I/O started inside `testWidgets` (e.g. the Offline maps screen's refresh after its first frame) completes in real time, but its callbacks run only when the fake clock is pumped. Awaiting that future inside `tester.runAsync` never returns. Alternate `runAsync(() => Future.delayed(5 ms))` and `pump()` until it completes, as `finishRefresh` in `offline_maps_charts_test.dart` does. Start services with real I/O inside `runAsync` before `pumpWidget`.

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
- **Charts get their own picker,** by coastal state (Phase 6): built as the Charts tab (S3d).
- **Night style** (red on black, for night vision) and **SDF icons** (buoys,
  peaks, trailheads). T9 brought colour sprite sheets (2026-10-22); icons that styles recolour (SDF) are still open.
