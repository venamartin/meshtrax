import 'dart:math';
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import 'path_helper.dart';

class GuessedLocation {
  final Contact contact;
  final LatLng position;
  final bool highConfidence;

  const GuessedLocation({
    required this.contact,
    required this.position,
    required this.highConfidence,
  });
}

/// All guessed-location math for the map: where a contact with no position
/// of its own probably is, from the repeaters it was heard through.
class GuessedLocationHelper {
  GuessedLocationHelper._();

  /// Contacts not heard for this long get no guess.
  static const Duration staleAfter = Duration(hours: 24);

  /// Estimates the free-space maximum LoRa range in km from the connected
  /// device's current radio parameters. Returns null if any is unknown.
  ///
  /// [freqKHz] is `connector.currentFreqHz`, which holds kHz despite its name
  /// (firmware `_prefs.freq * 1000`, freq in MHz).
  static double? estimateRangeKm({
    required int? freqKHz,
    required int? bwHz,
    required int? sf,
    required int? txPowerDbm,
  }) {
    if (freqKHz == null || bwHz == null || sf == null || txPowerDbm == null) {
      return null;
    }
    final freqHz = freqKHz * 1000.0;
    // LoRa receiver sensitivity = thermal noise + NF + required demod SNR
    const noiseFigureDb = 6.0;
    final thermalNoiseDbm = -174.0 + 10 * log(bwHz.toDouble()) / ln10;
    final sensitivityDbm =
        thermalNoiseDbm + noiseFigureDb + _sfToRequiredSnrDb(sf);
    // FSPL at max range equals link budget:
    //   FSPL = 20*log10(d_m) + 20*log10(f_hz) - 147.55
    final linkBudgetDb = txPowerDbm.toDouble() - sensitivityDbm;
    final exponent = (linkBudgetDb + 147.55 - 20 * log(freqHz) / ln10) / 20;
    return pow(10, exponent) / 1000;
  }

  static double _sfToRequiredSnrDb(int sf) {
    switch (sf) {
      case 5:
        return -2.5;
      case 6:
        return -5.0;
      case 7:
        return -7.5;
      case 8:
        return -10.0;
      case 9:
        return -12.5;
      case 10:
        return -15.0;
      case 11:
        return -17.5;
      case 12:
        return -20.0;
      default:
        return -10.0;
    }
  }

  /// A node cannot be in radio range of two points farther apart than twice
  /// the maximum range. Haversine, not the default Vincenty `Distance()`,
  /// which throws on near-antipodal points; a NaN from it compares false.
  static bool withinRange(LatLng a, LatLng b, double maxRangeKm) =>
      const Haversine().distance(a, b) <= maxRangeKm * 2000;

  /// The point halfway between [a] and [b], the short way round the globe.
  /// No evidence supports trusting either anchor more.
  static LatLng midpoint(LatLng a, LatLng b) {
    final lonDelta = _wrapLongitude(b.longitude - a.longitude);
    return LatLng(
      (a.latitude + b.latitude) / 2,
      _wrapLongitude(a.longitude + lonDelta / 2),
    );
  }

  static double _wrapLongitude(double lon) => ((lon + 540) % 360) - 180;

  /// Changes whenever [compute] could give a different result.
  /// The stale check goes in as a yes/no so an advert alone does not force a
  /// recompute, but crossing [staleBefore] does.
  static String cacheKey({
    required List<Contact> targets,
    required List<Contact> located,
    required double? maxRangeKm,
    required DateTime staleBefore,
  }) {
    final targetKeys = targets
        .map(
          (c) =>
              '${c.publicKeyHex}:${c.pathIdList}:${_inboundFirstHopHex(c)}:${c.lastSeen.isBefore(staleBefore)}',
        )
        .join(',');
    final locatedKeys = located
        .map((c) => '${c.publicKeyHex}:${c.type}:${c.latitude}:${c.longitude}')
        .join(',');
    return '$targetKeys|$locatedKeys|$maxRangeKm';
  }

  static int _inboundWidth(Contact c) =>
      c.inboundPathHashSize ?? c.pathHashSize;

  static String _inboundFirstHopHex(Contact c) =>
      PathHelper.firstHopHex(c.inboundPath, stride: _inboundWidth(c)) ?? '';

