import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pack.dart';
import 'pack_manager.dart';

/// The world base map bundled with this package (`assets/world/`), copied
/// into [dir] so it reads like any pack (PMTiles needs a file).
///
/// The copy is named after the bundled file's header, directories and
/// metadata (the first 16 kB, where a rebuild changes its build date), so an
/// app update writes a new file rather than replacing one a map may have
/// open, which Windows refuses. Older copies are removed when they can be.
Future<Pack> openBundledWorld(Directory dir, {AssetBundle? bundle}) async {
  final bytes = await _load(bundle ?? rootBundle);
  final head = bytes.sublist(0, bytes.length < 16384 ? bytes.length : 16384);
  // The length too, for files that share their first 16 kB.
  final id = sha256
      .convert([...head, ...'${bytes.length}'.codeUnits])
      .toString()
      .substring(0, 12);
  final file = File('${dir.path}/world@$id.pmtiles');
  if (!await file.exists()) {
    await dir.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(file.path);
  }
  await for (final old in dir.list()) {
    final name = old.uri.pathSegments.last;
    if (old is File && name.startsWith('world@') && old.path != file.path) {
      try {
        await old.delete();
      } on FileSystemException {
        // Still open (Windows); it goes on a later start.
      }
    }
  }
  return PackManager.open(file);
}

/// Apps see package assets under `packages/traxmap/`; the package's own
/// tests see them at the bare path.
Future<Uint8List> _load(AssetBundle bundle) async {
  for (final path in [
    'packages/traxmap/assets/world/world.pmtiles',
    'assets/world/world.pmtiles',
  ]) {
    try {
      final data = await bundle.load(path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on FlutterError {
      continue;
    }
  }
  throw StateError('world.pmtiles is not bundled');
}
