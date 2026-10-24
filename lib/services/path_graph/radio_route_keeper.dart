import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../connector/meshcore_protocol.dart';
import '../../helpers/path_helper.dart';
import '../../models/contact.dart';
import '../../models/path_selection.dart';
import '../../utils/app_logger.dart';

/// Keeps Pathfinder's route to each active contact stored on the radio.
///
/// The radio ACKs a DM that arrived direct on the route it stores for the
/// sender, 200 ms after the DM arrives and before the app hears of it
/// (firmware sendAckTo), so the route must be in place beforehand. A DM
/// that arrived as a flood is ACKed inside the flooded PATH reply and
/// ignores the stored route.
///
/// The stored route is Pathfinder's best; when Pathfinder knows nothing
/// it is cleared, so ACKs flood. When the same message arrives again the
/// sender missed the ACK, and the stored route steps down the DM ladder
/// ([planAttempts], the sequence a send uses), ending in a flood. A user
/// override, a contact Pathfinder cannot route for, and a contact whose
/// own ladder is running are left alone. A retry copy is never evidence
/// for Pathfinder: the sender's timer may simply be short.
///
/// Splices (owner, 2026-10-24): a route with guessed hops may hold the
/// stored route only at rung 0 and only with one guess; from the first
/// step down the rungs are proven routes, then flood. A splice whose ACK
/// was lost is retired for that contact, here and not in the graph, until
/// a send of mine delivers on it — otherwise the same wrong guess would be
/// written again for every new message while the hint stays fresh.
class RadioRouteKeeper {
  RadioRouteKeeper({
    required this.contacts,
    required this.routesFor,
    required this.radioWidth,
    required this.budget,
    required this.isSendingTo,
    required this.recentChats,
    required this.withRouteLock,
    required this.writeRoute,
  });

  final List<Contact> Function() contacts;
  // Pathfinder's ranked routes; null when it cannot route at all.
  final List<PathSelection>? Function(Contact) routesFor;
  final int Function() radioWidth;
  final int Function() budget;
  final bool Function(String contactKey) isSendingTo;
  final Future<Set<String>> Function(DateTime since) recentChats;
  final Future<void> Function(Future<void> Function() body) withRouteLock;
  // Writes the route; a flood clears it.
  final Future<void> Function(Contact, PathSelection) writeRoute;

  static const recentWindow = Duration(days: 7);
  static const episodeWindow = Duration(minutes: 3);
  static const syncDelay = Duration(seconds: 60);
  static const rewriteCooldown = Duration(minutes: 10);

  final Map<String, _Episode> _episodes = {};
  final Map<String, DateTime> _lastWrite = {};
  // Per contact: splices that lost an ACK while held, keyed like a ladder
  // rung, until a send of mine proves them.
  final Map<String, Set<String>> _retired = {};

  /// How many guessed hops a route may carry and still hold the stored
  /// route at rung 0.
  static const maxGuessedHopsHeld = 1;

  static String routeKey(PathSelection r) =>
      r.hopCount == 0 ? 'direct' : '${r.hashSize}:${r.pathBytes.join(',')}';
  Timer? _syncTimer;
  bool _syncing = false;
  bool _disposed = false;

  /// The ladder rung the radio should hold once [directCopies] copies of
  /// one message have arrived direct. A direct copy followed by another
  /// copy lost its ACK on the stored route, so the route steps past it;
  /// the newest copy's ACK is still on its way. Four direct copies are
  /// therefore ACKed on PF1, PF1, PF2, PF3.
  @visibleForTesting
  static int rungFor({required int directCopies, required bool newestDirect}) =>
      newestDirect ? directCopies - 1 : directCopies;

  /// Whether [contact], as the radio holds it, already stores [route].
  @visibleForTesting
  static bool holds(Contact contact, PathSelection route) {
    if (route.useFlood) return contact.pathLength < 0;
    if (contact.pathLength != route.hopCount) return false;
    if (route.hopCount == 0) return true;
    return contact.pathHashSize == route.hashSize &&
        listEquals(contact.path, route.pathBytes);
  }

