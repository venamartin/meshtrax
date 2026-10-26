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
  /// Installed packs for each pack kind referenced by the style, in
  /// preference order (see [packsByKind]). Several packs of one kind (e.g.
  /// neighbouring regions) are drawn as one source.
  final Map<PackKind, List<Pack>> packs;

  /// Glyph URL template, e.g. `file:///.../glyphs/{fontstack}/{range}.pbf`.
  final String? glyphs;

  /// Where the sprite sheets are, e.g. `file:///.../sprites`; styles name
  /// a sheet in it as `{sprite}/light`. The Flutter renderer reads the
  /// bundled sheets from [bundledSprites].
  final String? sprite;

  /// Builds the source URL for a pack. Defaults to `pmtiles://file://<path>`.
  final String Function(Pack pack) pmtilesUrl;

  /// Keeps only layers tagged for these units (`metadata["ovm:units"]`);
  /// untagged layers are always kept.
  final Units units;

  /// The app draws its own icons for points of interest: layers tagged
  /// with the `class` values the app covers (`metadata["ovm:appPlaces"]`)
  /// drop their icon for those, keeping the name.
  final bool appPlaces;

  const StyleContext({
    this.packs = const {},
    this.units = Units.imperial,
    this.glyphs,
    this.sprite,
    this.pmtilesUrl = defaultPmtilesUrl,
    this.appPlaces = false,
  });

  static String defaultPmtilesUrl(Pack pack) =>
      'pmtiles://${Uri.file(pack.file.absolute.path)}';

  /// Groups [packs] by kind, each list in preference order: packs in
  /// [units] first (contours variants), then the newest build, then by id.
  static Map<PackKind, List<Pack>> packsByKind(
    Iterable<Pack> packs, {
    required Units units,
  }) {
    final out = <PackKind, List<Pack>>{};
    for (final pack in packs) {
      (out[pack.kind] ??= []).add(pack);
    }
    for (final list in out.values) {
      list.sort((a, b) {
        final byUnits = (b.units == units ? 1 : 0) - (a.units == units ? 1 : 0);
        if (byUnits != 0) return byUnits;
        final aDate = a.buildDate, bDate = b.buildDate;
        if (aDate != null && bDate != null && aDate != bDate) {
          return bDate.compareTo(aDate);
        }
        return a.id.compareTo(b.id);
      });
    }
    return out;
  }
}

/// Loads the bundled MapLibre style JSON files and resolves their placeholders.
///
/// Styles in `assets/styles/` are written against these placeholders:
/// - source `url`: `pmtiles://{pack:<kind>}`, where kind is `base`,
///   `contours` or `charts`
/// - `glyphs`: `{glyphs}`
/// - `sprite`: `{sprite}/<sheet>`, e.g. `{sprite}/light`
///
/// A source whose pack kind is not installed is removed together with every
/// layer that uses it, so a missing optional pack never breaks the style.
/// When several packs of the kind are installed, the source's `url` names
/// the first and `ovm:urls` lists them all, in preference order.
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
      final packs = context.packs[PackKind.parse(m.group(1))] ?? const [];
      if (packs.isEmpty) {
        sources.remove(entry.key);
        dropped.add(entry.key);
      } else {
        source['url'] = context.pmtilesUrl(packs.first);
        if (packs.length > 1) {
          source['ovm:urls'] = [for (final p in packs) context.pmtilesUrl(p)];
        }
      }
    }
    (out['layers'] as List<Object?>?)?.removeWhere((l) {
      if (l is! Map) return false;
      if (dropped.contains(l['source'])) return true;
      final units = (l['metadata'] as Map?)?['ovm:units'];
      return units is String && units != context.units.name;
    });
    if (context.appPlaces) {
      for (final l in (out['layers'] as List<Object?>?) ?? const []) {
        if (l is! Map) continue;
        final classes = (l['metadata'] as Map?)?['ovm:appPlaces'];
        final layout = l['layout'];
        if (classes is! List || layout is! Map) continue;
        layout['icon-image'] = [
          'match',
          ['get', 'class'],
          classes,
          '',
          layout['icon-image'],
        ];
      }
    }

    _replaceOrRemove(out, 'glyphs', '{glyphs}', context.glyphs);
    _replaceOrRemove(out, 'sprite', '{sprite}', context.sprite);
    return out;
  }

  /// Replaces [placeholder] at the start of [key]'s value with [value], or
  /// removes the key when there is no [value].
  static void _replaceOrRemove(
    Map<String, Object?> style,
    String key,
    String placeholder,
    String? value,
  ) {
    final current = style[key];
    if (current is! String || !current.startsWith(placeholder)) return;
    if (value == null) {
      style.remove(key);
    } else {
      style[key] = value + current.substring(placeholder.length);
    }
  }
}
