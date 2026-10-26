import 'dart:convert';
import 'dart:io';

import 'catalog.dart';
import 'tar.dart';

/// A region's installed routing bundle.
class InstalledRouting {
  final String sha256;
  final List<String> tiles;

  const InstalledRouting(this.sha256, this.tiles);
}

/// The routing data on the device: one build at a time (tiles from two
/// builds break routing), as the one plain tar the engine opens, holding
/// each tile once even when several regions share it.
///
/// Layout under [root]: `<build>/tiles.tar`, and `manifest.json` naming the
/// build, which region uses which tile, and each tile's size. There are no
/// loose tiles: installing or removing a region rewrites the tar from the
/// old one and the new bundles, so the data takes its unpacked size once.
class RoutingStore {
  final Directory root;

  RoutingStore(this.root);

  File get _manifest => File('${root.path}/manifest.json');

  /// The build on the device, or null before the first install.
  String? get build => _read()?.build;

  Map<String, InstalledRouting> get regions => _read()?.regions ?? const {};

  File _tar(String build) => File('${root.path}/$build/tiles.tar');

  /// The combined tile file to open, or null when nothing is installed.
  File? get tileFile {
    final b = build;
    if (b == null || regions.isEmpty) return null;
    final f = _tar(b);
    return f.existsSync() ? f : null;
  }

  /// What [region]'s tiles take (shared tiles count for each region).
  int sizeOf(String region) {
    final m = _read();
    if (m == null) return 0;
    return (m.regions[region]?.tiles ?? const <String>[]).fold(
      0,
      (sum, t) => sum + (m.sizes[t] ?? 0),
    );
  }

  /// The regions to download for [wanted] new ones. When the catalogue has
  /// a newer build than the device, every installed region comes too, so
  /// all tiles stay from one build.
  Set<String> downloadsFor(RoutingCatalog catalog, Set<String> wanted) {
    final installed = regions;
    return {
      ...wanted.where(catalog.regions.containsKey),
      if (catalog.build != build) ...installed.keys,
      for (final MapEntry(:key, :value) in installed.entries)
        if (catalog.build == build &&
            catalog.regions[key] != null &&
            catalog.regions[key]!.sha256 != value.sha256)
          key,
    }.where(catalog.regions.containsKey).toSet();
  }

  /// Installs downloaded [bundles] (region → `.tar.gz` file and sha256) of
  /// [build]. A new build replaces the old one in one step: pass every
  /// region the device should keep, as [downloadsFor] lists them.
  Future<void> install(
    String build,
    Map<String, (File, String)> bundles,
  ) async {
    final old = _read();
    final sameBuild = old != null && old.build == build;
    final kept = <String, InstalledRouting>{
      if (sameBuild)
        for (final MapEntry(:key, :value) in old.regions.entries)
          if (!bundles.containsKey(key)) key: value,
    };
    final added = <String, InstalledRouting>{};
    final sizes = await _rewrite(build, from: sameBuild ? old : null, (
      out,
      written,
      sizes,
    ) async {
      for (final MapEntry(key: region, value: (file, sha)) in bundles.entries) {
        final names = <String>[];
        await copyTiles(file.openRead().transform(gzip.decoder), out, (
          name,
          size,
        ) {
          names.add(name);
          sizes[name] = size;
          return written.add(name);
        });
        added[region] = InstalledRouting(sha, names);
      }
    }, keep: {for (final r in kept.values) ...r.tiles});
    _write(build, {...kept, ...added}, sizes);
    if (!sameBuild) _deleteOtherBuilds(build);
  }

  /// Removes [region]; tiles other installed regions use stay.
  Future<void> remove(String region) async {
    final old = _read();
    if (old == null || !old.regions.containsKey(region)) return;
    final kept = Map.of(old.regions)..remove(region);
    if (kept.isEmpty) {
      final tar = _tar(old.build);
      if (tar.existsSync()) tar.deleteSync();
      _write(old.build, const {}, const {});
      return;
    }
    final sizes = await _rewrite(
      old.build,
      from: old,
      (out, written, sizes) async {},
      keep: {for (final r in kept.values) ...r.tiles},
    );
    _write(old.build, kept, sizes);
  }

  /// Writes `<build>/tiles.tar` anew: whatever [add] copies first, then the
  /// [keep] tiles from the current tar ([from]), each tile once. The old
  /// tar stays until the new one is complete.
  Future<Map<String, int>> _rewrite(
    String build,
    Future<void> Function(IOSink, Set<String>, Map<String, int>) add, {
    required _Manifest? from,
    required Set<String> keep,
  }) async {
    final tar = _tar(build)..parent.createSync(recursive: true);
    final tmp = File('${tar.path}.tmp');
    final out = tmp.openWrite();
    final written = <String>{};
    final sizes = <String, int>{};
    try {
      await add(out, written, sizes);
      if (from != null && tar.existsSync()) {
        await copyTiles(tar.openRead(), out, (name, size) {
          if (!keep.contains(name)) return false;
          sizes[name] = size;
          return written.add(name);
        });
      }
      out.add(tarEnd);
      await out.close();
    } catch (_) {
      await out.close();
      if (tmp.existsSync()) tmp.deleteSync();
      rethrow;
    }
    tmp.renameSync(tar.path);
    return sizes;
  }

  void _write(
    String build,
    Map<String, InstalledRouting> regions,
    Map<String, int> sizes,
  ) {
    root.createSync(recursive: true);
    final manifest = {
      'build': build,
      'regions': {
        for (final MapEntry(:key, :value) in regions.entries)
          key: {'sha256': value.sha256, 'tiles': value.tiles},
      },
      'sizes': sizes,
    };
    final tmp = File('${_manifest.path}.tmp')
      ..writeAsStringSync(jsonEncode(manifest));
    tmp.renameSync(_manifest.path);
  }

  void _deleteOtherBuilds(String keep) {
    for (final e in root.listSync()) {
      if (e is Directory && e.uri.pathSegments.reversed.skip(1).first != keep) {
        e.deleteSync(recursive: true);
      }
    }
  }

  _Manifest? _read() {
    if (!_manifest.existsSync()) return null;
    final json = jsonDecode(_manifest.readAsStringSync()) as Map;
    return _Manifest(json['build'] as String, {
      for (final MapEntry(:key, :value) in (json['regions'] as Map).entries)
        key as String: InstalledRouting(
          value['sha256'] as String,
          (value['tiles'] as List).cast<String>(),
        ),
    }, ((json['sizes'] as Map?) ?? const {}).cast<String, int>());
  }
}

class _Manifest {
  final String build;
  final Map<String, InstalledRouting> regions;
  final Map<String, int> sizes;

  const _Manifest(this.build, this.regions, this.sizes);
}
