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
