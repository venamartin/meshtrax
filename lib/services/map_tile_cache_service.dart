import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

const String kMapTileUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

class MapTileCacheProgress {
  final int completed;
  final int total;
  final int failed;

  const MapTileCacheProgress({
    required this.completed,
    required this.total,
    required this.failed,
  });
}

class MapTileCacheResult {
  final int total;
  final int downloaded;
  final int failed;

  const MapTileCacheResult({
    required this.total,
    required this.downloaded,
    required this.failed,
  });
}

class MapTileCacheService {
  static const String cacheKey = 'map_tile_cache';
  static const String userAgentPackageName = 'com.vena.meshtrax';
  static const int defaultMinZoom = 10;
  static const int defaultMaxZoom = 15;

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

  Map<String, String> get defaultHeaders => {
    'User-Agent': 'flutter_map ($userAgentPackageName)',
  };

  Future<void> clearCache() async {
    await cacheManager.emptyCache();
  }

  int estimateTileCount(LatLngBounds bounds, int minZoom, int maxZoom) {
    final safeMin = math.min(minZoom, maxZoom);
    final safeMax = math.max(minZoom, maxZoom);
    int total = 0;

    for (int zoom = safeMin; zoom <= safeMax; zoom++) {
      final tileBounds = _tileBoundsForBounds(bounds, zoom);
      final xCount = tileBounds.maxX - tileBounds.minX + 1;
      final yCount = tileBounds.maxY - tileBounds.minY + 1;
      total += xCount * yCount;
    }
    return total;
  }

  Future<MapTileCacheResult> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    int concurrentDownloads = 8,
    Map<String, String>? headers,
    void Function(MapTileCacheProgress progress)? onProgress,
  }) async {
    final safeMin = math.min(minZoom, maxZoom);
    final safeMax = math.max(minZoom, maxZoom);
    final total = estimateTileCount(bounds, safeMin, safeMax);
    final authHeaders = headers ?? defaultHeaders;
    final safeConcurrency = math.max(1, concurrentDownloads);
    int completed = 0;
    int failed = 0;

    final pending = <Future<void>>[];
    Future<void> queueDownload(String url) async {
      final future = cacheManager
          .downloadFile(url, key: url, authHeaders: authHeaders)
          .then((_) {
            completed += 1;
          })
          .catchError((_) {
            completed += 1;
            failed += 1;
          })
          .whenComplete(() {
            onProgress?.call(
              MapTileCacheProgress(
                completed: completed,
                total: total,
                failed: failed,
              ),
            );
          });

      pending.add(future);
      if (pending.length >= safeConcurrency) {
        await Future.wait(pending);
        pending.clear();
      }
    }

    for (int zoom = safeMin; zoom <= safeMax; zoom++) {
      final tileBounds = _tileBoundsForBounds(bounds, zoom);
      for (int x = tileBounds.minX; x <= tileBounds.maxX; x++) {
        for (int y = tileBounds.minY; y <= tileBounds.maxY; y++) {
          final url = _buildTileUrl(x, y, zoom);
          await queueDownload(url);
        }
      }
    }

    if (pending.isNotEmpty) {
      await Future.wait(pending);
    }

    return MapTileCacheResult(
      total: total,
      downloaded: completed - failed,
      failed: failed,
    );
  }

  static Map<String, double> boundsToJson(LatLngBounds bounds) {
    return {
      'north': bounds.north,
      'south': bounds.south,
      'east': bounds.east,
      'west': bounds.west,
    };
  }

  static LatLngBounds? boundsFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final north = (json['north'] as num?)?.toDouble();
    final south = (json['south'] as num?)?.toDouble();
    final east = (json['east'] as num?)?.toDouble();
    final west = (json['west'] as num?)?.toDouble();
    if (north == null || south == null || east == null || west == null) {
      return null;
    }
    return LatLngBounds.unsafe(
      north: north,
      south: south,
      east: east,
      west: west,
    );
  }

  _TileBounds _tileBoundsForBounds(LatLngBounds bounds, int zoom) {
    final north = _clampLatitude(bounds.north);
    final south = _clampLatitude(bounds.south);
    final maxIndex = (1 << zoom) - 1;

    final minX = _lonToTileX(bounds.west, zoom, maxIndex);
    final maxX = _lonToTileX(bounds.east, zoom, maxIndex);
    final minY = _latToTileY(north, zoom, maxIndex);
    final maxY = _latToTileY(south, zoom, maxIndex);

    return _TileBounds(
      minX: math.min(minX, maxX),
      maxX: math.max(minX, maxX),
      minY: math.min(minY, maxY),
      maxY: math.max(minY, maxY),
    );
  }

  int _lonToTileX(double lon, int zoom, int maxIndex) {
    final n = 1 << zoom;
    final value = ((lon + 180.0) / 360.0 * n).floor();
    return value.clamp(0, maxIndex);
  }

  int _latToTileY(double lat, int zoom, int maxIndex) {
    final n = 1 << zoom;
    final rad = lat * math.pi / 180.0;
    final value =
        ((1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n)
            .floor();
    return value.clamp(0, maxIndex);
  }

  double _clampLatitude(double lat) {
    const maxLat = 85.05112878;
    return lat.clamp(-maxLat, maxLat);
  }

  String _buildTileUrl(int x, int y, int zoom) {
    return kMapTileUrlTemplate
        .replaceAll('{z}', zoom.toString())
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString());
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

class _TileBounds {
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  const _TileBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}
