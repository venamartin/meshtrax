import 'dart:typed_data';

/// A feature for [encodeMvt]: absolute points in tile units, drawn as one
/// MoveTo and LineTos (closed for polygons).
typedef TestFeature = ({int id, int type, List<(int, int)> points});

/// Encodes a minimal vector tile: one layer per entry of [layers], each with
/// a key/value pair on every feature. [extent] null leaves the field out
/// (MVT's default, 4096).
Uint8List encodeMvt(Map<String, List<TestFeature>> layers, {int? extent}) {
  final tile = <int>[];
  for (final MapEntry(key: name, value: features) in layers.entries) {
    final layer = <int>[..._string(1, name)];
    for (final f in features) {
      final geometry = <int>[_command(1, 1)];
      var (cx, cy) = (0, 0);
      for (final (i, (x, y)) in f.points.indexed) {
        if (i == 1) geometry.add(_command(2, f.points.length - 1));
        geometry
          ..add(_zigzag(x - cx))
          ..add(_zigzag(y - cy));
        (cx, cy) = (x, y);
      }
      if (f.type == 3) geometry.add(_command(7, 1));
      final feature = <int>[
        ..._tag(1, 0),
        ..._varint(f.id),
        ..._bytes(2, [
          for (final v in [0, 0]) ..._varint(v),
        ]),
        ..._tag(3, 0),
        ..._varint(f.type),
        ..._bytes(4, [for (final v in geometry) ..._varint(v)]),
      ];
      layer.addAll(_bytes(2, feature));
    }
    layer
      ..addAll(_string(3, 'class'))
      ..addAll(_bytes(4, _string(1, 'town')));
    if (extent != null) layer.addAll([..._tag(5, 0), ..._varint(extent)]);
    layer.addAll([..._tag(15, 0), ..._varint(2)]);
    tile.addAll(_bytes(3, layer));
  }
  return Uint8List.fromList(tile);
}

/// A decoded layer: its extent and each feature's id, tags and absolute
/// points (MoveTo and LineTo vertices, in order).
typedef DecodedLayer = ({
  int extent,
  List<String> keys,
  List<({int id, List<int> tags, List<(int, int)> points})> features,
});

Map<String, DecodedLayer> decodeMvt(Uint8List bytes) {
  final layers = <String, DecodedLayer>{};
  for (final (field, layer) in _fields(bytes)) {
    if (field != 3) continue;
    var name = '';
    var extent = 4096;
    final keys = <String>[];
    final features = <({int id, List<int> tags, List<(int, int)> points})>[];
    for (final (f, v) in _fields(layer as Uint8List)) {
      switch (f) {
        case 1:
          name = String.fromCharCodes(v as Uint8List);
        case 3:
          keys.add(String.fromCharCodes(v as Uint8List));
        case 5:
          extent = v as int;
        case 2:
          var id = 0;
          var tags = <int>[];
          final points = <(int, int)>[];
          for (final (g, w) in _fields(v as Uint8List)) {
            if (g == 1) id = w as int;
            if (g == 2) tags = _packed(w as Uint8List);
            if (g != 4) continue;
            final ints = _packed(w as Uint8List);
            var (x, y) = (0, 0);
            for (var i = 0; i < ints.length;) {
              final id = ints[i] & 7;
              final count = ints[i++] >> 3;
              if (id == 7) continue;
              for (var c = 0; c < count; c++) {
                x += _unzigzag(ints[i++]);
                y += _unzigzag(ints[i++]);
                points.add((x, y));
              }
            }
          }
          features.add((id: id, tags: tags, points: points));
      }
    }
    layers[name] = (extent: extent, keys: keys, features: features);
  }
  return layers;
}

int _command(int id, int count) => (count << 3) | id;
int _zigzag(int n) => (n << 1) ^ (n >> 63);
int _unzigzag(int n) => (n >> 1) ^ -(n & 1);
List<int> _tag(int field, int wire) => _varint((field << 3) | wire);
List<int> _bytes(int field, List<int> body) => [
  ..._tag(field, 2),
  ..._varint(body.length),
  ...body,
];
List<int> _string(int field, String s) => _bytes(field, s.codeUnits);

List<int> _varint(int v) {
  final out = <int>[];
  while (v >= 0x80) {
    out.add((v & 0x7f) | 0x80);
    v >>= 7;
  }
  return out..add(v);
}

List<int> _packed(Uint8List b) {
  final out = <int>[];
  for (var i = 0; i < b.length;) {
    var v = 0;
    for (var shift = 0; ; shift += 7) {
      final byte = b[i++];
      v |= (byte & 0x7f) << shift;
      if (byte < 0x80) break;
    }
    out.add(v);
  }
  return out;
}

/// Each field of a message: varints as int, length-delimited as bytes.
Iterable<(int, Object)> _fields(Uint8List b) sync* {
  var i = 0;
  int varint() {
    var v = 0;
    for (var shift = 0; ; shift += 7) {
      final byte = b[i++];
      v |= (byte & 0x7f) << shift;
      if (byte < 0x80) return v;
    }
  }

  while (i < b.length) {
    final tag = varint();
    if (tag & 7 == 0) {
      yield (tag >> 3, varint());
    } else {
      final length = varint();
      yield (tag >> 3, Uint8List.sublistView(b, i, i + length));
      i += length;
    }
  }
}