  /// Guesses for each of [targets] that has no location, anchored on the
  /// repeaters in [located]. Both lists can name a contact twice: until the
  /// contact sync ends, a saved contact also appears as its discovered row.
  static List<GuessedLocation> compute({
    required List<Contact> targets,
    required List<Contact> located,
    required double? maxRangeKm,
    required DateTime staleBefore,
  }) {
    // Index known-location repeaters by their hash prefix per stride.
    // null value = two repeaters share the same hash prefix (ambiguous collision).
    final repeatersByStride = <int, Map<String, Contact?>>{};

    Map<String, Contact?> getRepeaterMapForStride(int stride) {
      if (repeatersByStride.containsKey(stride)) {
        return repeatersByStride[stride]!;
      }
      final map = <String, Contact?>{};
      for (final c in located) {
        if (c.type == advTypeRepeater) {
          final prefix = c.hashPrefixWithStride(stride);
          if (!map.containsKey(prefix)) {
            map[prefix] = c;
          } else if (map[prefix]?.publicKeyHex != c.publicKeyHex) {
            map[prefix] = null; // collision: can't disambiguate
          }
        }
      }
      repeatersByStride[stride] = map;
      return map;
    }

    final result = <GuessedLocation>[];
    final seen = <String>{};

    for (final contact in targets) {
      if (!seen.add(contact.publicKeyHex)) continue;
      if (contact.hasLocation) continue;
      if (contact.lastSeen.isBefore(staleBefore)) continue;

      final anchorSet = <LatLng>{};

      // Anchor on the repeater nearest the contact: the first hop of its
      // inbound advert path, or the last hop of its stored route.
      // Hops nearer our side would anchor against our own network.
      // The two paths carry their own widths: the advert's path is at the
      // contact's flood width, the route at the width it was learned at.
      final inboundWidth = _inboundWidth(contact);
      final inboundHops = PathHelper.getHops(
        contact.inboundPath,
        stride: inboundWidth,
      );
      final routeHops = PathHelper.getHops(
        contact.path,
        stride: contact.pathHashSize,
      );
      for (final (hop, width) in [
        if (inboundHops.isNotEmpty) (inboundHops.first, inboundWidth),
        if (routeHops.isNotEmpty) (routeHops.last, contact.pathHashSize),
      ]) {
        final r = getRepeaterMapForStride(width)[PathHelper.hopHex(hop)];
        if (r != null) anchorSet.add(LatLng(r.latitude!, r.longitude!));
      }

      if (anchorSet.isEmpty) continue;

      final anchors = anchorSet.toList();
      final bool highConfidence = anchors.length == 2;
      final LatLng position;
      if (highConfidence) {
        // Two anchors too far apart cannot both be right, and nothing shows
        // which one is wrong, so the contact gets no guess at all.
        if (maxRangeKm != null &&
            !withinRange(anchors[0], anchors[1], maxRangeKm)) {
          continue;
        }
        position = _offsetGuessedPosition(
          midpoint(anchors[0], anchors[1]),
          contact,
          radiusMeters: 120,
        );
      } else {
        // Spread single-anchor guesses around the anchor so they remain visible.
        position = _offsetGuessedPosition(
          anchors[0],
          contact,
          radiusMeters: 330,
        );
      }
      if (!_isPlausible(position)) continue; // near (0, 0)

      result.add(
        GuessedLocation(
          contact: contact,
          position: position,
          highConfidence: highConfidence,
        ),
      );
    }

    return result;
  }

  static bool _isPlausible(LatLng position) {
    const double epsilon = 1e-6;
    final lat = position.latitude;
    final lon = position.longitude;
    return (lat.abs() > epsilon || lon.abs() > epsilon) &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lon >= -180.0 &&
        lon <= 180.0;
  }

  static LatLng _offsetGuessedPosition(
    LatLng anchor,
    Contact contact, {
    required double radiusMeters,
  }) {
    final seed = _guessSeed(contact.publicKey);
    final angle = ((seed & 0xFFFF) / 0x10000) * 2 * pi;
    final latOffsetDeg = (radiusMeters / 111320.0) * cos(angle);
    final lonScale = max(cos(anchor.latitude * pi / 180.0).abs(), 0.2);
    final lonOffsetDeg = (radiusMeters / (111320.0 * lonScale)) * sin(angle);
    return LatLng(
      anchor.latitude + latOffsetDeg,
      _wrapLongitude(anchor.longitude + lonOffsetDeg),
    );
  }

  static int _guessSeed(Uint8List publicKey) {
    var seed = 0x811C9DC5;
    for (final byte in publicKey) {
      seed ^= byte;
      seed = (seed * 0x01000193) & 0x7FFFFFFF;
    }
    return seed;
  }
}
