import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// PMTiles v3 compression codes.
const _compressionNone = 1;
const _compressionGzip = 2;

/// The fixed 127-byte header of a PMTiles v3 archive.
class PmtilesHeader {
  final int rootOffset;
  final int rootLength;
  final int metadataOffset;
  final int metadataLength;
  final int leafOffset;
  final int leafLength;
  final int dataOffset;
  final int dataLength;
  final int internalCompression;
  final int tileCompression;
  final int tileType;
  final int minZoom;
  final int maxZoom;

  const PmtilesHeader({
    required this.rootOffset,
    required this.rootLength,
    required this.metadataOffset,
    required this.metadataLength,
    required this.leafOffset,
    required this.leafLength,
    required this.dataOffset,
    required this.dataLength,
    required this.internalCompression,
    required this.tileCompression,
    required this.tileType,
    required this.minZoom,
    required this.maxZoom,
  });

  factory PmtilesHeader.parse(Uint8List b) {
    if (b.length < 127 ||
        String.fromCharCodes(b, 0, 7) != 'PMTiles' ||
        b[7] != 3) {
      throw const FormatException('not a PMTiles v3 archive');
    }
    final v = ByteData.sublistView(b);
    int u64(int o) => v.getUint64(o, Endian.little);
    return PmtilesHeader(
      rootOffset: u64(8),
      rootLength: u64(16),
      metadataOffset: u64(24),
      metadataLength: u64(32),
      leafOffset: u64(40),
      leafLength: u64(48),
      dataOffset: u64(56),
      dataLength: u64(64),
      internalCompression: b[97],
      tileCompression: b[98],
      tileType: b[99],
      minZoom: b[100],
      maxZoom: b[101],
    );
  }
}

/// The PMTiles tile id of z/x/y: tiles of lower zooms first, then the
/// Hilbert curve position within the zoom.
int tileId(int z, int x, int y) {
  if (z < 0 || z > 26) throw ArgumentError.value(z, 'z');
  final n = 1 << z;
  if (x < 0 || y < 0 || x >= n || y >= n) {
    throw ArgumentError('tile $z/$x/$y is outside the grid');
  }
  final acc = ((1 << (2 * z)) - 1) ~/ 3;
  var d = 0, tx = x, ty = y;
  for (var s = n >> 1; s > 0; s >>= 1) {
    final rx = (tx & s) > 0 ? 1 : 0;
    final ry = (ty & s) > 0 ? 1 : 0;
    d += s * s * ((3 * rx) ^ ry);
    if (ry == 0) {
      if (rx == 1) {
        tx = s - 1 - tx;
        ty = s - 1 - ty;
      }
      final t = tx;
      tx = ty;
      ty = t;
    }
  }
  return acc + d;
}

/// One decoded directory: entries sorted by tile id.
class _Directory {
  final Int64List ids;
  final Int64List offsets;
  final Int64List lengths;
  final Int64List runs;

  _Directory(this.ids, this.offsets, this.lengths, this.runs);

  factory _Directory.decode(Uint8List b) {
    var pos = 0;
    int varint() {
      var result = 0, shift = 0;
      while (true) {
        if (pos >= b.length) {
          throw const FormatException('truncated PMTiles directory');
        }
        final byte = b[pos++];
        result |= (byte & 0x7f) << shift;
        if (byte < 0x80) return result;
        shift += 7;
      }
    }

    final n = varint();
    final ids = Int64List(n), runs = Int64List(n);
    final lengths = Int64List(n), offsets = Int64List(n);
    var last = 0;
    for (var i = 0; i < n; i++) {
      last += varint();
      ids[i] = last;
    }
    for (var i = 0; i < n; i++) {
      runs[i] = varint();
    }
    for (var i = 0; i < n; i++) {
      lengths[i] = varint();
    }
    for (var i = 0; i < n; i++) {
      final v = varint();
      offsets[i] = v == 0 && i > 0 ? offsets[i - 1] + lengths[i - 1] : v - 1;
    }
    return _Directory(ids, offsets, lengths, runs);
  }

  /// The entry with the largest id at or below [id], or -1.
  int indexAtOrBefore(int id) {
    var lo = 0, hi = ids.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final v = ids[mid];
      if (v < id) {
        lo = mid + 1;
      } else if (v > id) {
        hi = mid - 1;
      } else {
        return mid;
      }
    }
    return hi;
  }
}

/// A local PMTiles v3 archive read through one [RandomAccessFile].
///
/// The file opens on first use and stays open until [close]. Directories
/// and metadata are kept across [close] and [open] while the file stays the
/// same (same size, modification time and header); a replaced file starts
/// over and bumps [generation]. Windows can't replace or delete an open
/// file, so callers close it after each analysis.
class PmtilesFile {
  final String path;

