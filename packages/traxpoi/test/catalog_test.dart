import 'package:test/test.dart';
import 'package:traxpoi/traxpoi.dart';

void main() {
  final base = Uri.parse('http://127.0.0.1:8770/index.json');

  test("reads the catalogue's poi entry", () {
    final c = PoiCatalog.fromIndex({
      'poi': {
        'schema_version': 1,
        'build': '2026102601',
        'build_date': '2026-10-26',
        'regions': {
          'test/san-juans': {
            'points': {
              'url':
                  'poi/v1/2026102601/test/san-juans/points-of-interest.sqlite.gz',
              'bytes': 1000,
              'unpacked_bytes': 3000,
              'sha256': 'aa',
            },
            'addresses': {
              'url': 'poi/v1/2026102601/test/san-juans/addresses.sqlite.gz',
              'bytes': 500,
              'unpacked_bytes': 1500,
              'sha256': 'bb',
            },
          },
          'test/points-only': {
            'points': {
              'url': 'p.gz',
              'bytes': 1,
              'unpacked_bytes': 2,
              'sha256': 'cc',
            },
          },
        },
      },
    }, base)!;
    expect(c.build, '2026102601');
    final sj = c.regions['test/san-juans']!;
    expect(
      sj.points!.url.toString(),
      'http://127.0.0.1:8770/poi/v1/2026102601/test/san-juans/points-of-interest.sqlite.gz',
    );
    expect(sj.addresses!.bytes, 500);
    expect(c.regions['test/points-only']!.addresses, isNull);
  });

  test('none, or a newer schema, is nothing to offer', () {
    expect(PoiCatalog.fromIndex({'packs': []}, base), isNull);
    expect(
      PoiCatalog.fromIndex({
        'poi': {'schema_version': 2, 'build': 'x', 'regions': {}},
      }, base),
      isNull,
    );
  });
}
