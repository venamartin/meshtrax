/// TraxMap core: offline map packs and styles, in pure Dart (no Flutter).
///
/// Use this in isolates, background services, tools and tests. Flutter apps
/// import `package:traxmap/traxmap.dart`, which re-exports everything here.
library;

export 'src/packs/attribution.dart';
export 'src/packs/geo.dart';
export 'src/packs/pack.dart';
export 'src/packs/pack_download.dart';
export 'src/packs/pack_index.dart';
export 'src/packs/pack_manager.dart' show PackManager, PackException;
export 'src/packs/pmtiles_header.dart';
export 'src/packs/region_index.dart';
export 'src/styles/style_info.dart';
export 'src/styles/style_registry.dart';
