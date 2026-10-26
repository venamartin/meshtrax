import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:traxpoi/traxpoi.dart';

/// Builds files from the schema the way traxmapmaker's build does: run the
/// schema file, fill the tables, index the names, stamp the version.
File buildPoints(Directory dir, String name) {
  final file = File('${dir.path}/$name');
  final db = sqlite3.open(file.path);
  db.execute(File('lib/src/db/points_schema.drift').readAsStringSync());
  db.execute("INSERT INTO meta VALUES ('build', '2026102502')");
  const places = [
    (1, 'historic=mine', 'Camp Bird Mine', 37.9706, -107.7253, 1),
    (2, 'natural=peak', 'Mount Sneffels', 38.0038, -107.7923, 1),
    (3, 'mountain_pass=yes', 'Imogene Pass', 37.9314, -107.7342, 1),
    (4, 'natural=peak', 'Castle Rock', 37.9000, -107.7000, 0),
    (5, 'natural=peak', 'Castle Rock', 39.3722, -104.8561, 0),
    (6, 'waterway=waterfall', 'Bear Creek Falls', 38.0045, -107.6626, 0),
    (7, 'waterway=waterfall', 'Box Cañon Falls', 38.0179, -107.6727, 1),
  ];
  for (final (id, kind, name, lat, lon, rank) in places) {
    db.execute(
      'INSERT INTO place (id, kind, name, lat, lon, sources, rank) '
      "VALUES (?, ?, ?, ?, ?, 'osm', ?)",
      [id, kind, name, lat, lon, rank],
    );
    db.execute('INSERT INTO place_area VALUES (?, ?, ?, ?, ?)', [
      id,
      lat,
      lat,
      lon,
      lon,
    ]);
  }
  const features = [
    (1, 'place=town', 'Ouray', 38.0228, -107.6714),
    (2, 'waterway=river', 'Uncompahgre River', 38.0300, -107.6750),
    (3, 'natural=valley', 'Yankee Boy Basin', 37.9930, -107.7700),
  ];
  for (final (id, kind, name, lat, lon) in features) {
    db.execute(
      'INSERT INTO feature (id, kind, name, lat, lon) '
      'VALUES (?, ?, ?, ?, ?)',
      [id, kind, name, lat, lon],
    );
  }
  var nameId = 0;
  void addName(int? placeId, int? featureId, String name, String role) =>
      db.execute('INSERT INTO name VALUES (?, ?, ?, ?, ?, ?)', [
        ++nameId,
        placeId,
        featureId,
        name,
        normalizeName(name, NameRules.places),
        role,
      ]);
  for (final p in places) {
    addName(p.$1, null, p.$3, 'main');
  }
  for (final f in features) {
    addName(null, f.$1, f.$3, 'main');
  }
  addName(2, null, 'Mount Sneffels (Colorado)', 'redirect');
  db.execute("INSERT INTO name_search (name_search) VALUES ('rebuild')");
  db.execute(
    "INSERT INTO wiki VALUES (1, 'Camp Bird Mine', 'A gold mine near Ouray.')",
  );
  db.execute('INSERT INTO photo VALUES (1, ?, 219, 320, ?, ?, ?, NULL)', [
    [0x52, 0x49, 0x46, 0x46],
    'Camp_Bird.jpg',
    'A. Photographer',
    'CC BY 3.0',
  ]);
  db.execute('PRAGMA user_version = 1');
  db.close();
  return file;
}

File buildAddresses(Directory dir) {
  final file = File('${dir.path}/addresses.sqlite');
  final db = sqlite3.open(file.path);
  db.execute(File('lib/src/db/addresses_schema.drift').readAsStringSync());
  for (final (id, name, city) in [
    (1, 'Main Street', 'Ouray'),
    (2, 'Second Street', 'Ouray'),
  ]) {
    db.execute("INSERT INTO street VALUES (?, ?, ?, ?, '81427')", [
      id,
      name,
      normalizeName(name, NameRules.addresses),
      city,
    ]);
  }
  db.execute('INSERT INTO address VALUES (1, 1, ?, NULL, 38.0227, -107.6712)', [
    '612',
  ]);
  db.execute('INSERT INTO address VALUES (2, 2, ?, NULL, 38.0240, -107.6720)', [
    '320',
  ]);
  db.execute("INSERT INTO street_search (street_search) VALUES ('rebuild')");
  db.execute('PRAGMA user_version = 1');
  db.close();
  return file;
}

