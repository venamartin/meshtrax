import 'dart:convert';

import 'geo.dart';
import 'pack.dart';

/// One downloadable pack as listed in the server's pack index.
class PackIndexEntry {
  final String id;
  final String name;
  final PackKind kind;
  final LatLngBounds bbox;
  final int bytes;
  final String sha256;
  final DateTime buildDate;
  final int schemaVersion;
  final Uri url;

  /// Path of the region the pack was cut for, e.g.
  /// `north-america/us/rhode-island`: the `path` of a region in
  /// `picker.geojson`. Charts use their chart-area path (`charts/us/…`).
  final String? region;

  /// Variant within a kind, e.g. `20ft` or `10m` for contours.
  final String? variant;

  /// Unit system of a contours variant.
  final Units? units;

  /// Contour interval, in [intervalUnit]s.
  final num? interval;
  final String? intervalUnit;

  const PackIndexEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.bbox,
    required this.bytes,
    required this.sha256,
    required this.buildDate,
    required this.schemaVersion,
    required this.url,
    this.region,
    this.variant,
    this.units,
    this.interval,
    this.intervalUnit,
  });

  factory PackIndexEntry.fromJson(Map<String, Object?> j) => PackIndexEntry(
    id: j['id'] as String,
    name: j['name'] as String,
    kind: PackKind.parse(j['kind'] as String?),
    bbox: LatLngBounds.fromList(j['bbox'] as List<Object?>),
    bytes: (j['bytes'] as num).toInt(),
    sha256: j['sha256'] as String,
    buildDate: DateTime.parse(j['build_date'] as String),
    schemaVersion: (j['schema_version'] as num).toInt(),
    url: Uri.parse(j['url'] as String),
    region: j['region'] as String?,
    variant: j['variant'] as String?,
    units: Units.parse(j['units'] as String?),
    interval: j['interval'] as num?,
    intervalUnit: j['interval_unit'] as String?,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'bbox': bbox.toList(),
    'bytes': bytes,
    'sha256': sha256,
    'build_date': buildDate.toIso8601String(),
    'schema_version': schemaVersion,
    'url': url.toString(),
    'region': ?region,
    'variant': ?variant,
    'units': ?units?.name,
    'interval': ?interval,
    'interval_unit': ?intervalUnit,
  };
}

/// The pack index published by the pack server (traxmapmaker FINDINGS §1.1):
/// `{"generated", "schema_version", "packs": [ ... ], ...}`.
///
/// Other modules' keys (`routing`, `overlays`) are ignored until the app
/// uses them. A malformed pack entry is skipped, not fatal, so one bad row
/// can't hide the rest of the catalogue.
class PackIndex {
  /// Tile schema version the bundled styles are written for.
  static const supportedSchemaVersion = 1;

  final List<PackIndexEntry> packs;
  final DateTime? generated;

  /// The index's own schema version; newer than [supportedSchemaVersion]
  /// means the server has data this app version can't draw.
  final int? schemaVersion;

  /// Entries that couldn't be read, as short descriptions for logs.
  final List<String> skipped;

  const PackIndex(
    this.packs, {
    this.generated,
    this.schemaVersion,
    this.skipped = const [],
  });

  factory PackIndex.parse(String json) {
    final root = jsonDecode(json);
    if (root is! Map<String, Object?>) {
      throw const FormatException('pack index is not a JSON object');
    }
    final packs = <PackIndexEntry>[];
    final skipped = <String>[];
    for (final e in root['packs'] as List<Object?>? ?? const []) {
      try {
        packs.add(PackIndexEntry.fromJson(e as Map<String, Object?>));
      } on Object catch (error) {
        final id = e is Map ? e['id'] : null;
        skipped.add(
          '${id ?? 'entry ${packs.length + skipped.length}'}: $error',
        );
      }
    }
    return PackIndex(
      packs,
      generated: DateTime.tryParse(root['generated'] as String? ?? ''),
      schemaVersion: (root['schema_version'] as num?)?.toInt(),
      skipped: skipped,
    );
  }

  /// Packs this app can install and draw: a known kind, built for the
  /// bundled styles' schema.
  List<PackIndexEntry> get usable => [
    for (final e in packs)
      if (e.kind != PackKind.unknown &&
          e.schemaVersion == supportedSchemaVersion)
        e,
  ];

  /// The [usable] packs cut for the region at [path] (a picker `path`).
  List<PackIndexEntry> forRegion(String path) => [
    for (final e in usable)
      if (e.region == path) e,
  ];

  /// True when the server publishes a schema newer than this app supports.
  bool get needsNewerApp => (schemaVersion ?? 0) > supportedSchemaVersion;

  String encode() => jsonEncode({
    'generated': ?generated?.toIso8601String(),
    'schema_version': ?schemaVersion,
    'packs': [for (final e in packs) e.toJson()],
  });
}