  /// Leaf directories kept in memory (each a few tens of kilobytes).
  static const maxLeaves = 64;

  RandomAccessFile? _file;
  Uint8List? _headerBytes;
  int _length = -1;
  DateTime? _modified;
  PmtilesHeader? _header;
  Map<String, Object?>? _metadata;
  _Directory? _root;
  final _leaves = <int, _Directory>{};

  /// Changes whenever the file on disk turns out to have been replaced.
  int generation = 0;

  PmtilesFile(this.path);

  bool get isOpen => _file != null;

  /// Opens the file if needed and checks it is the one read before.
  void open() {
    if (_file != null) return;
    final stat = File(path).statSync();
    if (stat.type == FileSystemEntityType.notFound) {
      throw FileSystemException('pack not found', path);
    }
    final file = File(path).openSync();
    try {
      final head = file.readSync(127);
      final same =
          _headerBytes != null &&
          stat.size == _length &&
          stat.modified == _modified &&
          _equal(head, _headerBytes!);
      if (!same) {
        final header = PmtilesHeader.parse(head);
        _check(header);
        _headerBytes = head;
        _length = stat.size;
        _modified = stat.modified;
        _header = header;
        _metadata = null;
        _root = null;
        _leaves.clear();
        generation++;
      }
    } catch (_) {
      file.closeSync();
      rethrow;
    }
    _file = file;
  }

  void close() {
    _file?.closeSync();
    _file = null;
  }

  PmtilesHeader get header {
    open();
    return _header!;
  }

  /// The archive's JSON metadata.
  Map<String, Object?> get metadata {
    final h = header;
    return _metadata ??= _parseMetadata(
      _inflate(
        _read(h.metadataOffset, h.metadataLength),
        h.internalCompression,
      ),
    );
  }

  /// The tile's bytes, decompressed, or null when the archive has no such
  /// tile.
  Uint8List? tile(int z, int x, int y) {
    final h = header;
    if (z < h.minZoom || z > h.maxZoom) return null;
    final id = tileId(z, x, y);
    var dir = _root ??= _Directory.decode(
      _inflate(_read(h.rootOffset, h.rootLength), h.internalCompression),
    );
    for (var depth = 0; depth < 4; depth++) {
      final i = dir.indexAtOrBefore(id);
      if (i < 0) return null;
      final run = dir.runs[i];
      if (run == 0) {
        dir = _leaf(dir.offsets[i], dir.lengths[i]);
        continue;
      }
      if (id - dir.ids[i] >= run || dir.lengths[i] == 0) return null;
      return _inflate(
        _read(h.dataOffset + dir.offsets[i], dir.lengths[i]),
        h.tileCompression,
      );
    }
    return null;
  }

  _Directory _leaf(int offset, int length) {
    final cached = _leaves.remove(offset);
    if (cached != null) {
      _leaves[offset] = cached;
      return cached;
    }
    final h = _header!;
    final dir = _Directory.decode(
      _inflate(_read(h.leafOffset + offset, length), h.internalCompression),
    );
    if (_leaves.length >= maxLeaves) _leaves.remove(_leaves.keys.first);
    _leaves[offset] = dir;
    return dir;
  }

  Uint8List _read(int offset, int length) {
    open();
    if (offset < 0 || length < 0 || offset + length > _length) {
      throw FormatException('PMTiles range outside the file', path, offset);
    }
    final f = _file!;
    f.setPositionSync(offset);
    final b = f.readSync(length);
    if (b.length != length) {
      throw FormatException('short read from PMTiles file', path, offset);
    }
    return b;
  }

  void _check(PmtilesHeader h) {
    for (final c in [h.internalCompression, h.tileCompression]) {
      if (c != _compressionNone && c != _compressionGzip && c != 0) {
        throw FormatException('unsupported PMTiles compression $c', path);
      }
    }
  }

  static Uint8List _inflate(Uint8List b, int compression) {
    final gz = b.length >= 2 && b[0] == 0x1f && b[1] == 0x8b;
    if (compression == _compressionGzip || (compression == 0 && gz)) {
      final out = gzip.decode(b);
      return out is Uint8List ? out : Uint8List.fromList(out);
    }
    return b;
  }

  static Map<String, Object?> _parseMetadata(Uint8List b) {
    if (b.isEmpty) return const {};
    final v = jsonDecode(utf8.decode(b));
    return v is Map<String, Object?> ? v : const {};
  }

  static bool _equal(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
