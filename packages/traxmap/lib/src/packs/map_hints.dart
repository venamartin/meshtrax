import 'dart:convert';

/// Small map facts for the whole catalogue (`hints.json`, traxmapmaker
/// FINDINGS §1.9): what the styles need that no pack carries, fixed or
/// updated without rebuilding a pack. Desert parks first; later label
/// emphasis, seasonal closures or regional notices.
class MapHints {
  static const schemaVersion = 1;

  /// Parks whose land is mostly desert, by name as the osm packs' `park`
  /// layer spells it. The standard map draws them tan.
  final List<String> desertParks;

  const MapHints({this.desertParks = const []});

  /// Null for a schema this version doesn't read. Unknown keys are ignored.
  static MapHints? parse(String json) {
    final m = jsonDecode(json) as Map<String, Object?>;
    if (m['schema_version'] != schemaVersion) return null;
    final parks = m['parks'] as Map<String, Object?>?;
    return MapHints(
      desertParks: [
        for (final name in (parks?['desert'] as List?) ?? const [])
          name as String,
      ],
    );
  }

  /// The named lists styles take, for their `{list:<name>}` placeholders.
  Map<String, List<String>> get styleLists => {'desert-parks': desertParks};
}
