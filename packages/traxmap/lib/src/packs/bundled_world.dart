import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pack.dart';
import 'pack_manager.dart';

/// The world base map bundled with this package (`assets/world/`), copied
/// into [dir] so it reads like any pack (PMTiles needs a file).
///
/// The copy is named after the bundled file's id (`assets/world/world.id`,
/// see [worldIdOf]), so an app update writes a new file rather than
/// replacing one a map may have open, which Windows refuses, and a start
/// that finds its copy doesn't read the bundled map at all. Older copies are
/// removed when they can be.
Future<Pack> openBundledWorld(Directory dir, {AssetBundle? bundle}) async {
  bundle ??= rootBundle;
  final id = utf8.decode(_bytes(await _load(bundle, 'world.id'))).trim();
  final name = 'world@$id.pmtiles';
  final file = File('${dir.path}/$name');
  if (!await file.exists()) {
    await dir.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(
      _bytes(await _load(bundle, 'world.pmtiles')),
      flush: true,
    );
    await tmp.rename(file.path);
  }
  // By name: Windows lists `C:\app/maps` with `\`, so paths don't compare.
  await for (final old in dir.list()) {
    final oldName = old.uri.pathSegments.last;
    if (old is File && oldName.startsWith('world@') && oldName != name) {
      try {
        await old.delete();
      } on FileSystemException {
        // Still open (Windows); it goes on a later start.
      }
    }
  }
  return PackManager.open(file);
}

/// The id `assets/world/world.id` holds for the bundled map [bytes]: a hash
/// of its first 16 kB (header, directories and metadata, where a rebuild
/// changes its build date) and its length. Rewrite that file whenever the
/// map is replaced; bundled_world_test says if it's stale, and with what.
String worldIdOf(Uint8List bytes) {
  final head = bytes.sublist(0, bytes.length < 16384 ? bytes.length : 16384);
  // The length too, for files that share their first 16 kB.
  return sha256
      .convert([...head, ...'${bytes.length}'.codeUnits])
      .toString()
      .substring(0, 12);
}

/// Apps see package assets under `packages/traxmap/`; the package's own
/// tests see them at the bare path.
Future<ByteData> _load(AssetBundle bundle, String name) async {
  for (final path in [
    'packages/traxmap/assets/world/$name',
    'assets/world/$name',
  ]) {
    try {
      return await bundle.load(path);
    } on FlutterError {
      continue;
    }
  }
  throw StateError('$name is not bundled');
}

Uint8List _bytes(ByteData data) =>
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
