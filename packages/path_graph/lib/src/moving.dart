import 'estimator.dart';
import 'graph_store.dart';

/// Why Pathfinder treats a repeater as moving.
enum MovingReason {
  /// The user said it moves.
  manual,

  /// The user said it travels with this radio.
  manualWithMe,

  /// An advert from the same key showed it somewhere else.
  advertMoved,

  /// It stays my best doorstep while the repeaters behind it in my own
  /// echoes keep being new (watching-only detector).
  ridesWithMe,

  /// It keeps meeting repeaters it never had links to (watching-only
  /// detector).
  newLinks,
}

class MovingStatus {
  const MovingStatus(this.reason, {required this.acts});

  final MovingReason reason;

  /// False for a watching-only detector's tag: shown and logged, but
  /// routing ignores it ([PathGraphConfig.mobileAutoTagsRoute]).
  final bool acts;

  /// It travels with this radio: my doorstep row for it stays usable.
  bool get withMe =>
      reason == MovingReason.manualWithMe || reason == MovingReason.ridesWithMe;
}

/// Adverts from a repeater without a position fix carry 0,0, and one whose
/// owner has set only one of lat and lon carries a 0 in the other (the
/// firmware sends whole millionths, so an exact 0 means "not set").
bool isRealPosition(double? lat, double? lon) =>
    lat != null && lon != null && lat.abs() > 1e-6 && lon.abs() > 1e-6;

/// The user's word first, then an advert move, then the detectors.
MovingStatus? movingStatusOf(
    NodeState node, PathGraphConfig config, int nowMillis) {
  switch (node.movingOverride) {
    case MovingOverride.staysPut:
      return null;
    case MovingOverride.moves:
      return const MovingStatus(MovingReason.manual, acts: true);
    case MovingOverride.withMe:
      return const MovingStatus(MovingReason.manualWithMe, acts: true);
    case null:
      break;
  }
  final window = (config.mobileTagDays * Duration.millisecondsPerDay).round();
  bool recent(int? at) => at != null && nowMillis - at <= window;
  final auto = config.mobileAutoTagsRoute;
  if (auto && recent(node.autoRidesWithMeAt)) {
    return const MovingStatus(MovingReason.ridesWithMe, acts: true);
  }
  if (recent(node.movedAt)) {
    return const MovingStatus(MovingReason.advertMoved, acts: true);
  }
  if (recent(node.autoRidesWithMeAt)) {
    return MovingStatus(MovingReason.ridesWithMe, acts: auto);
  }
  if (recent(node.autoMovingAt)) {
    return MovingStatus(MovingReason.newLinks, acts: auto);
  }
  return null;
}

/// Watching-only detectors (owner, 2026-10-19). A fixed repeater's set of
/// links fills within a day and then barely grows; a moving one keeps
/// meeting repeaters it never had links to, hour after hour. One burst — me
/// arriving somewhere new, a propagation lift, a code twin starting to
/// relay — is not enough: the new links must spread over several slices.
class NoveltyCounter {
  NoveltyCounter({required this.sliceMs, this.slices = 6, this.minSlices = 3});

  final int sliceMs;
  final int slices;
  final int minSlices;
  final Map<String, List<int>> _times = {};

  /// Records one new link of [hash]; true when its new links in the last
  /// [slices] slices number at least [minLinks] and fill [minSlices] of
  /// them.
  bool add(String hash, int now, {required int minLinks}) {
    final span = sliceMs * slices;
    if (_times.length > 512) {
      _times.removeWhere((_, t) => t.isEmpty || now - t.last >= span);
    }
    final times = (_times[hash] ??= [])
      ..add(now)
      ..removeWhere((t) => now - t >= span);
    if (times.length < minLinks) return false;
    return {for (final t in times) (now - t) ~/ sliceMs}.length >= minSlices;
  }

  void clear() => _times.clear();
}
