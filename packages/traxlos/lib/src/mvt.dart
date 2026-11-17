import 'dart:convert';
import 'dart:typed_data';

/// The contour lines of one tile: every line's points one after another
/// in tile coordinates (the layer's extent across the tile, buffer
/// included), with each line's height.
class ContourLines {
  /// x, y pairs.
  final Int16List xy;

  /// Where each line starts, in points; one more entry than lines.
  final Int32List starts;

  /// Each line's height in metres.
  final Float64List levels;

  /// Tile coordinates across the tile (4096 in the MeshTrax packs).
  final int extent;

  const ContourLines(this.xy, this.starts, this.levels, this.extent);

  int get lineCount => levels.length;

  int get pointCount => xy.length ~/ 2;

  static final empty = ContourLines(
    Int16List(0),
    Int32List(1),
    Float64List(0),
    4096,
  );
}

/// A named summit from a map pack's `mountain_peak` layer.
class PeakPoint {
  final String name;
  final double eleM;

  /// Position in tile coordinates.
  final int x;
  final int y;
  final int extent;

  const PeakPoint(this.name, this.eleM, this.x, this.y, this.extent);
}

const _feet = 0.3048;

/// Reads the line features of [layer], each at its `ele_ft` (times 0.3048)
/// or `ele_m` height. Features without that height are skipped.
ContourLines decodeContours(
  Uint8List tile, {
  required bool feet,
  String layer = 'contour',
}) {
  final found = _findLayer(tile, layer);
  if (found == null) return ContourLines.empty;
  final key = found.keys.indexOf(feet ? 'ele_ft' : 'ele_m');
  if (key < 0) return ContourLines.empty;
  final xy = _IntBuffer();
  final starts = _IntBuffer()..add(0);
  final levels = <double>[];
  for (final f in found.features) {
    if (f.type != 2) continue;
    final v = f.tag(key, found.values);
    if (v is! num) continue;
    final level = feet ? v * _feet : v.toDouble();
    final g = _Pbf(tile, f.geometryStart, f.geometryEnd);
    var x = 0, y = 0, partStart = xy.length;
    void endPart() {
      if (xy.length - partStart >= 4) {
        starts.add(xy.length ~/ 2);
        levels.add(level);
      } else {
        xy.length = partStart;
      }
      partStart = xy.length;
    }

    while (!g.atEnd) {
      final c = g.varint();
      final id = c & 7, count = c >> 3;
      if (id == 1 || id == 2) {
        for (var k = 0; k < count; k++) {
          if (id == 1) endPart();
          x += _zigzag(g.varint());
          y += _zigzag(g.varint());
          xy
            ..add(_short(x))
            ..add(_short(y));
        }
      } else if (id == 7) {
        if (xy.length - partStart >= 2) {
          xy
            ..add(xy[partStart])
            ..add(xy[partStart + 1]);
        }
      } else {
        throw FormatException('bad MVT geometry command $id');
      }
    }
    endPart();
  }
  return ContourLines(
    Int16List.fromList(xy.toList()),
    Int32List.fromList(starts.toList()),
    Float64List.fromList(levels),
    found.extent,
  );
}

/// Reads the named peaks (class `peak` or `volcano`) with an `ele` height.
List<PeakPoint> decodePeaks(Uint8List tile, {String layer = 'mountain_peak'}) {
  final found = _findLayer(tile, layer);
  if (found == null) return const [];
  final nameKey = found.keys.indexOf('name');
  final eleKey = found.keys.indexOf('ele');
  final classKey = found.keys.indexOf('class');
  if (nameKey < 0 || eleKey < 0) return const [];
  final out = <PeakPoint>[];
  for (final f in found.features) {
    if (f.type != 1) continue;
    final name = f.tag(nameKey, found.values);
    final ele = f.tag(eleKey, found.values);
    final cls = classKey < 0 ? null : f.tag(classKey, found.values);
    if (name is! String || name.isEmpty || ele is! num) continue;
    if (cls != null && cls != 'peak' && cls != 'volcano') continue;
    final g = _Pbf(tile, f.geometryStart, f.geometryEnd);
    var x = 0, y = 0;
    while (!g.atEnd) {
      final c = g.varint();
      final id = c & 7, count = c >> 3;
      if (id != 1) break;
      for (var k = 0; k < count; k++) {
        x += _zigzag(g.varint());
        y += _zigzag(g.varint());
        out.add(PeakPoint(name, ele.toDouble(), x, y, found.extent));
      }
    }
  }
  return out;
}

class _Feature {
  final int type;
  final int tagsStart, tagsEnd;
  final int geometryStart, geometryEnd;
  final Uint8List bytes;

  _Feature(
    this.bytes,
    this.type,
    this.tagsStart,
    this.tagsEnd,
    this.geometryStart,
    this.geometryEnd,
  );

  /// The value of key index [key], or null.
  Object? tag(int key, List<Object?> values) {
    final t = _Pbf(bytes, tagsStart, tagsEnd);
    while (!t.atEnd) {
      final k = t.varint(), v = t.varint();
      if (k == key) return v < values.length ? values[v] : null;
    }
    return null;
  }
}

