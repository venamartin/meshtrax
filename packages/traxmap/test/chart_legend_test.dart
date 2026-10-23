import 'package:flutter/material.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

/// The chart legend asks the chart styles how they draw each item, so each
/// item must be one the styles do draw, with symbols the sheets hold.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final id in ['charts-light', 'charts-dark']) {
    group(id, () {
      late LegendStyle style;
      setUpAll(() async => style = await LegendStyle.load(bundledStyles(), id));

      test('every sample is drawn by its layer', () {
        for (final item in ChartLegendItem.values) {
          for (final sample in [...item.samples, chartLegendGround]) {
            final layer = style.layer(sample.layer);
            expect(layer, isNotNull, reason: '$item: ${sample.layer}');
            expect(
              sample.drawnBy(layer!),
              isTrue,
              reason: '$item: ${sample.layer} ${sample.properties}',
            );
          }
        }
      });

      test('every symbol and pattern is on the sheet', () {
        final sheet = style.sprites!.sprites;
        for (final item in ChartLegendItem.values) {
          for (final sample in item.samples) {
            final layer = style.layer(sample.layer)!;
            final ctx = sample.context(layer);
            final name = switch (layer) {
              vt.SymbolThemeLayer(:final iconImage) when sample.text == null =>
                iconImage?.eval(ctx),
              vt.LineThemeLayer(:final pattern) => pattern?.eval(ctx),
              _ => null,
            };
            if (layer is vt.SymbolThemeLayer && sample.text == null) {
              expect(name, isNotNull, reason: '$item');
            }
            if (name != null) {
              expect(sheet, contains(name), reason: '$item: $name');
            }
          }
        }
      });

      test('each depth item spans one colour, and its own', () {
        final layer = style.layer('depth-area')! as vt.FillThemeLayer;
        Color at(double metres) => layer.color.eval(
          LegendSample('depth-area', {'drval1': metres}).context(layer),
        );
        final colours = <Color>[];
        for (final item in ChartLegendItem.values) {
          final (from, to) = item.depth ?? (null, null);
          if (from == null) continue;
          // The style steps up at `to`.
          expect(at(to == null ? 1000 : to - 0.1), at(from), reason: '$item');
          colours.add(at(from));
        }
        colours.add(at(-1));
        expect(colours.toSet(), hasLength(colours.length));
      });
    });
  }

  testWidgets('a legend symbol paints', (tester) async {
    final style = (await tester.runAsync(
      () => LegendStyle.load(bundledStyles(), 'charts-light'),
    ))!;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          children: [
            for (final item in ChartLegendItem.values)
              LegendSymbol(
                style: style,
                samples: item.samples,
                ground: chartLegendGround,
              ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.byType(LegendSymbol),
      findsNWidgets(ChartLegendItem.values.length),
    );
  });
}
