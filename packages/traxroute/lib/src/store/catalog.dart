/// The routing data the app can read: Valhalla 3.9.x tiles. A future app on
/// another Valhalla version reads another entry, and the server keeps both
/// while older apps are in use (FINDINGS §9).
const routingEngineKey = 'valhalla-3.9';

class RoutingBundle {
  final Uri url;
  final int bytes;
  final int unpackedBytes;
  final String sha256;

  const RoutingBundle(this.url, this.bytes, this.unpackedBytes, this.sha256);
}

/// The catalogue's `routing` entry for [routingEngineKey]: one build, with
/// a bundle per region.
class RoutingCatalog {
  final String build;
  final String engineVersion;
  final String? buildDate;
  final Map<String, RoutingBundle> regions;

  const RoutingCatalog(
    this.build,
    this.engineVersion,
    this.buildDate,
    this.regions,
  );

  /// Null when the catalogue has no routing this app can read.
  static RoutingCatalog? fromIndex(Map<String, dynamic> index, Uri base) {
    final entry = (index['routing'] as Map?)?[routingEngineKey];
    if (entry is! Map) return null;
    final regions = <String, RoutingBundle>{};
    for (final MapEntry(:key, :value) in (entry['regions'] as Map).entries) {
      if (value is! Map) continue;
      regions[key as String] = RoutingBundle(
        base.resolve(value['url'] as String),
        value['bytes'] as int,
        value['unpacked_bytes'] as int,
        value['sha256'] as String,
      );
    }
    return RoutingCatalog(
      entry['build'] as String,
      entry['engine_version'] as String,
      entry['build_date'] as String?,
      regions,
    );
  }
}
