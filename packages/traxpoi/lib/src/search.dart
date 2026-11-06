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
/// for the name typed exactly and for notable places (an article, a
/// heritage listing, a town), and a small cost for each word the matched
/// name has beyond what was typed.
double rankScore({
  required double match,
  required int queryWords,
  required int nameWords,
  double? km,
  int notability = 0,
  bool exact = false,
}) =>
    match -
    (km == null ? 0 : math.min(km, 300) / 30) +
    (exact ? 15 : 0) +
    notability * 1.5 -
    math.max(0, nameWords - queryWords) * 0.5;

/// How well an address query's words (after the house number) match a
/// street, 0–100: the leading words must match the street name, and words
/// after them may name its town or ZIP. A town or ZIP that matches costs
/// nothing. On a street with no town recorded it costs a little, so the
/// address is still found ("607 Main St Ouray" on a Main Street whose town
/// wasn't mapped); on a street in another town it costs much more, so a
/// look-alike street elsewhere ranks below the street that was asked for.
double addressMatch(List<String> query, String street, List<String> place) {
  for (var n = query.length; n > 0; n--) {
    final streetMatch = wordMatch(query.take(n).join(' '), street);
    if (streetMatch == 0) continue;
    var cost = 0.0;
    for (final w in query.skip(n)) {
      final inPlace = place.any(
        (p) => fuzz.ratio(w, p) >= 80 || (w.length >= 2 && p.startsWith(w)),
      );
      if (!inPlace) cost += place.isEmpty ? 5 : 25;
    }
    return math.max(1, streetMatch - cost);
  }
  return 0;
}

/// What offering the street of an address query costs in rank, for when
/// its house number isn't in the addresses: an exact address still comes
/// first, a same-numbered house on a look-alike street elsewhere after it.
const streetInsteadCost = 30.0;

/// How closely a road's name must match the typed street to be offered for
/// an address: typos pass ("fothill drive"), a different street that only
/// shares letters with the street and its town doesn't.
const streetMatchFloor = 90.0;
