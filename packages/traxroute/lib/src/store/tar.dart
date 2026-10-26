import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Valhalla tile paths, the only names a routing bundle may hold.
final tilePath = RegExp(r'^[0-2]/\d{3}/\d{3}(/\d{3})?\.gph$');

/// Unpacks the `.gph` tiles of a gzipped tar into [into], streaming, and
/// returns their paths. Anything that isn't a plain file with a tile path
/// is refused, so a bundle can't write outside [into].
Future<List<String>> extractTiles(File archive, Directory into) async {
  final names = <String>[];
  final pending = BytesBuilder(copy: false);
  IOSink? sink;
  var remaining = 0, padding = 0;
  var done = false;

  Future<void> consume(Uint8List chunk) async {
    var data = chunk;
    while (data.isNotEmpty && !done) {
      if (remaining > 0) {
        final n = remaining < data.length ? remaining : data.length;
        final out = sink!..add(data.sublist(0, n));
        remaining -= n;
        data = data.sublist(n);
        if (remaining == 0) {
          await out.close();
          sink = null;
        }
        continue;
      }
      if (padding > 0) {
        final n = padding < data.length ? padding : data.length;
        padding -= n;
        data = data.sublist(n);
        continue;
      }
      final need = 512 - pending.length;
      final take = need < data.length ? need : data.length;
      pending.add(data.sublist(0, take));
      data = data.sublist(take);
      if (pending.length < 512) continue;
      final header = pending.takeBytes();
      if (header.every((b) => b == 0)) {
        done = true;
        break;
      }
      final name = _text(header, 345, 155).isEmpty
          ? _text(header, 0, 100)
          : '${_text(header, 345, 155)}/${_text(header, 0, 100)}';
      final size = int.parse(_text(header, 124, 12).trim(), radix: 8);
      final type = header[156];
      if ((type != 0x30 && type != 0) || !tilePath.hasMatch(name)) {
        throw FormatException('Not a routing tile: $name');
      }
      final file = File('${into.path}/$name')
        ..parent.createSync(recursive: true);
      names.add(name);
      sink = file.openWrite();
      remaining = size;
      padding = (512 - size % 512) % 512;
      if (size == 0) {
        await sink!.close();
        sink = null;
      }
    }
  }

  await for (final chunk in archive.openRead().transform(gzip.decoder)) {
    await consume(chunk is Uint8List ? chunk : Uint8List.fromList(chunk));
    if (done) break;
  }
  await sink?.close();
  return names;
}

/// Writes a plain tar of [names] (paths under [root]), streaming: the
/// combined tile file Valhalla opens.
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
  sink.add(Uint8List(1024));
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
