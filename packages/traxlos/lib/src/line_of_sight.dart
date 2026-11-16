import 'dart:math' as math;
import 'dart:typed_data';

import 'geo.dart';
import 'profile.dart';

/// Effective earth radius factor for standard refraction. Fixed: frequency
/// doesn't change it.
const kFactor = 4 / 3;

/// The default radio frequency, MHz.
const defaultFrequencyMHz = 915.0;

/// Within this distance of a radio, ground only counts when it is above
/// the line, and then makes the answer Marginal at worst.
const nearEndM = 50.0;

/// Ground within this distance of a radio is reported as near that radio.
const nearRadioM = 100.0;

const _speedOfLight = 299792458.0;

/// How far the earth's curve (k = 4/3) lifts the ground into a straight
/// line at [d1] and [d2] metres from its ends.
double earthBulgeM(double d1, double d2) =>
    d1 * d2 / (2 * kFactor * earthRadiusM);

/// The first Fresnel zone's radius at [d1] and [d2] metres from the ends.
double fresnelRadiusM(double d1, double d2, double frequencyMHz) {
  if (d1 <= 0 || d2 <= 0) return 0;
  final lambda = _speedOfLight / (frequencyMHz * 1e6);
  return math.sqrt(lambda * d1 * d2 / (d1 + d2));
}

enum Verdict {
  /// The ground stays out of 60% of the first Fresnel zone everywhere,
  /// even with hilltops one contour interval higher than drawn.
  clear,

  /// Too close to call within the data's error, or ground just in front
  /// of a radio comes up to the line.
  marginal,

  /// Ground is more than one contour interval above the line (or above it
  /// where the earth's curve alone already is).
  blocked,

  /// Can't tell: part of the line has no data, or an end's height isn't
  /// known.
  unknown,
}

/// Which radio the ground that decides the answer is near.
enum NearRadio { none, from, to }

enum HeightSource { given, contours, peak, unknown }

/// Why an end's ground height isn't known.
enum HeightIssue {
  /// Inside the lowest contour line with no lower line: the packs have no
  /// lines at or below sea level, so the ground may be far lower.
  belowLowestContour,

  /// No contour line within 15 km.
  noLinesNearby,

  /// Outside every installed contours pack.
  notDownloaded,
}

enum UnknownReason { notDownloaded, fromHeight, toHeight }

/// A summit from a map pack, with its height.
class Peak {
  final String name;
  final double eleM;
  final Geo position;

  const Peak(this.name, this.eleM, this.position);

  @override
  bool operator ==(Object other) =>
      other is Peak &&
      other.name == name &&
      other.eleM == eleM &&
      other.position == position;

  @override
  int get hashCode => Object.hash(name, eleM, position);

  @override
  String toString() => 'Peak($name, ${eleM.toStringAsFixed(0)} m)';
}

/// One end's ground height and where it came from.
class EndHeight {
  /// Metres above sea level; null when unknown.
  final double? groundM;
  final HeightSource source;
  final HeightIssue? issue;

  /// Set when a peak's height was used.
  final Peak? peak;

  const EndHeight(this.groundM, this.source, {this.issue, this.peak});

  const EndHeight.unknown(HeightIssue this.issue)
    : groundM = null,
      source = HeightSource.unknown,
      peak = null;

  bool get isKnown => groundM != null;

  @override
  String toString() =>
      'EndHeight(${groundM?.toStringAsFixed(1)}, ${source.name}'
      '${issue == null ? '' : ', ${issue!.name}'})';
}

/// A radio at one end of a link.
class LinkEnd {
  final Geo position;

  /// Antenna height above the ground, metres.
  final double antennaM;

  /// The ground height here in metres above sea level, when the caller
  /// knows it (e.g. the radio's GPS altitude less its antenna height).
  final double? groundM;

  /// Use [groundM] only where the contours can't tell the height.
  final bool groundIsFallback;

  const LinkEnd(
    this.position, {
    this.antennaM = 1.5,
    this.groundM,
    this.groundIsFallback = false,
  });
}

/// A point on the line and how the ground there stands against it.
class Obstacle {
  /// Metres from the From end.
  final double distanceM;

  /// The ground height there, metres above sea level.
  final double groundM;

  /// How far the ground (with the earth's curve) is above the radio line;
  /// negative when below it.
  final double aboveLineM;

