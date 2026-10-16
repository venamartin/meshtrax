import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/core.dart';

import 'support/fake_pmtiles.dart';

/// The core library must stay pure Dart: no Flutter, so it runs in
/// isolates, background services and tools.
void main() {
  test('core imports nothing from Flutter', () {
    final seen = <String>{};
    final offending = <String>[];
    void visit(String path) {
      if (!seen.add(path)) return;
      final source = File(path).readAsStringSync();
      for (final m in RegExp(
        r'''^(?:import|export)\s+'([^']+)';''',
        multiLine: true,
      ).allMatches(source)) {
        final uri = m.group(1)!;
        if (uri.startsWith('package:flutter') ||
            uri == 'dart:ui' ||
            uri.startsWith('package:flutter_map')) {
          offending.add('$path → $uri');
        } else if (!uri.contains(':')) {
          visit(File(path).parent.uri.resolve(uri).toFilePath());
        }
      }
    }

    visit('lib/core.dart');
    expect(seen.length, greaterThan(5));
    expect(offending, isEmpty);
  });

  test('styles load from a directory without Flutter assets', () async {
    final registry = StyleRegistry(
      DirectoryStyleSource(Directory('assets/styles')),
    );
    expect(await registry.available(), hasLength(6));
    expect(await registry.styleFor(MapType.charts, dark: true), 'charts-dark');
    expect(
      (await registry.info('charts-light')).disclaimer,
      'Not for navigation',
    );
    final usgs = await registry.load('usgs-light', const StyleContext());
    expect(usgs['version'], 8);
  });

  test('PackManager reports installs and deletes', () async {
    final tmp = await Directory.systemTemp.createTemp('traxmap');
    addTearDown(() => tmp.delete(recursive: true));
    final manager = PackManager(Directory('${tmp.path}/packs'));
    addTearDown(manager.close);
    var changes = 0;
    final sub = manager.changes.listen((_) => changes++);
    addTearDown(sub.cancel);

    final src = File('${tmp.path}/a.pmtiles')..writeAsBytesSync(fakePmTiles());
    final pack = await manager.install(src);
    await manager.delete(pack);
    await Future<void>.delayed(Duration.zero);
    expect(changes, 2);
  });
}
