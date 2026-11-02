import 'dart:math' as math;
import 'dart:typed_data';

/// Re-expresses plain (not gzipped) vector tile bytes as the tile [dz]
/// levels below them at offset ([dx], [dy]), so a source can serve zooms
/// deeper than its data.
///
/// Nothing is clipped or scaled: each layer's extent shrinks by 2^[dz] and
/// each feature's first point moves by the child's offset (MVT geometry is
/// relative after that), so coordinates stay exact and the renderer clips
/// what crosses the tile's edge. Features that don't reach the child tile
/// (give or take an eighth of it, for line ends and labels) are left out,
/// so a child costs what it shows, not its whole parent.
Uint8List reframeMvt(Uint8List tile, int dz, int dx, int dy) {
  final out = _Writer(tile.length >> dz);
  final r = _Reader(tile, 0, tile.length);
  while (!r.atEnd) {
    final start = r.pos;
    final tag = r.varint();
    if (tag == 26) {
      // field 3: layer
      final (s, e) = r.slice();
      _layer(out, tile, s, e, dz, dx, dy);
    } else {
      r.skip(tag & 7);
      out.bytes(tile, start, r.pos);
    }
  }
  return out.result();
}

void _layer(
  _Writer out,
  Uint8List b,
  int start,
  int end,
  int dz,
  int dx,
  int dy,
) {
  var extent = 4096;
  for (final r = _Reader(b, start, end); !r.atEnd;) {
    final tag = r.varint();
    if (tag == 40) {
      extent = r.varint();
    } else {
      r.skip(tag & 7);
    }
  }
  final size = extent >> dz;
  final margin = math.max(size >> 3, 1);
  final x0 = dx * size;
  final y0 = dy * size;

  // What the layer keeps, in order: raw fields as (start, end), features
  // as _Feature. Its length must be known before it's written.
  final parts = <Object>[];
  var length = 0;
  for (final r = _Reader(b, start, end); !r.atEnd;) {
    final fieldStart = r.pos;
    final tag = r.varint();
    if (tag == 40) {
      r.varint();
    } else if (tag == 18) {
      // field 2: feature
      final (s, e) = r.slice();
      final f = _Feature.read(b, s, e);
      if (f != null &&
          f.maxX >= x0 - margin &&
          f.minX <= x0 + size + margin &&
          f.maxY >= y0 - margin &&
          f.minY <= y0 + size + margin) {
        f.moveTo(x0, y0);
        parts.add(f);
        length += 1 + _varintSize(f.length) + f.length;
      }
    } else {
      r.skip(tag & 7);
      parts.add((fieldStart, r.pos));
      length += r.pos - fieldStart;
    }
  }
  length += 1 + _varintSize(size);

  out
    ..varint(26)
    ..varint(length);
  for (final part in parts) {
    switch (part) {
      case (final int s, final int e):
        out.bytes(b, s, e);
      case final _Feature f:
        f.write(out);
    }
  }
  out
    ..varint(40)
    ..varint(size);
}

/// A feature to copy with its first point moved: everything else is copied
/// byte for byte from [b].
class _Feature {
  final Uint8List b;
  final int start, end;

  /// Where the geometry field starts (its tag), and its content.
  final int field, geomStart, geomEnd;

  /// The first point, and where its two parameters lie in [b].
  final int x, y, pointStart, pointEnd;

  /// The geometry's bounds, in tile units.
  final int minX, minY, maxX, maxY;

  int _x = 0, _y = 0;

  _Feature._(
    this.b,
    this.start,
    this.end,
    this.field,
    this.geomStart,
    this.geomEnd,
    this.x,
    this.y,
    this.pointStart,
    this.pointEnd,
    this.minX,
    this.minY,
    this.maxX,
    this.maxY,
  );

