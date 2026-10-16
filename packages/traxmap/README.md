# traxmap

Offline vector maps for [MeshTrax](../meshtrax): renders map packs (PMTiles,
Mapbox Vector Tiles) with bundled styles, manages installed packs, and
exposes hooks for the app. Works with no network at all.

Packs are built by **[traxmapmaker](../traxmapmaker)**, whose
[`SCHEMA.md`](../traxmapmaker/SCHEMA.md) defines the layers and pack metadata
the styles here are written against.

## What it does and doesn't do

| Does | Doesn't |
| --- | --- |
| Draws the map surface (`OfflineMapView`) from installed packs | Screens, menus, pickers, buttons |
| Draws app overlays on the map: markers (any widget), labels from a zoom, lines, polygons | Banners, credits chips, empty states (it hands the app the data) |
| Camera control (`OfflineMapController`), tap and long-press on the map | Network fetching while the map is in use |
| Installs, verifies, lists and deletes packs (`PackManager`) | Downloading packs (planned) |
| Bundled styles (Topo, Dark, Modern, Outdoor, OSM Topo, Chart), units, dark-mode matching | |

**The app must show** the credits from `MapStyleState.credits` (required by
the OpenStreetMap licence and the data sources), and `MapStyleState.disclaimer`
when present (chart styles: "Not for navigation").

## Libraries

- `package:traxmap/traxmap.dart`: everything, for Flutter apps.
- `package:traxmap/core.dart`: the pure-Dart part (packs, pack index, style
  loading and resolution). No Flutter imports, so it runs in isolates,
  background services and tools. A test enforces this.
- `package:traxmap/latlong2.dart`: `toOvm()` / `toLatLong2()` conversions for
  apps on latlong2. Where both `LatLng`s meet in one file, import traxmap with
  `hide LatLng, LatLngBounds`.

## Use

```yaml
dependencies:
  traxmap:
    git: <repo url>   # or path: ../traxmap
```

```dart
final packs = await PackManager(dir).listInstalled();
final controller = OfflineMapController();
MapStyleState? style;

OfflineMapView(
  styleId: 'outdoor',
  packs: packs,
  units: Units.imperial,
  controller: controller,
  initialFit: MapFit.points(nodePositions, padding: EdgeInsets.all(64), maxZoom: 15),
  overlays: [
    MapMarker(
      id: node.id,
      position: node.position,
      size: const Size(35, 35),
      child: NodeDot(node),
      label: node.name,
      labelMinZoom: 13,
      onTap: () => showNode(node),
    ),
    MapLine(id: 'path', points: hops, width: 4, color: Colors.blueAccent),
  ],
  onTap: (latLng) { /* … */ },
  onLongPress: (latLng) => showShareSheet(latLng),
  onStyleLoaded: (s) => setState(() => style = s), // draw s.credits, s.disclaimer
);

controller.move(center, zoom: 12);
controller.fitPoints(points, maxZoom: 15);
```

- **Zooms are MapLibre zooms**, one lower than flutter_map's. Use
  `MapCamera.fromFlutterMapZoom` when porting numbers.
- **Packs:** one per kind is used (`base`, `osm`, `contours`, `charts`).
  Among contours variants (`20ft`, `10m`, …) the one matching `units` wins.
  A style source whose pack kind isn't installed is dropped, along with its
  layers.
- **Dark mode:** `await bundledStyles().forBrightness(Theme.of(context).brightness, preferred: 'outdoor')`.
  `MapStyleState.info.isDark` tells the app when to darken its own chrome.
- **Escape hatch:** `extraLayers` takes raw flutter_map 8.x layers, for
  anything not yet ported to `MapOverlay`s. It's the only part tied to
  flutter_map.
- **Sharpness:** tile bitmaps are drawn at twice the screen density, capped
  at 4, so lines stay crisp between whole zoom levels. `tileResolution`
  overrides it on memory-constrained devices.
- **Hooks:**
  - `OfflineMapController` is a `ChangeNotifier`: camera, visible bounds,
    ready state.
  - `PackManager.changes` fires on install and delete.

## MeshTrax integration

