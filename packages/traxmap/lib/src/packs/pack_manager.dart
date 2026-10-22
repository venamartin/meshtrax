import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'geo.dart';
import 'pack.dart';
import 'pack_download.dart' show PackDownloader;
import 'pmtiles_header.dart';

/// Thrown when a pack cannot be installed or read.
class PackException implements Exception {
  final String message;
  const PackException(this.message);
  @override
  String toString() => 'PackException: $message';
}

/// Manages PMTiles packs stored in a single directory on the device.
///
/// The app only ever reads local files here. Downloads from the pack server
/// (a [PackDownloader]) land through [install] once the file is on disk.
///
/// A pack installed with a checksum is stored as `<id>@<sha12>.pmtiles`, so
/// each build has its own file name. An update is written next to the old
/// build, which is then deleted. This gives the map a new path to reload
/// from, and works on Windows, where an open file can't be replaced. If the
/// old build is still in use, [listInstalled] removes it later.
///
/// Deleting works the same way: on Windows a pack open in a map can't be
/// deleted, so it's marked deleted (`<file>.deleted`) and no longer listed.
/// The map then reloads without it and lets go of the file, which is
/// deleted on a retry.
class PackManager {
  static const String extension = '.pmtiles';
  static const String _partial = '.part';
  static const String _deleted = '.deleted';
  static const String _buildSeparator = '@';
  static const int _shaPrefixLength = 12;
  static const int _retries = 5;

  final Directory root;

  /// How long after a file couldn't be deleted (still open on Windows) to
  /// try again. Each further try waits twice as long, up to [_retries]
  /// tries; [listInstalled] always tries too.
  final Duration retryDelay;

  final _changes = StreamController<void>.broadcast();
  Timer? _retry;
  var _tries = 0;
  var _failures = 0;

  /// Deletes a file; tests replace it to act like Windows, where a file
  /// that's open can't be deleted.
  @visibleForTesting
  Future<void> Function(File file) deleteFile = (file) => file.delete();

  PackManager(this.root, {this.retryDelay = const Duration(seconds: 2)});

  /// Fires after a pack is installed or deleted, so apps can refresh lists.
  Stream<void> get changes => _changes.stream;

  /// Closes [changes]; call when the manager is no longer used.
  Future<void> close() {
    _retry?.cancel();
    return _changes.close();
  }

