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
| Bundled styles: OSM, USGS and NOAA Charts, each light and dark; units | |

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

final styleId = await styles.styleForBrightness(MapType.osm, Theme.of(context).brightness);

OfflineMapView(
  styleId: styleId!,
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
- **Map and mode:** the user picks a `MapType` (`osm`, `usgs`, `charts`) and
  light or dark. `styles.styleFor(type, dark: …)` (or `styleForBrightness`)
  returns the style id. Contours on/off is the app's choice of whether to
  pass the contours pack. It applies to all three maps, which draw land
  contours from the same contours pack (on charts, over the land fill).
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
| `themeMode` (the map ignored it) | `styleForBrightness(type, brightness)` |
| Map source selector | `MapType` picker: OSM, USGS, NOAA Charts |
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

**Offline maps screen** (replaces `map_cache_screen.dart`; planned
2026-10-16). MeshTrax owns the screen. traxmap supplies the models, and
the example app's region picker is the prototype to copy. The design comes
from the regions mockup in traxmapmaker
(`experiments/geofabrik_regions/`).
- **Look and feel:** Martin likes the mockup, so stay as close to it as
  possible while keeping MeshTrax's style. Keep the mockup's structure
  and components. Take colours, type and widgets from MeshTrax's theme
  (Material 3, blue seed, DejaVu Sans, light/dark from the app setting),
  never the mockup's hex values.

  | Mockup | MeshTrax |
  | --- | --- |
  | Green accent, soft-accent fills | `colorScheme.primary` / `primaryContainer` |
  | Amber warning callout (large region, "Not for navigation") | Orange-tinted box with an orange left border, as in the mockup (MeshTrax already uses `Colors.orange` for warnings) |
  | Bordered panels, 10 px radius | `Card.outlined` |
  | Tabs under the title | `TabBar` in the `AppBar` (`AdaptiveAppBarTitle`) |
  | Breadcrumb trail (North America › United States › …) | Same: tappable `TextButton`s with › separators, above the map |
  | Map fills by download size (4 bands plus a grey "later"), with a legend strip under the map | Same bands as translucent `MapPolygon` fills over the world pack, tinted from the colour scheme; same legend strip |
  | Region list as a chip grid under the map, with a "later" pill | `Wrap` of chips, same pill |
  | Pack rows: checkbox, name, one-line source, size right-aligned in monospace | Same row as an outlined tile; sizes in monospace |
  | Contour interval dropdown inside the Contours row | Same, as a `DropdownButton` |
  | "Download" total row, then one primary "Download 1.2 GB" button | Same; `FilledButton` |
  | Toast line | `SnackBar` |
  | Map beside the panel above 880 px, stacked below | Same breakpoint; on phones the panel becomes the list sheet |

  Drop the mockup-only parts: the "Mockup" tag, the outline-area and
  OSM-extract rows, and the "sizes are estimates" note (the index has
  real sizes).
- **Tabs:** "Maps & contours" and "NOAA Charts". Charts are picked by
  coastal state, not by land region.
- **Layout:** on phones, the map is on top with a draggable list sheet
  below. On wide screens, the map and list sit side by side.
- **Map:**
  - `OfflineMapView` draws region outlines as `MapPolygon`s. Tap one to
    select it.
  - Installed regions are filled, and selected ones are highlighted.
  - It draws on a **small bundled world pack** (vector, z0–6), so the
    picker works offline before any download. The same pack fills the
    main map when nothing is installed.
- **List:**
  - A drill-down tree (North America › United States › California ›
    NorCal).
  - A "Suggested" row at the top for the region at the GPS fix or map
    centre.
  - Per-kind toggles with sizes: Map, Contours (on by default), and USGS
    (US only).
  - Progress, pause and cancel through `PackDownloader`.
- **Installed:** storage used, "update available" (the index's sha256
  differs from the installed pack), and delete.
- **Data:**
  - The simplified region outlines (`picker.geojson`) are **fetched from
    R2** next to `index.json` and cached, so new regions appear without an
    app release.
  - Packs pair with regions by region id.
  - Still to build: a `RegionIndex` in `core.dart` (tree, outlines,
    `regionAt(LatLng)`, pairing with `PackIndexEntry`s), the world pack,
    and `picker.geojson` in `./tmm regions` / `./tmm publish`.

**MeshTrax can then delete:**
- `map_tile_cache_service.dart` and its provider;
- `map_cache_screen.dart` and its settings and strings;
- possibly `flutter_cache_manager`.

## Example app

`example/` is the test bench: it shows how an app draws the chrome itself
(see `lib/map_chrome.dart`). Run it with `flutter run -d linux`, or on a phone.

**Screens:**
- the main screen: map picker (OSM / USGS / NOAA Charts), light/dark,
  contours on/off, ft/m, a pack drawer, and a stress test;
- a MeshTrax-style demo (hub button).

**Desktop testing variables:**
- `OVM_MAP=osm|usgs|charts` and `OVM_THEME=dark`: starting map and mode;
- `OVM_CAMERA=lat,lon,zoom`: starting view;
- `OVM_UNITS=metric`;
- `OVM_CONTOURS=off`;
- `OVM_SCREEN=meshtrax`: open the demo directly.

The bundled test packs (Watsonville to Monterey) come from traxmapmaker:
`./build.py --install-to ../traxmap/example/assets/packs`.

## Styles

**Six bundled styles,** one light and one dark per map:

| Map | Light | Dark |
| --- | --- | --- |
| OSM | `osm-light` | `osm-dark` |
| USGS | `usgs-light` | `usgs-dark` |
| NOAA Charts | `charts-light` | `charts-dark` |

**Where they come from:**
- **Hand-written:** `usgs-light` and `charts-light`.
- **Generated by `tool/make_dark_variants.py`:** their dark versions. That
  script swaps colours only, so layer changes carry over.
- **Generated by `tool/make_styles.py`:** the OSM pair, from one layer design
  with two palettes.

**Style metadata:**

| Key | Values |
| --- | --- |
| `ovm:map` | `osm`, `usgs`, `charts` |
| `ovm:theme` | `light`, `dark` |
| `ovm:family` | `standard` |
| `ovm:disclaimer` | chart styles only |
| `ovm:units` | on label layers: keep only for those units |

**Future styles:** `ovm:family` is the slot for future looks, e.g. an
"outdoor" family with its own light and dark style per map. Its palette is
already kept in `tool/make_styles.py`. `styleFor(…, family:)` falls back to
`standard` when a family isn't bundled.

**Placeholders** resolved at runtime: `pmtiles://{pack:<kind>}`, `{glyphs}`,
`{sprite}`.

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

## Findings

traxmapmaker's [`FINDINGS.md`](../traxmapmaker/FINDINGS.md) records the
decisions, measurements and pitfalls behind this package (renderer choice,
Flutter pitfalls, MeshTrax integration). Both repos grew from the
`vectormaps` prototype.
