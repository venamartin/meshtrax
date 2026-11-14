import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';

import 'db/addresses_database.dart';
import 'db/points_database.dart';
import 'normalize.dart';
import 'search.dart';

enum ResultType { place, feature, address }

/// One search result: something to show in the list and route to.
class SearchResult {
  final ResultType type;
  final int id;
  final String name;

  /// The place or feature kind (`natural=peak`, `place=town`, …); `address`
  /// for addresses.
  final String kind;
  final GeoPoint point;

  /// How well the name matched what was typed, 0–100.
  final double match;

  /// Distance from the search's `near` point, when one was given.
  final double? km;

  /// The sort key (higher first).
  final double score;

  /// Identifies the same place in two regions' files.
  final String key;

  /// For a place without a name: the name of what it is next to, a named
  /// place or a park or village, to tell it apart ([PoiRegion.searchKinds]).
  final String? near;

  const SearchResult({
    required this.type,
    required this.id,
    required this.name,
    required this.kind,
    required this.point,
    required this.match,
    required this.km,
    required this.score,
    required this.key,
    this.near,
  });

  SearchResult withScore(double score) => SearchResult(
    type: type,
    id: id,
    name: name,
    kind: kind,
    point: point,
    match: match,
    km: km,
    score: score,
    key: key,
    near: near,
  );
}

/// A place with its article and photo, for the place sheet.
class PlaceDetail {
  final PlaceData place;
  final WikiData? wiki;
  final PhotoData? photo;

  const PlaceDetail(this.place, this.wiki, this.photo);
}

/// A region's downloaded "Points of interest" and "Addresses" files, either
/// of which may be missing.
class PoiRegion {
  final PointsDatabase? points;
  final AddressesDatabase? addresses;

  PoiRegion._(this.points, this.addresses);

  /// Opens the files on a background isolate, without writing to them.
  static PoiRegion open({File? points, File? addresses}) {
    QueryExecutor readOnly(File f) => NativeDatabase.createInBackground(
      f,
      setup: (db) => db.execute('PRAGMA query_only = ON'),
    );
    return PoiRegion._(
      points == null ? null : PointsDatabase(readOnly(points)),
      addresses == null ? null : AddressesDatabase(readOnly(addresses)),
    );
  }

