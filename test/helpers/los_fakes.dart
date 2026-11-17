import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:traxmap/traxmap.dart';

import 'package:meshtrax/services/map_packs_service.dart';

import '../../packages/traxlos/test/support/pmtiles_writer.dart';
import 'map_fakes.dart';

const _fixtures = 'packages/traxlos/test/fixtures';

/// Downloads asked for, never run.
class RecordingDownloads implements PackDownloader {
  final started = <String>[];

  @override
  Stream<PackDownload> get updates => const Stream.empty();
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(DownloadItem item) async => started.add(item.id);
  @override
  Future<void> pause(String id) async {}
  @override
  Future<void> resume(String id) async {}
  @override
  Future<void> cancel(String id) async {}
  @override
  Future<void> finish(String id, {String? error}) async {}
}

Map<String, Object?> _entry(
  String region,
  String id,
  String kind,
  int mb, [
  String? variant,
]) => {
  'id': id,
  'name': id,
  'kind': kind,
  'bbox': [-125.9, 35.0, -114.0, 42.1],
  'bytes': mb * 1000000,
  'sha256': '0' * 64,
  'build_date': '2026-10-21',
  'schema_version': 1,
  'url': 'https://maps.example/v1/$region/$id.pmtiles',
  'region': region,
  if (variant != null) ...{
    'variant': variant,
    'units': variant == '20ft' ? 'imperial' : 'metric',
    'interval': variant == '20ft' ? 20 : 10,
    'interval_unit': variant == '20ft' ? 'ft' : 'm',
  },
};

/// A map catalogue and region outlines (no network: every request is a
/// 404), with the real NorCal 20 ft contours tiles around Death Valley
/// installed when [contours] is set. Nevada's contours can be downloaded;
/// Mexico has none. [picker] replaces the region outlines.
Future<MapPacksService> losMaps(
  Directory tmp, {
  bool contours = true,
  bool catalogue = true,
  String? picker,
  PackDownloader? downloader,
  http.Client? client,
}) async {
  const norcal = 'north-america/us/california/norcal';
  const nevada = 'north-america/us/nevada';
  if (catalogue) {
    File('${tmp.path}/index.json').writeAsStringSync(
      jsonEncode({
        'generated': '2026-11-16T00:00:00Z',
        'schema_version': 1,
        'packs': [
          _entry(norcal, 'us-california-norcal-osm', 'osm', 447),
          _entry(
            norcal,
            'us-california-norcal-contours-20ft',
            'contours',
            504,
            '20ft',
          ),
          _entry(
            norcal,
            'us-california-norcal-contours-10m',
            'contours',
            310,
            '10m',
          ),
          _entry(nevada, 'us-nevada-contours-20ft', 'contours', 363, '20ft'),
          _entry(nevada, 'us-nevada-contours-10m', 'contours', 224, '10m'),
          _entry('north-america/mexico', 'mexico-osm', 'osm', 800),
        ],
      }),
    );
    if (picker != null) {
      File('${tmp.path}/picker.geojson').writeAsStringSync(picker);
    } else {
      File('packages/traxmap/test/support/picker.geojson')
          .copySync('${tmp.path}/picker.geojson');
    }
  }
  final packs = Directory('${tmp.path}/packs')..createSync(recursive: true);
  if (contours) installDeathValleyContours(packs);
  final maps = MapPacksService(
    manager: PackManager(packs),
    downloader: downloader ?? RecordingDownloads(),
    cacheDir: tmp,
    client: client ?? MockClient((_) async => http.Response('', 404)),
    styles: StyleRegistry(MemoryStyles()),
  );
  await maps.start();
  return maps;
}

/// The real tiles of packages/traxlos/test/fixtures (USGS 3DEP, public
/// domain) as the installed NorCal 20 ft contours pack.
void installDeathValleyContours(Directory packs) {
  const name = 'norcal-contours-20ft';
  final manifest = jsonDecode(
    File('$_fixtures/fixtures.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final pack = (manifest['packs'] as Map)[name] as Map<String, Object?>;
  writePmtiles(
    '${packs.path}/us-california-norcal-contours-20ft.pmtiles',
    {
      for (final t in (pack['tiles'] as List).cast<String>())
        (13, int.parse(t.split('/')[0]), int.parse(t.split('/')[1])): File(
          '$_fixtures/$name/13-${t.replaceAll('/', '-')}.mvt.gz',
        ).readAsBytesSync(),
    },
    Map<String, Object?>.from(pack['metadata'] as Map),
    leafSize: 8,
  );
}
