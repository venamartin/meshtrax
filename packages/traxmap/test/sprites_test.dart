import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/src/renderer/flutter_map_renderer.dart';
import 'package:traxmap/traxmap.dart';

/// The sprite sheets (tool/make_sprites.py) and the icons the styles name.
void main() {
  Map<String, Object?> json(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

  final light = json('assets/sprites/light@2x.json');
  final dark = json('assets/sprites/dark@2x.json');

  test('the light and dark sheets hold the same symbols', () {
    expect(dark.keys.toSet(), light.keys.toSet());
  });

  /// Every combination of [values], as feature properties.
  List<Map<String, Object?>> combos(Map<String, List<Object?>> values) {
    var out = [<String, Object?>{}];
    values.forEach((key, options) {
      out = [
        for (final props in out)
          for (final v in options) {...props, key: ?v},
      ];
    });
    return out;
  }

  const fills = [
    ('red', null),
    ('green', null),
    ('yellow', null),
    ('white', null),
    ('black', null),
    ('orange', null),
    ('grey', null),
    (null, null),
    ('green,red,green', 'horizontal_stripes'),
    ('red,white', 'vertical_stripes'),
    ('black,yellow,black', 'horizontal_stripes'),
    ('white,orange', 'horizontal_stripes'),
    ('white,red,white,red,red', 'border_stripe'),
    ('red,green', 'diagonal_stripes'),
  ];
  List<Map<String, Object?>> withFills(List<Map<String, Object?>> base) => [
    for (final props in base)
      for (final (colours, pattern) in fills)
        {
          ...props,
          'colours': ?colours,
          'colour': ?colours?.split(',').first,
          'colour_pattern': ?pattern,
        },
  ];

  // Feature properties per source layer, as traxmapmaker writes them,
  // with values the sheets have no symbol for.
  final features = <String, List<Map<String, Object?>>>{
    'nav_aid': withFills(
      combos({
        'kind': ['buoy', 'beacon'],
        'shape': [
          'conical',
          'can',
          'spherical',
          'pillar',
          'spar',
          'barrel',
          'super-buoy',
          'ice',
          'stake',
          'withy',
          'tower',
          'lattice',
          'pile',
          'cairn',
          'buoyant',
          null,
        ],
        'side': ['port', 'starboard', null],
        'category': ['lateral', 'special', 'safe_water', null],
      }),
    ),
    'aid_extra': withFills(
      combos({
        'class': ['DAYMAR', 'TOPMAR', 'FOGSIG'],
        'shape': [
          'square',
          'triangle_point_up',
          'rhombus',
          'rectangle_vertical',
          'board',
          'two_cones_up',
          'sphere',
          'x_shape',
          'flag',
          'besom_point_up',
          'other_shape',
          null,
        ],
      }),
    ),
    'light': combos({
      'colour': ['red', 'green', 'white', 'yellow', 'blue', null],
    }),
    'hazard': combos({
      'kind': ['wreck', 'rock', 'obstruction', null],
      'category': [
        'dangerous',
        'hull_showing',
        'mast_showing',
        'foul_area',
        'fish_haven',
        null,
      ],
      'water_level': ['awash', 'covers_uncovers', 'dry', 'submerged', null],
      'dangerous': [1, null],
    }),
    'regulated_area': combos({
      'class': [
        'ACHARE',
        'ACHBRT',
        'CTNARE',
        'RESARE',
        'CBLARE',
        'PIPARE',
        'MIPARE',
        'DMPGRD',
      ],
      'restriction': ['entry', 'anchoring', 'fishing', 'other', null],
      'anchor': [1, null],
    }),
    'route': combos({
      'class': ['TSSLPT', 'DWRTPT', 'RCTLPT', 'FAIRWY'],
      'anchor': [1, null],
      'orient': [45, null],
    }),
    'tide_current': combos({
      'class': ['TS_FEB', 'CURENT', 'WATTUR'],
      'category': ['flood', 'ebb', 'other', null],
      'orient': [200, null],
    }),
    'landmark': combos({
      'class': ['LNDMRK', 'SILTNK', 'BUISGL'],
      'category': [
        'windmotor',
        'tower',
        'mast',
        'chimney',
        'spire_minaret',
        'dome',
        'flagstaff',
        'tank',
        'cairn',
        null,
      ],
      'function': ['church', 'radio', 'light_support', null],
      'conspicuous': [1, null],
    }),
    'mountain_peak': [
      {'name': 'Bare Rock', 'ele_ft': 1200, 'ele': 366},
    ],
  };

  for (final id in ['charts-light', 'charts-dark', 'osm-light', 'osm-dark']) {
    test('$id names only symbols on its sheet', () {
      final style = json('assets/styles/$id.json');
      final sheet = id.endsWith('dark') ? 'dark' : 'light';
      expect(style['sprite'], '{sprite}/$sheet');
      final theme = vt.ThemeReader().read(style);
      final names = (sheet == 'dark' ? dark : light).keys.toSet();
      final icons = theme.layers.whereType<vt.SymbolThemeLayer>().where(
        (l) => l.iconImage != null,
      );
      expect(icons, isNotEmpty);
      for (final layer in icons) {
        final drawn = <String>{};
        for (final props in features[layer.sourceLayer]!) {
          final ctx = vt.EvalContext(
            zoom: 14,
            properties: props,
            geometryType: 'Point',
          );
          if (layer.filter(ctx) != true) continue;
          final name = layer.iconImage!.eval(ctx);
          expect(names, contains(name), reason: '${layer.id} $props');
          drawn.add(name);
        }
        expect(drawn, isNotEmpty, reason: '${layer.id} draws nothing');
      }
      for (final layer in theme.layers.whereType<vt.LineThemeLayer>()) {
        final pattern = layer.pattern;
        if (pattern == null) continue;
        final name = pattern.eval(vt.EvalContext(zoom: 14, properties: {}));
        expect(names, contains(name), reason: layer.id);
      }
    });
  }

  testWidgets('the renderer reads the style\'s sheet from the asset bundle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FlutterMapRenderer(
          style: {
            'version': 8,
            'sprite': '$bundledSprites/light',
            'sources': <String, Object?>{},
            'layers': <Object?>[],
          },
          initialCamera: MapCamera(center: LatLng(41.5, -71.3), zoom: 12),
        ),
      ),
    );
    // Reading the asset and decoding the image are real async work.
    final layer = find.byType(vt.VectorTileLayer);
    for (var i = 0; i < 50 && layer.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    final sprites = tester.widget<vt.VectorTileLayer>(layer).sprites;
    expect(sprites?['buoy-can-green'], isNotNull);
    expect(sprites?.pixelRatio, 2);
  });
}