  /// Places and features whose names match [query], typos included, best
  /// first. With [near], nearer matches rank higher. When the query names
  /// [kinds], a place of one of them ranks as [searchKinds] ranks it, and
  /// no name gets a lift for being typed exactly or for a notable place:
  /// "Gas Station" is then a word for a kind, not one place's name.
  Future<List<SearchResult>> searchNames(
    String query, {
    GeoPoint? near,
    int limit = 20,
    Map<String, double> kinds = const {},
  }) async {
    final db = points;
    if (db == null) return const [];
    final norm = normalizeName(query, NameRules.places);
    if (norm.isEmpty) return const [];
    final fts = trigramQuery(norm);
    final candidates = fts == null
        ? (await db.namePrefix('$norm%', 200).get()).map(
            (r) => (r.placeId, r.featureId, r.norm),
          )
        : (await db.nameCandidates(fts, 2000).get()).map(
            (r) => (r.placeId, r.featureId, r.norm),
          );

    // Each place's best-matching name (main or alternate).
    final best = <(int?, int?), (double, String)>{};
    for (final (placeId, featureId, candidate) in candidates) {
      final match = wordMatch(norm, candidate);
      if (match == 0) continue;
      final id = (placeId, featureId);
      if (match > (best[id]?.$1 ?? 0)) best[id] = (match, candidate);
    }
    // Among equal matches the name typed exactly goes first, so a common
    // word ("Yosemite") keeps its exact names in the cut below.
    final top = best.entries.toList()
      ..sort((a, b) {
        final byMatch = b.value.$1.compareTo(a.value.$1);
        if (byMatch != 0) return byMatch;
        return (b.value.$2 == norm ? 1 : 0) - (a.value.$2 == norm ? 1 : 0);
      });

    final results = <SearchResult>[];
    final queryWords = norm.split(' ').length;
    for (final MapEntry(key: (placeId, featureId), value: (match, matched))
        in top.take(limit * 5)) {
      final nameWords = matched.split(' ').length;
      final exact = matched == norm;
      if (placeId != null) {
        final p = await db.placeById(placeId).getSingle();
        final point = GeoPoint(p.lat, p.lon);
        final km = near?.kmTo(point);
        results.add(
          SearchResult(
            type: ResultType.place,
            id: p.id,
            name: p.name,
            kind: p.kind,
            point: point,
            match: match,
            km: km,
            score: switch (kinds[p.kind]) {
              final kindMatch? => _kindScore(kindMatch, km),
              null => rankScore(
                match: match,
                queryWords: queryWords,
                nameWords: nameWords,
                km: km,
                notability: kinds.isEmpty ? p.rank : 0,
                exact: exact && kinds.isEmpty,
              ),
            },
            key: _placeKey(p),
          ),
        );
      } else {
        final f = await db.featureById(featureId!).getSingle();
        final point = GeoPoint(f.lat, f.lon);
        final km = near?.kmTo(point);
        results.add(
          SearchResult(
            type: ResultType.feature,
            id: f.id,
            name: f.name,
            kind: f.kind,
            point: point,
            match: match,
            km: km,
            score: rankScore(
              match: match,
              queryWords: queryWords,
              nameWords: nameWords,
              km: km,
              notability: kinds.isEmpty && _towns.contains(f.kind) ? 1 : 0,
              exact: exact && kinds.isEmpty,
            ),
            key:
                '${f.kind}:${f.name}@${f.lat.toStringAsFixed(2)},${f.lon.toStringAsFixed(2)}',
          ),
        );
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  /// The places of the [kinds] a search names ([kindsNamed]) nearest to
  /// [near], named or not, nearest first: "toilets" finds the unnamed ones
  /// around you, which a name search can't.
  Future<List<SearchResult>> searchKinds(
    Map<String, double> kinds, {
    required GeoPoint near,
    int limit = 20,
  }) async {
    final db = points;
    if (db == null || kinds.isEmpty) return const [];
    // The nearest in a box around [near] that doubles until they are all
    // inside the circle within it (none outside can be nearer), or it
    // reaches about 300 km out.
    final cos = math.max(0.1, math.cos(near.lat * math.pi / 180));
    var found = <(PlaceData, double)>[];
    for (var half = 0.05; ; half *= 2) {
      final rows = await db
          .placesOfKindsIn(
            near.lat + half,
            near.lat - half,
            near.lon + half / cos,
            near.lon - half / cos,
            kinds.keys.toList(),
            near.lat,
            near.lon,
            cos * cos,
            limit,
          )
          .get();
      found = [
        for (final r in rows) (r.p, near.kmTo(GeoPoint(r.p.lat, r.p.lon))),
      ];
      if ((found.length == limit && found.last.$2 <= half * 111) || half >= 3) {
        break;
      }
    }
    found.sort((a, b) => a.$2.compareTo(b.$2));
    final nextTo = await _nearNames([
      for (final (p, _) in found)
        if (p.name.isEmpty) p,
    ]);
    return [
      for (final (p, km) in found)
        SearchResult(
          type: ResultType.place,
          id: p.id,
          name: p.name,
          kind: p.kind,
          point: GeoPoint(p.lat, p.lon),
          match: kinds[p.kind]!,
          km: km,
          score: _kindScore(kinds[p.kind]!, km),
          key: _placeKey(p),
          near: nextTo[p.id],
        ),
    ];
  }

  /// What each of the unnamed [places] is next to, by id: the nearest named
  /// place within 100 m that says where you are (not a rock, a spring or
  /// another toilet), else the nearest park or village within 250 m. Parks
  /// and villages are search-only names, found in one look over the area.
  Future<Map<int, String>> _nearNames(List<PlaceData> places) async {
    final db = points!;
    final near = <int, String>{};
    for (final p in places) {
      final here = GeoPoint(p.lat, p.lon);
      final cos = math.max(0.1, math.cos(p.lat * math.pi / 180));
      const half = 0.001;
      final rows = await db
          .namedPlacesIn(
            p.lat + half,
            p.lat - half,
            p.lon + half / cos,
            p.lon - half / cos,
            p.lat,
            p.lon,
            cos * cos,
            5,
          )
          .get();
      for (final r in rows) {
        if (_saysWhere(r.p.kind) &&
            here.kmTo(GeoPoint(r.p.lat, r.p.lon)) <= 0.1) {
          near[p.id] = r.p.name;
          break;
        }
      }
    }
    final rest = [
      for (final p in places)
        if (!near.containsKey(p.id)) p,
    ];
    if (rest.isEmpty) return near;
    const half = 0.003;
    final cos = math.max(0.1, math.cos(rest.first.lat * math.pi / 180));
    final features = await db
        .featuresOfKindsIn(
          rest.map((p) => p.lat).reduce(math.max) + half,
          rest.map((p) => p.lat).reduce(math.min) - half,
          rest.map((p) => p.lon).reduce(math.max) + half / cos,
          rest.map((p) => p.lon).reduce(math.min) - half / cos,
          _areaKinds.toList(),
        )
        .get();
    for (final p in rest) {
      final here = GeoPoint(p.lat, p.lon);
      FeatureData? best;
      var bestKm = 0.25;
      for (final f in features) {
        final km = here.kmTo(GeoPoint(f.lat, f.lon));
        if (km <= bestKm) (best, bestKm) = (f, km);
      }
      if (best != null) near[p.id] = best.name;
    }
    return near;
  }

  /// Addresses matching [query] ("816 Farmington Ave West Hartford"): the
  /// house number exactly, the street (and city or ZIP) with typos allowed.
  Future<List<SearchResult>> searchAddresses(
    String query, {
    GeoPoint? near,
    int limit = 20,
  }) async {
    final db = addresses;
    if (db == null) return const [];
    final words = normalizeName(query, NameRules.addresses).split(' ');
    if (words.length < 2 || !RegExp(r'^\d+[a-z]?$').hasMatch(words.first)) {
      return const [];
    }
    final number = words.first;
    final rest = words.skip(1).toList();
    final fts = trigramQuery(rest.join(' '));
    if (fts == null) return const [];
    final results = <SearchResult>[];
    for (final s in await db.streetCandidates(fts, 500).get()) {
      final place = [
        if (s.city != null)
          ...normalizeName(s.city!, NameRules.addresses).split(' '),
        if (s.zip != null) s.zip!.split('-').first,
      ];
      final match = addressMatch(rest, s.norm, place);
      if (match == 0) continue;
      for (final a in await db.addressesOn(s.id, number).get()) {
        final point = GeoPoint(a.lat, a.lon);
        final km = near?.kmTo(point);
        results.add(
          SearchResult(
            type: ResultType.address,
            id: a.id,
            name: ['${a.number} ${s.name}', ?s.city, ?s.zip].join(', '),
            kind: 'address',
            point: point,
            match: match,
            km: km,
            score: rankScore(
              match: match,
              queryWords: rest.length,
              nameWords: s.norm.split(' ').length,
              km: km,
            ),
            key: 'address:${a.id}',
          ),
        );
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  /// The street of an address query ("14 Cedar Ln Ouray"), for when
  /// its house isn't in the addresses: the street's search-only name, with
  /// trailing words dropped one by one, as they may name its town. Only a
  /// close match ([streetMatchFloor]) ends the search, so a loose one with
  /// the town still in doesn't hide the street itself. Ranked
  /// [streetInsteadCost] below an exact address.
  Future<List<SearchResult>> searchStreets(
    String query, {
    GeoPoint? near,
    int limit = 20,
  }) async {
    final words = normalizeName(query, NameRules.addresses).split(' ');
    if (words.length < 2 || !RegExp(r'^\d+[a-z]?$').hasMatch(words.first)) {
      return const [];
    }
    final rest = words.skip(1).toList();
    for (var n = rest.length; n > 0; n--) {
      final streets = [
        for (final r in await searchNames(
          rest.take(n).join(' '),
          near: near,
          limit: limit,
        ))
          if ((r.kind == 'highway=road' || r.kind == 'highway=track') &&
              r.match >= streetMatchFloor)
            r.withScore(r.score - streetInsteadCost),
      ];
      if (streets.isNotEmpty) return streets;
    }
    return const [];
  }

  /// Places inside a box, most notable first, for the icons on the map.
  Future<List<PlaceData>> placesIn({
    required double north,
    required double south,
    required double east,
    required double west,
    int limit = 500,
  }) async {
    final db = points;
    if (db == null) return const [];
    return (await db.placesIn(north, south, east, west, limit).get())
        .map((r) => r.p)
        .toList();
  }

  Future<PlaceDetail?> detail(int placeId) async {
    final db = points;
    if (db == null) return null;
    final place = await db.placeById(placeId).getSingleOrNull();
    if (place == null) return null;
    return PlaceDetail(
      place,
      await db.wikiFor(placeId).getSingleOrNull(),
      await db.photoFor(placeId).getSingleOrNull(),
    );
  }

  Future<FeatureData?> feature(int featureId) async =>
      points?.featureById(featureId).getSingleOrNull();

  Future<String?> meta(String name) async =>
      await points?.metaValue(name).getSingleOrNull() ??
      await addresses?.metaValue(name).getSingleOrNull();

  Future<void> close() async {
    await points?.close();
    await addresses?.close();
  }
}

/// Searches every region and merges the results, best first. A place in
/// two regions' files (near a border) appears once. Addresses, and the
/// street in case the house isn't mapped, are searched when [query] starts
/// with a house number. With [near], the places of the [kinds] the query
/// names ([kindsNamed]) are searched too.
Future<List<SearchResult>> searchRegions(
  Iterable<PoiRegion> regions,
  String query, {
  GeoPoint? near,
  int limit = 20,
  Map<String, double> kinds = const {},
}) async {
  final all = <String, SearchResult>{};
  for (final region in regions) {
    for (final r in [
      ...await region.searchNames(
        query,
        near: near,
        limit: limit,
        kinds: kinds,
      ),
      if (near != null)
        ...await region.searchKinds(kinds, near: near, limit: limit),
      ...await region.searchAddresses(query, near: near, limit: limit),
      ...await region.searchStreets(query, near: near, limit: limit),
    ]) {
      final seen = all[r.key];
      if (seen == null || r.score > seen.score) all[r.key] = r;
    }
  }
  final merged = all.values.toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return merged.take(limit).toList();
}

/// Search-only names that count as notable, like a place with an article.
const _towns = {'place=city', 'place=town', 'place=village'};

/// Search-only names an unnamed place can be said to be near.
const _areaKinds = {
  'leisure=park',
  'boundary=protected_area',
  'place=town',
  'place=village',
  'place=hamlet',
};

/// Whether a named place says where you are, for an unnamed one next to
/// it: a picnic area or a museum does, a boulder or another toilet doesn't.
bool _saysWhere(String kind) =>
    !(kind.startsWith('natural=') && kind != 'natural=beach') &&
    !const {
      'amenity=toilets',
      'amenity=drinking_water',
      'amenity=water_point',
      'emergency=phone',
    }.contains(kind);

/// A place of a kind the search names ranks by distance alone, as a name
/// typed in full would: one named "Toilets" gets no lift over an unnamed
/// one.
double _kindScore(double match, double? km) =>
    rankScore(match: match, queryWords: 1, nameWords: 1, km: km);

/// Identifies the same place in two regions' files.
String _placeKey(PlaceData p) =>
    p.osm ??
    p.wikidata ??
    '${p.name}@${p.lat.toStringAsFixed(3)},${p.lon.toStringAsFixed(3)}';
