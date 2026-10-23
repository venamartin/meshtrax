/// TraxMap: offline vector maps for MeshTrax, rendered from PMTiles packs.
///
/// The package renders the map surface and manages packs and styles. It has
/// no screens: the app builds its own UI from the hooks here (controller,
/// tap/long-press, [MapStyleState] credits and disclaimer, pack changes).
///
/// Apps built on latlong2 can also import `package:traxmap/latlong2.dart`.
library;

export 'core.dart';
export 'src/packs/background_pack_downloader.dart';
export 'src/packs/bundled_world.dart';
export 'src/renderer/flutter_map_renderer.dart' show TileCoverage;
export 'src/styles/asset_style_source.dart';
export 'src/view/attribution.dart' show AttributionChip;
export 'src/view/camera.dart';
export 'src/view/map_controller.dart' show OfflineMapController, MapFit;
export 'src/view/offline_map_view.dart';
export 'src/view/overlays.dart';
