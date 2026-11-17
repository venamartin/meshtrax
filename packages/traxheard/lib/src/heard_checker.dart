import 'dart:async';

import 'observer_server.dart';
import 'sighting.dart';

/// Asks an observer server whether messages that went out were heard.
/// Each send is asked about [askAfter] it went out. A resend is a new
/// packet with its own hash and its own asks. Asks that fall due within
/// [gather] of each other share one request. Once any hash of a message
/// is heard, [onHeard] gets every observer that heard it and the message
/// is no longer asked about.
class HeardChecker {
  HeardChecker({
    required this.server,
    required this.onHeard,
    this.onError,
    this.askAfter = const [
      Duration(seconds: 10),
      Duration(seconds: 25),
      Duration(seconds: 60),
    ],
    this.gather = const Duration(seconds: 1),
    this.maxTracked = 32,
  });

  /// The server to ask, or null to ask nothing.
  final ObserverServer? Function() server;

  /// [id] was heard: one sighting per observer over all its sends, the
  /// closest copy it heard, and the closest observers first.
  final void Function(String id, List<Sighting> sightings) onHeard;

  /// A request failed. Its messages are asked again at their next turn.
  final void Function(Object error)? onError;

  final List<Duration> askAfter;
  final Duration gather;

  /// Messages asked about at once; the oldest is dropped beyond this.
  final int maxTracked;

  final _tracked = <String, _Tracked>{};
  final _due = <String>{};
  Timer? _gatherTimer;

  /// Starts asking about [hash], the packet message [id] just went out as.
  void track(String id, String hash) {
    final tracked = _tracked.remove(id) ?? _Tracked();
    _tracked[id] = tracked;
    tracked.hashes.add(hash.toLowerCase());
    for (final after in askAfter) {
      tracked.timers.add(Timer(after, () => _askSoon(id)));
    }
    while (_tracked.length > maxTracked) {
      forget(_tracked.keys.first);
    }
  }

  /// Adds a hash message [id] was heard under, to ask about it too.
  void addHash(String id, String hash) =>
      _tracked[id]?.hashes.add(hash.toLowerCase());

  /// The hashes message [id] is asked about, or null when it isn't.
  Set<String>? hashesOf(String id) => _tracked[id]?.hashes;

  void forget(String id) {
    _tracked.remove(id)?.cancel();
    _due.remove(id);
  }

  void dispose() {
    for (final tracked in _tracked.values) {
      tracked.cancel();
    }
    _tracked.clear();
    _due.clear();
    _gatherTimer?.cancel();
    _gatherTimer = null;
  }

  void _askSoon(String id) {
    if (!_tracked.containsKey(id)) return;
    _due.add(id);
    _gatherTimer ??= Timer(gather, () => unawaited(_ask()));
  }

  Future<void> _ask() async {
    _gatherTimer = null;
    final server = this.server();
    final idOf = <String, String>{
      for (final id in _due)
        for (final hash in _tracked[id]?.hashes ?? const <String>{}) hash: id,
    };
    _due.clear();
    if (server == null || idOf.isEmpty) return;

    final Map<String, List<Sighting>> found;
    try {
      found = await server.sightings(idOf.keys);
    } catch (e) {
      onError?.call(e);
      return;
    }

    final heard = <String, Map<String, Sighting>>{};
    for (final MapEntry(key: hash, value: sightings) in found.entries) {
      final id = idOf[hash];
      if (id == null) continue;
      final byObserver = heard[id] ??= {};
      for (final sighting in sightings) {
        final kept = byObserver[sighting.observer];
        // An observer often hears several copies, one per path.
        if (kept == null || _closestFirst(sighting, kept) < 0) {
          byObserver[sighting.observer] = sighting;
        }
      }
    }
    for (final MapEntry(key: id, value: byObserver) in heard.entries) {
      // Forgotten while the request was out: the app moved on.
      if (byObserver.isEmpty || !_tracked.containsKey(id)) continue;
      forget(id);
      onHeard(id, byObserver.values.toList()..sort(_closestFirst));
    }
  }
}

/// Fewer repeaters first, direct at the top and unknown at the bottom,
/// then the stronger signal.
int _closestFirst(Sighting a, Sighting b) {
  const unknown = 1 << 30;
  final hops = (a.hops ?? unknown).compareTo(b.hops ?? unknown);
  if (hops != 0) return hops;
  return (b.snr ?? double.negativeInfinity)
      .compareTo(a.snr ?? double.negativeInfinity);
}

class _Tracked {
  final hashes = <String>{};
  final timers = <Timer>[];

  void cancel() {
    for (final timer in timers) {
      timer.cancel();
    }
  }
}
