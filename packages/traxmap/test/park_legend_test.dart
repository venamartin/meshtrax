import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

/// The park legend asks the OSM styles how they draw each feature, so each
/// must be one the styles draw, with an icon the sheets hold.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final id in ['osm-light', 'osm-dark']) {
    test('$id draws every park legend item with its own icon', () async {
      final style = await LegendStyle.load(bundledStyles(), id);
      final sheet = style.sprites!.sprites;
      final icons = <String>{};
      for (final item in ParkLegendItem.values) {
        final layer = style.layer(item.sample.layer);
        expect(layer, isA<vt.SymbolThemeLayer>(), reason: '$item');
        expect(item.sample.drawnBy(layer!), isTrue, reason: '$item');
        final name = (layer as vt.SymbolThemeLayer).iconImage!.eval(
          item.sample.context(layer),
        );
        expect(sheet, contains(name), reason: '$item');
        icons.add(name);
      }
      expect(icons, hasLength(ParkLegendItem.values.length));
      expect(style.layer(parkLegendGround.layer), isNotNull);
    });
  }
}
