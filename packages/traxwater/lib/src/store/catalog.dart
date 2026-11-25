/// The tiles this app reads: WRM2. A new tile format is published under its
/// own key beside this one while older apps are in use (FINDINGS 1.11).
const waterFormatKey = 'wrm-2';

/// One chart area's water-routing bundle in the catalogue.
class WaterBundle {
  const WaterBundle(
    this.url,
    this.bytes,
    this.unpackedBytes,
    this.sha256, {
    this.chartsSha256,
    this.attribution,
    this.notice,
  });

  final Uri url;
  final int bytes;
  final int unpackedBytes;
  final String sha256;

  /// The sha256 of the charts pack the area's routing was built from.
  final String? chartsSha256;
  final String? attribution;

  /// The warning the data comes with ("Not for navigation. …").
  final String? notice;
}

/// The catalogue's `water_routing` entry for [waterFormatKey]: one build,
/// with a bundle per chart area (`charts/us/california`).
class WaterCatalog {
  const WaterCatalog(this.build, this.buildDate, this.regions);

  final String build;
  final String? buildDate;
  final Map<String, WaterBundle> regions;

  /// Whether [index] has water routing, but only in formats a newer app
  /// reads.
  static bool needsNewerApp(Map<String, dynamic> index) {
    final entry = index['water_routing'];
    return entry is Map && entry.isNotEmpty && entry[waterFormatKey] is! Map;
  }

  /// Null when the catalogue has no water routing this app reads.
  static WaterCatalog? fromIndex(Map<String, dynamic> index, Uri base) {
    final entry = (index['water_routing'] as Map?)?[waterFormatKey];
    if (entry is! Map) return null;
    return WaterCatalog(
      entry['build'] as String,
      entry['build_date'] as String?,
      {
        for (final MapEntry(:key, :value) in (entry['regions'] as Map).entries)
          if (value is Map)
            key as String: WaterBundle(
              base.resolve(value['url'] as String),
              value['bytes'] as int,
              value['unpacked_bytes'] as int,
              value['sha256'] as String,
              chartsSha256: value['charts_sha256'] as String?,
              attribution: value['attribution'] as String?,
              notice: value['notice'] as String?,
            ),
      },
    );
  }
}
