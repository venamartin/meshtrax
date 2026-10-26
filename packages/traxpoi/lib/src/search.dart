import 'dart:math' as math;

import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzz;

/// A position in degrees.
class GeoPoint {
  final double lat;
  final double lon;

  const GeoPoint(this.lat, this.lon);

  double kmTo(GeoPoint other) {
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(other.lat - lat);
    final dLon = rad(other.lon - lon);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat)) *
            math.cos(rad(other.lat)) *
            math.pow(math.sin(dLon / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(a));
  }

  @override
  String toString() => '$lat, $lon';
}

/// The FTS5 query that finds every name sharing a trigram with [norm]:
/// a typo still leaves most of a word's trigrams intact. Null when no word
/// is three letters long.
String? trigramQuery(String norm) {
  final trigrams = <String>{
    for (final word in norm.split(' '))
      for (var i = 0; i + 3 <= word.length; i++) word.substring(i, i + 3),
  };
  if (trigrams.isEmpty) return null;
  return trigrams.map((t) => '"$t"').join(' OR ');
}

/// How well the normalized [query] matches the normalized [name], 0–100:
/// every query word must closely match a word of the name (a word still
/// being typed may match the start of one), and the average decides.
/// 0 when any query word has no match.
double wordMatch(String query, String name) {
  final nameWords = name.split(' ');
  var total = 0;
  final queryWords = query.split(' ');
  for (final q in queryWords) {
    var best = 0;
    for (final w in nameWords) {
      best = math.max(best, fuzz.ratio(q, w));
      if (q.length >= 2 && w.startsWith(q)) best = math.max(best, 90);
    }
    if (best < 60) return 0;
    total += best;
  }
  return total / queryWords.length;
}

/// The order of results: good matches first, then nearer ones, with a lift
/// for notable places (an article, a heritage listing) and a small cost for
/// names much longer than what was typed.
double rankScore({
  required double match,
  required int queryWords,
  required int nameWords,
  double? km,
  int notability = 0,
}) =>
    match -
    (km == null ? 0 : math.min(km, 300) / 30) +
    notability * 1.5 -
    math.max(0, nameWords - queryWords) * 0.5;
