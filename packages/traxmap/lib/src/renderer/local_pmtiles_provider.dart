import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

/// Serves vector tiles from a PMTiles archive on local storage.
///
/// flutter_map_vector_tiles' own `PmTilesVectorTileProvider` only reads over
/// HTTP range requests; this reads the file directly. Tile blobs are returned
/// still gzipped: the layer sniffs the gzip header and inflates on its worker
/// isolates, off the UI thread.
class LocalPmTilesVectorTileProvider extends vt.VectorTileProvider {
  final File file;
  final vt.PmTilesHeader header;
  final vt.PmTilesDirectory _root;
  final RandomAccessFile _raf;
  final _leaves = <int, vt.PmTilesDirectory>{};
  // RandomAccessFile allows one pending operation at a time.
  Future<void> _queue = Future.value();
  var _disposed = false;

  LocalPmTilesVectorTileProvider._(
    this.file,
    this.header,
    this._root,
    this._raf,
  );

  static Future<LocalPmTilesVectorTileProvider> open(File file) async {
    final raf = await file.open();
    try {
      final prefix = await raf.read(16384);
      final header = vt.PmTilesHeader.parse(prefix);
      if (header.internalCompression != vt.PmTilesCompression.gzip &&
          header.internalCompression != vt.PmTilesCompression.none) {
        throw vt.PmTilesException(
          'unsupported directory compression ${header.internalCompression}',
        );
      }
      await raf.setPosition(header.rootDirectoryOffset);
      final rootBytes = await raf.read(header.rootDirectoryLength);
      final root = vt.PmTilesDirectory.decode(_inflate(header, rootBytes));
      return LocalPmTilesVectorTileProvider._(file, header, root, raf);
    } catch (_) {
      await raf.close();
      rethrow;
    }
  }

  @override
  int get minimumZoom => header.minZoom;

  @override
  int get maximumZoom => header.maxZoom;

  @override
  String get cacheKey => 'local-pmtiles:${file.absolute.path}';

  /// Already local: don't copy tiles into the layer's disk cache.
  @override
  bool get cacheBytesToDisk => false;

  @override
  Future<vt.TileResponse> load(
    vt.TileKey tile, {
    vt.CancellationToken? cancellation,
  }) async {
    if (tile.z < minimumZoom ||
        tile.z > maximumZoom ||
        tile.z > vt.pmTilesMaxAddressableZoom) {
      return const vt.TileResponseNotFound();
    }
    final tileId = vt.zxyToTileId(tile.z, tile.x, tile.y);
    try {
      var directory = _root;
      for (var depth = 0; depth < 3; depth++) {
        if (_disposed || (cancellation?.isCancelled ?? false)) {
          return const vt.TileResponseCancelled();
        }
        final entry = directory.find(tileId);
        if (entry == null) return const vt.TileResponseNotFound();
        if (!entry.isLeaf) {
          final bytes = await _read(
            header.tileDataOffset + entry.offset,
            entry.length,
          );
          return bytes.isEmpty
              ? const vt.TileResponseNotFound()
              : vt.TileResponseData(bytes);
        }
        directory = _leaves[entry.offset] ??= vt.PmTilesDirectory.decode(
          _inflate(
            header,
            await _read(
              header.leafDirectoriesOffset + entry.offset,
              entry.length,
            ),
          ),
        );
      }
      return const vt.TileResponseNotFound();
    } catch (e) {
      if (_disposed) return const vt.TileResponseCancelled();
      return vt.TileResponseError(e);
    }
  }

  /// Whether the archive has [tile], from its directories alone (no tile
  /// data is read).
  Future<bool> contains(vt.TileKey tile) async {
    if (tile.z < minimumZoom ||
        tile.z > maximumZoom ||
        tile.z > vt.pmTilesMaxAddressableZoom) {
      return false;
    }
    final tileId = vt.zxyToTileId(tile.z, tile.x, tile.y);
    var directory = _root;
    for (var depth = 0; depth < 3 && !_disposed; depth++) {
      final entry = directory.find(tileId);
      if (entry == null) return false;
      if (!entry.isLeaf) return entry.length > 0;
      directory = _leaves[entry.offset] ??= vt.PmTilesDirectory.decode(
        _inflate(
          header,
          await _read(header.leafDirectoriesOffset + entry.offset, entry.length),
        ),
      );
    }
    return false;
  }

  Future<Uint8List> _read(int offset, int length) {
    final result = _queue.then((_) async {
      await _raf.setPosition(offset);
      return _raf.read(length);
    });
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  static Uint8List _inflate(vt.PmTilesHeader header, Uint8List bytes) {
    if (header.internalCompression != vt.PmTilesCompression.gzip) return bytes;
    final out = gzip.decode(bytes);
    return out is Uint8List ? out : Uint8List.fromList(out);
  }

  @override
  void dispose() {
    _disposed = true;
    _queue.whenComplete(_raf.close);
  }
}
