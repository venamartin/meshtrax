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

/// The route a send to [contact] goes out on. A user override is written at
/// the radio's current width ([radioWidth]); the firmware's own route carries
/// the width it was learned at.
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
      hashSize: radioWidth,
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
