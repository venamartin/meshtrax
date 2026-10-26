import 'dart:io';

import 'package:test/test.dart';
import 'package:traxroute/src/store/tar.dart';
import 'package:traxroute/traxroute.dart';

void main() {
  late Directory tmp;
  late RoutingStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('traxroute');
    store = RoutingStore(Directory('${tmp.path}/routing'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  /// A gzipped bundle of [tiles], each holding [content].
  Future<File> bundle(String name, List<String> tiles, String content) async {
    final src = Directory('${tmp.path}/src-$name');
    for (final t in tiles) {
      File('${src.path}/$t')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('$content $t');
    }
    final tar = File('${tmp.path}/$name.tar');
    await writeTar(tar, src, tiles);
    final gz = File('${tmp.path}/$name.tar.gz')
      ..writeAsBytesSync(gzip.encode(tar.readAsBytesSync()));
    return gz;
  }

  /// The names and contents in a plain tar, read back by unpacking it.
  Future<Map<String, String>> tarContents(File tar) async {
    final gz = File('${tar.path}.gz')
      ..writeAsBytesSync(gzip.encode(tar.readAsBytesSync()));
    final out = Directory('${tmp.path}/check-${tar.hashCode}');
    final names = await extractTiles(gz, out);
    return {
      for (final n in names) n: File('${out.path}/$n').readAsStringSync(),
    };
  }

  const shared = '0/002/898.gph';
  const a1 = '2/000/734/688.gph';
  const b1 = '2/000/736/128.gph';

  test('two regions share tiles in one combined file', () async {
    await store.install('b1', {
      'test/a': (await bundle('a', [shared, a1], 'b1'), 'sha-a'),
    });
    await store.install('b1', {
      'test/b': (await bundle('b', [shared, b1], 'b1'), 'sha-b'),
    });
    expect(store.build, 'b1');
    expect(store.regions.keys, unorderedEquals(['test/a', 'test/b']));
    expect((await tarContents(store.tileFile!)).keys, [shared, a1, b1]);
  });

  test('removing a region keeps the tiles another region uses', () async {
    await store.install('b1', {
      'test/a': (await bundle('a', [shared, a1], 'b1'), 'sha-a'),
      'test/b': (await bundle('b', [shared, b1], 'b1'), 'sha-b'),
    });
    await store.remove('test/a');
    expect(store.regions.keys, ['test/b']);
    expect((await tarContents(store.tileFile!)).keys, [shared, b1]);
    await store.remove('test/b');
    expect(store.tileFile, isNull);
  });

  test('a new build replaces every region in one step', () async {
    await store.install('b1', {
      'test/a': (await bundle('a1', [shared, a1], 'old'), 'sha-a1'),
    });
    await store.install('b2', {
      'test/a': (await bundle('a2', [shared, a1], 'new'), 'sha-a2'),
    });
    expect(store.build, 'b2');
    final contents = await tarContents(store.tileFile!);
    expect(contents[shared], 'new $shared');
    expect(Directory('${tmp.path}/routing/b1').existsSync(), isFalse);
  });

  test(
    'what to download: new regions, and everything on a new build',
    () async {
      await store.install('b1', {
        'test/a': (await bundle('a', [shared, a1], 'b1'), 'sha-a'),
      });
      RoutingCatalog catalog(String build, String shaA) =>
          RoutingCatalog(build, '3.9.1', null, {
            'test/a': RoutingBundle(Uri.parse('a'), 1, 1, shaA),
            'test/b': RoutingBundle(Uri.parse('b'), 1, 1, 'sha-b'),
          });
      expect(store.downloadsFor(catalog('b1', 'sha-a'), {'test/b'}), {
        'test/b',
      });
      expect(store.downloadsFor(catalog('b2', 'sha-a'), {'test/b'}), {
        'test/a',
        'test/b',
      });
      expect(store.downloadsFor(catalog('b1', 'sha-a-new'), {}), {'test/a'});
      expect(store.downloadsFor(catalog('b1', 'sha-a'), {'test/c'}), isEmpty);
    },
  );

  test('a bundle with anything but tile paths is refused', () async {
    final src = Directory('${tmp.path}/evil')..createSync();
    File('${src.path}/x').writeAsStringSync('x');
    final tar = File('${tmp.path}/evil.tar');
    await writeTar(tar, src, ['x']);
    final bytes = tar.readAsBytesSync();
    bytes.setAll(0, '../../escape.gph'.codeUnits + [0]);
    final gz = File('${tmp.path}/evil.tar.gz')
      ..writeAsBytesSync(gzip.encode(bytes));
    expect(
      () => extractTiles(gz, Directory('${tmp.path}/out')),
      throwsFormatException,
    );
    expect(File('${tmp.path}/escape.gph').existsSync(), isFalse);
  });

  test("reads the catalogue's routing entry", () {
    final c = RoutingCatalog.fromIndex({
      'routing': {
        'valhalla-3.9': {
          'engine': 'valhalla',
          'engine_version': '3.9.1',
          'build': '2026102502',
          'build_date': '2026-10-26',
          'regions': {
            'test/san-juans': {
              'url': 'routing/valhalla-3.9/2026102502/test/san-juans.tar.gz',
              'bytes': 7846913,
              'unpacked_bytes': 17428480,
              'sha256': 'da8b',
            },
          },
        },
        'valhalla-4.0': {'build': 'x', 'regions': {}},
      },
    }, Uri.parse('http://127.0.0.1:8770/index.json'))!;
    expect(c.build, '2026102502');
    expect(
      c.regions['test/san-juans']!.url.toString(),
      'http://127.0.0.1:8770/routing/valhalla-3.9/2026102502/test/san-juans.tar.gz',
    );
    expect(RoutingCatalog.fromIndex({'packs': []}, Uri()), isNull);
  });
}