  /// A DM or room post from [contact] that arrived while connected.
  void onCopy(Contact contact, int senderTimestamp, int txtType, String text,
      bool direct) {
    if (_disposed || !_eligible(contact)) return;
    final key = _key(contact.publicKeyHex);
    final id = '$txtType:$senderTimestamp:$text';
    appLogger.info(
        'DM from ${contact.name} arrived ${direct ? "on a route" : "as a flood"}; '
        'the radio ACKed it '
        '${!direct ? "inside its flooded path reply" : contact.pathLength < 0 ? "by flood (no stored route)" : "on ${_describeStored(contact)}"}',
        tag: 'PathGraph');
    var episode = _episodes[key];
    if (episode == null || episode.message != id) {
      episode?.expiry?.cancel();
      if (routesFor(contact) == null) {
        _episodes.remove(key);
        return;
      }
      episode = _episodes[key] = _Episode(id);
    } else {
      appLogger.info(
          '${contact.name} sent the same message again, so my last ACK '
          '(${episode.newestAckOnRoute ? "on the stored route" : "a flood"}) '
          'never reached them',
          tag: 'PathGraph');
      if (episode.newestAckOnRoute) {
        episode.held ??=
            routesFor(contact)?.where((r) => holds(contact, r)).firstOrNull;
        _retireHeldSplice(contact, key);
      }
    }
    if (direct) episode.directCopies++;
    episode.newestDirect = direct;
    // The radio ACKs a direct copy on its stored route, or floods the ACK
    // when it has none.
    episode.newestAckOnRoute = direct && contact.pathLength >= 0;
    episode.expiry?.cancel();
    episode.expiry = Timer(episodeWindow, () {
      _episodes.remove(key);
      unawaited(_apply(key));
    });
    unawaited(_apply(key));
  }

  /// The stored route the last ACK went on was a splice: it is not held
  /// again for this contact until a send of mine proves it.
  void _retireHeldSplice(Contact contact, String key) {
    final held = _rung0(contact);
    if (held == null || held.guessedHops == 0 || !holds(contact, held)) return;
    (_retired[key] ??= {}).add(routeKey(held));
    appLogger.info(
        'the stored route to ${contact.name} (${_describe(held)}, '
        '${held.guessedHops} hop${held.guessedHops == 1 ? "" : "s"} guessed) '
        'lost an ACK: not held again until a send of mine proves it',
        tag: 'PathGraph');
  }

  /// A send of mine delivered on [route]: the route is proven, and a
  /// retired splice of it may be held again.
  void onDelivered(String contactKey, PathSelection route) {
    if (route.useFlood) return;
    _retired[_key(contactKey)]?.remove(routeKey(route));
  }

  /// The radio's route to [contactKey] may no longer be Pathfinder's: the
  /// firmware learned a new one, or a ladder of mine left its last rung.
  void reassert(String contactKey) {
    if (_disposed) return;
    unawaited(_apply(_key(contactKey)));
  }

  /// The radio (re)connected: check every active contact soon.
  void onConnected() {
    _lastWrite.clear();
    scheduleSync();
  }

