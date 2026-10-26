/// The schema this app reads (`PRAGMA user_version` of the files).
const poiSchemaVersion = 1;

class PoiFile {
  final Uri url;
  final int bytes;
  final int unpackedBytes;
  final String sha256;

  const PoiFile(this.url, this.bytes, this.unpackedBytes, this.sha256);
}

/// A region's two downloads; either may be missing.
class PoiRegionFiles {
  final PoiFile? points;
  final PoiFile? addresses;

  const PoiRegionFiles(this.points, this.addresses);
}

/// The catalogue's `poi` entry (FINDINGS §1.8): one build, with each
/// region's "Points of interest" and "Addresses" files.
class PoiCatalog {
  final String build;
  final String? buildDate;
  final Map<String, PoiRegionFiles> regions;

  const PoiCatalog(this.build, this.buildDate, this.regions);

  /// Null when the catalogue has none, or only of a schema this app can't
  /// read.
  static PoiCatalog? fromIndex(Map<String, dynamic> index, Uri base) {
    final entry = index['poi'];
    if (entry is! Map || entry['schema_version'] != poiSchemaVersion) {
      return null;
    }
    PoiFile? file(Object? json) => json is Map
        ? PoiFile(
            base.resolve(json['url'] as String),
            json['bytes'] as int,
            json['unpacked_bytes'] as int,
            json['sha256'] as String,
          )
        : null;
    return PoiCatalog(
      entry['build'] as String,
      entry['build_date'] as String?,
      {
        for (final MapEntry(:key, :value) in (entry['regions'] as Map).entries)
          if (value is Map)
            key as String: PoiRegionFiles(
              file(value['points']),
              file(value['addresses']),
            ),
      },
    );
  }
}
