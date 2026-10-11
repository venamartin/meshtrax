import 'dart:typed_data';

import 'contact.dart';

const int recentAttemptDiversityWindow = 2;

class PathSelection {
  final List<int> pathBytes;
  final int hopCount;
  // Hash width of pathBytes; the radio's own width for a flood.
  final int hashSize;
  final bool useFlood;

  const PathSelection({
    required this.pathBytes,
    required this.hopCount,
    required this.hashSize,
    required this.useFlood,
  });
}

/// The route a send to [contact] goes out on. Every route carries the width
/// it was made at: an override the radio width when the user set it, the
/// firmware's own route the width it was learned at. [radioWidth] is only
/// for floods and for overrides saved before their width was recorded.
PathSelection resolvePathSelection(
  Contact contact, {
  required int radioWidth,
  PathSelection? selection,
  bool forceFlood = false,
}) {
  if (contact.pathOverride != null) {
    if (contact.pathOverride! < 0) {
      return PathSelection(
        pathBytes: const [],
        hopCount: -1,
        hashSize: radioWidth,
        useFlood: true,
      );
    }
    return PathSelection(
      pathBytes: contact.pathOverrideBytes ?? Uint8List(0),
      hopCount: contact.pathOverride!,
      hashSize: contact.overrideHashSize(radioWidth),
      useFlood: false,
    );
  }

  if (forceFlood || contact.pathLength < 0 || selection?.useFlood == true) {
    return PathSelection(
      pathBytes: const [],
      hopCount: -1,
      hashSize: radioWidth,
      useFlood: true,
    );
  }

  if (selection != null && selection.pathBytes.isNotEmpty) {
    return PathSelection(
      pathBytes: selection.pathBytes,
      hopCount: selection.hopCount,
      hashSize: selection.hashSize,
      useFlood: false,
    );
  }

  return PathSelection(
    pathBytes: contact.path,
    hopCount: contact.pathLength,
    hashSize: contact.pathHashSize,
    useFlood: false,
  );
}
