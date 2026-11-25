import 'dart:convert';
import 'dart:io';

import '../route.dart';
import '../trip.dart';
import '../wrm.dart';
import 'catalog.dart';
import 'tar.dart';

/// A chart area's installed water routing, with what the catalogue said of
/// it, so its credits and chart show offline.
class InstalledWater {
  const InstalledWater(
    this.sha256,
    this.tiles, {
    this.chartsSha256,
    this.attribution,
    this.notice,
  });

  final String sha256;

  /// Its tiles' names (`<iy>_<ix>.wrm`).
  final List<String> tiles;

  /// The charts pack it was built from.
  final String? chartsSha256;
  final String? attribution;
  final String? notice;
}

/// The water-routing tiles on the device: one build at a time, since the
/// router refuses tiles of two, and each tile once where areas share it.
///
/// Layout under [root]: `<build>/<iy>_<ix>.wrm`, and `manifest.json` naming
/// the build, which area uses which tile, and each tile's size.
class WaterStore {
  WaterStore(this.root);

  final Directory root;
  _Manifest? _manifestRead;

  File get _manifest => File('${root.path}/manifest.json');

  /// The build on the device, or null before the first install.
  String? get build => _read()?.build;

  Map<String, InstalledWater> get regions => _read()?.regions ?? const {};

  /// Where the tiles are, or null when none are installed.
  Directory? get tileDir {
    final m = _read();
    return m == null || m.regions.isEmpty
        ? null
        : Directory('${root.path}/${m.build}');
  }

  /// The installed tiles, by key: iy × 1440 + ix.
  Set<int> get tileKeys => {
    for (final name in _read()?.sizes.keys ?? const <String>[])
      if (_key(name) case final key?) key,
  };

  /// What [region]'s tiles take (shared tiles count for each region).
  int sizeOf(String region) {
    final m = _read();
    if (m == null) return 0;
    return (m.regions[region]?.tiles ?? const <String>[]).fold(
      0,
      (sum, t) => sum + (m.sizes[t] ?? 0),
    );
  }

  /// What every installed tile takes, each once.
  int get totalBytes =>
      _read()?.sizes.values.fold<int>(0, (sum, s) => sum + s) ?? 0;

  /// A trip over the installed tiles, each read as the router reaches it.
  /// Synchronous: run it in an isolate.
  WaterTrip route(
    LatLon from,
    LatLon to, {
    WaterRouteOptions options = const WaterRouteOptions(),
    DateTime? when,
  }) {
    final dir = tileDir?.path;
    final keys = tileKeys;
    bool has(int ix, int iy) => keys.contains(iy * tileColumns + ix);
    return routeOnWater(
      from,
      to,
      hasTile: has,
      tileAt: (ix, iy) => has(ix, iy)
          ? WaterTile.parse(File('$dir/${tileName(ix, iy)}').readAsBytesSync())
          : null,
      options: options,
      when: when,
    );
  }

  /// The areas to download for [wanted] new ones. When the catalogue has a
  /// newer build than the device, every installed area comes too, so all
  /// tiles stay of one build.
  Set<String> downloadsFor(WaterCatalog catalog, Set<String> wanted) {
    final installed = regions;
    return {
      ...wanted,
      if (catalog.build != build) ...installed.keys,
      for (final MapEntry(:key, :value) in installed.entries)
        if (catalog.build == build &&
            catalog.regions[key] != null &&
            catalog.regions[key]!.sha256 != value.sha256)
          key,
    }.where(catalog.regions.containsKey).toSet();
  }

