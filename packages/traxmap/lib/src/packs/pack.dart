import 'dart:io';

import 'geo.dart';
import 'pmtiles_header.dart';

/// What a pack contains. Matches `kind` in the pack index.
enum PackKind {
  base,
  contours,
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

  const Pack({
    required this.id,
    required this.file,
    required this.header,
    this.metadata = const {},
  });

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