  /// Every readable pack in [root], one per id. Files that fail to parse are
  /// skipped and reported through [onError] if given. Where an update left
  /// two builds of one pack, the newer file is listed and the older one
  /// deleted.
  Future<List<Pack>> listInstalled({
    void Function(File file, Object error)? onError,
  }) async {
    if (!await root.exists()) return const [];
    final files = [
      await for (final entity in root.list())
        if (entity is File) entity,
    ];
    final failuresBefore = _failures;
    final marked = <String>{};
    for (final marker in files.where((f) => f.path.endsWith(_deleted))) {
      final path = marker.path.substring(
        0,
        marker.path.length - _deleted.length,
      );
      marked.add(path);
      if (await _deleteQuietly(File(path))) await _deleteQuietly(marker);
    }
    final byId = <String, Pack>{};
    for (final entity in files) {
      if (p.extension(entity.path) != extension ||
          marked.contains(entity.path)) {
        continue;
      }
      final Pack pack;
      try {
        pack = await open(entity);
      } catch (e) {
        onError?.call(entity, e);
        continue;
      }
      final other = byId[pack.id];
      if (other == null) {
        byId[pack.id] = pack;
        continue;
      }
      final newer =
          (await pack.file.lastModified()).isAfter(
            await other.file.lastModified(),
          )
          ? pack
          : other;
      byId[pack.id] = newer;
      await _deleteQuietly(identical(newer, pack) ? other.file : pack.file);
    }
    if (_failures == failuresBefore) _tries = 0;
    return byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Reads the header and metadata of a PMTiles file without installing it.
  static Future<Pack> open(File file) async {
    final header = await PmTilesHeader.read(file);
    final metadata = await header.readMetadata(file) ?? const {};
    final name = p.basenameWithoutExtension(file.path);
    final at = name.lastIndexOf(_buildSeparator);
    return Pack(
      id: at < 0 ? name : name.substring(0, at),
      file: file,
      header: header,
      metadata: metadata,
      sha256Prefix: at < 0 ? null : name.substring(at + 1),
    );
  }

  /// Copies [source] into [root], replacing any pack with the same id. The
  /// copy goes to a temporary file and is renamed only after the header
  /// parses and, if [sha256] is given, the checksum matches.
  ///
  /// With a [sha256] the file is named `<id>@<sha12>.pmtiles`, otherwise
  /// `<id>.pmtiles`. Other builds of the same id are deleted afterwards,
  /// where the platform allows (see the class docs).
  ///
  /// With [move], [source] is renamed instead of copied (falling back to a
  /// copy across file systems), so a large download in [root] needs no
  /// second copy's worth of space. A rejected file is deleted either way.
  Future<Pack> install(
    File source, {
    String? id,
    String? sha256,
    bool move = false,
  }) async {
    id ??= p.basenameWithoutExtension(source.path);
    if (id.isEmpty || id.contains(RegExp(r'[/\\@]'))) {
      throw PackException('Invalid pack id "$id"');
    }
    await root.create(recursive: true);
    final sha = sha256?.toLowerCase();
    final build = sha == null
        ? ''
        : '$_buildSeparator${sha.length > _shaPrefixLength ? sha.substring(0, _shaPrefixLength) : sha}';
    final target = File(p.join(root.path, '$id$build$extension'));
    final temp = File('${target.path}$_partial');
    try {
      if (move) {
        try {
          await source.rename(temp.path);
        } on FileSystemException {
          await source.copy(temp.path);
          await source.delete();
        }
      } else {
        await source.copy(temp.path);
      }
      await PmTilesHeader.read(temp);
      if (sha256 != null && !await _matches(temp, sha256)) {
        throw PackException('Checksum mismatch for "$id"');
      }
      await temp.rename(target.path);
      await _deleteQuietly(File('${target.path}$_deleted'));
    } catch (e) {
      if (await temp.exists()) await temp.delete();
      if (e is PackException) rethrow;
      throw PackException('Could not install "$id": $e');
    }
    final pack = await open(target);
    await for (final entity in root.list()) {
      if (entity is! File ||
          entity.path == target.path ||
          p.extension(entity.path) != extension) {
        continue;
      }
      final name = p.basenameWithoutExtension(entity.path);
      if (name == id || name.startsWith('$id$_buildSeparator')) {
        await _deleteQuietly(entity);
      }
    }
    if (!_changes.isClosed) _changes.add(null);
    return pack;
  }

  /// True if the pack's SHA-256 matches [expectedSha256] (hex, any case).
  Future<bool> verify(Pack pack, String expectedSha256) =>
      _matches(pack.file, expectedSha256);

  /// Deletes [pack]. If a map still has it open (Windows), it's marked
  /// deleted instead and removed once the map lets go (see the class docs).
  Future<void> delete(Pack pack) async {
    if (!await _deleteQuietly(pack.file)) {
      await File('${pack.file.path}$_deleted').create();
    }
    if (!_changes.isClosed) _changes.add(null);
  }

  LatLngBounds coverage(Pack pack) => pack.bounds;

  Future<int> sizeOf(Pack pack) => pack.file.length();

  /// The pack that should serve [viewport] among [packs], optionally limited to
  /// one [kind]. Prefers the pack covering most of the viewport, then the
  /// newest build. Returns null if none intersect.
  static Pack? bestFor(
    LatLngBounds viewport,
    Iterable<Pack> packs, {
    PackKind? kind,
  }) {
    Pack? best;
    var bestCoverage = 0.0;
    for (final pack in packs) {
      if (kind != null && pack.kind != kind) continue;
      final c = pack.bounds.coverageOf(viewport);
      if (c <= 0) continue;
      if (best == null ||
          c > bestCoverage ||
          (c == bestCoverage && _buildDate(pack).isAfter(_buildDate(best)))) {
        best = pack;
        bestCoverage = c;
      }
    }
    return best;
  }

  static DateTime _buildDate(Pack pack) =>
      pack.buildDate ?? pack.file.statSync().modified;

  /// Hashes on a background isolate: a multi-GB pack takes many seconds.
  static Future<bool> _matches(File file, String expected) async {
    final path = file.path;
    final digest = await Isolate.run(
      () async => (await sha256.bind(File(path).openRead()).first).toString(),
    );
    return digest == expected.toLowerCase();
  }

  /// Deletes [file] if it can, and says whether it's gone. A file still
  /// open elsewhere (Windows) is tried again later by [listInstalled].
  Future<bool> _deleteQuietly(File file) async {
    try {
      await deleteFile(file);
      return true;
    } on PathNotFoundException {
      return true;
    } on FileSystemException {
      _failures++;
      _retryLater();
      return false;
    }
  }

  void _retryLater() {
    if ((_retry?.isActive ?? false) || _tries >= _retries) return;
    _retry = Timer(retryDelay * (1 << _tries++), () {
      if (!_changes.isClosed) listInstalled();
    });
  }
}