  /// Installs downloaded [bundles] (area → `.tar.gz` file and its catalogue
  /// entry) of [build]. A new build replaces the old one in one step: pass
  /// every area the device should keep, as [downloadsFor] lists them.
  ///
  /// A bundle holding anything but tiles of [build] throws a
  /// [FormatException], and nothing of it is installed.
  Future<void> install(
    String build,
    Map<String, (File, WaterBundle)> bundles,
  ) async {
    final old = _read();
    final sameBuild = old != null && old.build == build;
    final dir = Directory('${root.path}/$build')..createSync(recursive: true);
    final kept = <String, InstalledWater>{
      if (sameBuild)
        for (final MapEntry(:key, :value) in old.regions.entries)
          if (!bundles.containsKey(key)) key: value,
    };
    final sizes = <String, int>{if (sameBuild) ...old.sizes};
    final added = <String, InstalledWater>{};
    // Every bundle is unpacked and checked before any tile moves in.
    final incoming = Directory('${root.path}/$build.incoming');
    if (incoming.existsSync()) incoming.deleteSync(recursive: true);
    try {
      final unpacked = <String, (Directory, Map<String, int>)>{};
      for (final MapEntry(key: region, value: (file, _)) in bundles.entries) {
        final into = Directory('${incoming.path}/${unpacked.length}')
          ..createSync(recursive: true);
        unpacked[region] = (
          into,
          await unpackTiles(
            file.openRead().transform(gzip.decoder),
            into,
            build: build,
          ),
        );
      }
      for (final MapEntry(key: region, value: (into, tiles))
          in unpacked.entries) {
        for (final name in tiles.keys) {
          File('${into.path}/$name').renameSync('${dir.path}/$name');
        }
        sizes.addAll(tiles);
        final entry = bundles[region]!.$2;
        added[region] = InstalledWater(
          entry.sha256,
          tiles.keys.toList(),
          chartsSha256: entry.chartsSha256,
          attribution: entry.attribution,
          notice: entry.notice,
        );
      }
    } finally {
      if (incoming.existsSync()) incoming.deleteSync(recursive: true);
    }
    final regions = {...kept, ...added};
    _write(build, regions, _prune(dir, sizes, regions));
    if (!sameBuild) _deleteOtherBuilds(build);
  }

  /// Removes [region]; tiles other installed areas use stay.
  Future<void> remove(String region) async {
    final old = _read();
    if (old == null || !old.regions.containsKey(region)) return;
    final kept = Map.of(old.regions)..remove(region);
    final dir = Directory('${root.path}/${old.build}');
    _write(old.build, kept, _prune(dir, Map.of(old.sizes), kept));
  }

  /// Deletes the tiles in [dir] no area in [regions] uses, and returns the
  /// sizes of those left.
  Map<String, int> _prune(
    Directory dir,
    Map<String, int> sizes,
    Map<String, InstalledWater> regions,
  ) {
    final used = {for (final r in regions.values) ...r.tiles};
    for (final name in sizes.keys.where((n) => !used.contains(n)).toList()) {
      final f = File('${dir.path}/$name');
      if (f.existsSync()) f.deleteSync();
      sizes.remove(name);
    }
    return sizes;
  }

  void _write(
    String build,
    Map<String, InstalledWater> regions,
    Map<String, int> sizes,
  ) {
    root.createSync(recursive: true);
    final manifest = {
      'build': build,
      'regions': {
        for (final MapEntry(:key, :value) in regions.entries)
          key: {
            'sha256': value.sha256,
            'tiles': value.tiles,
            'charts_sha256': ?value.chartsSha256,
            'attribution': ?value.attribution,
            'notice': ?value.notice,
          },
      },
      'sizes': sizes,
    };
    final tmp = File('${_manifest.path}.tmp')
      ..writeAsStringSync(jsonEncode(manifest));
    tmp.renameSync(_manifest.path);
    _manifestRead = _Manifest(build, Map.of(regions), Map.of(sizes));
  }

  void _deleteOtherBuilds(String keep) {
    for (final e in root.listSync()) {
      if (e is Directory && e.uri.pathSegments.reversed.skip(1).first != keep) {
        e.deleteSync(recursive: true);
      }
    }
  }

  _Manifest? _read() {
    if (_manifestRead case final m?) return m;
    if (!_manifest.existsSync()) return null;
    final json = jsonDecode(_manifest.readAsStringSync()) as Map;
    return _manifestRead = _Manifest(json['build'] as String, {
      for (final MapEntry(:key, :value) in (json['regions'] as Map).entries)
        key as String: InstalledWater(
          value['sha256'] as String,
          (value['tiles'] as List).cast<String>(),
          chartsSha256: value['charts_sha256'] as String?,
          attribution: value['attribution'] as String?,
          notice: value['notice'] as String?,
        ),
    }, (json['sizes'] as Map).cast<String, int>());
  }

  static int? _key(String name) {
    final m = RegExp(r'^(\d+)_(\d+)\.wrm$').firstMatch(name);
    return m == null ? null : int.parse(m[1]!) * tileColumns + int.parse(m[2]!);
  }
}

class _Manifest {
  const _Manifest(this.build, this.regions, this.sizes);

  final String build;
  final Map<String, InstalledWater> regions;
  final Map<String, int> sizes;
}
