/// What an app needs to know about a style without rendering it.
class StyleInfo {
  final String id;
  final String name;

  /// From `metadata["ovm:dark"]`; apps can match their UI theme to it.
  final bool isDark;

  /// From `metadata["ovm:disclaimer"]`, e.g. "Not for navigation".
  final String? disclaimer;

  /// From `metadata["ovm:status"]`.
  final String? description;

  const StyleInfo({
    required this.id,
    required this.name,
    this.isDark = false,
    this.disclaimer,
    this.description,
  });

  factory StyleInfo.fromStyle(String id, Map<String, Object?> style) {
    final metadata = style['metadata'];
    final m = metadata is Map ? metadata : const {};
    final disclaimer = m['ovm:disclaimer'];
    return StyleInfo(
      id: id,
      name: (style['name'] as String?) ?? id,
      isDark: m['ovm:dark'] == true,
      disclaimer: disclaimer is String && disclaimer.isNotEmpty
          ? disclaimer
          : null,
      description: m['ovm:status'] as String?,
    );
  }

  @override
  String toString() => 'StyleInfo($id, dark: $isDark)';
}
