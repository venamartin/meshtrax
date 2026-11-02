import 'dart:io';

import 'package:flutter/services.dart';
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
    expect(world.header.maxZoom, 7);
    expect(
      world.metadata['attribution'],
      'Made with Natural Earth; © GeoNames (CC BY 4.0)',
    );
    final copied = world.file.lastModifiedSync();

    // The next start finds the same copy.
    final again = await openBundledWorld(dir);
    expect(again.file.path, world.file.path);
    expect(again.file.lastModifiedSync(), copied);
  });

  test('world.id names the bundled map', () async {
    final data = await rootBundle.load('assets/world/world.pmtiles');
    final id = worldIdOf(data.buffer.asUint8List());
    expect(
      (await rootBundle.loadString('assets/world/world.id')).trim(),
      id,
      reason: 'write $id into assets/world/world.id',
    );
  });

  test('the copy stays when the folder lists it under another path', () async {
    // Windows lists `C:\app/maps` as `C:\app/maps\world@….pmtiles`, not the
    // `C:\app/maps/world@….pmtiles` written; a trailing slash does it here.
    final world = await openBundledWorld(Directory('${dir.path}/'));
    expect(world.file.existsSync(), isTrue);
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

  test('every style draws the base map wherever region packs do not', () async {
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
      final source = (style['sources'] as Map)['world'] as Map;
      expect(
        source['url'],
        'pmtiles://${Uri.file(world.file.path)}',
        reason: id,
      );
      // Left out where packs draw (GapFillProvider), except under charts:
      // they cover what they draw, and the base map's towns show beside.
      expect(
        source['ovm:mask'],
        id.startsWith('charts') ? isFalse : isNull,
        reason: id,
      );
      final layers = [
        for (final l in style['layers'] as List)
          if ((l as Map)['source'] == 'world') l,
      ];
      expect(layers, isNotEmpty, reason: id);
      for (final l in layers) {
        expect(l['maxzoom'], isNull, reason: '$id ${l['id']}');
      }
    }
  });
}