| MeshTrax today | traxmap |
| --- | --- |
| `TileLayer(urlTemplate: kMapTileUrlTemplate, …)` | `OfflineMapView(styleId:, packs:)` |
| `MapController.move(latLng, zoom)` | `OfflineMapController.move(latLng, zoom: z - 1)` |
| `initialCameraFit: CameraFit.bounds(padding 64, maxZoom 16)` | `initialFit: MapFit.points(pts, padding: EdgeInsets.all(64), maxZoom: 15)` |
| `fitCamera(CameraFit.bounds(...))` | `controller.fitBounds(...)` / `fitPoints(...)` |
| `ValueKey(...)` rebuilds, post-frame `move` | Controller calls; they apply once the map is ready |
| `onPositionChanged` toggling labels at zoom 14 | `MapMarker(label:, labelMinZoom: 13)` |
| 35×35 node `Marker` | `MapMarker(child:, size: Size(35, 35), onTap:, onLongPress:)` |
| Separate label `Marker`s | Deleted; `MapMarker.label` (styled via `labelStyle`) |
| Flag pins / highlight pin | `MapMarker(anchor: …)` / `MapMarker(interactive: false)` |
| Path and line-of-sight `PolylineLayer`s | `MapLine` (`pattern: MapLinePattern.dashed` for "no data") |
| Cache-area `PolygonLayer` | `MapPolygon` |
| `MapOptions.onTap` / `onLongPress` | `OfflineMapView.onTap` / `onLongPress` |
| `camera.visibleBounds` / `camera.zoom` | `controller.visibleBounds` / `controller.camera` |
| `UnitSystem` | `Units` (also picks the contours variant) |
| `themeMode` (the map ignored it) | `forBrightness(...)`, `MapStyleState.info.isDark` |
| No attribution | App draws `MapStyleState.credits` |

**Zoom conversion** (MeshTrax → traxmap):

| MeshTrax | traxmap |
| --- | --- |
| min 2 / max 18 | 1 / 17 |
| main-map label threshold 14 | 13 |
| path-map label threshold 8.5 | 7.5 |
| fit maxZoom 16 | 15 |

**Migration order:**
1. `repeater_login_dialog.dart`: the mini-map.
2. `channel_message_path_screen.dart`.
3. `path_trace_map.dart`.
4. `line_of_sight_map_screen.dart`: long-press passes through lines.
5. `map_screen.dart`.
6. `map_cache_screen.dart`: becomes a pack-management screen.

**MeshTrax can then delete:**
- `map_tile_cache_service.dart` and its provider;
- `map_cache_screen.dart` and its settings and strings;
- possibly `flutter_cache_manager`.

## Example app

`example/` is the test bench: it shows how an app draws the chrome itself
(see `lib/map_chrome.dart`). Run it with `flutter run -d linux`, or on a phone.

**Screens:**
- the main screen: style picker, contours on/off, ft/m, a pack drawer, and a
  stress test;
- a MeshTrax-style demo (hub button).

**Desktop testing variables:**
- `OVM_STYLE=<id>`: starting style;
- `OVM_CAMERA=lat,lon,zoom`: starting view;
- `OVM_UNITS=metric`;
- `OVM_CONTOURS=off`;
- `OVM_SCREEN=meshtrax`: open the demo directly.

The bundled test packs (Watsonville to Monterey) come from traxmapmaker:
`./build.py --install-to ../traxmap/example/assets/packs`.

## Styles

The bundled styles live in `assets/styles/`:
- **Hand-written:** `topo.json`, `chart.json`, `osm.json`.
- **Generated:** `dark.json`, `modern.json` and `outdoor.json`, by
  `tool/make_styles.py assets/styles` from one layer design with three
  palettes.

**Placeholders** resolved at runtime: `pmtiles://{pack:<kind>}`, `{glyphs}`,
`{sprite}`.

**Metadata keys:**
- `ovm:units` on a layer keeps it only for those units;
- `ovm:dark` on the style marks it as dark;
- `ovm:disclaimer` on the style sets its disclaimer.

## Tests

```sh
flutter test
```

**Covered:**
- packs, the pack index and the PMTiles reader;
- style resolution and units;
- overlay gestures and labels;
- the controller;
- attribution;
- the core library staying Flutter-free.

`real_pack_test.dart` reads the bundled test packs when present.

## Origin

Grown from the `vectormaps` prototype. Its `FINDINGS.md` records the
decisions, measurements and pitfalls behind this package.
