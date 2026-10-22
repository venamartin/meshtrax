import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/services/map_tile_cache_service.dart';

/// Map styles held in memory (`osm-light`, `osm-dark`, and the same for any
/// other [maps]): no asset bundle, so no fake-async hang in widget tests.
class MemoryStyles implements StyleSource {
  /// Map types with a style, each needing packs of the kind of that name.
  final List<String> maps;

  MemoryStyles({this.maps = const ['osm']});

  @override
  Future<List<String>> ids() async => [
    for (final map in maps) ...['$map-dark', '$map-light'],
  ];

  @override
  Future<Map<String, Object?>> load(String id) async {
    final map = id.substring(0, id.lastIndexOf('-'));
    return {
      'version': 8,
      'name': id,
      'metadata': {
        'ovm:map': map,
        'ovm:theme': id.endsWith('dark') ? 'dark' : 'light',
        'ovm:requires': [map],
        if (map == 'charts') 'ovm:disclaimer': 'Not for navigation',
      },
      'sources': {
        map: {'type': 'vector', 'url': 'pmtiles://{pack:$map}'},
      },
      'layers': [
        {'id': 'bg', 'type': 'background'},
      ],
    };
  }
}

/// Online map tiles that never touch the network or disk.
class BlankTileCache extends MapTileCacheService {
  BlankTileCache() : super(cacheManager: _NoCacheManager());

  @override
  fm.TileProvider get tileProvider => _BlankTileProvider();
}

class _BlankTileProvider extends fm.TileProvider {
  // A 1×1 transparent PNG.
  static final _png = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0B, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x00, 0x02, 0x00,
    0x00, 0x05, 0x00, 0x01, 0x7A, 0x5E, 0xAB, 0x3F, 0x00, 0x00, 0x00, 0x00,
    0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  ImageProvider getImage(fm.TileCoordinates c, fm.TileLayer options) =>
      MemoryImage(_png);
}

/// A cache manager that's never used: the real one opens a cache store
/// through path_provider, which tests don't have.
class _NoCacheManager extends Fake implements BaseCacheManager {}
