import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/src/renderer/flutter_map_renderer.dart';
import 'package:traxmap/traxmap.dart';

import 'support/fake_pmtiles.dart';

/// Styles held in memory: no asset bundle, so no fake-async hang in tests.
class _MemoryStyles implements StyleSource {
  final Map<String, Map<String, Object?>> styles;
  _MemoryStyles(this.styles);

  @override
  Future<List<String>> ids() async => styles.keys.toList()..sort();

  @override
  Future<Map<String, Object?>> load(String id) async => styles[id]!;
}

Pack _pack(String id, String kind, String attribution) => Pack(
  id: id,
  file: File('/packs/$id.pmtiles'),
  header: PmTilesHeader.parse(fakePmTiles()),
  metadata: {'kind': kind, 'attribution': attribution},
);

void main() {
  const camera = MapCamera(center: LatLng(36.75, -121.85), zoom: 10);

  testWidgets('onStyleLoaded hands the app credits and disclaimer', (
    tester,
  ) async {
    final registry = StyleRegistry(
      _MemoryStyles({
        'chart': {
          'version': 8,
          'name': 'Chart',
          'metadata': {'ovm:disclaimer': 'Not for navigation'},
          'sources': {
            'charts': {'type': 'vector', 'url': 'pmtiles://{pack:charts}'},
          },
          'layers': [
            {'id': 'bg', 'type': 'background'},
          ],
        },
      }),
    );
    MapStyleState? state;
    await tester.pumpWidget(
      MaterialApp(
        home: OfflineMapView(
          styleId: 'chart',
          // The osm pack is installed but unused by this style: not credited.
          packs: [
            _pack('r-charts', 'charts', 'NOAA Office of Coast Survey'),
            _pack('r-osm', 'osm', '© OpenStreetMap contributors'),
          ],
          initialCamera: camera,
          styleRegistry: registry,
          onStyleLoaded: (s) => state = s,
        ),
      ),
    );
    await tester.pump();
    expect(state, isNotNull);
    expect(state!.disclaimer, 'Not for navigation');
    expect(state!.info.name, 'Chart');
    expect(state!.credits, ['NOAA Office of Coast Survey']);
    expect(state!.packsInUse.map((p) => p.id), ['r-charts']);
    // The package draws no chrome of its own.
    expect(find.text('NOT FOR NAVIGATION'), findsNothing);
  });

  testWidgets('the base map fills the gaps unless its source opts out', (
    tester,
  ) async {
    final registry = StyleRegistry(
      _MemoryStyles({
        'streets': {
          'version': 8,
          'metadata': {
            'ovm:requires': ['osm'],
          },
          'sources': {
            'osm': {'type': 'vector', 'url': 'pmtiles://{pack:osm}'},
            'world': {'type': 'vector', 'url': 'pmtiles://{pack:world}'},
          },
          'layers': const [],
        },
        'charts': {
          'version': 8,
          'metadata': {
            'ovm:requires': ['charts'],
          },
          'sources': {
            'charts': {'type': 'vector', 'url': 'pmtiles://{pack:charts}'},
            'world': {
              'type': 'vector',
              'url': 'pmtiles://{pack:world}',
              'ovm:mask': false,
            },
          },
          'layers': const [],
        },
      }),
    );
    final packs = [
      _pack('r-osm', 'osm', '© OpenStreetMap contributors'),
      _pack('r-charts', 'charts', 'NOAA Office of Coast Survey'),
      _pack('world', 'world', 'Made with Natural Earth'),
    ];
    Future<FlutterMapRenderer> renderer(String styleId) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OfflineMapView(
            key: ValueKey(styleId),
            styleId: styleId,
            packs: packs,
            initialCamera: camera,
            styleRegistry: registry,
          ),
        ),
      );
      await tester.pump();
      return tester.widget(find.byType(FlutterMapRenderer));
    }

    final streets = await renderer('streets');
    expect(streets.coverageSources, {'osm'});
    expect(streets.fillSources, {'world'});
    final charts = await renderer('charts');
    expect(charts.coverageSources, {'charts'});
    expect(charts.fillSources, isEmpty);
  });

  test('camera project/unproject round-trips', () {
    const size = Size(400, 300);
    final p = const LatLng(36.6, -121.9);
    final back = camera.fromScreen(camera.toScreen(p, size), size);
    expect(back.latitude, closeTo(p.latitude, 1e-9));
    expect(back.longitude, closeTo(p.longitude, 1e-9));
    expect(camera.toScreen(camera.center, size), size.center(Offset.zero));
  });
}
