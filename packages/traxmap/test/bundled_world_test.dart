import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

void main() {
  // Plain async tests: the asset bundle and file I/O are real.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('world'));
  tearDown(() => dir.delete(recursive: true));

  test('the bundled world map is copied once and reads as a pack', () async {
    final world = await openBundledWorld(dir);
    expect(world.kind, PackKind.world);
    expect(world.header.maxZoom, 5);
    expect(world.metadata['attribution'], 'Made with Natural Earth');
    final copied = world.file.lastModifiedSync();

    // The next start finds the same copy.
    final again = await openBundledWorld(dir);
    expect(again.file.path, world.file.path);
    expect(again.file.lastModifiedSync(), copied);
  });

  test('an older copy goes once the new one is in place', () async {
    final old = File('${dir.path}/world@000000000000.pmtiles')
      ..writeAsBytesSync([1, 2, 3]);
    final world = await openBundledWorld(dir);
    expect(old.existsSync(), isFalse);
    expect(dir.listSync().map((f) => f.uri.pathSegments.last), [
      world.file.uri.pathSegments.last,
    ]);
  });

  test('every style draws the world map below the region packs', () async {
    final world = await openBundledWorld(dir);
    final registry = bundledStyles();
    for (final id in await registry.available()) {
      final style = await registry.load(
        id,
        StyleContext(
          packs: {
            PackKind.world: [world],
          },
        ),
      );
      final url = ((style['sources'] as Map)['world'] as Map)['url'];
      expect(url, 'pmtiles://${Uri.file(world.file.path)}', reason: id);
      final layers = [
        for (final l in style['layers'] as List)
          if ((l as Map)['source'] == 'world') l,
      ];
      expect(layers, isNotEmpty, reason: id);
      for (final l in layers) {
        expect(l['maxzoom'], 6, reason: '$id ${l['id']}');
      }
    }
  });
}
