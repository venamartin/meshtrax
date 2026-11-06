import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/core.dart';

void main() {
  final file = DownloadFile(
    id: 'routing-test_a',
    name: 'A',
    region: 'test/a',
    url: Uri.parse('https://maps.example/routing/b1/test/a.tar.gz'),
    bytes: 3,
    sha256: 'ab',
    kind: 'routing',
    payload: {'build': 'b1', 'notice': 'n'},
  );

  test("the app's file survives a restart through its JSON, told from a pack",
      () {
    final json = file.toJson();
    expect(DownloadFile.isFile(json), isTrue);
    final back = DownloadFile.fromJson(json);
    expect(back.id, file.id);
    expect(back.name, file.name);
    expect(back.region, file.region);
    expect(back.url, file.url);
    expect(back.bytes, file.bytes);
    expect(back.sha256, file.sha256);
    expect(back.kind, file.kind);
    expect(back.payload, file.payload);

    final pack = PackIndexEntry(
      id: 'ri-osm',
      name: 'Rhode Island',
      kind: PackKind.osm,
      bbox: LatLngBounds.fromList([-72, 41, -71, 42]),
      bytes: 1,
      sha256: 'cd',
      buildDate: DateTime.utc(2026, 11, 6),
      schemaVersion: 1,
      url: Uri.parse('https://maps.example/ri.pmtiles'),
    );
    expect(DownloadFile.isFile(pack.toJson()), isFalse);
  });

  test('a snapshot tells a pack from a file', () {
    final download = PackDownload(
      file,
      PackDownloadState.downloaded,
      progress: 1,
      path: 'a.tar.gz',
    );
    expect(download.file, file);
    expect(download.entry, isNull);
    expect(download.id, file.id);
    expect(download.bytesDone, 3);
    expect(download.copyWith(state: PackDownloadState.installed).path, 'a.tar.gz');
  });
}
