import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxwater/traxwater.dart';

import 'support/fixture.dart';

const _build = '2026112401';
const _a = 'charts/us/a', _b = 'charts/us/b';

void main() {
  late Directory tmp;
  late WaterStore store;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('water_store');
    store = WaterStore(Directory('${tmp.path}/store'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  final south = tileBytes('monterey', 232, 506);
  final north = tileBytes('monterey', 232, 507);

  File bundle(String name, Map<String, Uint8List> entries, {int type = 0x30}) {
    final f = File('${tmp.path}/$name.tar.gz');
    final tar = BytesBuilder();
    for (final MapEntry(:key, :value) in entries.entries) {
      tar
        ..add(_header(key, value.length, type))
        ..add(value)
        ..add(Uint8List((512 - value.length % 512) % 512));
    }
    tar.add(Uint8List(1024));
    f.writeAsBytesSync(gzip.encode(tar.takeBytes()));
    return f;
  }

  WaterBundle entry(String sha) =>
      WaterBundle(Uri.parse('https://x/$sha'), 1, 1, sha, chartsSha256: 'c');

  test('reads the catalogue', () {
    final index = {
      'water_routing': {
        'wrm-2': {
          'build': _build,
          'build_date': '2026-11-24',
          'regions': {
            _a: {
              'url': 'water-routing/wrm-2/$_build/charts/us/a.tar.gz',
              'bytes': 10,
              'unpacked_bytes': 20,
              'sha256': 's',
              'tiles': 2,
              'charts_sha256': 'c',
              'attribution': 'NOAA Office of Coast Survey',
              'notice': 'Not for navigation.',
            },
          },
        },
      },
    };
    final c = WaterCatalog.fromIndex(
      index,
      Uri.parse('https://maps.example/index.json'),
    )!;
    expect(c.build, _build);
    expect(
      c.regions[_a]!.url.toString(),
      'https://maps.example/water-routing/wrm-2/$_build/charts/us/a.tar.gz',
    );
    expect(c.regions[_a]!.chartsSha256, 'c');
    expect(WaterCatalog.needsNewerApp(index), isFalse);
    expect(
      WaterCatalog.needsNewerApp({
        'water_routing': {'wrm-3': {}},
      }),
      isTrue,
    );
    expect(WaterCatalog.fromIndex({}, Uri()), isNull);
  });

  test('keeps a tile two areas share once', () async {
    await store.install(_build, {
      _a: (
        bundle('a', {'506_232.wrm': south, '507_232.wrm': north}),
        entry('sa'),
      ),
      _b: (bundle('b', {'507_232.wrm': north}), entry('sb')),
    });
    expect(store.build, _build);
    expect(store.tileKeys, {506 * 1440 + 232, 507 * 1440 + 232});
    expect(store.sizeOf(_a), south.length + north.length);
    expect(store.totalBytes, south.length + north.length);
    expect(store.regions[_b]!.chartsSha256, 'c');

    await store.remove(_a);
    expect(store.tileKeys, {507 * 1440 + 232});
    expect(File('${store.tileDir!.path}/506_232.wrm').existsSync(), isFalse);
    expect(WaterStore(store.root).regions.keys, [_b]);

    await store.remove(_b);
    expect(store.tileDir, isNull);
    expect(store.totalBytes, 0);
  });

  test('routes over the installed tiles', () async {
    await store.install(_build, {
      _a: (
        bundle('a', {'506_232.wrm': south, '507_232.wrm': north}),
        entry('sa'),
      ),
    });
    final args = FixtureSet('monterey').trips.first['args'] as List;
    final expected = tripOf(FixtureSet('monterey'), args.cast());
    final trip = WaterStore(store.root).route(
      pointOf(args.cast(), 'from'),
      pointOf(args.cast(), 'to'),
      options: optionsOf(args.cast()),
      when: DateTime.utc(2026, 11, 24),
    );
    expect(trip.distanceM, closeTo(expected.distanceM, 0.01));
  });

  test('refuses a bundle with anything but tiles of its build', () async {
    await store.install(_build, {
      _a: (bundle('a', {'507_232.wrm': north}), entry('sa')),
    });
    final otherBuild = Uint8List.fromList(south)
      ..setAll(26, '2026112402'.padRight(16, '\x00').codeUnits);
    for (final bad in [
      bundle('dir', {'506_232.wrm': south}, type: 0x35),
      bundle('pax', {'506_232.wrm': south}, type: 0x78),
      bundle('dot', {'./506_232.wrm': south}),
      bundle('other', {'readme.txt': south}),
      bundle('misnamed', {'506_233.wrm': south}),
      bundle('build', {'506_232.wrm': otherBuild}),
      bundle('both', {'506_232.wrm': south, 'x.wrm': north}),
    ]) {
      await expectLater(
        store.install(_build, {_b: (bad, entry('sb'))}),
        throwsFormatException,
      );
    }
    expect(store.regions.keys, [_a]);
    expect(store.tileKeys, {507 * 1440 + 232});
    expect(
      Directory(store.root.path).listSync().map((e) => e.uri.pathSegments),
      isNot(contains(contains('$_build.incoming'))),
    );
  });

  test('a new build replaces the old one', () async {
    await store.install(_build, {
      _a: (bundle('a', {'506_232.wrm': south}), entry('sa')),
      _b: (bundle('b', {'507_232.wrm': north}), entry('sb')),
    });
    const next = '2026120101';
    final newer = Uint8List.fromList(north)
      ..setAll(26, next.padRight(16, '\x00').codeUnits);
    await store.install(next, {
      _b: (bundle('b2', {'507_232.wrm': newer}), entry('sb2')),
    });
    expect(store.build, next);
    expect(store.regions.keys, [_b]);
    expect(Directory('${store.root.path}/$_build').existsSync(), isFalse);

    final catalog = WaterCatalog('2026120102', null, {
      _a: entry('sa3'),
      _b: entry('sb3'),
    });
    expect(store.downloadsFor(catalog, {}), {_b});
    expect(store.downloadsFor(catalog, {_a, 'charts/us/none'}), {_a, _b});
    expect(
      store.downloadsFor(WaterCatalog(next, null, {_b: entry('sb2')}), {}),
      isEmpty,
    );
    expect(
      store.downloadsFor(WaterCatalog(next, null, {_b: entry('re-cut')}), {}),
      {_b},
    );
  });
}

Uint8List _header(String name, int size, int type) {
  final h = Uint8List(512);
  void put(int at, String s) => h.setAll(at, ascii.encode(s));
  String octal(int v, int width) =>
      '${v.toRadixString(8).padLeft(width - 1, '0')}\u0000';
  put(0, name);
  put(100, octal(420, 8));
  put(108, octal(0, 8));
  put(116, octal(0, 8));
  put(124, octal(size, 12));
  put(136, octal(0, 12));
  put(148, '        ');
  h[156] = type;
  put(257, 'ustar\u0000');
  put(263, '00');
  final sum = h.fold<int>(0, (a, b) => a + b);
  put(148, '${sum.toRadixString(8).padLeft(6, '0')}\u0000 ');
  return h;
}
