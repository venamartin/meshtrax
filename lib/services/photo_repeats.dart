import 'dart:typed_data';

import '../helpers/path_helper.dart';

/// What this radio heard of one photo it sent through repeaters: which of
/// its packets a repeater was heard passing on, from copies of them in the
/// radio's raw log, and whether one may go out once more.
///
/// The radio hears its own packet only when a repeater sends it again, so a
/// copy always comes with at least one repeater in its path. Only a copy
/// that is the packet as sent, byte for byte, counts: two senders can share
/// the 2-byte prefix and image id.
class PhotoRepeats {
  /// The packets as sent, the repair packet last if [hasRepair].
  final List<Uint8List> blobs;

  final bool hasRepair;

  /// The pause after each packet, and when the first went out.
  final Duration gap;
  final DateTime startedAt = DateTime.now();

  PhotoRepeats({
    required this.blobs,
    required this.hasRepair,
    this.gap = Duration.zero,
  });

  /// Packets the photo went out as, the repair packet included.
  int get packets => blobs.length;

  final Set<int> _passedOn = {};

  /// The paths the copies came through, each once, first heard first.
  final List<Uint8List> paths = [];

  /// The width of the repeater codes in [paths].
  int pathHashSize = 1;

  /// Copies heard, every one, car repeaters' too.
  int copies = 0;

  /// Copies through a repeater that doesn't move with the user, and how
  /// many there were when the last packet went out once more.
  int _passedOnCopies = 0;
  int? _passedOnCopiesAtResend;

  /// The first repeaters already told to Pathfinder, by code.
  final Set<String> _firstHops = {};

  /// The photo's chat row, once it is filed.
  String? messageId;

  /// Where the photo rules apply: the radio and the time this photo counted
  /// against them, so its time through repeaters can be given back.
  ({String radio, DateTime at})? counted;

  /// When observers began to be asked about its packets, if they are.
  DateTime? observersAskedAt;

  /// A copy of packet [index] came back as [blob] through [path], in
  /// [width]-byte repeater codes. [carOnly]: every repeater in its path
  /// moves with the user, so it says nothing of the mesh (as for channel
  /// texts, #356). False when it isn't a copy of that packet as sent.
  bool note(
    int index,
    Uint8List blob,
    Uint8List path,
    int width, {
    bool carOnly = false,
  }) {
    if (path.isEmpty ||
        index < 0 ||
        index >= packets ||
        !_same(blob, blobs[index])) {
      return false;
    }
    copies++;
    pathHashSize = width;
    if (!paths.any((p) => _same(p, path))) paths.add(Uint8List.fromList(path));
    if (!carOnly) {
      _passedOn.add(index);
      _passedOnCopies++;
    }
    return true;
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

  /// Whether packet [index] goes out once more: no repeater was heard
  /// passing it on. Not while nothing has been heard since the last packet
  /// that went once more. With the same bytes, that one could be heard only
  /// if the repeater missed the first, so its silence alone proves nothing;
  /// but where no repeater hears this radio at all (or none carries the
  /// channel's region), every copy would be wasted, and this keeps it to one.
  bool sendAgain(int index) {
    if (passedOn(index) || _passedOnCopies == _passedOnCopiesAtResend) {
      return false;
    }
    _passedOnCopiesAtResend = _passedOnCopies;
    sentAgain(index);
    return true;
  }

  final Map<int, int> _timesAgain = {};

  /// How many times packet [index] went out once more.
  int timesAgain(int index) => _timesAgain[index] ?? 0;

  void sentAgain(int index) => _timesAgain[index] = timesAgain(index) + 1;

  /// The data packets no repeater was heard passing on and no observer
  /// heard ([heard]), by index; none when what was heard already lets a
  /// receiver put the photo together.
  List<int> unconfirmed(Set<int> heard) {
    bool confirmed(int i) => passedOn(i) || heard.contains(i);
    final data = hasRepair ? packets - 1 : packets;
    final missing = [
      for (var i = 0; i < data; i++)
        if (!confirmed(i)) i,
    ];
    if (hasRepair && missing.length == 1 && confirmed(packets - 1)) {
      return const [];
    }
    return missing;
  }

  static bool _same(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