  /// Reads the feature in [b] from [start] to [end]; null unless its
  /// geometry starts with a MoveTo (decoders drop the rest anyway).
  static _Feature? read(Uint8List b, int start, int end) {
    for (final r = _Reader(b, start, end); !r.atEnd;) {
      final field = r.pos;
      final tag = r.varint();
      if (tag != 34) {
        r.skip(tag & 7);
        continue;
      }
      // field 4: geometry, packed commands and zigzag parameters
      final (s, e) = r.slice();
      final g = _Reader(b, s, e);
      if (g.atEnd || g.varint() & 7 != 1) return null;
      final pointStart = g.pos;
      g.pos = s;
      var x = 0, y = 0, firstX = 0, firstY = 0, pointEnd = 0;
      var minX = 1 << 40, minY = 1 << 40, maxX = -(1 << 40);
      var maxY = -(1 << 40);
      while (!g.atEnd) {
        final command = g.varint();
        if (command & 7 == 7) continue;
        for (var count = command >> 3; count > 0; count--) {
          x += _unzigzag(g.varint());
          y += _unzigzag(g.varint());
          if (pointEnd == 0) {
            firstX = x;
            firstY = y;
            pointEnd = g.pos;
          }
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
      if (pointEnd == 0) return null;
      return _Feature._(
        b,
        start,
        end,
        field,
        s,
        e,
        firstX,
        firstY,
        pointStart,
        pointEnd,
        minX,
        minY,
        maxX,
        maxY,
      );
    }
    return null;
  }

  /// Moves the first point into a frame whose origin is ([x0], [y0]).
  void moveTo(int x0, int y0) {
    _x = _zigzag(x - x0);
    _y = _zigzag(y - y0);
  }

  int get _geomLength =>
      geomEnd -
      geomStart -
      (pointEnd - pointStart) +
      _varintSize(_x) +
      _varintSize(_y);

  int get length =>
      (field - start) +
      1 +
      _varintSize(_geomLength) +
      _geomLength +
      (end - geomEnd);

  void write(_Writer out) => out
    ..varint(18)
    ..varint(length)
    ..bytes(b, start, field)
    ..varint(34)
    ..varint(_geomLength)
    ..bytes(b, geomStart, pointStart)
    ..varint(_x)
    ..varint(_y)
    ..bytes(b, pointEnd, end);
}

int _unzigzag(int n) => (n >> 1) ^ -(n & 1);

int _zigzag(int n) => (n << 1) ^ (n >> 63);

int _varintSize(int v) {
  var size = 1;
  while (v >= 0x80) {
    v >>= 7;
    size++;
  }
  return size;
}

class _Writer {
  Uint8List _buf;
  int _length = 0;

  _Writer(int capacity) : _buf = Uint8List(math.max(capacity, 256));

  void _reserve(int n) {
    if (_length + n <= _buf.length) return;
    var capacity = _buf.length * 2;
    while (capacity < _length + n) {
      capacity *= 2;
    }
    _buf = Uint8List(capacity)..setRange(0, _length, _buf);
  }

  void varint(int v) {
    _reserve(10);
    while (v >= 0x80) {
      _buf[_length++] = (v & 0x7f) | 0x80;
      v >>= 7;
    }
    _buf[_length++] = v;
  }

  void bytes(Uint8List b, int start, int end) {
    _reserve(end - start);
    _buf.setRange(_length, _length + end - start, b, start);
    _length += end - start;
  }

  Uint8List result() => Uint8List.sublistView(_buf, 0, _length);
}

class _Reader {
  final Uint8List b;
  int pos;
  final int end;

  _Reader(this.b, this.pos, this.end);

  bool get atEnd => pos >= end;

  int varint() {
    var result = 0;
    for (var shift = 0; ; shift += 7) {
      final byte = b[pos++];
      result |= (byte & 0x7f) << shift;
      if (byte < 0x80) return result;
    }
  }

  (int, int) slice() {
    final length = varint();
    final start = pos;
    pos += length;
    return (start, pos);
  }

  void skip(int wire) {
    switch (wire) {
      case 0:
        varint();
      case 1:
        pos += 8;
      case 2:
        // Not `pos += varint()`: that reads pos before varint() moves it.
        final length = varint();
        pos += length;
      case 5:
        pos += 4;
      default:
        throw FormatException('Unknown protobuf wire type $wire');
    }
  }
}
