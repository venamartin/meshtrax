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

/// Adverts from a repeater without a position fix carry 0,0.
bool isRealPosition(double? lat, double? lon) =>
    lat != null && lon != null && (lat.abs() > 1e-6 || lon.abs() > 1e-6);

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
