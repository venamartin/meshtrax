## Unreleased

- **`ChartAreaIndex`** (core) parses the pack server's `chart_areas.geojson`
  (FINDINGS §1.4): NOAA chart areas, each one charts pack (`packRegion`),
  grouped by coast in the server's order (`coasts`, and `coast_areas` for a
  coastline order when present). `inCoast`, `byPackRegion`, `areasAt` (most
  specific first) and `areasOverlapping` (a region's outline, say). Bad
  features are skipped and named.
- **`MapFit.minZoom`** (and `OfflineMapController.fitBounds(minZoom:)`):
  a fit never zooms out past it; a bigger area shows its middle. MeshTrax
  frames a downloaded region no further out than its packs draw.
- **`TileCoverage`:** `OfflineMapView.onTileCoverage` reports which tiles
  the style's required packs draw, whenever the style or the packs change.
  `TileCoverage.covers(z, x, y)` takes flutter_map tile numbers, so an app
  can draw online tiles only in the gaps (MeshTrax does, with a tile
  provider that never fetches covered tiles). `onCoverageChanged` now uses
  the same lookup and matches the renderer at the packs' lowest zoom.
- **Failed downloads can be dismissed:** `PackDownloader.cancel` on a
  failed download forgets it. `BackgroundPackDownloader` deletes the
  plugin's record and emits `canceled`, so the failure isn't restored at
  the next launch.
- **Neighbouring regions draw as one map** (breaking for `StyleContext`):
  - `StyleContext.packs` is now `Map<PackKind, List<Pack>>`, in preference
    order from `StyleContext.packsByKind(packs, units:)`: the units
    variant first, then the newest build.
  - A resolved source names its first pack in `url` and every pack in
    `ovm:urls`. The renderer serves it with `CompositePmTilesProvider`,
    each tile from the first pack that has it. `sourceUrls(source)` reads
    either form; `packsUsedBy` credits all of them.
  - The decoded-tile cache key covers each file's size and modification
    time, so an updated or replaced pack never shows stale tiles.
  - Checked on the Pi with the Puerto Rico and US Virgin Islands packs from
    maps.meshtrax.io/dev.
- **Coverage and base layers** (for apps that show online tiles where no
  pack is installed):
  - `OfflineMapView.onCoverageChanged(bool)` reports whether the style's
    required packs have a tile at the view centre. It's checked from the
    packs' directories once the camera settles.
  - `baseLayers` draws raw flutter_map layers between the map's tiles and
    the overlays.
  - `StyleInfo.requiredKinds` comes from the new `ovm:requires` style
    metadata: osm, base (USGS) and charts. All six bundled styles carry it,
    and so does `tool/make_styles.py`.
- **Licence notices:** `MapStyleState.notices` lists the distinct `notice`
  lines of the packs a style draws from (Copernicus' liability statement
  is the first). `noticesOf(packs)` is in core.
- **`MapPolygon.holes`** for outlines with cut-outs.
- **Pack index v2:** matches traxmapmaker's server contract (FINDINGS §1.1).
  - `PackIndexEntry` reads `region` (the region path), `variant`, `units`,
    `interval` and `interval_unit`, and writes them back, so downloads
    restored after a restart keep them.
  - `PackIndex` has `generated`, `schemaVersion`, `usable` (known kinds at
    the bundled styles' schema) and `needsNewerApp`.
  - A malformed entry is skipped and listed in `skipped`, not fatal. A
    missing `packs` key is an empty catalogue.
  - The test fixture is the real `dev/index.json` from maps.meshtrax.io.
  - `forRegion(path)` lists the usable packs cut for a picker region.
- **`RegionIndex`** (core): the download picker's region tree from
  `picker.geojson` (traxmapmaker FINDINGS §1.2).
  - `Region` holds id, name, path, parent path, level, downloadable, fit
    bounds and outline polygons with holes.
  - The index offers `roots`, `childrenOf` (by name), `ancestorsOf`, and
    `regionAt(LatLng)` (the smallest downloadable region containing the
    point).
  - It keeps the `attribution` credit the app must show, and the `version`
    (`needsNewerApp`).
  - Malformed features are skipped and listed in `skipped`. Outlines are
    already split at the antimeridian.
- **Pack builds and updates:**
  - A pack installed with a checksum is stored as `<id>@<sha12>.pmtiles`.
    `Pack.sha256Prefix` and `Pack.isBuild(sha256)` tell whether the index
    has a newer build.
  - An update installs beside the old build and then deletes it. The map
    sees a new path, and Windows, which can't replace an open file, keeps
    working. `listInstalled` lists one pack per id and removes leftover
    builds.
  - Ids may not contain `@`.
  - `Pack.region` and `Pack.buildDate` come from the metadata.
- **SHA-256 checks run on a background isolate,** so verifying a
  multi-GB pack doesn't stall the UI.
- **`BackgroundPackDownloader`:**
  - `setRequiresWiFi(bool)` replaces the `requiresWiFi` constructor flag,
    and applies to running downloads too.
  - `configureNotifications(running:, paused:, failed:)` sets translated
    notification titles at any time, e.g. once the app knows its locale.
- **Pack downloads:**
  - **`PackDownloader`** (core): `PackDownload` snapshots with state,
    progress and error.
  - **`BackgroundPackDownloader`** (Flutter): built on background_downloader
    9.6. It downloads in the background, pauses and resumes with range
    requests, restores interrupted downloads at launch, and checks the
    SHA-256 before installing.
  - **`PackManager.install(move: true)`** renames a downloaded pack into
    place instead of copying it.
  - **Example:** a "Get maps" page; `OVM_INDEX` and `OVM_DOWNLOAD`; Android
    internet and notification permissions; the macOS network client
    entitlement; an integration test for a real download.
- **Charts draw land contours:** `charts-light` and `charts-dark` read the
  contours pack (lines plus ft/m labels) like the OSM and USGS styles, so
  contours on/off and light/dark apply to all three maps.
- **Example:** the contours toggle shows for NOAA Charts too, and
  `OVM_STYLES=<dir>` loads styles from a folder (desktop testing).

## 0.1.0

First version, split out of the `vectormaps` prototype.

- **Map surface:** `OfflineMapView` renders local PMTiles packs with
  flutter_map + flutter_map_vector_tiles. It draws no chrome: credits and
  disclaimers reach the app through `onStyleLoaded` (`MapStyleState`).
- **Camera:** `OfflineMapController` (a `ChangeNotifier`) moves and fits the
  camera, applying calls made before the map is ready. `MapFit` sets the
  initial frame.
- **Overlays:**
  - `MapMarker` with any widget, an anchor, labels from a zoom, and tap and
    long-press;
  - `MapLine` (solid, dashed or dotted) and `MapPolygon`;
  - map-level `onTap` and `onLongPress`;
  - `extraLayers` for raw flutter_map layers.
- **Packs:** `PackManager` installs, verifies, lists and deletes packs, with
  a `changes` stream. `PackIndex` covers the server index.
- **Styles:**
  - bundled Topo, Dark, Modern, Outdoor, OSM Topo and Chart;
  - `StyleRegistry` over any `StyleSource` (assets or a directory);
  - `forDark` / `forBrightness`;
  - unit-tagged label layers.
- **`package:traxmap/core.dart`:** the pure-Dart part, with no Flutter
  imports.

## Unreleased

**Breaking: the bundled styles are now three maps × light/dark:**
- **Styles:** `osm-light/dark`, `usgs-light/dark` and `charts-light/dark`.
  They replace Topo, Dark, Modern, Outdoor, OSM Topo and Chart.
- **New dark styles:** `usgs-dark` and `charts-dark`.
- **API:**
  - `MapType`, `StyleFamily`;
  - `StyleInfo.mapType` and `.family`;
  - `StyleRegistry.styleFor` / `styleForBrightness`, `mapTypes()` and
    `families()`. These replace `forDark` / `forBrightness`.
