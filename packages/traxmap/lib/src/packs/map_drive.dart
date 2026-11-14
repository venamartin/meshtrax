import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A folder of map files outside the app, such as `MeshTrax-maps` on a USB
/// drive: the map server's `index.json`, `picker.geojson` and
/// `chart_areas.geojson`, and its files at their URL paths
/// (`v1/north-america/us/rhode-island/osm.pmtiles`). A drive may hold only
/// some of the files its `index.json` lists.
abstract interface class MapDrive {
  /// What the user calls it: the drive's or the folder's name.
  String get name;

  /// Every file under the folder, by its path there with `/` separators,
  /// and its size in bytes.
  Future<Map<String, int>> list();

  /// The text of the file at [path], read as UTF-8.
  Future<String> readText(String path);

  /// Copies the file at [path] to [to], from byte [from] on: 0 starts
  /// afresh, more appends to what [to] already holds. Throws
  /// [DriveCopyStopped] once [stop] completes.
  Future<void> copy(String path, File to, {int from = 0, Future<void>? stop});

  /// Whether the folder can still be read: false once the drive is gone.
  Future<bool> isReadable();

  /// The same drive, read from its subfolder [name] (e.g. `MeshTrax-maps`
  /// when the drive's own top folder was chosen).
  MapDrive inFolder(String name);

  /// Lets go of the folder.
  Future<void> close();
}

/// [MapDrive.copy] stopped before the end.
class DriveCopyStopped implements Exception {
  const DriveCopyStopped();

  @override
  String toString() => 'Copy stopped';
}

/// A [MapDrive] read with `dart:io`: on desktops, and on an iPhone once its
/// folder picker has granted the folder.
class IoMapDrive implements MapDrive {
  final Directory root;

  @override
  final String name;

  /// Runs on [close], e.g. to end an iPhone's access to the folder.
  final Future<void> Function()? onClose;

  IoMapDrive(this.root, {String? name, this.onClose})
    : name = name ?? p.basename(root.path);

  @override
  Future<Map<String, int>> list() async {
    final files = <String, int>{};
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) continue;
      final path = p.relative(entity.path, from: root.path);
      files[p.split(path).join('/')] = await entity.length();
    }
    return files;
  }

  @override
  Future<String> readText(String path) => _file(path).readAsString();

  @override
  Future<void> copy(
    String path,
    File to, {
    int from = 0,
    Future<void>? stop,
  }) async {
    var stopped = false;
    unawaited(stop?.then((_) => stopped = true));
    final sink = to.openWrite(
      mode: from == 0 ? FileMode.writeOnly : FileMode.writeOnlyAppend,
    );
    try {
      await for (final chunk in _file(path).openRead(from)) {
        if (stopped) throw const DriveCopyStopped();
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
  }

  @override
  Future<bool> isReadable() async {
    try {
      return await _file('index.json').exists();
    } on FileSystemException {
      return false;
    }
  }

  @override
  MapDrive inFolder(String name) => IoMapDrive(
    Directory(p.join(root.path, name)),
    name: this.name,
    onClose: onClose,
  );

  @override
  Future<void> close() async => onClose?.call();

  File _file(String path) => File(p.joinAll([root.path, ...path.split('/')]));
}