  /// What Pathfinder knows changed: check every active contact, at most
  /// once a [syncDelay].
  void scheduleSync() {
    if (_disposed) return;
    _syncTimer ??= Timer(syncDelay, () {
      _syncTimer = null;
      unawaited(_syncAll());
    });
  }

  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
    for (final episode in _episodes.values) {
      episode.expiry?.cancel();
    }
    _episodes.clear();
    _retired.clear();
  }

  Future<void> _syncAll() async {
    if (_syncing || _disposed) return;
    _syncing = true;
    try {
      final recent = {
        for (final k in await recentChats(DateTime.now().subtract(recentWindow)))
          _key(k),
      };
      for (final contact in contacts()) {
        if (_disposed) return;
        if (!_eligible(contact)) continue;
        final key = _key(contact.publicKeyHex);
        if (!contact.isFavorite &&
            !recent.contains(key) &&
            !_episodes.containsKey(key)) {
          continue;
        }
        final last = _lastWrite[key];
        await _apply(key,
            clearOnly: last != null &&
                DateTime.now().difference(last) < rewriteCooldown);
      }
    } catch (e) {
      appLogger.warn('stored route check failed: $e', tag: 'PathGraph');
    } finally {
      _syncing = false;
    }
  }

  /// [clearOnly]: inside the rewrite cooldown only a clear goes out — a
  /// route Pathfinder no longer stands behind (a moving repeater's link
  /// went stale) would have the radio ACK on a dead route meanwhile.
  Future<void> _apply(String key, {bool clearOnly = false}) async {
    try {
      await withRouteLock(() async {
        if (_disposed) return;
        final contact = contacts()
            .where((c) => _key(c.publicKeyHex) == key)
            .firstOrNull;
        if (contact == null ||
            !_eligible(contact) ||
            isSendingTo(contact.publicKeyHex)) {
          return;
        }
        final want = _wanted(contact);
        if (want == null || holds(contact, want)) return;
        if (clearOnly && !want.useFlood) return;
        _lastWrite[key] = DateTime.now();
        appLogger.info(
            'stored route to ${contact.name} set to '
            '${want.useFlood ? "none (ACKs flood)" : _describe(want)}',
            tag: 'PathGraph');
        await writeRoute(contact, want);
      });
    } catch (e) {
      appLogger.warn('stored route write failed: $e', tag: 'PathGraph');
    }
  }

  /// Pathfinder's current best until a retry shows an ACK lost; from the
  /// first step on, the ladder planned at that step.
  PathSelection? _wanted(Contact contact) {
    final episode = _episodes[_key(contact.publicKeyHex)];
    final rung = episode == null
        ? 0
        : rungFor(
            directCopies: episode.directCopies,
            newestDirect: episode.newestDirect);
    if (rung == 0) return _rung0(contact);
    // The ladder a send would have run from the held route: that route
    // first (its rung is the one that failed), then proven routes only.
    final ladder = episode!.ladder ??=
        _ladderFor(contact, provenOnly: true, first: episode.held);
    if (ladder == null) return null;
    return rung < ladder.length ? ladder[rung] : PathSelection.flood(radioWidth());
  }

  /// The route held before any step down: Pathfinder's best among routes
  /// with at most [maxGuessedHopsHeld] guessed hops that are not retired.
  PathSelection? _rung0(Contact contact) {
    final retired = _retired[_key(contact.publicKeyHex)] ?? const <String>{};
    return _ladderFor(contact,
        keep: (r) =>
            r.guessedHops <= maxGuessedHopsHeld &&
            !retired.contains(routeKey(r)))?.first;
  }

  /// The DM ladder for [contact] over Pathfinder's routes, [keep] only;
  /// [provenOnly] keeps routes with no guessed hop (the step-down rungs);
  /// [first] goes ahead of them whatever it is.
  List<PathSelection>? _ladderFor(Contact contact,
      {bool provenOnly = false,
      bool Function(PathSelection)? keep,
      PathSelection? first}) {
    final routes = routesFor(contact);
    if (routes == null) return null;
    return planAttempts(contact,
        radioWidth: radioWidth(),
        budget: budget(),
        graphRoutes: [
          ?first,
          for (final r in routes)
            if ((!provenOnly || r.guessedHops == 0) && (keep?.call(r) ?? true))
              r,
        ]);
  }

  static bool _eligible(Contact contact) =>
      contact.pathOverride == null &&
      (contact.type == advTypeChat || contact.type == advTypeRoom);

  static String _key(String pubkeyHex) => pubkeyHex.toLowerCase();

  static String _describe(PathSelection route) => route.hopCount == 0
      ? 'direct (no repeater)'
      : PathHelper.formatPathHex(route.pathBytes, stride: route.hashSize);

  static String _describeStored(Contact contact) => contact.pathLength == 0
      ? 'direct (no repeater)'
      : PathHelper.formatPathHex(contact.path, stride: contact.pathHashSize);
}

/// The copies of one message from one contact.
class _Episode {
  _Episode(this.message);

  final String message;
  // Planned at the first step down, then kept, like a send's ladder.
  List<PathSelection>? ladder;
  // The route the radio held when the first ACK was lost: the ladder's
  // rung 0, whatever Pathfinder ranks now.
  PathSelection? held;
  int directCopies = 0;
  bool newestDirect = false;
  bool newestAckOnRoute = false;
  Timer? expiry;
}