  /// The room the signal needs there: 60% of the first Fresnel zone.
  final double neededM;

  /// On a hilltop between two crossings of the same contour line.
  final bool crest;
  final Geo position;

  const Obstacle({
    required this.distanceM,
    required this.groundM,
    required this.aboveLineM,
    required this.neededM,
    required this.crest,
    required this.position,
  });

  @override
  String toString() =>
      'Obstacle(${(distanceM / 1000).toStringAsFixed(2)} km, ground '
      '${groundM.toStringAsFixed(1)} m, above line '
      '${aboveLineM.toStringAsFixed(1)} m, needed '
      '${neededM.toStringAsFixed(1)} m${crest ? ', crest' : ''})';
}

/// A stretch of the line, metres from the From end.
class Stretch {
  final double startM;
  final double endM;
  final Geo start;
  final Geo end;

  const Stretch(this.startM, this.endM, this.start, this.end);

  double get lengthM => endM - startM;

  @override
  String toString() =>
      'Stretch(${startM.toStringAsFixed(0)}-${endM.toStringAsFixed(0)} m)';
}

/// The ground along a line, for drawing.
class TerrainProfile {
  final ProfileData _p;

  TerrainProfile(this._p);

  double get lengthM => _p.length;

  /// Metres from the From end, increasing.
  Float64List get distancesM => _p.d.asUnmodifiableView();

  /// Ground heights, metres; NaN where unknown.
  Float64List get groundM => _p.h.asUnmodifiableView();

  /// [PointKind] flags per point.
  Uint8List get kinds => _p.kind.asUnmodifiableView();

  /// The ground [distanceM] from the From end; NaN where unknown.
  double groundAt(double distanceM) => _p.heightAt(distanceM);
}

/// The answer for one link.
class LineOfSight {
  final Verdict verdict;
  final double distanceM;
  final Geo from;
  final Geo to;
  final EndHeight fromGround;
  final EndHeight toGround;
  final double fromAntennaM;
  final double toAntennaM;
  final double frequencyMHz;

  /// The point that decides the answer; null when the ends' heights
  /// aren't known or nothing on the line counts.
  final Obstacle? deciding;

  /// Whether [deciding] is within 100 m of a radio: then the ground next
  /// to that radio is what limits the link.
  final NearRadio nearRadio;

  /// The worst point more than 100 m from both radios.
  final Obstacle? beyondNearGround;

  final Set<UnknownReason> unknownReasons;

  /// Stretches outside every installed contours pack.
  final List<Stretch> notDownloaded;

  /// Stretches where contour lines may be missing (a step of more than one
  /// interval) or a hill can't be told from a valley.
  final List<Stretch> uncertain;

  /// Peak heights used; show the map pack's credit with them.
  final List<Peak> peaksUsed;

  /// Data credits to show with the answer.
  final List<String> credits;

  /// Packs that couldn't be read, by path; their areas count as not
  /// downloaded.
  final List<String> skippedPacks;

  final TerrainProfile profile;

  const LineOfSight({
    required this.verdict,
    required this.distanceM,
    required this.from,
    required this.to,
    required this.fromGround,
    required this.toGround,
    required this.fromAntennaM,
    required this.toAntennaM,
    required this.frequencyMHz,
    required this.deciding,
    required this.nearRadio,
    required this.beyondNearGround,
    required this.unknownReasons,
    required this.notDownloaded,
    required this.uncertain,
    required this.peaksUsed,
    required this.credits,
    required this.skippedPacks,
    required this.profile,
  });

  /// The radio line's height above sea level [d] metres from the From
  /// end, straight between the antennas; null when an end's height isn't
  /// known. Draw the ground plus [bulgeAt] against it.
  double? lineAt(double d) {
    final a = fromGround.groundM, b = toGround.groundM;
    if (a == null || b == null || distanceM <= 0) return null;
    final za = a + fromAntennaM, zb = b + toAntennaM;
    return za + (zb - za) * d / distanceM;
  }

  /// How far the earth's curve lifts the ground at [d].
  double bulgeAt(double d) => earthBulgeM(d, distanceM - d);

  /// The room the signal needs at [d]: 60% of the first Fresnel zone.
  double neededAt(double d) =>
      0.6 * fresnelRadiusM(d, distanceM - d, frequencyMHz);

