import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../packs/pack.dart';
import 'style_info.dart';

/// Where style JSON comes from: the app's bundled assets (`AssetStyleSource`
/// in the Flutter layer), a directory ([DirectoryStyleSource]), or anything
/// else an app implements.
abstract interface class StyleSource {
  /// Style ids, e.g. `topo`, `dark`, `chart`.
  Future<List<String>> ids();

  /// The raw style JSON for [id], with placeholders intact.
  Future<Map<String, Object?>> load(String id);
}

/// Styles stored as `<id>.json` files in a directory.
class DirectoryStyleSource implements StyleSource {
  final Directory directory;

  DirectoryStyleSource(this.directory);

  @override
  Future<List<String>> ids() async => [
    await for (final f in directory.list())
      if (f is File && f.path.endsWith('.json'))
        p.basenameWithoutExtension(f.path),
  ]..sort();

  @override
  Future<Map<String, Object?>> load(String id) async =>
      jsonDecode(await File(p.join(directory.path, '$id.json')).readAsString())
          as Map<String, Object?>;
}

/// Local locations a style needs at runtime, supplied by the renderer adapter.
///
/// Native renderers cannot read Flutter assets directly, so the adapter copies
/// glyphs and sprites to disk and passes their URLs here.
class StyleContext {
  /// Installed pack to use for each pack kind referenced by the style.
  final Map<PackKind, Pack> packs;

  /// Glyph URL template, e.g. `file:///.../glyphs/{fontstack}/{range}.pbf`.
  final String? glyphs;

  /// Sprite base URL without extension, e.g. `file:///.../sprites/sprite`.
  final String? sprite;

  /// Builds the source URL for a pack. Defaults to `pmtiles://file://<path>`.
  final String Function(Pack pack) pmtilesUrl;

  /// Keeps only layers tagged for these units (`metadata["ovm:units"]`);
  /// untagged layers are always kept.
  final Units units;

  const StyleContext({
    this.packs = const {},
    this.units = Units.imperial,
    this.glyphs,
    this.sprite,
    this.pmtilesUrl = defaultPmtilesUrl,
  });

  static String defaultPmtilesUrl(Pack pack) =>
      'pmtiles://${Uri.file(pack.file.absolute.path)}';
}

/// Loads the bundled MapLibre style JSON files and resolves their placeholders.
///
/// Styles in `assets/styles/` are written against these placeholders:
/// - source `url`: `pmtiles://{pack:<kind>}`, where kind is `base`,
///   `contours` or `charts`
/// - `glyphs`: `{glyphs}`
/// - `sprite`: `{sprite}`
///
/// A source whose pack kind is not installed is removed together with every
/// layer that uses it, so a missing optional pack never breaks the style.
///
/// Layers can be tagged `"metadata": {"ovm:units": "imperial" | "metric"}`
/// (e.g. a contour label in feet and its twin in metres); only those matching
/// [StyleContext.units] are kept.
class StyleRegistry {
  final StyleSource source;
  Future<List<String>>? _ids;

  StyleRegistry(this.source);

  /// Ids of the available styles, sorted.
  Future<List<String>> available() => _ids ??= source.ids();

  /// The raw style JSON for [id], with placeholders intact.
  Future<Map<String, Object?>> loadRaw(String id) => source.load(id);

  final _info = <String, Future<StyleInfo>>{};

  /// Name, darkness and disclaimer of style [id] (cached).
  Future<StyleInfo> info(String id) =>
      _info[id] ??= loadRaw(id).then((raw) => StyleInfo.fromStyle(id, raw));

  /// [StyleInfo] for every bundled style, in [available] order.
  Future<List<StyleInfo>> all() async =>
      Future.wait([for (final id in await available()) info(id)]);

  /// The style id for [type] in light or [dark] mode, from [family].
  ///
  /// Falls back to the other mode, then to the [StyleFamily.standard]
  /// family, if the exact combination isn't bundled. Returns null when no
  /// style exists for [type] at all.
  Future<String?> styleFor(
    MapType type, {
    bool dark = false,
    String family = StyleFamily.standard,
  }) async {
    final styles = (await all()).where((s) => s.mapType == type).toList();
    StyleInfo? pick(bool Function(StyleInfo) test) =>
        styles.where(test).firstOrNull;
    return (pick((s) => s.family == family && s.isDark == dark) ??
            pick((s) => s.family == family) ??
            pick((s) => s.family == StyleFamily.standard && s.isDark == dark) ??
            pick((_) => true))
        ?.id;
  }

  /// The map types that have at least one style.
  Future<List<MapType>> mapTypes() async => [
    for (final t in MapType.values)
      if ((await all()).any((s) => s.mapType == t)) t,
  ];

  /// The style families available for [type] (only "standard" today).
  Future<List<String>> families(MapType type) async => {
    for (final s in await all())
      if (s.mapType == type) s.family,
  }.toList();

  /// The style for [id] with placeholders resolved against [context].
  Future<Map<String, Object?>> load(String id, StyleContext context) async =>
      resolve(await loadRaw(id), context);

  static final _packPlaceholder = RegExp(r'^pmtiles://\{pack:(\w+)\}$');

  /// Resolves placeholders in a decoded style. Does not modify [style].
  static Map<String, Object?> resolve(
    Map<String, Object?> style,
    StyleContext context,
  ) {
    final out = jsonDecode(jsonEncode(style)) as Map<String, Object?>;

    final sources = (out['sources'] as Map<String, Object?>?) ?? {};
    final dropped = <String>{};
    for (final entry in sources.entries.toList()) {
      final source = entry.value as Map<String, Object?>;
      final url = source['url'];
      if (url is! String) continue;
      final m = _packPlaceholder.firstMatch(url);
      if (m == null) continue;
      final pack = context.packs[PackKind.parse(m.group(1))];
      if (pack == null) {
        sources.remove(entry.key);
        dropped.add(entry.key);
      } else {
        source['url'] = context.pmtilesUrl(pack);
      }
    }
    (out['layers'] as List<Object?>?)?.removeWhere((l) {
      if (l is! Map) return false;
      if (dropped.contains(l['source'])) return true;
      final units = (l['metadata'] as Map?)?['ovm:units'];
      return units is String && units != context.units.name;
    });

    _replaceOrRemove(out, 'glyphs', '{glyphs}', context.glyphs);
    _replaceOrRemove(out, 'sprite', '{sprite}', context.sprite);
    return out;
  }

  static void _replaceOrRemove(
    Map<String, Object?> style,
    String key,
    String placeholder,
    String? value,
  ) {
    if (style[key] != placeholder) return;
    if (value == null) {
      style.remove(key);
    } else {
      style[key] = value;
    }
  }
}
