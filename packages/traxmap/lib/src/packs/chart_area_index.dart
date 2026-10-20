import 'dart:convert';

import 'geo.dart';
import 'outline.dart';

/// A NOAA chart area from the pack server's `chart_areas.geojson`
/// (traxmapmaker FINDINGS §1.4): one charts pack, listed under its coasts.
class ChartArea {
  /// e.g. `charts-us-al`; not the pack id.
  final String id;

  /// e.g. `Alabama`, `Lake Champlain (Vermont)`.
  final String name;

  /// The coast groups it's listed in; Florida is in two.
  final List<String> coasts;

  /// `charts/us/<slug>`: the charts pack's `region`, and the only way to
  /// pair an area with its pack.
  final String packRegion;

  /// Simplified coverage: polygons, each its outer ring followed by any
  /// holes. For suggestions, not for deciding what a pack draws.
  final List<List<List<LatLng>>> polygons;

  /// Each polygon's box. There's no box for the whole area: Alaska and the
  /// Pacific areas span the antimeridian.
  final List<LatLngBounds> parts;

  ChartArea({
    required this.id,
    required this.name,
    required this.coasts,
    required this.packRegion,
    required this.polygons,
  }) : parts = [
         for (final p in polygons)
           if (p.isNotEmpty && p.first.isNotEmpty) outerExtent([p]),
       ];

  bool contains(LatLng p) => polygons.any((poly) => polygonContains(poly, p));

  @override
  String toString() => 'ChartArea($id)';
}

/// The Charts tab's areas and coast groups, parsed from
/// `chart_areas.geojson`.
class ChartAreaIndex {
  /// `chart_areas.geojson` version this app understands.
  static const supportedVersion = 1;

  /// In file order.
  final List<ChartArea> areas;

  /// Coast groups in display order: the file's top-level `coasts`, then any
  /// other coast an area names, in order of first use.
  final List<String> coasts;

  final int version;

  /// e.g. the NOAA ENC catalogue date.
  final String? source;

  /// Credit to show with the list, e.g. `NOAA Office of Coast Survey`.
  final String? attribution;

  /// Features that couldn't be read, as short descriptions for logs.
  final List<String> skipped;

  /// Area ids per coast in coastline order, from the file's `coast_areas`
  /// when it has one.
  final Map<String, List<String>> coastOrder;
  final Map<String, ChartArea> _byPackRegion;

  ChartAreaIndex(
    this.areas, {
    List<String> coasts = const [],
    this.coastOrder = const {},
    this.version = supportedVersion,
    this.source,
    this.attribution,
    this.skipped = const [],
  }) : coasts = [
         ...{...coasts, for (final a in areas) ...a.coasts},
       ],
       _byPackRegion = {for (final a in areas) a.packRegion: a};

  factory ChartAreaIndex.parse(String json) {
    final root = jsonDecode(json);
    if (root is! Map<String, Object?>) {
      throw const FormatException('chart_areas.geojson is not a JSON object');
    }
    final areas = <ChartArea>[];
    final skipped = <String>[];
    final ids = <String>{};
    final packRegions = <String>{};
    final features = root['features'] as List<Object?>? ?? const [];
    for (final (i, f) in features.indexed) {
      try {
        final area = _areaFromFeature(f as Map<String, Object?>);
        if (!ids.add(area.id)) throw const FormatException('repeated id');
        if (!packRegions.add(area.packRegion)) {
          throw const FormatException('repeated pack_region');
        }
        areas.add(area);
      } on Object catch (error) {
        final props = f is Map ? f['properties'] : null;
        final id = props is Map ? props['id'] : null;
        skipped.add('${id ?? 'feature $i'}: $error');
      }
    }
    return ChartAreaIndex(
      areas,
      coasts: [
        for (final c in root['coasts'] as List<Object?>? ?? const [])
          if (c is String) c,
      ],
      coastOrder: {
        for (final MapEntry(:key, :value)
            in (root['coast_areas'] as Map<String, Object?>? ?? const {})
                .entries)
          if (value is List) key: [...value.whereType<String>()],
      },
      version: (root['version'] as num?)?.toInt() ?? supportedVersion,
      source: root['source'] as String?,
      attribution: root['attribution'] as String?,
      skipped: skipped,
    );
  }

  /// True when the server publishes a format newer than this app.
  bool get needsNewerApp => version > supportedVersion;

  ChartArea? byPackRegion(String path) => _byPackRegion[path];

  /// The areas listed under [coast]: in coastline order when the file gives
  /// one, else by name; areas the order leaves out follow, by name.
  List<ChartArea> inCoast(String coast) {
    final listed = [
      for (final a in areas)
        if (a.coasts.contains(coast)) a,
    ];
    final order = coastOrder[coast] ?? const [];
    int rank(ChartArea a) {
      final i = order.indexOf(a.id);
      return i < 0 ? order.length : i;
    }

    return listed..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0
          ? byRank
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  /// The areas containing [p], the one with the smallest containing part
  /// first (areas overlap in border waters).
  List<ChartArea> areasAt(LatLng p) {
    final found = <(ChartArea, double)>[];
    for (final a in areas) {
      double? smallest;
      for (final polygon in a.polygons) {
        if (!polygonContains(polygon, p)) continue;
        final size = boxArea(outerExtent([polygon]));
        if (smallest == null || size < smallest) smallest = size;
      }
      if (smallest != null) found.add((a, smallest));
    }
    found.sort((x, y) => x.$2.compareTo(y.$2));
    return [for (final (a, _) in found) a];
  }

  /// The areas with a part whose box overlaps [box].
  List<ChartArea> areasIn(LatLngBounds box) => [
    for (final a in areas)
      if (a.parts.any(box.intersects)) a,
  ];
}

ChartArea _areaFromFeature(Map<String, Object?> f) {
  final props = f['properties'] as Map<String, Object?>;
  final coasts = [
    for (final c in props['coasts'] as List<Object?>) c as String,
  ];
  if (coasts.isEmpty) throw const FormatException('no coasts');
  final geometry = f['geometry'] as Map<String, Object?>?;
  return ChartArea(
    id: props['id'] as String,
    name: props['name'] as String,
    coasts: coasts,
    packRegion: props['pack_region'] as String,
    polygons: geometry == null ? const [] : parsePolygons(geometry),
  );
}
