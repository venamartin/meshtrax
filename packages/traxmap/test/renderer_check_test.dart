import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
// The renderer's own decoder, so properties keep the types it gives them.
// ignore: implementation_imports
import 'package:flutter_map_vector_tiles/src/mvt/mvt_decoder.dart';
// ignore: implementation_imports
import 'package:flutter_map_vector_tiles/src/mvt/mvt_tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/src/renderer/local_pmtiles_provider.dart';
import 'package:traxmap/traxmap.dart';

/// What every bundled style draws on real tiles, compared across versions of
/// the renderer (flutter_map_vector_tiles). Run it before and after changing
/// the version:
///
///     flutter test test/renderer_check_test.dart
///
/// It goes through the same sample of tiles every run, from the packs in
/// `test/packs` (or the folder in `TRAXMAP_PACKS`) and the bundled world map.
/// For each style layer it counts the features its filter matches and what
/// each property evaluates to on them, and saves that as
/// `build/renderer_check/<version>.json`. With a result from another version
/// there, it fails on every layer that matches or paints differently: a
/// filter or property whose types the new version rejects, an expression it
/// now evaluates another way.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final folder = Directory(
    Platform.environment['TRAXMAP_PACKS'] ?? 'test/packs',
  );
  final files = folder.existsSync()
      ? [
          for (final f in folder.listSync())
            if (f is File && f.path.endsWith('.pmtiles')) f,
        ]
      : <File>[];
  files.sort((a, b) => a.path.compareTo(b.path));

  test(
    'every style layer draws what it drew on the last renderer checked',
    () async {
      final warnings = <String>[];
      final all = <_Layer>[];
      final bySource = <(PackKind, String), List<_Layer>>{};
      final registry = bundledStyles();
      for (final id in await registry.available()) {
        final raw = await registry.loadRaw(id);
        final kinds = {
          for (final MapEntry(:key, :value)
              in (raw['sources'] as Map<String, Object?>).entries)
            if (_packUrl.firstMatch('${(value as Map)['url']}') case final m?)
              key: PackKind.parse(m.group(1)),
        };
        final theme = vt.ThemeReader(
          logger: vt.Logger.custom(onWarn: (m) => warnings.add('$id: $m')),
        ).read(raw, id: id);
        for (final layer in theme.layers) {
          final kind = kinds[layer.source];
          final sourceLayer = layer.sourceLayer;
          if (kind == null || sourceLayer == null) continue;
          final drawn = _Layer('$id/${layer.id}', layer);
          all.add(drawn);
          (bySource[(kind, sourceLayer)] ??= []).add(drawn);
        }
      }

      final tiles = <String, int>{};
      for (final file in [...files, File('assets/world/world.pmtiles')]) {
        final pack = await PackManager.open(file);
        final provider = await LocalPmTilesVectorTileProvider.open(file);
        final name = file.uri.pathSegments.last;
        try {
          for (var z = pack.minZoom; z <= pack.maxZoom; z++) {
            // The last level is drawn at every zoom above it too.
            final zooms = [
              for (var d = z; d <= (z == pack.maxZoom ? _topZoom : z); d++)
                d.toDouble(),
            ];
            final sample = await _sample(provider, pack.bounds, z);
            tiles[name] = (tiles[name] ?? 0) + sample.length;
            for (final bytes in sample) {
              for (final source in decodeMvt(bytes).layers) {
                final drawn = bySource[(pack.kind, source.name)];
                if (drawn != null) _count(source, drawn, zooms);
              }
            }
          }
        } finally {
          provider.dispose();
        }
      }

      final version = _rendererVersion();
      final dir = Directory('build/renderer_check')
        ..createSync(recursive: true);
      final text = const JsonEncoder.withIndent(' ').convert({
        'renderer': version,
        'tiles': tiles,
        'warnings': warnings..sort(),
        'layers': {
          for (final l in all..sort((a, b) => a.key.compareTo(b.key)))
            l.key: l.toJson(),
        },
      });
      File('${dir.path}/$version.json').writeAsStringSync(text);

      final others = [
        for (final f in dir.listSync())
          if (f is File &&
              f.path.endsWith('.json') &&
              f.uri.pathSegments.last != '$version.json')
            f,
      ]..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      if (others.isEmpty) return;
      final before = jsonDecode(others.first.readAsStringSync()) as Map;
      final differences = _differences(before, jsonDecode(text) as Map);
      if (differences.isNotEmpty) {
        fail(
          'Renderer ${before['renderer']} → $version: these draw differently '
          '(both results are in ${dir.path}):\n${differences.join('\n')}',
        );
      }
    },
    skip: files.isEmpty
        ? 'put map packs in ${folder.path}, or name a folder in TRAXMAP_PACKS'
        : false,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

const _tilesPerZoom = 16;

/// The highest zoom a pack's last level is checked at.
const _topZoom = 18;

final _packUrl = RegExp(r'^pmtiles://\{pack:(\w+)\}$');

const _geometryTypes = {
  MvtGeomType.point: 'Point',
  MvtGeomType.lineString: 'LineString',
  MvtGeomType.polygon: 'Polygon',
};

/// A style layer and what it drew so far.
class _Layer {
  final String key;
  final vt.ThemeLayer theme;
  final Map<String, Object? Function(vt.EvalContext)> properties;
  var features = 0;
  var matched = 0;
  final values = <String, Map<String, int>>{};

  _Layer(this.key, this.theme)
    : properties = {
        for (final MapEntry(:key, :value) in _propertiesOf(theme).entries)
          key: ?value,
      };

  Map<String, Object?> toJson() => {
    'features': features,
    'matched': matched,
    'properties': {
      for (final name in values.keys.toList()..sort())
        name: {
          for (final v in values[name]!.keys.toList()..sort())
            v: values[name]![v],
        },
    },
  };
}

/// Matches [source]'s features against each layer in [drawn] at [zooms], and
/// tallies the properties of those that match.
void _count(MvtLayer source, List<_Layer> drawn, List<double> zooms) {
  final features = [
    for (final f in source.features)
      if (_geometryTypes[f.type] case final type?)
        (
          properties: f.decodeProperties(source),
          type: type,
          id: f.id == 0 ? null : f.id,
        ),
  ];
  for (final layer in drawn) {
    for (final zoom in zooms) {
      if (zoom < layer.theme.minzoom || zoom >= layer.theme.maxzoom) continue;
      for (final f in features) {
        final context = vt.EvalContext(
          zoom: zoom,
          properties: f.properties,
          geometryType: f.type,
          featureId: f.id,
        );
        layer.features++;
        if (!layer.theme.matches(context)) continue;
        layer.matched++;
        for (final MapEntry(:key, :value) in layer.properties.entries) {
          final tally = layer.values[key] ??= {};
          final shown = _show(value(context));
          tally[shown] = (tally[shown] ?? 0) + 1;
        }
      }
    }
  }
}

/// Every property the renderer evaluates per feature, by its style name.
Map<String, Object? Function(vt.EvalContext)?> _propertiesOf(
  vt.ThemeLayer layer,
) => switch (layer) {
  vt.FillThemeLayer l => {
    'fill-color': l.color.eval,
    'fill-opacity': l.opacity.eval,
    'fill-outline-color': l.outlineColor?.eval,
    'fill-pattern': l.pattern?.eval,
  },
  vt.LineThemeLayer l => {
    'line-color': l.color.eval,
    'line-width': l.width.eval,
    'line-opacity': l.opacity.eval,
    'line-gap-width': l.gapWidth.eval,
    'line-dasharray': l.dashArray?.eval,
    'line-cap': l.cap.eval,
    'line-join': l.join.eval,
    'line-pattern': l.pattern?.eval,
  },
  vt.CircleThemeLayer l => {
    'circle-radius': l.radius.eval,
    'circle-color': l.color.eval,
    'circle-opacity': l.opacity.eval,
    'circle-stroke-color': l.strokeColor.eval,
    'circle-stroke-width': l.strokeWidth.eval,
    'circle-stroke-opacity': l.strokeOpacity.eval,
  },
  vt.SymbolThemeLayer l => {
    'symbol-placement': l.placement.eval,
    'symbol-sort-key': l.sortKey.eval,
    'symbol-spacing': l.spacing.eval,
    'text-field': l.textField.eval,
    'text-size': l.textSize.eval,
    'text-font': l.textFont.eval,
    'text-max-width': l.textMaxWidth.eval,
    'text-letter-spacing': l.textLetterSpacing.eval,
    'text-transform': l.textTransform.eval,
    'text-anchor': l.textAnchor.eval,
    'text-variable-anchor': l.textVariableAnchor?.eval,
    'text-radial-offset': l.textRadialOffset.eval,
    'text-offset': l.textOffset.eval,
    'text-padding': l.textPadding.eval,
    'text-allow-overlap': l.textAllowOverlap.eval,
    'text-optional': l.textOptional.eval,
    'text-max-angle': l.textMaxAngle.eval,
    'text-keep-upright': l.textKeepUpright.eval,
    'text-rotation-alignment': l.textRotationAlignment.eval,
    'text-color': l.textColor.eval,
    'text-halo-color': l.textHaloColor.eval,
    'text-halo-width': l.textHaloWidth.eval,
    'text-opacity': l.textOpacity.eval,
    'icon-image': l.iconImage?.eval,
    'icon-size': l.iconSize.eval,
    'icon-anchor': l.iconAnchor.eval,
    'icon-offset': l.iconOffset.eval,
    'icon-allow-overlap': l.iconAllowOverlap.eval,
    'icon-rotate': l.iconRotate.eval,
    'icon-rotation-alignment': l.iconRotationAlignment.eval,
    'icon-color': l.iconColor.eval,
    'icon-halo-color': l.iconHaloColor.eval,
    'icon-halo-width': l.iconHaloWidth.eval,
    'icon-opacity': l.iconOpacity.eval,
  },
  _ => const {},
};

/// A property's value as one string that compares across runs.
String _show(Object? value) => switch (value) {
  double v => v.isFinite ? v.toStringAsFixed(2) : '$v',
  Color c => '#${c.toARGB32().toRadixString(16).padLeft(8, '0')}',
  List<Object?> l => l.map(_show).join(','),
  _ => '$value',
};

/// Up to [_tilesPerZoom] tiles of [provider] at [z] within [bounds], the same
/// ones every run: the busiest of up to four times as many, taken in random
/// order (all of them where there are few). Busy tiles hold the most kinds
/// of feature; a random one over a big pack is mostly empty land or sea.
Future<List<Uint8List>> _sample(
  LocalPmTilesVectorTileProvider provider,
  LatLngBounds bounds,
  int z,
) async {
  final (x0, y0) = _tileAt(bounds.north, bounds.west, z);
  final (x1, y1) = _tileAt(bounds.south, bounds.east, z);
  final width = x1 - x0 + 1;
  final count = width * (y1 - y0 + 1);
  final random = math.Random(z);
  final picks = count <= 4 * _tilesPerZoom
      ? ([for (var i = 0; i < count; i++) i]..shuffle(random))
      : {for (var i = 0; i < 8 * _tilesPerZoom; i++) random.nextInt(count)};
  final found = <Uint8List>[];
  for (final i in picks) {
    if (found.length == 4 * _tilesPerZoom) break;
    final response = await provider.load(
      vt.TileKey(z, x0 + i % width, y0 + i ~/ width),
    );
    if (response is vt.TileResponseData) found.add(response.bytes);
  }
  found.sort((a, b) => b.length.compareTo(a.length));
  return [
    for (final bytes in found.take(_tilesPerZoom))
      bytes.length > 1 && bytes[0] == 0x1f && bytes[1] == 0x8b
          ? Uint8List.fromList(gzip.decode(bytes))
          : bytes,
  ];
}

(int, int) _tileAt(double latitude, double longitude, int z) {
  final n = 1 << z;
  final lat = latitude.clamp(-85.0511, 85.0511) * math.pi / 180;
  final x = ((longitude + 180) / 360 * n).floor().clamp(0, n - 1);
  final y =
      ((1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2 * n)
          .floor()
          .clamp(0, n - 1);
  return (x, y);
}

/// The renderer's version, from the folder pub put it in.
String _rendererVersion() {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map;
  final renderer = (config['packages'] as List).firstWhere(
    (p) => p['name'] == 'flutter_map_vector_tiles',
  );
  return RegExp(r'flutter_map_vector_tiles-([^/]+)')
          .firstMatch('${renderer['rootUri']}')
          ?.group(1) ??
      'unknown';
}

/// What changed from [before] to [after], one line per layer or property.
List<String> _differences(Map before, Map after) {
  if ('${before['tiles']}' != '${after['tiles']}') {
    return ['other tiles: ${before['tiles']} → ${after['tiles']}'];
  }
  final wasWarned = before['warnings'] as List;
  final isWarned = after['warnings'] as List;
  final out = [
    for (final w in wasWarned)
      if (!isWarned.contains(w)) 'warning gone: $w',
    for (final w in isWarned)
      if (!wasWarned.contains(w)) 'new warning: $w',
  ];
  final was = before['layers'] as Map;
  final now = after['layers'] as Map;
  for (final key in {...was.keys, ...now.keys}) {
    final a = was[key] as Map?;
    final b = now[key] as Map?;
    if (a == null || b == null) {
      out.add('$key: ${a == null ? 'a new layer' : 'no longer in the style'}');
    } else if (a['features'] != b['features']) {
      out.add('$key: not the same tiles (${a['features']} → ${b['features']})');
    } else if (a['matched'] != b['matched']) {
      out.add('$key: matches ${a['matched']} → ${b['matched']} features');
    } else {
      final pa = a['properties'] as Map;
      final pb = b['properties'] as Map;
      for (final name in {...pa.keys, ...pb.keys}) {
        final ha = (pa[name] as Map?) ?? const {};
        final hb = (pb[name] as Map?) ?? const {};
        int delta(Object? v) =>
            (((hb[v] ?? 0) as int) - ((ha[v] ?? 0) as int)).abs();
        final changed = [
          for (final v in {...ha.keys, ...hb.keys})
            if (ha[v] != hb[v]) v,
        ]..sort((x, y) => delta(y).compareTo(delta(x)));
        if (changed.isEmpty) continue;
        final shown = [
          for (final v in changed.take(4)) '"$v" ${ha[v] ?? 0} → ${hb[v] ?? 0}',
        ];
        out.add(
          '$key $name: ${shown.join(', ')}${changed.length > 4 ? ', …' : ''}',
        );
      }
    }
  }
  return out;
}
