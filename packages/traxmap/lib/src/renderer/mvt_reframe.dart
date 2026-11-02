import 'dart:typed_data';

/// Re-expresses plain (not gzipped) vector tile bytes as the tile [dz]
/// levels below them at offset ([dx], [dy]), so a source can serve zooms
/// deeper than its data.
///
/// Nothing is clipped or scaled: each layer's extent shrinks by 2^[dz] and
/// each feature's first point moves by the child's offset (MVT geometry is
/// relative after that), so coordinates stay exact and the renderer drops
/// what falls outside the tile.
Uint8List reframeMvt(Uint8List tile, int dz, int dx, int dy) {
  final out = BytesBuilder(copy: false);
  final r = _Reader(tile, 0, tile.length);
  while (!r.atEnd) {
    final start = r.pos;
    final tag = r.varint();
    if (tag == 26) {
      // field 3: layer
      final (s, e) = r.slice();
      _message(out, 26, _layer(tile, s, e, dz, dx, dy));
    } else {
      r.skip(tag & 7);
      out.add(Uint8List.sublistView(tile, start, r.pos));
    }
  }
  return out.takeBytes();
}

Uint8List _layer(Uint8List b, int start, int end, int dz, int dx, int dy) {
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
  final out = BytesBuilder(copy: false);
  for (final r = _Reader(b, start, end); !r.atEnd;) {
    final fieldStart = r.pos;
    final tag = r.varint();
    if (tag == 40) {
      r.varint();
    } else if (tag == 18) {
      // field 2: feature
      final (s, e) = r.slice();
      _message(out, 18, _feature(b, s, e, -dx * size, -dy * size));
    } else {
      r.skip(tag & 7);
      out.add(Uint8List.sublistView(b, fieldStart, r.pos));
    }
  }
  _varint(out, 40);
  _varint(out, size);
  return out.takeBytes();
}

Uint8List _feature(Uint8List b, int start, int end, int shiftX, int shiftY) {
  final out = BytesBuilder(copy: false);
  for (final r = _Reader(b, start, end); !r.atEnd;) {
    final fieldStart = r.pos;
    final tag = r.varint();
    if (tag == 34) {
      // field 4: geometry, packed commands and zigzag parameters
      final (s, e) = r.slice();
      final geometry = <int>[];
      for (final g = _Reader(b, s, e); !g.atEnd;) {
        geometry.add(g.varint());
      }
      if (geometry.length >= 3 &&
          geometry[0] & 7 == 1 &&
          geometry[0] >> 3 > 0) {
        geometry[1] = _zigzag(_unzigzag(geometry[1]) + shiftX);
        geometry[2] = _zigzag(_unzigzag(geometry[2]) + shiftY);
      }
      final packed = BytesBuilder(copy: false);
      for (final v in geometry) {
        _varint(packed, v);
      }
      _message(out, 34, packed.takeBytes());
    } else {
      r.skip(tag & 7);
      out.add(Uint8List.sublistView(b, fieldStart, r.pos));
    }
  }
  return out.takeBytes();
}

int _unzigzag(int n) => (n >> 1) ^ -(n & 1);

int _zigzag(int n) => (n << 1) ^ (n >> 63);

void _message(BytesBuilder out, int tag, Uint8List body) {
  _varint(out, tag);
  _varint(out, body.length);
  out.add(body);
}

void _varint(BytesBuilder out, int v) {
  while (v >= 0x80) {
    out.addByte((v & 0x7f) | 0x80);
    v >>= 7;
  }
  out.addByte(v);
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
