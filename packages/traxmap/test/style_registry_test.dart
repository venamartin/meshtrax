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

  test('chart style: disclaimer, and works without a charts pack', () async {
    final chart = await bundledStyles().load(
      'chart',
      StyleContext(packs: {PackKind.base: base}),
    );
    expect(
      StyleInfo.fromStyle("chart", chart).disclaimer,
      'Not for navigation',
    );
    expect((chart['sources'] as Map).keys, ['base']);
    for (final layer in chart['layers'] as List) {
      expect((layer as Map)['source'], anyOf(isNull, 'base'));
    }
    final topo = await bundledStyles().load('topo', const StyleContext());
    expect(StyleInfo.fromStyle("topo", topo).disclaimer, isNull);
  });

  test('style info and picking a style for the app brightness', () async {
    final registry = bundledStyles();
    expect((await registry.info('dark')).isDark, isTrue);
    expect((await registry.info('topo')).isDark, isFalse);
    expect((await registry.info('chart')).disclaimer, 'Not for navigation');

    expect(await registry.forBrightness(Brightness.dark), 'dark');
    expect(
      await registry.forBrightness(Brightness.light, preferred: 'topo'),
      'topo',
    );
    // A dark preference in light mode falls back to a light,
    // general-purpose style (never the chart).
    final light = await registry.forBrightness(
      Brightness.light,
      preferred: 'dark',
    );
    expect((await registry.info(light)).isDark, isFalse);
    expect(light, isNot('chart'));
  });

  test('bundled styles load and resolve', () async {
    final registry = bundledStyles();
    final ids = await registry.available();
    expect(ids, contains('topo'));
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
