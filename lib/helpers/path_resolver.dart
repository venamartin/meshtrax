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

  int getHopCount(int stride) => PathHelper.getHopCount(pathBytes, stride: stride);
}

class _MeasuredPath {
  final int hops;
  final double length;
  final List<ResolvedHop> path;
  final LatLng? previousLocation;

  const _MeasuredPath({
    required this.hops,
    required this.length,
    required this.path,
    required this.previousLocation
  });

  static final distance = Distance();

  /// Returns a copy of this instance that includes the given [current] hop in
  /// its distance figures and path.
  _MeasuredPath operator +(ResolvedHop current) {
    final currentLocation = current.position;

    if (currentLocation == null || previousLocation == null) {
      // Count the hop in the path, but don't factor it into the average
      return _MeasuredPath(
          hops: hops,
          length: length,
          path: path + [current],
          previousLocation: currentLocation ?? previousLocation
      );
    } else {
      // Count the hop in the path and factor it into the average
      return _MeasuredPath(
          hops: hops + 1,
          length: length + distance(currentLocation, previousLocation!),
          path: path + [current],
          previousLocation: currentLocation
      );
    }
  }

  /// Returns a copy of this instance that includes the distance to the given
  /// [endLocation], if possible.
  _MeasuredPath toEnd(LatLng? endLocation) {
    if (endLocation == null || previousLocation == null) {
      return this;
    } else {
      return _MeasuredPath(
          hops: hops + 1,
          length: length + distance(endLocation, previousLocation!),
          path: path,
          previousLocation: endLocation
      );
    }
  }
}

class PathResolver {
  /// Maximum distance in meters a repeater can be from the previous hop
  /// before we consider it an implausible match (~310 miles).
  static const double _maxHopDistanceMeters = 500000.0;

  /// Builds a list of resolved hops given a raw path buffer.
  /// Applies geometric constraints to pick the likeliest repeater when hashes collide.
  static List<ResolvedHop> buildPathHops(
    Uint8List pathBytes,
    List<Contact> allContacts, {
    LatLng? startLocation,
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

    var previousPosition = startLocation;
    final distCalc = Distance();
    final hops = <ResolvedHop>[];
    var hopIndex = 1;

    for (var i = 0; i < pathBytes.length; i += stride) {
      if (pathBytes[i] == 0x00) break; // padding sentinel

      final slotEnd = (i + stride).clamp(0, pathBytes.length);
      final slotBytes = pathBytes.sublist(i, slotEnd);
      final fullPrefix = slotBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join();

      final searchPoint = hopIndex == 1 ? startLocation : previousPosition;
      final candidatesList = candidatesByPrefix[fullPrefix];
      Contact? contact;

      if (candidatesList != null && candidatesList.isNotEmpty) {
        var bestMatchIndex = 0;
        var closestDistance = double.infinity;

        if (searchPoint != null) {
          for (int j = 0; j < candidatesList.length; j++) {
            final candidate = candidatesList[j];
            if (!candidate.hasLocation ||
                candidate.latitude == null ||
                candidate.longitude == null) {
              continue;
            }
            final d = distCalc(
              searchPoint,
              LatLng(candidate.latitude!, candidate.longitude!),
            );
            if (d < closestDistance) {
              closestDistance = d;
              bestMatchIndex = j;
            }
          }
        }

        // Peek at the winner before committing. Only reject if:
        //  - we have a known search point AND the candidate has GPS
        //  - AND it is implausibly far (> _maxHopDistanceMeters)
        // If the candidate has no GPS we always accept it (can't judge distance).
        final winner = candidatesList[bestMatchIndex];
        final winnerHasGps = winner.hasLocation &&
            winner.latitude != null &&
            winner.longitude != null;
        final tooFar = winnerHasGps &&
            searchPoint != null &&
            closestDistance != double.infinity &&
            closestDistance > _maxHopDistanceMeters;

        if (!tooFar) {
          contact = candidatesList.removeAt(bestMatchIndex);
          if (candidatesList.isEmpty) {
            candidatesByPrefix.remove(fullPrefix);
          }
        }
      }

      final resolvedPosition = _resolvePosition(contact);
      if (resolvedPosition != null) {
        previousPosition = resolvedPosition;
      }

      hops.add(
        ResolvedHop(
          index: hopIndex,
          fullPrefixLabel: fullPrefix,
          contact: contact,
          position: resolvedPosition,
        ),
      );
      hopIndex++;
    }
    return hops;
  }

  /// Builds a list of resolved hops given a raw path buffer.
  /// Performs a depth-first search to find the path with the smallest average
  /// distance between hops, when prefixes collide.
  static List<ResolvedHop> buildPathHopsNew(
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

      var iterations = 0;
      var shortestAverage = double.infinity;
      _MeasuredPath? shortestPath;

      void recurse(int depth, _MeasuredPath path) {
        // Abort early when the graph would take ages to search completely
        if (++iterations >= pathBytes.length * pathBytes.length && shortestPath != null) {
          return;
        }

        final slotStart = depth * stride;

        if (slotStart >= pathBytes.length || pathBytes[slotStart] == 0x00) {
          // We've hit the end of our path or have encountered a padding sentinel
          final endPath = path.toEnd(endLocation);
          final average = endPath.hops == 0 ? double.infinity : endPath.length / endPath.hops;

          if (average < shortestAverage || shortestPath == null) {
            shortestAverage = average;
            shortestPath = endPath;
          }
        } else {
          final slotEnd = (slotStart + stride).clamp(0, pathBytes.length);
          final slotBytes = pathBytes.sublist(slotStart, slotEnd);
          final fullPrefix = slotBytes
              .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
              .join();
          final candidates = candidatesByPrefix[fullPrefix];

          if (candidates != null) {
            for (int i = 0; i < candidates.length; i++) {
              final candidate = candidates[i];
              final hop = ResolvedHop(
                  index: depth,
                  fullPrefixLabel: fullPrefix,
                  contact: candidate,
                  position: _resolvePosition(candidate)
              );

              recurse(depth + 1, path + hop);
            }
          }
        }
      }

      recurse(0, _MeasuredPath(hops: 0, length: 0, path: [], previousLocation: startLocation));

      return shortestPath!.path;
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
