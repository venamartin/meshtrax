import 'dart:io';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

import 'local_pmtiles_provider.dart';

/// One style source served from several packs of the same kind, e.g. the
/// OSM packs of neighbouring regions: each tile comes from the first pack
/// (in the given order) that has it. Packs cut from one master hold
/// identical tiles where they overlap, so the order only matters for
/// variants (the user's contours units go first).
class CompositePmTilesProvider extends vt.VectorTileProvider {
  final List<LocalPmTilesVectorTileProvider> parts;
  final String _cacheKey;

  CompositePmTilesProvider._(this.parts, this._cacheKey);

  /// Opens [files] in preference order.
  static Future<CompositePmTilesProvider> open(List<File> files) async {
    final parts = <LocalPmTilesVectorTileProvider>[];
    final key = StringBuffer('local-pmtiles:');
    try {
      for (final file in files) {
        parts.add(await LocalPmTilesVectorTileProvider.open(file));
        // A replaced or updated file must not reuse decoded tiles cached
        // for the old one, so the key covers each file's size and time.
        final stat = await file.stat();
        key.write(
          '${file.absolute.path}:${stat.size}:'
          '${stat.modified.microsecondsSinceEpoch}|',
        );
      }
    } catch (_) {
      for (final part in parts) {
        part.dispose();
      }
      rethrow;
    }
    return CompositePmTilesProvider._(parts, key.toString());
  }

  @override
  int get minimumZoom =>
      parts.map((p) => p.minimumZoom).reduce((a, b) => a < b ? a : b);

  @override
  int get maximumZoom =>
      parts.map((p) => p.maximumZoom).reduce((a, b) => a > b ? a : b);

  @override
  String get cacheKey => _cacheKey;

  /// Already local: don't copy tiles into the layer's disk cache.
  @override
  bool get cacheBytesToDisk => false;

  @override
  Future<vt.TileResponse> load(
    vt.TileKey tile, {
    vt.CancellationToken? cancellation,
  }) async {
    vt.TileResponse result = const vt.TileResponseNotFound();
    for (final part in parts) {
      final r = await part.load(tile, cancellation: cancellation);
      if (r is vt.TileResponseData || r is vt.TileResponseCancelled) return r;
      if (r is vt.TileResponseError) result = r;
    }
    return result;
  }

  /// Whether any pack has [tile], from the directories alone.
  Future<bool> contains(vt.TileKey tile) async {
    for (final part in parts) {
      if (await part.contains(tile)) return true;
    }
    return false;
  }

  @override
  void dispose() {
    for (final part in parts) {
      part.dispose();
    }
  }
}
