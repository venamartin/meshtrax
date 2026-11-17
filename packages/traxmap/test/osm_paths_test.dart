import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

/// OSM `class=path` holds trails and city paths alike. Trails keep their bold
/// dashed line; paved footways, steps, pedestrian streets and cycleways are
/// thin walkways from zoom 14 (Martin, 2026-11-17).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final id in ['osm-light', 'osm-dark']) {
    test('$id draws paved paths as walkways and trails as trails', () async {
      final style = await LegendStyle.load(bundledStyles(), id);

      List<String> lines(
        String subclass,
        double zoom, {
        String? surface,
        String type = 'LineString',
      }) {
        final ctx = vt.EvalContext(
          zoom: zoom,
          properties: {
            'class': 'path',
            'subclass': subclass,
            'surface': ?surface,
          },
          geometryType: type,
        );
        bool draws(vt.ThemeLayer layer) {
          final v = layer.filter(ctx);
          return layer.minzoom <= zoom &&
              layer.maxzoom > zoom &&
              v != null &&
              v != false;
        }

        return [
          for (final id in ['walkway', 'trail-halo', 'trail'])
            if (draws(style.layer(id)!)) id,
        ];
      }

      const trail = ['trail-halo', 'trail'];
      for (final zoom in [14.0, 16.0, 17.0]) {
        for (final subclass in ['footway', 'steps', 'pedestrian', 'cycleway']) {
          for (final surface in [null, 'paved']) {
            expect(lines(subclass, zoom, surface: surface), [
              'walkway',
            ], reason: '$subclass $surface z$zoom');
          }
        }
        expect(lines('footway', zoom, surface: 'unpaved'), trail);
        for (final subclass in ['path', 'bridleway']) {
          for (final surface in [null, 'paved', 'unpaved']) {
            expect(
              lines(subclass, zoom, surface: surface),
              trail,
              reason: '$subclass $surface z$zoom',
            );
          }
        }
        expect(lines('platform', zoom), isEmpty);
        expect(lines('corridor', zoom), isEmpty);
        // A pedestrian area (a plaza) gets no outline.
        expect(lines('pedestrian', zoom, type: 'Polygon'), isEmpty);
      }

      for (final zoom in [11.0, 13.0, 13.9]) {
        for (final subclass in ['footway', 'steps', 'pedestrian', 'cycleway']) {
          expect(lines(subclass, zoom), isEmpty, reason: '$subclass z$zoom');
        }
        expect(lines('footway', zoom, surface: 'unpaved'), trail);
        expect(lines('path', zoom), trail);
      }
    });
  }
}
