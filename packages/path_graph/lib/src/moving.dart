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

/// What a watching-only detector counted when it judged a repeater: its
/// links new in the window, its older links heard again in it, and
/// whether the new ones outnumbered them enough to tag it.
typedef MovingCheck = ({int newLinks, int oldLinks, bool tagged});

/// Watching-only detectors (owner, 2026-10-19). A moving repeater keeps
/// meeting repeaters it never had links to, hour after hour, and leaves
/// its old neighbours behind. A busy fixed one meets new ones too — the
/// radio only ever samples its links — but keeps being heard with the
/// old ones (field, 2026-10-23: hilltops 0–12% new, a van 57%). One burst
/// — me arriving somewhere new, a propagation lift, a code twin starting
/// to relay — is not enough: the new links must spread over several
/// slices.
class NoveltyCounter {
  NoveltyCounter({required this.sliceMs, this.slices = 6, this.minSlices = 3});

  final int sliceMs;
  final int slices;
  final int minSlices;
  final Map<String, List<int>> _times = {};
  // Per repeater: its links from before the window heard again in it, and
  // when last.
  final Map<String, Map<(String, String), int>> _old = {};
  int _sweptAt = 0;

  int get span => sliceMs * slices;

  /// Records one new link of [hash]; true when its new links in the last
  /// [slices] slices number at least [minLinks] and fill [minSlices] of
  /// them.
  bool add(String hash, int now, {required int minLinks}) {
    if (_times.length > 512) {
      _times.removeWhere((_, t) => t.isEmpty || now - t.last >= span);
    }
    final times = (_times[hash] ??= [])
      ..add(now)
      ..removeWhere((t) => now - t >= span);
    if (times.length < minLinks) return false;
    return {for (final t in times) (now - t) ~/ sliceMs}.length >= minSlices;
  }

  /// A sighting of [hash]'s existing [link]; counts when the link is
  /// older than the window.
  void seen(String hash, (String, String) link, int now, int? firstObserved) {
    if (firstObserved != null && now - firstObserved < span) return;
    if (now - _sweptAt >= span) {
      _sweptAt = now;
      for (final links in _old.values) {
        links.removeWhere((_, t) => now - t >= span);
      }
      _old.removeWhere((_, links) => links.isEmpty);
    }
    (_old[hash] ??= {})[link] = now;
  }

  /// [hash]'s new links in the window, as of its last [add].
  int newLinks(String hash) => _times[hash]?.length ?? 0;

  /// [hash]'s links from before the window heard again in it.
  int oldLinks(String hash, int now) =>
      _old[hash]?.values.where((t) => now - t < span).length ?? 0;

  void clear() {
    _times.clear();
    _old.clear();
  }
}