void main() {
  // One database per region file is intended.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late PoiRegion region;
  const ouray = GeoPoint(38.0228, -107.6714);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('traxpoi');
    region = PoiRegion.open(
      points: buildPoints(dir, 'points.sqlite'),
      addresses: buildAddresses(dir),
    );
  });
  tearDown(() async {
    await region.close();
    dir.deleteSync(recursive: true);
  });

  Future<String?> top(String query, {GeoPoint? near}) async =>
      (await region.searchNames(query, near: near)).firstOrNull?.name;

  test('finds places despite typos', () async {
    expect(await top('Camp Brd Mine'), 'Camp Bird Mine');
    expect(await top('mt sneffles'), 'Mount Sneffels');
    expect(await top('imogine pass'), 'Imogene Pass');
  });

  test('accents and abbreviations do not matter', () async {
    expect(await top('box canon falls'), 'Box Cañon Falls');
    expect(await top('Bear Ck Falls'), 'Bear Creek Falls');
  });

  test('a word still being typed matches the start of a name', () async {
    expect(await top('imog'), 'Imogene Pass');
    expect(await top('im'), 'Imogene Pass');
  });

  test('search-only names are found', () async {
    final r = (await region.searchNames('ouray')).first;
    expect(
      (r.name, r.type, r.kind),
      ('Ouray', ResultType.feature, 'place=town'),
    );
    expect(await top('yankee boy'), 'Yankee Boy Basin');
  });

  test('alternate names lead to the place', () async {
    final r = await region.searchNames('sneffels colorado');
    expect(r.first.name, 'Mount Sneffels');
    expect(r.where((x) => x.name == 'Mount Sneffels'), hasLength(1));
  });

  test('the nearer of two equal matches comes first', () async {
    final r = await region.searchNames('castle rock', near: ouray);
    expect(r.first.point.lat, 37.9);
    expect(r[1].point.lat, 39.3722);
    expect(r.first.km, lessThan(20));
  });

  test('nothing for words that match no name', () async {
    expect(await region.searchNames('zzzz qqqq'), isEmpty);
  });

  test('addresses: exact number, street with typos', () async {
    final r = await region.searchAddresses('612 Main St Ouray', near: ouray);
    expect(r.single.name, '612 Main Street, Ouray, 81427');
    expect((await region.searchAddresses('612 Mian Street')).single.id, 1);
    expect(await region.searchAddresses('999 Main St'), isEmpty);
    expect(await region.searchAddresses('Main St'), isEmpty);
  });

  test('places in a box, for the map icons', () async {
    final r = await region.placesIn(
      north: 38.1,
      south: 37.75,
      east: -107.45,
      west: -107.95,
    );
    expect(r.map((p) => p.id), containsAll([1, 2, 3, 4, 6, 7]));
    expect(r.map((p) => p.id), isNot(contains(5)));
  });

  test('a place with its article and photo', () async {
    final d = (await region.detail(1))!;
    expect(d.place.name, 'Camp Bird Mine');
    expect(d.wiki!.summary, 'A gold mine near Ouray.');
    expect(
      (d.photo!.author, d.photo!.licence),
      ('A. Photographer', 'CC BY 3.0'),
    );
    expect((await region.detail(2))!.photo, isNull);
    expect(await region.meta('build'), '2026102502');
  });

  test('one place in two regions appears once', () async {
    final other = PoiRegion.open(points: buildPoints(dir, 'other.sqlite'));
    addTearDown(other.close);
    final r = await searchRegions([region, other], 'Camp Bird Mine');
    expect(r.where((x) => x.name == 'Camp Bird Mine'), hasLength(1));
  });

  test('a file from a newer schema is refused', () async {
    final file = buildPoints(dir, 'newer.sqlite');
    final db = sqlite3.open(file.path)..execute('PRAGMA user_version = 2');
    db.close();
    final newer = PoiRegion.open(points: file);
    addTearDown(newer.close);
    expect(newer.searchNames('camp bird'), throwsA(anything));
  });
}
