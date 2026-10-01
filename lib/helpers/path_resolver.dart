import 'dart:typed_data';

import '../helpers/path_helper.dart';

import 'package:latlong2/latlong.dart';

import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../models/resolved_hop.dart';

/// A raw path buffer paired with whether it is the primary (longest) observed path.
class ObservedPath {
  final Uint8List pathBytes;
  final bool isPrimary;

  const ObservedPath({required this.pathBytes, required this.isPrimary});

  int getHopCount(int stride) =>
      PathHelper.getHopCount(pathBytes, stride: stride);
}

class PathResolver {
  /// Maximum distance in meters a repeater can be from the previous located hop
  /// before we consider it an implausible match (~310 miles).
  static const double _maxHopDistanceMeters = 500000.0;

  /// Upper bound on search steps when prefixes collide heavily. A path with no
  /// collisions costs one step per hop; a complete path is always found before
  /// this limit can trigger, so hitting it only stops looking for a better one.
  static const int _maxSearchVisits = 2000;

  /// Builds a list of resolved hops given a raw path buffer.
  /// When prefixes collide, searches every candidate combination and keeps the
  /// path with the smallest average distance between located hops. A hop with
  /// no plausible candidate is kept as an unknown placeholder.
  static List<ResolvedHop> buildPathHops(
    Uint8List pathBytes,
    List<Contact> allContacts, {
    LatLng? startLocation,
    LatLng? endLocation,
    int stride = 1,
  }) {
    if (pathBytes.isEmpty) return const [];

    // Group contacts by their full hex prefix
    final candidatesByPrefix = <String, List<Contact>>{};
    for (final contact in allContacts) {
      if (contact.publicKey.isEmpty) continue;
      if (contact.type != advTypeRepeater && contact.type != advTypeRoom) {
        continue;
      }
      final prefix = contact.hashPrefixWithStride(stride);
      candidatesByPrefix.putIfAbsent(prefix, () => <Contact>[]).add(contact);
    }

    for (final candidates in candidatesByPrefix.values) {
      candidates.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    }

    const distance = Distance();
    var visits = 0;
    var bestAverage = double.infinity;
    List<ResolvedHop>? best;

    void search(
      int depth,
      List<ResolvedHop> path,
      LatLng? lastLocation,
      double length,
      int segments,
    ) {
      if (++visits > _maxSearchVisits && best != null) return;

      final slotStart = depth * stride;
      if (slotStart >= pathBytes.length || pathBytes[slotStart] == 0x00) {
        if (endLocation != null && lastLocation != null) {
          length += distance(lastLocation, endLocation);
          segments++;
        }
        final average = segments == 0 ? double.infinity : length / segments;
        if (best == null || average < bestAverage) {
          bestAverage = average;
          best = path;
        }
        return;
      }

      final slotEnd = (slotStart + stride).clamp(0, pathBytes.length);
      final fullPrefix = pathBytes
          .sublist(slotStart, slotEnd)
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join();

      var matched = false;
      for (final candidate in candidatesByPrefix[fullPrefix] ?? const <Contact>[]) {
        if (path.any((hop) => hop.contact == candidate)) continue;

        final position = _resolvePosition(candidate);
        if (position != null &&
            lastLocation != null &&
            distance(lastLocation, position) > _maxHopDistanceMeters) {
          continue;
        }

        matched = true;
        final hop = ResolvedHop(
          index: depth + 1,
          fullPrefixLabel: fullPrefix,
          contact: candidate,
          position: position,
        );
        if (position == null || lastLocation == null) {
          search(depth + 1, [...path, hop], position ?? lastLocation, length, segments);
        } else {
          search(
            depth + 1,
            [...path, hop],
            position,
            length + distance(lastLocation, position),
            segments + 1,
          );
        }
      }

      if (!matched) {
        final hop = ResolvedHop(index: depth + 1, fullPrefixLabel: fullPrefix);
        search(depth + 1, [...path, hop], lastLocation, length, segments);
      }
    }

    search(0, const [], startLocation, 0, 0);
    return best ?? const [];
  }

  static LatLng? _resolvePosition(Contact? contact) {
    if (contact == null) return null;
    if (!contact.hasLocation) return null;
    final latitude = contact.latitude;
    final longitude = contact.longitude;
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  static Uint8List selectPrimaryPath(
    Uint8List pathBytes,
    List<Uint8List> variants,
  ) {
    Uint8List primary = pathBytes;
    for (final variant in variants) {
      if (variant.length > primary.length) {
        primary = variant;
      }
    }
    return primary;
  }

  static List<Uint8List> otherPaths(
    Uint8List primary,
    List<Uint8List> variants,
  ) {
    final others = <Uint8List>[];
    for (final variant in variants) {
      if (variant.isEmpty) continue;
      if (!pathsEqual(primary, variant)) {
        others.add(variant);
      }
    }
    return others;
  }

  static List<ObservedPath> buildObservedPaths(
    Uint8List primary,
    List<Uint8List> variants,
  ) {
    final observed = <ObservedPath>[];

    void addPath(Uint8List pathBytes, bool isPrimary) {
      if (pathBytes.isEmpty) return;
      for (final existing in observed) {
        if (pathsEqual(existing.pathBytes, pathBytes)) return;
      }
      observed.add(ObservedPath(pathBytes: pathBytes, isPrimary: isPrimary));
    }

    addPath(primary, true);
    for (final variant in variants) {
      addPath(variant, false);
    }

    return observed;
  }

  static Uint8List resolveSelectedPath(
    Uint8List? selected,
    List<ObservedPath> observedPaths,
    Uint8List fallback,
  ) {
    if (selected != null) {
      for (final path in observedPaths) {
        if (pathsEqual(path.pathBytes, selected)) {
          return path.pathBytes;
        }
      }
    }
    if (observedPaths.isNotEmpty) {
      return observedPaths.first.pathBytes;
    }
    return fallback;
  }

  static int indexForPath(Uint8List selected, List<ObservedPath> paths) {
    for (int i = 0; i < paths.length; i++) {
      if (pathsEqual(paths[i].pathBytes, selected)) {
        return i;
      }
    }
    return 0;
  }

  static bool pathsEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
