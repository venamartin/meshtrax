import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

/// The roads legend asks the OSM styles how they draw each line and shield,
/// so each sample must be one the styles draw, and each shield on the sheets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final id in ['osm-light', 'osm-dark']) {
    test('$id draws every roads legend item', () async {
      final style = await LegendStyle.load(bundledStyles(), id);
      final sheet = style.sprites!.sprites;
      for (final item in RoadLegendItem.values) {
        for (final sample in item.samples) {
          final layer = style.layer(sample.layer);
          expect(layer, isNotNull, reason: '$item ${sample.layer}');
          expect(sample.drawnBy(layer!), isTrue, reason: '$item');
          if (layer is vt.SymbolThemeLayer) {
            final ctx = sample.context(layer);
            expect(
              sheet,
              contains(layer.iconImage!.eval(ctx)),
              reason: '$item',
            );
            expect(layer.textField.eval(ctx), sample.text, reason: '$item');
          }
        }
      }
    });
  }

  test(
    'shields: the route network picks the sign, the number its width',
    () async {
      final style = await LegendStyle.load(bundledStyles(), 'osm-light');
      final shield = style.layer('road-shield')! as vt.SymbolThemeLayer;
      String? icon(Map<String, Object?> properties) {
        final sample = LegendSample('road-shield', properties);
        return sample.drawnBy(shield)
            ? shield.iconImage!.eval(sample.context(shield))
            : null;
      }

      expect(
        icon({'route_1_network': 'US:I', 'route_1_ref': '5'}),
        'shield-interstate-2',
      );
      expect(
        icon({'route_1_network': 'US:I', 'route_1_ref': '405'}),
        'shield-interstate-3',
      );
      expect(
        icon({'route_1_network': 'US:US', 'route_1_ref': '101'}),
        'shield-us-3',
      );
      expect(
        icon({
          'network': 'us-state',
          'route_1_network': 'US:CA',
          'route_1_ref': '1',
        }),
        'shield-state-2',
      );
      // Express lanes, unknown networks and long refs get no shield.
      expect(
        icon({'route_1_network': 'US:I:Express', 'route_1_ref': '10'}),
        isNull,
      );
      expect(icon({'network': 'road', 'route_1_ref': '1D'}), isNull);
      expect(icon({'route_1_network': 'US:I', 'route_1_ref': '1234'}), isNull);
    },
  );
}
