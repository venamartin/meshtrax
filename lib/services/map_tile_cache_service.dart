import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

const String kMapTileUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Online OpenStreetMap tiles, loaded on demand and kept in a disk cache of
/// the tiles already viewed. Where an offline map pack is installed the app
/// draws that instead (docs/offline-maps.md). Bulk downloading of these
/// tiles is against OSM's tile policy, so there is none.
class MapTileCacheService {
  static const String cacheKey = 'map_tile_cache';
  static const String userAgentPackageName = 'com.vena.meshtrax';

  final BaseCacheManager cacheManager;
  late final TileProvider tileProvider;

  MapTileCacheService({BaseCacheManager? cacheManager})
    : cacheManager =
          cacheManager ??
          CacheManager(
            Config(
              cacheKey,
              stalePeriod: const Duration(days: 365),
              maxNrOfCacheObjects: 200000,
            ),
          ) {
    tileProvider = CachedNetworkTileProvider(cacheManager: this.cacheManager);
  }

  Future<void> clearCache() async {
    await cacheManager.emptyCache();
  }
}

class CachedNetworkTileProvider extends TileProvider {
  final BaseCacheManager cacheManager;

  CachedNetworkTileProvider({required this.cacheManager, super.headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedNetworkImageProvider(
      url,
      cacheManager: cacheManager,
      headers: headers,
    );
  }
}
