import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Valhalla tile paths, the only names a routing bundle may hold.
final tilePath = RegExp(r'^[0-2]/\d{3}/\d{3}(/\d{3})?\.gph$');

/// Copies the tiles of the tar streamed from [source] that [take] wants
/// into [out] as tar entries, streaming. The end-of-archive blocks are
/// left to the caller, who may copy from several sources into one tar.
///
/// An entry that isn't a plain file with a tile path is refused, so a
/// bundle can only ever add routing tiles.
Future<void> copyTiles(
  Stream<List<int>> source,
  IOSink out,
  bool Function(String name, int size) take,
) async {
  final header = BytesBuilder(copy: false);
  var remaining = 0, padding = 0;
  var copying = false, done = false;
  await for (final chunk in source) {
    var data = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
    while (data.isNotEmpty && !done) {
      if (remaining > 0) {
        final n = math.min(remaining, data.length);
        if (copying) out.add(data.sublist(0, n));
        remaining -= n;
        data = data.sublist(n);
        if (remaining == 0 && copying && padding > 0) {
          out.add(Uint8List(padding));
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
      final prefix = _text(h, 345, 155);
      final name = prefix.isEmpty
          ? _text(h, 0, 100)
          : '$prefix/${_text(h, 0, 100)}';
      final size = int.parse(_text(h, 124, 12).trim(), radix: 8);
      final type = h[156];
      if ((type != 0x30 && type != 0) || !tilePath.hasMatch(name)) {
        throw FormatException('Not a routing tile: $name');
      }
      copying = take(name, size);
      if (copying) out.add(_header(name, size));
      remaining = size;
      padding = (512 - size % 512) % 512;
      if (size == 0 && copying && padding > 0) out.add(Uint8List(padding));
    }
    if (done) break;
  }
}

/// The two empty blocks that end a tar.
final tarEnd = Uint8List(1024);

/// Writes a plain tar of [names] (paths under [root]), streaming.
Future<void> writeTar(File out, Directory root, Iterable<String> names) async {
  final sink = out.openWrite();
  for (final name in names) {
    final file = File('${root.path}/$name');
    final size = file.lengthSync();
    sink.add(_header(name, size));
    await sink.addStream(file.openRead());
    final pad = (512 - size % 512) % 512;
    if (pad > 0) sink.add(Uint8List(pad));
  }
  sink.add(tarEnd);
  await sink.close();
}

String _text(Uint8List b, int start, int length) {
  final end = b.indexOf(0, start);
  return ascii.decode(
    b.sublist(start, end < 0 || end > start + length ? start + length : end),
  );
}

Uint8List _header(String name, int size) {
  final h = Uint8List(512);
  void put(int at, String s) => h.setAll(at, ascii.encode(s));
  String octal(int v, int width) =>
      '${v.toRadixString(8).padLeft(width - 1, '0')}\u0000';
  put(0, name);
  put(100, octal(420, 8));
  put(108, octal(0, 8));
  put(116, octal(0, 8));
  put(124, octal(size, 12));
  put(136, octal(0, 12));
  put(148, '        ');
  h[156] = 0x30;
  put(257, 'ustar\u0000');
  put(263, '00');
  final sum = h.fold<int>(0, (a, b) => a + b);
  put(148, '${sum.toRadixString(8).padLeft(6, '0')}\u0000 ');
  return h;
}
