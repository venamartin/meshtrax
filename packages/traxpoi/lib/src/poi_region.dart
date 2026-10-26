import 'dart:io';

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
  });
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
  /// first. With [near], nearer matches rank higher.
  Future<List<SearchResult>> searchNames(
    String query, {
    GeoPoint? near,
    int limit = 20,
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

    final best = <(int?, int?), double>{};
    for (final (placeId, featureId, candidate) in candidates) {
      final match = wordMatch(norm, candidate);
      if (match == 0) continue;
      final id = (placeId, featureId);
      if (match > (best[id] ?? 0)) best[id] = match;
    }
    final top = best.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final results = <SearchResult>[];
    final queryWords = norm.split(' ').length;
    for (final MapEntry(key: (placeId, featureId), value: match) in top.take(
      limit * 5,
    )) {
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
            score: rankScore(
              match: match,
              queryWords: queryWords,
              nameWords: normalizeName(
                p.name,
                NameRules.places,
              ).split(' ').length,
              km: km,
              notability: p.rank,
            ),
            key:
                p.osm ??
                p.wikidata ??
                '${p.name}@${p.lat.toStringAsFixed(3)},${p.lon.toStringAsFixed(3)}',
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
              nameWords: normalizeName(
                f.name,
                NameRules.places,
              ).split(' ').length,
              km: km,
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
    final street = words.skip(1).join(' ');
    final fts = trigramQuery(street);
    if (fts == null) return const [];
    final results = <SearchResult>[];
    for (final s in await db.streetCandidates(fts, 500).get()) {
      final place = [
        s.norm,
        if (s.city != null) normalizeName(s.city!, NameRules.addresses),
        ?s.zip,
      ].join(' ');
      final match = wordMatch(street, place);
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
              queryWords: street.split(' ').length,
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

  Future<String?> meta(String name) async =>
      await points?.metaValue(name).getSingleOrNull() ??
      await addresses?.metaValue(name).getSingleOrNull();

  Future<void> close() async {
    await points?.close();
    await addresses?.close();
  }
}

/// Searches every region and merges the results, best first. A place in
/// two regions' files (near a border) appears once. Addresses are searched
/// when [query] starts with a house number.
Future<List<SearchResult>> searchRegions(
  Iterable<PoiRegion> regions,
  String query, {
  GeoPoint? near,
  int limit = 20,
}) async {
  final all = <String, SearchResult>{};
  for (final region in regions) {
    for (final r in [
      ...await region.searchNames(query, near: near, limit: limit),
      ...await region.searchAddresses(query, near: near, limit: limit),
    ]) {
      final seen = all[r.key];
      if (seen == null || r.score > seen.score) all[r.key] = r;
    }
  }
  final merged = all.values.toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return merged.take(limit).toList();
}
