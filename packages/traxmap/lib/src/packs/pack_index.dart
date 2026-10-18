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
  };
}

/// The pack index published by the pack server: `{"packs": [ ... ]}`.
///
/// The app caches the last fetched copy so available packs can be shown
/// offline.
class PackIndex {
  final List<PackIndexEntry> packs;

  const PackIndex(this.packs);

  factory PackIndex.parse(String json) {
    final root = jsonDecode(json) as Map<String, Object?>;
    return PackIndex([
      for (final e in root['packs'] as List<Object?>)
        PackIndexEntry.fromJson(e as Map<String, Object?>),
    ]);
  }

  String encode() => jsonEncode({
    'packs': [for (final e in packs) e.toJson()],
  });
}
