import 'dart:io';
import 'dart:typed_data';

import 'dart:ui' show Brightness;

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

void main() {
  final base = Pack(
    id: 'ca-base',
    file: File('/data/packs/ca-base.pmtiles'),
    header: PmTilesHeader.parse(_header()),
    metadata: const {'kind': 'base'},
  );

  final style = <String, Object?>{
    'version': 8,
    'glyphs': '{glyphs}',
    'sprite': '{sprite}',
    'sources': {
      'base': {'type': 'vector', 'url': 'pmtiles://{pack:base}'},
      'contours': {'type': 'vector', 'url': 'pmtiles://{pack:contours}'},
    },
    'layers': [
      {'id': 'bg', 'type': 'background'},
      {'id': 'water', 'type': 'fill', 'source': 'base'},
      {'id': 'contour', 'type': 'line', 'source': 'contours'},
    ],
  };

  test('rewrites pack, glyph and sprite urls', () {
    final out = StyleRegistry.resolve(
      style,
      StyleContext(
        packs: {PackKind.base: base},
        glyphs: 'file:///g/{fontstack}/{range}.pbf',
        sprite: 'file:///s/sprite',
      ),
    );
    final sources = out['sources'] as Map;
    expect(
      sources['base']['url'],
      'pmtiles://file:///data/packs/ca-base.pmtiles',
    );
    expect(out['glyphs'], 'file:///g/{fontstack}/{range}.pbf');
    expect(out['sprite'], 'file:///s/sprite');
  });

  test('drops sources for missing packs and their layers', () {
    final out = StyleRegistry.resolve(
      style,
      StyleContext(packs: {PackKind.base: base}),
    );
    expect((out['sources'] as Map).keys, ['base']);
    expect([for (final l in out['layers'] as List) l['id']], ['bg', 'water']);
    expect(out.containsKey('glyphs'), isFalse);
    expect(out.containsKey('sprite'), isFalse);
  });

  test('keeps only layers tagged for the requested units', () {
    final tagged = <String, Object?>{
      'version': 8,
      'sources': <String, Object?>{},
      'layers': [
        {'id': 'bg', 'type': 'background'},
        {
          'id': 'label-ft',
          'type': 'symbol',
          'metadata': {'ovm:units': 'imperial'},
        },
        {
          'id': 'label-m',
          'type': 'symbol',
          'metadata': {'ovm:units': 'metric'},
        },
      ],
    };
    List<Object?> ids(Units u) => [
      for (final l
          in StyleRegistry.resolve(tagged, StyleContext(units: u))['layers']
              as List)
        (l as Map)['id'],
    ];
    expect(ids(Units.imperial), ['bg', 'label-ft']);
    expect(ids(Units.metric), ['bg', 'label-m']);
  });

  test('does not modify the input', () {
    StyleRegistry.resolve(style, const StyleContext());
    expect((style['layers'] as List), hasLength(3));
  });

  // Plain async tests: rootBundle caches asset futures, and one created in a
  // testWidgets fake-async zone never completes when awaited from another.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chart styles: disclaimer, and work without a charts pack', () async {
    for (final id in ['charts-light', 'charts-dark']) {
      final chart = await bundledStyles().load(
        id,
        StyleContext(packs: {PackKind.base: base}),
      );
      expect(StyleInfo.fromStyle(id, chart).disclaimer, 'Not for navigation');
      expect((chart['sources'] as Map).keys, ['base']);
      for (final layer in chart['layers'] as List) {
        expect((layer as Map)['source'], anyOf(isNull, 'base'));
      }
    }
    final usgs = await bundledStyles().load('usgs-light', const StyleContext());
    expect(StyleInfo.fromStyle('usgs-light', usgs).disclaimer, isNull);
  });

  test('every map draws land contours from the one contours pack', () async {
    final contours = Pack(
      id: 'ca-contours-20ft',
      file: File('/data/packs/ca-contours-20ft.pmtiles'),
      header: PmTilesHeader.parse(_header()),
      metadata: const {'kind': 'contours', 'variant': '20ft'},
    );
    final registry = bundledStyles();
    for (final id in await registry.available()) {
      final on = await registry.load(
        id,
        StyleContext(packs: {PackKind.contours: contours}),
      );
      final url = ((on['sources'] as Map)['contours'] as Map)['url'];
      expect(url, 'pmtiles://${Uri.file(contours.file.path)}', reason: id);
      final ids = [for (final l in on['layers'] as List) (l as Map)['id']];
      expect(ids, containsAll(['contour', 'contour-label']), reason: id);
      expect(ids, isNot(contains('contour-label-m')), reason: id);
      // Contours off: the app leaves the pack out, the layers go.
      final off = await registry.load(id, const StyleContext());
      expect((off['sources'] as Map).containsKey('contours'), isFalse);
    }
  });

  test('every map type has a light and a dark standard style', () async {
    final registry = bundledStyles();
    expect(await registry.mapTypes(), MapType.values);
    for (final type in MapType.values) {
      final light = await registry.styleFor(type);
      final dark = await registry.styleFor(type, dark: true);
      expect(light, '${type.name}-light');
      expect(dark, '${type.name}-dark');
      expect((await registry.info(dark!)).isDark, isTrue);
      expect((await registry.info(light!)).isDark, isFalse);
      expect(await registry.families(type), [StyleFamily.standard]);
    }
    expect(
      await registry.styleForBrightness(MapType.usgs, Brightness.dark),
      'usgs-dark',
    );
    // A family that doesn't exist yet falls back to the standard look.
    expect(
      await registry.styleFor(MapType.osm, dark: true, family: 'outdoor'),
      'osm-dark',
    );
  });

  test('each map names the pack kinds it requires', () async {
    final registry = bundledStyles();
    for (final (type, kind) in [
      (MapType.osm, PackKind.osm),
      (MapType.usgs, PackKind.base),
      (MapType.charts, PackKind.charts),
    ]) {
      for (final dark in [false, true]) {
        final id = await registry.styleFor(type, dark: dark);
        expect((await registry.info(id!)).requiredKinds, {kind}, reason: id);
      }
    }
  });

  test('bundled styles load and resolve', () async {
    final registry = bundledStyles();
    final ids = await registry.available();
    expect(ids, hasLength(6));
    for (final id in ids) {
      final s = await registry.load(id, const StyleContext());
      expect(s['version'], 8);
    }
  });
}

// Minimal valid header, reused from the fake builder without metadata.
Uint8List _header() {
  final b = List<int>.filled(127, 0);
  b.setAll(0, 'PMTiles'.codeUnits);
  b[7] = 3;
  return Uint8List.fromList(b);
}