  @override
  String toString() =>
      'LineOfSight(${verdict.name}, ${(distanceM / 1000).toStringAsFixed(2)}'
      ' km, deciding: $deciding, near: ${nearRadio.name})';
}

/// How the ground stands against the line: the verdict and the deciding
/// points (indexes into the profile, -1 for none).
class Judgement {
  final Verdict verdict;
  final int deciding;
  final int beyondNear;

  const Judgement(this.verdict, this.deciding, this.beyondNear);
}

/// Judges [p] between ground heights [hA] and [hB] with antennas [antA]
/// and [antB].
///
/// Per point x metres from the From end, with o the ground (plus the
/// earth's curve) above the line and I the contour interval there:
/// - within 50 m of an end, ground above the line (o > 0) is Marginal;
/// - Blocked when o > I, or o > 0 where the earth's curve alone already
///   rises above the line (the margin is for the data's error, and the
///   earth's curve has none);
/// - otherwise Marginal when the ground, with hilltops raised by one
///   interval, comes within 60% of the first Fresnel zone of the line.
Judgement judge(
  ProfileData p,
  double hA,
  double hB,
  double antA,
  double antB,
  double frequencyMHz,
) {
  final length = p.length;
  final za = hA + antA, zb = hB + antB;
  final lambda = _speedOfLight / (frequencyMHz * 1e6);
  const twoKR = 2 * kFactor * earthRadiusM;
  var bestClass = -1, bestI = -1, nearClass = -1, nearI = -1;
  var bestKey = double.negativeInfinity, nearKey = double.negativeInfinity;
  final d = p.d, h = p.h, raise = p.raise, iv = p.interval;
  for (var i = 0; i < p.count; i++) {
    final x = d[i];
    if (x <= 0 || x >= length) continue;
    final g = h[i];
    if (g.isNaN) continue;
    final f = x / length;
    final line = za + (zb - za) * f;
    final bulge = x * (length - x) / twoKR;
    final o = g + bulge - line;
    int cls;
    double key;
    if (x < nearEndM || x > length - nearEndM) {
      if (o <= 0) continue;
      cls = 1;
      key = o;
    } else {
      final e = bulge - (antA + (antB - antA) * f);
      final oB = math.min(o, math.max(o - iv[i], e));
      if (oB > 0) {
        cls = 2;
        key = o;
      } else {
        final needed = 0.6 * math.sqrt(lambda * x * (length - x) / length);
        key = needed + o + raise[i];
        cls = key > 0 ? 1 : 0;
      }
    }
    if (cls > bestClass || (cls == bestClass && key > bestKey)) {
      bestClass = cls;
      bestKey = key;
      bestI = i;
    }
    if (x >= nearRadioM && x <= length - nearRadioM) {
      if (cls > nearClass || (cls == nearClass && key > nearKey)) {
        nearClass = cls;
        nearKey = key;
        nearI = i;
      }
    }
  }
  final verdict = switch (bestClass) {
    2 => Verdict.blocked,
    1 => Verdict.marginal,
    _ => Verdict.clear,
  };
  return Judgement(verdict, bestI, nearI);
}

/// The answer for ground heights that are known exactly: [distancesM]
/// from the From end (0 first, the length last) and [groundM] at each.
///
/// [intervalM] is the margin for the data's error: 0 for exact heights.
LineOfSight lineOfSightOver(
  List<double> distancesM,
  List<double> groundM, {
  double fromAntennaM = 1.5,
  double toAntennaM = 1.5,
  double frequencyMHz = defaultFrequencyMHz,
  double intervalM = 0,
  Geo from = const Geo(0, 0),
  Geo? to,
}) {
  if (distancesM.length < 2 || distancesM.length != groundM.length) {
    throw ArgumentError('need two or more distances, one height each');
  }
  final length = distancesM.last;
  // Every height is exact here: no contour rules, just fill so the earth's
  // curve shows on long gaps.
  final b = <double>[], hb = <double>[];
  for (var i = 0; i < distancesM.length; i++) {
    if (i > 0) {
      final d0 = distancesM[i - 1], d1 = distancesM[i];
      final n = ((d1 - d0) / 50).ceil();
      for (var k = 1; k < n; k++) {
        b.add(d0 + (d1 - d0) * k / n);
        hb.add(groundM[i - 1] + (groundM[i] - groundM[i - 1]) * k / n);
      }
    }
    b.add(distancesM[i]);
    hb.add(groundM[i]);
  }
  final n = b.length;
  final p = ProfileData(
    Float64List.fromList(b),
    Float64List.fromList(hb),
    Float64List(n),
    Float64List(n)..fillRange(0, n, intervalM),
    Uint8List(n),
    length,
    const [],
  );
  final end = to ?? destination(from, 90, length);
  return assembleLineOfSight(
    profile: p,
    from: from,
    to: end,
    fromGround: EndHeight(groundM.first, HeightSource.given),
    toGround: EndHeight(groundM.last, HeightSource.given),
    fromAntennaM: fromAntennaM,
    toAntennaM: toAntennaM,
    frequencyMHz: frequencyMHz,
  );
}

