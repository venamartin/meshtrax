import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

import 'composite_pmtiles_provider.dart';
import 'mvt_reframe.dart';

/// Serves [fill] (the bundled base map) only where none of [masks] (the
/// downloaded packs) has a tile, judged at each tile's own zoom, so the base
/// map fills the gaps between regions without drawing over them.
///
/// Where the masks go deeper than the fill's data, the fill's deepest tiles
/// are served reframed for each deeper tile ([reframeMvt]). Stretching them
/// in the renderer instead would mask in the fill's big top-zoom tiles and
/// leave a blank band beside each region.
class GapFillProvider extends vt.VectorTileProvider {
  final CompositePmTilesProvider fill;
  final List<CompositePmTilesProvider> masks;

  /// Inflated top-zoom fill tiles, shared by the tiles reframed from them.
  final _parents = <vt.TileKey, Uint8List>{};

  GapFillProvider(this.fill, {required this.masks});

  @override
  int get minimumZoom => fill.minimumZoom;

  @override
  int get maximumZoom =>
      masks.fold(fill.maximumZoom, (z, m) => math.max(z, m.maximumZoom));

  @override
  String get cacheKey =>
      '${fill.cacheKey}|under:${masks.map((m) => m.cacheKey).join(',')}';

  @override
  bool get cacheBytesToDisk => false;

  @override
  Future<vt.TileResponse> load(
    vt.TileKey tile, {
    vt.CancellationToken? cancellation,
  }) async {
    if (await _masked(tile)) return const vt.TileResponseNotFound();
    final dz = tile.z - fill.maximumZoom;
    if (dz <= 0) return fill.load(tile, cancellation: cancellation);

    final key = vt.TileKey(fill.maximumZoom, tile.x >> dz, tile.y >> dz);
    var parent = _parents.remove(key);
    if (parent == null) {
      final r = await fill.load(key, cancellation: cancellation);
      if (r is! vt.TileResponseData) return r;
      parent = _inflate(r.bytes);
    }
    _parents[key] = parent;
    if (_parents.length > 8) _parents.remove(_parents.keys.first);
    final within = (1 << dz) - 1;
    return vt.TileResponseData(
      reframeMvt(parent, dz, tile.x & within, tile.y & within),
    );
  }

  Future<bool> _masked(vt.TileKey tile) async {
    for (final mask in masks) {
      // Below a pack's lowest zoom it draws nothing; above its highest the
      // renderer stretches its top-zoom tiles.
      if (tile.z < mask.minimumZoom) continue;
      final at = math.min(tile.z, mask.maximumZoom);
      final shift = tile.z - at;
      if (await mask.contains(
        vt.TileKey(at, tile.x >> shift, tile.y >> shift),
      )) {
        return true;
      }
    }
    return false;
  }

  static Uint8List _inflate(Uint8List bytes) {
    if (bytes.length < 2 || bytes[0] != 0x1f || bytes[1] != 0x8b) return bytes;
    final out = gzip.decode(bytes);
    return out is Uint8List ? out : Uint8List.fromList(out);
  }

  /// Disposes [fill] only: the masks are sources of their own.
  @override
  void dispose() => fill.dispose();
}
