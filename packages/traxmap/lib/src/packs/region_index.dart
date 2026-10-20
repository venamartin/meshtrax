import 'dart:convert';

import 'geo.dart';
import 'outline.dart';

/// A region from the pack server's `picker.geojson` (traxmapmaker
/// FINDINGS §1.2): a node in the download picker's tree.
class Region {
  final String id;
  final String name;

  /// Server path, e.g. `north-america/us/rhode-island`. Packs carry it as
  /// their `region`.
  final String path;

  /// Path of the parent region; null at the top.
  final String? parentPath;

  /// `continent`, `country`, `state` or `subregion`.
  final String level;

  /// False for containers (a continent, the US, California): users pick
  /// one of their children instead.
  final bool downloadable;

  /// Box to fit the view to: the largest part of the outline.
  final LatLngBounds bounds;

  /// Simplified outline: polygons, each its outer ring followed by any
  /// holes. Rings never cross the antimeridian.
  final List<List<List<LatLng>>> polygons;

  const Region({
    required this.id,
    required this.name,
    required this.path,
    required this.parentPath,
    required this.level,
    required this.downloadable,
    required this.bounds,
    required this.polygons,
  });

  bool contains(LatLng p) => polygons.any((poly) => polygonContains(poly, p));

  @override
  String toString() => 'Region($path)';
}

/// The download picker's region tree, parsed from `picker.geojson`.
class RegionIndex {
  /// `picker.geojson` version this app understands.
  static const supportedVersion = 1;

  final List<Region> regions;
  final int version;

  /// Where the outlines came from, e.g. the Geofabrik index date.
  final String? source;

  /// Credit the app must show with the picker map.
  final String? attribution;

  /// Features that couldn't be read, as short descriptions for logs.
  final List<String> skipped;

  final Map<String, Region> _byPath;
  final Map<String?, List<Region>> _children;

  RegionIndex(
    this.regions, {
    this.version = supportedVersion,
    this.source,
    this.attribution,
    this.skipped = const [],
  }) : _byPath = {for (final r in regions) r.path: r},
       _children = {} {
    for (final r in regions) {
      final parent = _byPath.containsKey(r.parentPath) ? r.parentPath : null;
      (_children[parent] ??= []).add(r);
    }
    for (final list in _children.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  factory RegionIndex.parse(String json) {
    final root = jsonDecode(json);
    if (root is! Map<String, Object?>) {
      throw const FormatException('picker.geojson is not a JSON object');
    }
    final regions = <Region>[];
    final skipped = <String>[];
    for (final f in root['features'] as List<Object?>? ?? const []) {
      try {
        regions.add(_regionFromFeature(f as Map<String, Object?>));
      } on Object catch (error) {
        final props = f is Map ? f['properties'] : null;
        final path = props is Map ? props['path'] : null;
        skipped.add(
          '${path ?? 'feature ${regions.length + skipped.length}'}: $error',
        );
      }
    }
    return RegionIndex(
      regions,
      version: (root['version'] as num?)?.toInt() ?? supportedVersion,
      source: root['source'] as String?,
      attribution: root['attribution'] as String?,
      skipped: skipped,
    );
  }

  /// True when the server publishes a picker format newer than this app.
  bool get needsNewerApp => version > supportedVersion;

  Region? operator [](String path) => _byPath[path];

  /// Top-level regions (continents), sorted by name.
  List<Region> get roots => childrenOf(null);

  /// [region]'s children sorted by name; null gives the top level.
  List<Region> childrenOf(Region? region) =>
      _children[region?.path] ?? const [];

  /// [region]'s ancestors, from the top level down to its parent.
  List<Region> ancestorsOf(Region region) {
    final chain = <Region>[];
    var parent = _byPath[region.parentPath];
    while (parent != null && !chain.contains(parent)) {
      chain.insert(0, parent);
      parent = _byPath[parent.parentPath];
    }
    return chain;
  }

  /// The most specific downloadable region at [p]: the smallest one whose
  /// outline contains it (outlines overlap at sea and at borders).
  /// Downloadable regions are leaves, so smallest also means deepest.
  /// Null when none contains [p].
  Region? regionAt(LatLng p) {
    Region? best;
    for (final r in regions) {
      if (!r.downloadable || !r.contains(p)) continue;
      if (best == null || boxArea(r.bounds) < boxArea(best.bounds)) best = r;
    }
    return best;
  }
}

Region _regionFromFeature(Map<String, Object?> f) {
  final props = f['properties'] as Map<String, Object?>;
  final polygons = parsePolygons(f['geometry'] as Map<String, Object?>);
  final bbox = props['display_bbox'] as List<Object?>?;
  return Region(
    id: props['id'] as String,
    name: props['name'] as String,
    path: props['path'] as String,
    parentPath: props['parent'] as String?,
    level: props['level'] as String? ?? 'subregion',
    downloadable: props['downloadable'] as bool? ?? false,
    bounds: bbox != null ? LatLngBounds.fromList(bbox) : outerExtent(polygons),
    polygons: polygons,
  );
}