/// Judges [profile] and puts the answer together.
LineOfSight assembleLineOfSight({
  required ProfileData profile,
  required Geo from,
  required Geo to,
  required EndHeight fromGround,
  required EndHeight toGround,
  required double fromAntennaM,
  required double toAntennaM,
  required double frequencyMHz,
  List<Peak> peaksUsed = const [],
  List<String> credits = const [],
  List<String> skippedPacks = const [],
}) {
  final length = profile.length;
  Geo at(double d) => length <= 0 ? from : interpolate(from, to, d / length);
  final reasons = <UnknownReason>{};
  if (!fromGround.isKnown) reasons.add(UnknownReason.fromHeight);
  if (!toGround.isKnown) reasons.add(UnknownReason.toHeight);
  final notDownloaded = _stretches(profile, PointKind.unknown, at);
  if (notDownloaded.isNotEmpty) reasons.add(UnknownReason.notDownloaded);
  final uncertain = _stretches(profile, PointKind.uncertain, at);

  Obstacle? obstacle(int i) {
    if (i < 0) return null;
    final x = profile.d[i];
    final za = fromGround.groundM! + fromAntennaM;
    final zb = toGround.groundM! + toAntennaM;
    final line = za + (zb - za) * x / length;
    return Obstacle(
      distanceM: x,
      groundM: profile.h[i],
      aboveLineM: profile.h[i] + earthBulgeM(x, length - x) - line,
      neededM: 0.6 * fresnelRadiusM(x, length - x, frequencyMHz),
      crest: profile.kind[i] & PointKind.crest != 0,
      position: at(x),
    );
  }

  var verdict = Verdict.unknown;
  Obstacle? deciding, beyond;
  var near = NearRadio.none;
  if (fromGround.isKnown && toGround.isKnown) {
    final j = judge(
      profile,
      fromGround.groundM!,
      toGround.groundM!,
      fromAntennaM,
      toAntennaM,
      frequencyMHz,
    );
    if (reasons.isEmpty) verdict = j.verdict;
    deciding = obstacle(j.deciding);
    beyond = obstacle(j.beyondNear);
    if (deciding != null) {
      if (deciding.distanceM < nearRadioM) {
        near = NearRadio.from;
      } else if (deciding.distanceM > length - nearRadioM) {
        near = NearRadio.to;
      }
    }
  }
  return LineOfSight(
    verdict: verdict,
    distanceM: length,
    from: from,
    to: to,
    fromGround: fromGround,
    toGround: toGround,
    fromAntennaM: fromAntennaM,
    toAntennaM: toAntennaM,
    frequencyMHz: frequencyMHz,
    deciding: deciding,
    nearRadio: near,
    beyondNearGround: beyond,
    unknownReasons: reasons,
    notDownloaded: notDownloaded,
    uncertain: uncertain,
    peaksUsed: peaksUsed,
    credits: credits,
    skippedPacks: skippedPacks,
    profile: TerrainProfile(profile),
  );
}

List<Stretch> _stretches(ProfileData p, int flag, Geo Function(double) at) {
  final out = <Stretch>[];
  double? start;
  var last = 0.0;
  for (var i = 0; i < p.count; i++) {
    final on = p.kind[i] & flag != 0;
    if (on) {
      start ??= p.d[i];
      last = p.d[i];
    } else if (start != null) {
      out.add(Stretch(start, last, at(start), at(last)));
      start = null;
    }
  }
  if (start != null) out.add(Stretch(start, last, at(start), at(last)));
  return out;
}