class _Layer {
  final List<String> keys;
  final List<Object?> values;
  final List<_Feature> features;
  final int extent;

  _Layer(this.keys, this.values, this.features, this.extent);
}

_Layer? _findLayer(Uint8List b, String name) {
  final r = _Pbf(b, 0, b.length);
  while (!r.atEnd) {
    final tag = r.varint();
    if (tag == 26) {
      final n = r.varint();
      final layer = _layer(b, r.pos, r.pos + n, name);
      if (layer != null) return layer;
      r.pos += n;
    } else {
      r.skip(tag & 7);
    }
  }
  return null;
}

_Layer? _layer(Uint8List b, int start, int end, String want) {
  final r = _Pbf(b, start, end);
  String? name;
  var extent = 4096;
  final keys = <String>[];
  final values = <Object?>[];
  final features = <(int, int)>[];
  while (!r.atEnd) {
    final tag = r.varint();
    switch (tag) {
      case 10:
        final n = r.varint();
        name = utf8.decode(Uint8List.sublistView(b, r.pos, r.pos + n));
        r.pos += n;
        if (name != want) return null;
      case 18:
        final n = r.varint();
        features.add((r.pos, r.pos + n));
        r.pos += n;
      case 26:
        final n = r.varint();
        keys.add(utf8.decode(Uint8List.sublistView(b, r.pos, r.pos + n)));
        r.pos += n;
      case 34:
        final n = r.varint();
        values.add(_value(b, r.pos, r.pos + n));
        r.pos += n;
      case 40:
        extent = r.varint();
      default:
        r.skip(tag & 7);
    }
  }
  if (name != want) return null;
  if (extent <= 0) throw const FormatException('bad MVT extent');
  return _Layer(keys, values, [
    for (final (s, e) in features) _feature(b, s, e),
  ], extent);
}

_Feature _feature(Uint8List b, int start, int end) {
  final f = _Pbf(b, start, end);
  var type = 0, ts = 0, te = 0, gs = 0, ge = 0;
  while (!f.atEnd) {
    final tag = f.varint();
    switch (tag) {
      case 18:
        final n = f.varint();
        ts = f.pos;
        te = f.pos + n;
        f.pos += n;
      case 24:
        type = f.varint();
      case 34:
        final n = f.varint();
        gs = f.pos;
        ge = f.pos + n;
        f.pos += n;
      default:
        f.skip(tag & 7);
    }
  }
  return _Feature(b, type, ts, te, gs, ge);
}

Object? _value(Uint8List b, int start, int end) {
  final r = _Pbf(b, start, end);
  Object? v;
  while (!r.atEnd) {
    final tag = r.varint();
    switch (tag) {
      case 10:
        final n = r.varint();
        v = utf8.decode(Uint8List.sublistView(b, r.pos, r.pos + n));
        r.pos += n;
      case 21:
        v = ByteData.sublistView(
          b,
          r.pos,
          r.pos + 4,
        ).getFloat32(0, Endian.little);
        r.pos += 4;
      case 25:
        v = ByteData.sublistView(
          b,
          r.pos,
          r.pos + 8,
        ).getFloat64(0, Endian.little);
        r.pos += 8;
      case 32:
        v = r.varint(); // int64: negatives arrive as 10-byte two's complement
      case 40:
        v = r.varint();
      case 48:
        v = _zigzag(r.varint());
      case 56:
        v = r.varint() != 0;
      default:
        r.skip(tag & 7);
    }
  }
  return v;
}

int _zigzag(int n) => (n >>> 1) ^ -(n & 1);

int _short(int v) => v < -32768 ? -32768 : (v > 32767 ? 32767 : v);

class _Pbf {
  final Uint8List b;
  int pos;
  final int end;

  _Pbf(this.b, this.pos, this.end);

  bool get atEnd => pos >= end;

  int varint() {
    var result = 0, shift = 0;
    while (true) {
      if (pos >= end) throw const FormatException('truncated MVT');
      final byte = b[pos++];
      result |= (byte & 0x7f) << shift;
      if (byte < 0x80) return result;
      shift += 7;
      if (shift > 63) throw const FormatException('bad MVT varint');
    }
  }

  void skip(int wire) {
    switch (wire) {
      case 0:
        varint();
      case 1:
        pos += 8;
      case 2:
        pos += varint();
      case 5:
        pos += 4;
      default:
        throw FormatException('bad MVT wire type $wire');
    }
    if (pos > end) throw const FormatException('truncated MVT');
  }
}

/// A growable list of small ints without boxing.
class _IntBuffer {
  Int32List _b = Int32List(256);
  int length = 0;

  void add(int v) {
    if (length == _b.length) {
      final n = Int32List(_b.length * 2)..setRange(0, length, _b);
      _b = n;
    }
    _b[length++] = v;
  }

  int operator [](int i) => _b[i];

  Int32List toList() => Int32List.sublistView(_b, 0, length);
}
