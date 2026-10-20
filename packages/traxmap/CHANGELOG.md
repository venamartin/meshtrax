## Unreleased

- **Pack index v2:** matches traxmapmaker's server contract (FINDINGS §1.1).
  - `PackIndexEntry` reads `region` (the region path), `variant`, `units`,
    `interval` and `interval_unit`, and writes them back, so downloads
    restored after a restart keep them.
  - `PackIndex` has `generated`, `schemaVersion`, `usable` (known kinds at
    the bundled styles' schema) and `needsNewerApp`.
  - A malformed entry is skipped and listed in `skipped`, not fatal. A
    missing `packs` key is an empty catalogue.
  - The test fixture is the real `dev/index.json` from maps.meshtrax.io.
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
