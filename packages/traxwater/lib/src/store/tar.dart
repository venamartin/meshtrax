import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../wrm.dart';

final _tileName = RegExp(r'^(\d{1,3})_(\d{1,4})\.wrm$');

/// Unpacks the tiles of the tar streamed from [source] into [dir], which
/// should be empty, and returns each tile's name and size.
///
/// Every entry must be a regular file named `<iy>_<ix>.wrm` holding tile
/// (ix, iy) of [build] (FINDINGS 1.11). Anything else throws a
/// [FormatException], and the caller drops the whole bundle.
Future<Map<String, int>> unpackTiles(
  Stream<List<int>> source,
  Directory dir, {
  required String build,
}) async {
  final sizes = <String, int>{};
  final header = BytesBuilder(copy: false);
  final body = BytesBuilder(copy: false);
  String? name;
  var remaining = 0, padding = 0;
  var done = false;
  await for (final chunk in source) {
    var data = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
    while (data.isNotEmpty && !done) {
      if (remaining > 0) {
        final n = math.min(remaining, data.length);
        body.add(data.sublist(0, n));
        remaining -= n;
        data = data.sublist(n);
        if (remaining == 0) {
          sizes[name!] = _write(dir, name, body.takeBytes(), build);
        }
        continue;
      }
      if (padding > 0) {
        final n = math.min(padding, data.length);
        padding -= n;
        data = data.sublist(n);
        continue;
      }
      final n = math.min(512 - header.length, data.length);
      header.add(data.sublist(0, n));
      data = data.sublist(n);
      if (header.length < 512) continue;
      final h = header.takeBytes();
      if (h.every((b) => b == 0)) {
        done = true;
        break;
      }
      name = _text(h, 0, 100);
      final type = h[156];
      if ((type != 0x30 && type != 0) ||
          _text(h, 345, 155).isNotEmpty ||
          !_tileName.hasMatch(name)) {
        throw FormatException('Not a water-routing tile: $name');
      }
      remaining = int.parse(_text(h, 124, 12).trim(), radix: 8);
      padding = (512 - remaining % 512) % 512;
      if (remaining == 0) throw FormatException('Empty tile: $name');
    }
    if (done) break;
  }
  if (!done) throw const FormatException('Water-routing bundle cut short');
  return sizes;
}

/// Checks that [bytes] is the tile [name] says, of [build], and writes it.
int _write(Directory dir, String name, Uint8List bytes, String build) {
  final m = _tileName.firstMatch(name)!;
  final iy = int.parse(m[1]!), ix = int.parse(m[2]!);
  if (iy >= tileRows || ix >= tileColumns) {
    throw FormatException('No such tile: $name');
  }
  final b = ByteData.sublistView(bytes);
  if (bytes.length < 42 ||
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'WRM2' ||
      b.getInt32(6, Endian.little) != ix ||
      b.getInt32(10, Endian.little) != iy) {
    throw FormatException('Not the tile it is named: $name');
  }
  final id = ascii.decode(
    bytes.sublist(26, 42).takeWhile((c) => c != 0).toList(),
    allowInvalid: true,
  );
  if (id != build) throw FormatException('$name is of build $id, not $build');
  File('${dir.path}/$name').writeAsBytesSync(bytes);
  return bytes.length;
}

String _text(Uint8List b, int start, int length) {
  final end = b.indexOf(0, start);
  return ascii.decode(
    b.sublist(start, end < 0 || end > start + length ? start + length : end),
    allowInvalid: true,
  );
}
