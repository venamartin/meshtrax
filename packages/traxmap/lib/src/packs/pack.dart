import 'dart:io';

import 'geo.dart';
import 'pmtiles_header.dart';

/// What a pack contains. Matches `kind` in the pack index.
enum PackKind {
  base,
  contours,

  /// Hill shading and elevation bands, drawn under every base map.
  terrain,
  charts,

  /// OpenStreetMap, OpenMapTiles schema (experiment; see FINDINGS.md).
  osm,
  unknown;

  static PackKind parse(String? s) =>
      values.firstWhere((k) => k.name == s, orElse: () => unknown);
}

/// Unit system for labels and for choosing pack variants.
enum Units {
  imperial,
  metric;

  static Units? parse(String? s) =>
      values.where((u) => u.name == s).firstOrNull;
}

/// An installed PMTiles region pack on local storage.
class Pack {
  /// Stable id, taken from the file name without extension.
  final String id;
  final File file;
  final PmTilesHeader header;

  /// The archive's JSON metadata, if readable.
  final Map<String, Object?> metadata;

  /// Start of the SHA-256 the pack was installed with, from its file name
  /// (`<id>@<sha12>.pmtiles`); null for packs installed without one.
  final String? sha256Prefix;

  const Pack({
    required this.id,
    required this.file,
    required this.header,
    this.metadata = const {},
    this.sha256Prefix,
  });

  /// True when this file is the build with [sha256] (hex, any case), e.g.
  /// the pack index's current one. False means an update is available;
  /// null means unknown (installed without a checksum).
  bool? isBuild(String sha256) => sha256Prefix == null
      ? null
      : sha256.toLowerCase().startsWith(sha256Prefix!);

  /// Path of the region the pack was cut for, e.g.
  /// `north-america/us/rhode-island`.
  String? get region => metadata['region'] as String?;

  DateTime? get buildDate =>
      DateTime.tryParse(metadata['build_date'] as String? ?? '');

  String get name => (metadata['name'] as String?) ?? id;

  /// Read from the `kind` metadata key the pipeline writes; `unknown` if absent.
  PackKind get kind => PackKind.parse(metadata['kind'] as String?);

  LatLngBounds get bounds => header.bounds;
  int get minZoom => header.minZoom;
  int get maxZoom => header.maxZoom;

  /// Vector layer ids declared in the metadata (`vector_layers[].id`).
  List<String> get vectorLayers => [
    for (final l in (metadata['vector_layers'] as List<Object?>? ?? const []))
      if (l is Map && l['id'] is String) l['id'] as String,
  ];

  String? get attribution => metadata['attribution'] as String?;

  /// Variant within a kind, e.g. `20ft` or `10m` for contours packs.
  String? get variant => metadata['variant'] as String?;

  /// Unit system of the pack's data where it matters (contour intervals).
  Units? get units => Units.parse(metadata['units'] as String?);

  @override
  String toString() => 'Pack($id, z$minZoom-$maxZoom, $bounds)';
}
