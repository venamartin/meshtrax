import 'dart:typed_data';

import '../helpers/path_helper.dart';

/// What this radio heard of one photo it sent through repeaters, for the
/// photo's row: which of its packets a repeater was heard passing on, from
/// the copies the chat matched to them
/// (MeshCoreConnector.sendChannelPackets).
///
/// The radio hears its own packet only when a repeater sends it again, so a
/// copy always comes with at least one repeater in its path.
class PhotoRepeats {
  PhotoRepeats({
    required this.packets,
    required this.hasRepair,
    required this.messageId,
  });

  /// Packets the photo went out as, the repair packet included.
  final int packets;

  final bool hasRepair;

  /// The photo's chat row.
  final String messageId;

  final Set<int> _passedOn = {};

  /// The paths the copies came through, each once, first heard first.
  final List<Uint8List> paths = [];

  /// The width of the repeater codes in [paths].
  int pathHashSize = 1;

  /// Copies heard, every one, car repeaters' too.
  int copies = 0;

  /// The first repeaters already told to Pathfinder, by code.
  final Set<String> _firstHops = {};

  /// Where the photo rules apply: the radio and the time this photo counted
  /// against them, so its time through repeaters can be given back.
  ({String radio, DateTime at})? counted;

  /// When a packet last went to the radio, first or again.
  DateTime? lastSentAt;

  /// A copy of packet [index] came back through [path], in [width]-byte
  /// repeater codes. [repeaters]: the codes in [path] of the repeaters that
  /// don't move with the user; none says nothing of the mesh (as for channel
  /// texts, #356).
  void note(
    int index,
    Uint8List path,
    int width, {
    Set<String> repeaters = const {},
  }) {
    copies++;
    pathHashSize = width;
    if (!paths.any((p) => _same(p, path))) paths.add(Uint8List.fromList(path));
    if (repeaters.isNotEmpty) _passedOn.add(index);
  }

  /// Whether a copy through [path] is the first of this photo through its
  /// first repeater, which then heard this radio directly: Pathfinder hears
  /// of each once.
  bool firstThrough(Uint8List path, int width) =>
      path.length >= width &&
      _firstHops.add(PathHelper.hopHex(path.sublist(0, width)));

  bool passedOn(int index) => _passedOn.contains(index);

  /// How many of the [packets] a repeater was heard passing on.
  int get passedOnCount => _passedOn.length;

  /// A repeater was heard passing on every packet a receiver needs: all the
  /// data packets, or all but one and the repair packet.
  bool get complete {
    final data = hasRepair ? packets - 1 : packets;
    final dataHeard = _passedOn.where((i) => i < data).length;
    return dataHeard == data ||
        (hasRepair && passedOn(packets - 1) && dataHeard == data - 1);
  }

  static bool _same(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
