import '../packs/pack.dart';

/// The maps a user picks between. Each has light and dark styles.
enum MapType {
  /// OpenStreetMap streets, places and land cover; works worldwide.
  osm,

  /// USGS topographic data; US only.
  usgs,

  /// NOAA nautical charts; US coastal waters only.
  charts;

  static MapType? parse(String? s) =>
      values.where((t) => t.name == s).firstOrNull;
}

/// The look families a style can belong to. Only [standard] is bundled
/// today; future looks (e.g. "outdoor") become new families with their own
/// light and dark styles per map.
abstract final class StyleFamily {
  static const standard = 'standard';
}

/// What an app needs to know about a style without rendering it.
class StyleInfo {
  final String id;
  final String name;

  /// From `metadata["ovm:map"]`.
  final MapType? mapType;

  /// From `metadata["ovm:theme"]` (or the older `ovm:dark`); apps can match
  /// their UI theme to it.
  final bool isDark;

  /// From `metadata["ovm:family"]`; [StyleFamily.standard] when absent.
  final String family;

  /// From `metadata["ovm:disclaimer"]`, e.g. "Not for navigation".
  final String? disclaimer;

  /// From `metadata["ovm:status"]`.
  final String? description;

  /// Pack kinds the map can't be drawn without, from
  /// `metadata["ovm:requires"]` (e.g. `osm` for the OSM map). Other sources,
  /// such as contours, only add detail.
  final Set<PackKind> requiredKinds;

  const StyleInfo({
    required this.id,
    required this.name,
    this.mapType,
    this.isDark = false,
    this.family = StyleFamily.standard,
    this.disclaimer,
    this.description,
    this.requiredKinds = const {},
  });

  factory StyleInfo.fromStyle(String id, Map<String, Object?> style) {
    final metadata = style['metadata'];
    final m = metadata is Map ? metadata : const {};
    final disclaimer = m['ovm:disclaimer'];
    return StyleInfo(
      id: id,
      name: (style['name'] as String?) ?? id,
      mapType: MapType.parse(m['ovm:map'] as String?),
      isDark: m['ovm:theme'] == 'dark' || m['ovm:dark'] == true,
      family: (m['ovm:family'] as String?) ?? StyleFamily.standard,
      disclaimer: disclaimer is String && disclaimer.isNotEmpty
          ? disclaimer
          : null,
      description: m['ovm:status'] as String?,
      requiredKinds: {
        for (final k in (m['ovm:requires'] as List?) ?? const [])
          if (k is String) PackKind.parse(k),
      }..remove(PackKind.unknown),
    );
  }

  @override
  String toString() =>
      'StyleInfo($id, ${mapType?.name}, ${isDark ? 'dark' : 'light'}, $family)';
}
