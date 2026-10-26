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
/// builds break routing), unpacked once per tile, and combined into the one
/// plain tar the engine opens.
///
/// Layout under [root]: `<build>/tiles/…` and `<build>/tiles.tar`, plus
/// `manifest.json` naming the build and which region uses which tile.
class RoutingStore {
  final Directory root;

  RoutingStore(this.root);

  File get _manifest => File('${root.path}/manifest.json');

  /// The build on the device, or null before the first install.
  String? get build => _read()?.$1;

  Map<String, InstalledRouting> get regions => _read()?.$2 ?? const {};

  /// The combined tile file to open, or null when nothing is installed.
  File? get tileFile {
    final b = build;
    if (b == null || regions.isEmpty) return null;
    final f = File('${root.path}/$b/tiles.tar');
    return f.existsSync() ? f : null;
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

  /// Installs downloaded [bundles] (region → file and sha256) of [build].
  /// A new build replaces the old one in one step: pass every region the
  /// device should keep, as [downloadsFor] lists them.
  Future<void> install(
    String build,
    Map<String, (File, String)> bundles,
  ) async {
    final sameBuild = build == this.build;
    final kept = sameBuild ? Map.of(regions) : <String, InstalledRouting>{};
    final dir = Directory('${root.path}/$build/tiles')
      ..createSync(recursive: true);
    for (final MapEntry(key: region, value: (file, sha)) in bundles.entries) {
      kept[region] = InstalledRouting(sha, await extractTiles(file, dir));
    }
    await _commit(build, kept);
    if (!sameBuild) _deleteOtherBuilds(build);
  }

  /// Removes [region]; tiles other installed regions use stay.
  Future<void> remove(String region) async {
    final b = build;
    if (b == null) return;
    final kept = Map.of(regions)..remove(region);
    final stillUsed = {for (final r in kept.values) ...r.tiles};
    for (final tile in regions[region]?.tiles ?? const <String>[]) {
      if (!stillUsed.contains(tile)) {
        final f = File('${root.path}/$b/tiles/$tile');
        if (f.existsSync()) f.deleteSync();
      }
    }
    await _commit(b, kept);
  }

  Future<void> _commit(String build, Map<String, InstalledRouting> kept) async {
    final tiles = {for (final r in kept.values) ...r.tiles}.toList()..sort();
    final tar = File('${root.path}/$build/tiles.tar');
    final tmp = File('${tar.path}.tmp');
    if (tiles.isEmpty) {
      if (tar.existsSync()) tar.deleteSync();
    } else {
      await writeTar(tmp, Directory('${root.path}/$build/tiles'), tiles);
      tmp.renameSync(tar.path);
    }
    final manifest = {
      'build': build,
      'regions': {
        for (final MapEntry(:key, :value) in kept.entries)
          key: {'sha256': value.sha256, 'tiles': value.tiles},
      },
    };
    final tmpManifest = File('${_manifest.path}.tmp')
      ..writeAsStringSync(jsonEncode(manifest));
    tmpManifest.renameSync(_manifest.path);
  }

  void _deleteOtherBuilds(String keep) {
    for (final e in root.listSync()) {
      if (e is Directory && e.uri.pathSegments.reversed.skip(1).first != keep) {
        e.deleteSync(recursive: true);
      }
    }
  }

  (String, Map<String, InstalledRouting>)? _read() {
    if (!_manifest.existsSync()) return null;
    final json = jsonDecode(_manifest.readAsStringSync()) as Map;
    return (
      json['build'] as String,
      {
        for (final MapEntry(:key, :value) in (json['regions'] as Map).entries)
          key as String: InstalledRouting(
            value['sha256'] as String,
            (value['tiles'] as List).cast<String>(),
          ),
      },
    );
  }
}
