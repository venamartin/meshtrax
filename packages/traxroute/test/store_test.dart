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

  /// The names and contents in a plain tar.
  Map<String, String> tarContents(File tar) {
    final b = tar.readAsBytesSync();
    final out = <String, String>{};
    var at = 0;
    while (at + 512 <= b.length && b.sublist(at, at + 512).any((x) => x != 0)) {
      final h = b.sublist(at, at + 512);
      final name = String.fromCharCodes(h.sublist(0, h.indexOf(0)));
      final size = int.parse(
        String.fromCharCodes(h.sublist(124, 135)).trim(),
        radix: 8,
      );
      out[name] = String.fromCharCodes(b.sublist(at + 512, at + 512 + size));
      at += 512 + (size + 511) ~/ 512 * 512;
    }
    return out;
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
    expect(
      tarContents(store.tileFile!).keys,
      unorderedEquals([shared, a1, b1]),
    );
  });

  test('removing a region keeps the tiles another region uses', () async {
    await store.install('b1', {
      'test/a': (await bundle('a', [shared, a1], 'b1'), 'sha-a'),
      'test/b': (await bundle('b', [shared, b1], 'b1'), 'sha-b'),
    });
    await store.remove('test/a');
    expect(store.regions.keys, ['test/b']);
    expect(tarContents(store.tileFile!).keys, [shared, b1]);
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
    final contents = tarContents(store.tileFile!);
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
      () => store.install('b1', {'test/evil': (gz, 'x')}),
      throwsFormatException,
    );
    expect(store.tileFile, isNull);
    expect(File('${tmp.path}/escape.gph').existsSync(), isFalse);
  });

  test('a failed install keeps what was there', () async {
    await store.install('b1', {
      'test/a': (await bundle('a', [shared, a1], 'b1'), 'sha-a'),
    });
    final before = tarContents(store.tileFile!);
    final broken = File('${tmp.path}/broken.tar.gz')
      ..writeAsBytesSync([0x1f, 0x8b, 1, 2, 3]);
    await expectLater(
      store.install('b1', {'test/b': (broken, 'sha-b')}),
      throwsA(anything),
    );
    expect(store.regions.keys, ['test/a']);
    expect(tarContents(store.tileFile!), before);
  });

  test('sizes, and no loose tiles on disk', () async {
    await store.install('b1', {
      'test/a': (await bundle('a', [shared, a1], 'b1'), 'sha-a'),
      'test/b': (await bundle('b', [shared, b1], 'b1'), 'sha-b'),
    });
    expect(store.sizeOf('test/a'), 'b1 $shared'.length + 'b1 $a1'.length);
    final files =
        Directory('${tmp.path}/routing')
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => f.path.split('/routing/').last)
            .toList()
          ..sort();
    expect(files, ['b1/tiles.tar', 'manifest.json']);
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
