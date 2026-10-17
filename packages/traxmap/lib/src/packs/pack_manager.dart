import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
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
class PackManager {
  static const String extension = '.pmtiles';
  static const String _partial = '.part';

  final Directory root;
  final _changes = StreamController<void>.broadcast();

  PackManager(this.root);

  /// Fires after a pack is installed or deleted, so apps can refresh lists.
  Stream<void> get changes => _changes.stream;

  /// Closes [changes]; call when the manager is no longer used.
  Future<void> close() => _changes.close();

  /// Every readable pack in [root]. Files that fail to parse are skipped and
  /// reported through [onError] if given.
  Future<List<Pack>> listInstalled({
    void Function(File file, Object error)? onError,
  }) async {
    if (!await root.exists()) return const [];
    final packs = <Pack>[];
    await for (final entity in root.list()) {
      if (entity is! File || p.extension(entity.path) != extension) continue;
      try {
        packs.add(await open(entity));
      } catch (e) {
        onError?.call(entity, e);
      }
    }
    packs.sort((a, b) => a.id.compareTo(b.id));
    return packs;
  }

  /// Reads the header and metadata of a PMTiles file without installing it.
  static Future<Pack> open(File file) async {
    final header = await PmTilesHeader.read(file);
    final metadata = await header.readMetadata(file) ?? const {};
    return Pack(
      id: p.basenameWithoutExtension(file.path),
      file: file,
      header: header,
      metadata: metadata,
    );
  }

  /// Copies [source] into [root] as `<id>.pmtiles`, replacing any pack with the
  /// same id. The copy goes to a temporary file and is renamed only after the
  /// header parses and, if [sha256] is given, the checksum matches.
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
    if (id.isEmpty || id.contains(RegExp(r'[/\\]'))) {
      throw PackException('Invalid pack id "$id"');
    }
    await root.create(recursive: true);
    final target = File(p.join(root.path, '$id$extension'));
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
    } catch (e) {
      if (await temp.exists()) await temp.delete();
      if (e is PackException) rethrow;
      throw PackException('Could not install "$id": $e');
    }
    final pack = await open(target);
    if (!_changes.isClosed) _changes.add(null);
    return pack;
  }

  /// True if the pack's SHA-256 matches [expectedSha256] (hex, any case).
  Future<bool> verify(Pack pack, String expectedSha256) =>
      _matches(pack.file, expectedSha256);

  Future<void> delete(Pack pack) async {
    if (await pack.file.exists()) await pack.file.delete();
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
      DateTime.tryParse(pack.metadata['build_date'] as String? ?? '') ??
      pack.file.statSync().modified;

  static Future<bool> _matches(File file, String expected) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == expected.toLowerCase();
  }
}
