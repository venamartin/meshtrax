import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/path_graph/radio_route_keeper.dart';

// The radio ACKs a direct DM on the route it stores for the sender, before
// the app hears of the DM. The keeper holds Pathfinder's best there and,
// when the same message arrives again (the ACK was lost), steps down the
// DM ladder: the ACKs of four direct copies go on PF1, PF1, PF2, PF3.

PathSelection _route(List<int> bytes) => PathSelection(
      pathBytes: bytes,
      hopCount: bytes.length ~/ 2,
      hashSize: 2,
      useFlood: false,
      source: RouteSource.graph,
      estDelivery: 0.5,
    );

final _pf1 = _route([0xA1, 0xA1]);
final _pf2 = _route([0xB2, 0xB2, 0xC3, 0xC3]);
final _pf3 = _route([0xD4, 0xD4]);

Contact _contact({
  String name = 'CAROL',
  int seed = 0xC0,
  int type = advTypeChat,
  int flags = 0,
  int? pathOverride,
  PathSelection? stored,
}) =>
    Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
      name: name,
      type: type,
      flags: flags,
      pathLength: stored == null ? -1 : stored.hopCount,
      path: Uint8List.fromList(stored?.pathBytes ?? const []),
      pathHashSize: 2,
      pathOverride: pathOverride,
      lastSeen: DateTime.now(),
    );

class _Radio {
  _Radio(this.contacts);

  final List<Contact> contacts;
  List<PathSelection>? routes = [_pf1, _pf2, _pf3];
  int budget = 5;
  final sending = <String>{};
  Set<String> recent = {};
  final writes = <String>[];

  late final keeper = RadioRouteKeeper(
    contacts: () => contacts,
    routesFor: (_) => routes,
    radioWidth: () => 2,
    budget: () => budget,
    isSendingTo: sending.contains,
    recentChats: (_) async => recent,
    withRouteLock: (body) => body(),
    writeRoute: (contact, route) async {
      final i =
          contacts.indexWhere((c) => c.publicKeyHex == contact.publicKeyHex);
      contacts[i] = contacts[i].copyWith(
        pathLength: route.useFlood ? -1 : route.hopCount,
        path: Uint8List.fromList(route.pathBytes),
        pathHashSize: route.hashSize,
      );
      writes.add('${contact.name}:${_name(route)}');
    },
  );

  String _name(PathSelection r) => r.useFlood
      ? 'flood'
      : identical(r, _pf1)
          ? 'PF1'
          : identical(r, _pf2)
              ? 'PF2'
              : identical(r, _pf3)
                  ? 'PF3'
                  : 'other';

  void copy(FakeAsync async, Contact c,
      {bool direct = true, int stamp = 1000, String text = 'hi'}) {
    keeper.onCopy(c, stamp, txtTypePlain, text, direct);
    async.flushMicrotasks();
  }
}

void main() {
  test('step rule: a direct copy counts once the next copy shows its ACK lost',
      () {
    expect(RadioRouteKeeper.rungFor(directCopies: 1, newestDirect: true), 0);
    expect(RadioRouteKeeper.rungFor(directCopies: 2, newestDirect: true), 1);
    expect(RadioRouteKeeper.rungFor(directCopies: 1, newestDirect: false), 1);
    expect(RadioRouteKeeper.rungFor(directCopies: 0, newestDirect: false), 0);
  });

  test('holds compares the stored route with the wanted one', () {
    expect(RadioRouteKeeper.holds(_contact(stored: _pf1), _pf1), isTrue);
    expect(RadioRouteKeeper.holds(_contact(stored: _pf1), _pf2), isFalse);
    expect(RadioRouteKeeper.holds(_contact(), const PathSelection.flood(2)),
        isTrue);
    expect(RadioRouteKeeper.holds(_contact(stored: _pf1),
        const PathSelection.flood(2)), isFalse);
    // A zero-hop route is "no repeater" at any width.
    final direct = PathSelection(
        pathBytes: const [], hopCount: 0, hashSize: 1, useFlood: false);
    expect(RadioRouteKeeper.holds(_contact(stored: _route(const [])), direct),
        isTrue);
  });

  test('retry copies step the stored route down the ladder, then clear it',
      () {
    fakeAsync((async) {
      final radio = _Radio([_contact(stored: _pf1)]);
      final carol = radio.contacts.first;
      radio.copy(async, carol); // ACKed on PF1, which it already holds
      expect(radio.writes, isEmpty);
      radio.copy(async, carol); // ACKed on PF1: the first ACK was lost
      expect(radio.writes, ['CAROL:PF2']);
      radio.copy(async, carol);
      radio.copy(async, carol);
      radio.copy(async, carol); // past the routes: the ladder floods
      expect(radio.writes, ['CAROL:PF2', 'CAROL:PF3', 'CAROL:flood']);
    });
  });

  test('a copy that came as a flood does not test the stored route', () {
    fakeAsync((async) {
      final radio = _Radio([_contact(stored: _pf1)]);
      final carol = radio.contacts.first;
      radio.copy(async, carol, direct: false);
      radio.copy(async, carol, direct: false);
      expect(radio.writes, isEmpty);
      radio.copy(async, carol); // the second flood's ACK flooded too
      expect(radio.writes, isEmpty);
      radio.copy(async, carol, direct: false); // the direct copy's ACK lost
      expect(radio.writes, ['CAROL:PF2']);
    });
  });

  test('the ladder follows the retry budget, like a send', () {
    fakeAsync((async) {
      final radio = _Radio([_contact(stored: _pf1)])..budget = 3;
      final carol = radio.contacts.first;
      radio.copy(async, carol);
      radio.copy(async, carol); // budget 3: one route, then floods
      expect(radio.writes, ['CAROL:flood']);
    });
  });

  // Field 2026-10-16: the first DM came while Pathfinder knew nothing; my
  // reply's PATH reply taught it "direct" a second later, but the stored
  // route stayed cleared for the 3-minute wait.
  test('a route Pathfinder learns before any retry is used at once', () {
    fakeAsync((async) {
      final radio = _Radio([_contact(stored: _pf1)])..routes = [];
      final carol = radio.contacts.first;
      radio.copy(async, carol);
      radio.routes = [_pf1, _pf2];
      radio.keeper.reassert(carol.publicKeyHex);
      async.flushMicrotasks();
      expect(radio.writes, ['CAROL:flood', 'CAROL:PF1']);
    });
  });

  test('a new message starts again from the best route', () {
    fakeAsync((async) {
      final radio = _Radio([_contact(stored: _pf1)]);
      final carol = radio.contacts.first;
      radio.copy(async, carol);
      radio.copy(async, carol);
      radio.copy(async, radio.contacts.first, stamp: 2000, text: 'next');
      expect(radio.writes, ['CAROL:PF2', 'CAROL:PF1']);
    });
  });

  test('after the copies stop the best route goes back', () {
    fakeAsync((async) {
      final radio = _Radio([_contact(stored: _pf1)]);
      final carol = radio.contacts.first;
      radio.copy(async, carol);
      radio.copy(async, carol);
      async.elapse(RadioRouteKeeper.episodeWindow);
      expect(radio.writes, ['CAROL:PF2', 'CAROL:PF1']);
    });
  });

  test('overrides, repeaters and a Pathfinder that cannot route are left alone',
      () {
    fakeAsync((async) {
      final radio = _Radio([
        _contact(name: 'CUSTOM', seed: 0x10, pathOverride: 2, stored: _pf3),
        _contact(name: 'RPT', seed: 0x40, type: advTypeRepeater, stored: _pf3),
      ]);
      for (final c in List.of(radio.contacts)) {
        radio.copy(async, c);
        radio.copy(async, c);
      }
      radio.routes = null;
      final carol = _contact(stored: _pf3);
      radio.contacts.add(carol);
      radio.copy(async, carol);
      radio.copy(async, carol);
      expect(radio.writes, isEmpty);
    });
  });

  test('a running send ladder owns the route; its end hands it back', () {
    fakeAsync((async) {
      final radio = _Radio([_contact(stored: _pf3)]);
      final carol = radio.contacts.first;
      radio.sending.add(carol.publicKeyHex);
      radio.copy(async, carol);
      expect(radio.writes, isEmpty);
      radio.sending.clear();
      radio.keeper.onLadderEnded(carol.publicKeyHex, delivered: true);
      async.flushMicrotasks();
      expect(radio.writes, ['CAROL:PF1']);
    });
  });

  test('the firmware replacing the route is undone', () {
    fakeAsync((async) {
      final radio = _Radio([_contact(stored: _route([0xEE, 0xEE]))]);
      radio.keeper.reassert(radio.contacts.first.publicKeyHex.toUpperCase());
      async.flushMicrotasks();
      expect(radio.writes, ['CAROL:PF1']);
    });
  });

  test('background check: recent chats and favourites only, once per cooldown',
      () {
    fakeAsync((async) {
      final radio = _Radio([
        _contact(name: 'RECENT', seed: 0x10),
        _contact(name: 'FAV', seed: 0x40, flags: contactFlagFavorite),
        _contact(name: 'QUIET', seed: 0x70),
      ]);
      radio.recent = {radio.contacts.first.publicKeyHex.toUpperCase()};
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, ['RECENT:PF1', 'FAV:PF1']);

      // Pathfinder's best moved but the stored route is still listed: within
      // the cooldown it waits.
      radio.routes = [_pf2, _pf1];
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, hasLength(2));

      // A reconnect checks again at once.
      radio.keeper.onConnected();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes.skip(2), ['RECENT:PF2', 'FAV:PF2']);
    });
  });

  // A moving repeater's link went stale: Pathfinder stops standing behind
  // the route, and the radio must not ACK on it for the rest of the
  // cooldown.
  test('a route Pathfinder drops is cleared inside the cooldown', () {
    fakeAsync((async) {
      final radio = _Radio([_contact()]);
      radio.recent = {radio.contacts.first.publicKeyHex};
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, ['CAROL:PF1']);

      radio.routes = [];
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, ['CAROL:PF1', 'CAROL:flood']);

      radio.routes = [_pf2];
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, hasLength(2), reason: 'a new route still waits');
    });
  });

  test('a route Pathfinder drops for another is replaced inside the cooldown',
      () {
    fakeAsync((async) {
      final radio = _Radio([_contact()]);
      radio.recent = {radio.contacts.first.publicKeyHex};
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, ['CAROL:PF1']);

      // PF1 is gone from Pathfinder's list: the radio must not ACK on it.
      radio.routes = [_pf2, _pf3];
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, ['CAROL:PF1', 'CAROL:PF2']);

      // Demoted but still listed: that waits for the cooldown.
      radio.routes = [_pf3, _pf2];
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, hasLength(2));

      radio.routes = [_pf3];
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes.last, 'CAROL:PF3');
    });
  });

  // Field 2026-10-17: a ladder of mine ran out, the graph was told of its
  // failures 5 minutes later, and meanwhile the keeper re-stored the route
  // that had just failed; the next DM's ACK rode it and was lost.
  test('after a ladder of mine ran out the contact is left alone, then held '
      'again', () {
    fakeAsync((async) {
      final radio = _Radio([_contact()]); // the ladder cleared the route
      final carol = radio.contacts.first;
      radio.keeper.onLadderEnded(carol.publicKeyHex, delivered: false);
      async.flushMicrotasks();
      expect(radio.writes, isEmpty,
          reason: 'Pathfinder still ranks the failed route first');
      radio.copy(async, carol); // their DM, ACKed by flood
      expect(radio.writes, isEmpty);
      async.elapse(RadioRouteKeeper.failedLadderHold);
      expect(radio.writes, ['CAROL:PF1']);
    });
  });

  test('a delivery ends the hold at once', () {
    fakeAsync((async) {
      final radio = _Radio([_contact()]);
      final carol = radio.contacts.first;
      radio.keeper.onLadderEnded(carol.publicKeyHex, delivered: false);
      radio.keeper.reassert(carol.publicKeyHex);
      async.flushMicrotasks();
      expect(radio.writes, isEmpty);
      radio.keeper.onDelivered(carol.publicKeyHex, _pf2);
      radio.keeper.reassert(carol.publicKeyHex);
      async.flushMicrotasks();
      expect(radio.writes, ['CAROL:PF1']);

      radio.keeper.onLadderEnded(carol.publicKeyHex, delivered: false);
      radio.routes = [_pf2];
      radio.keeper.onLadderEnded(carol.publicKeyHex, delivered: true);
      async.flushMicrotasks();
      expect(radio.writes, ['CAROL:PF1', 'CAROL:PF2']);
    });
  });

  test('Pathfinder knows nothing: the stored route is cleared, ACKs flood', () {
    fakeAsync((async) {
      final radio = _Radio([_contact(stored: _pf3)])..routes = [];
      radio.recent = {radio.contacts.first.publicKeyHex};
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, ['CAROL:flood']);
    });
  });

  // Splices (owner, 2026-10-24): one guessed hop may hold the stored route
  // at rung 0; the step-down rungs are proven routes only; a splice whose
  // ACK was lost is retired until a send of mine proves it.
  group('splices', () {
    PathSelection splice(List<int> bytes, List<bool> guessed) =>
        PathSelection(
          pathBytes: bytes,
          hopCount: bytes.length ~/ 2,
          hashSize: 2,
          useFlood: false,
          source: RouteSource.graph,
          estDelivery: 0.4,
          guessedLinks: guessed,
        );
    final oneGuess = splice([0xA2, 0x77, 0xAD, 0x77, 0x10, 0x00], [false, true]);
    final twoGuess =
        splice([0xA2, 0x77, 0xAD, 0x77, 0x10, 0x00, 0xBE, 0xEF], [false, true, true]);

    test('rung 0 holds a one-guess splice, never a two-guess one', () {
      fakeAsync((async) {
        final radio = _Radio([_contact(stored: _pf1)])
          ..routes = [twoGuess, oneGuess, _pf2];
        radio.copy(async, radio.contacts.first);
        expect(radio.writes, ['CAROL:other']);
        expect(radio.contacts.first.path, oneGuess.pathBytes);
      });
    });

    test('after a step down the rungs are proven routes only, and the '
        'splice that lost the ACK is retired', () {
      fakeAsync((async) {
        final radio = _Radio([_contact(stored: oneGuess)])
          ..routes = [oneGuess, _pf2, _pf3];
        final carol = radio.contacts.first;
        radio.copy(async, carol); // ACKed on the splice it already holds
        expect(radio.writes, isEmpty);
        radio.copy(async, carol); // same message again: that ACK was lost
        expect(radio.writes, ['CAROL:PF2']);
        // A new message starts from rung 0 again, but the splice is
        // retired, so the best proven route stays: nothing to write.
        radio.copy(async, radio.contacts.first, stamp: 2000, text: 'next');
        expect(radio.writes, ['CAROL:PF2']);
        expect(radio.contacts.first.path, _pf2.pathBytes);
      });
    });

    test('retiring is per guessed link: another route with the same guess '
        'is skipped too', () {
      fakeAsync((async) {
        // oneGuess and sameGuess both guess AD77→1000; otherGuess guesses
        // a different link.
        final sameGuess = splice(
            [0xA2, 0x77, 0xF5, 0xEE, 0xAD, 0x77, 0x10, 0x00],
            [false, false, true]);
        final otherGuess =
            splice([0xA2, 0x77, 0xBE, 0xEF, 0x10, 0x00], [false, true]);
        final radio = _Radio([_contact(stored: oneGuess)])
          ..routes = [oneGuess, sameGuess, otherGuess, _pf2];
        final carol = radio.contacts.first;
        radio.copy(async, carol);
        radio.copy(async, carol); // the splice's ACK was lost: retired
        radio.copy(async, radio.contacts.first, stamp: 2000, text: 'next');
        expect(radio.contacts.first.path, otherGuess.pathBytes,
            reason: 'sameGuess carries the retired link; otherGuess does not');
      });
    });

    test('a send of mine delivering on the splice brings it back', () {
      fakeAsync((async) {
        final radio = _Radio([_contact(stored: oneGuess)])
          ..routes = [oneGuess, _pf2];
        final carol = radio.contacts.first;
        radio.copy(async, carol);
        radio.copy(async, carol); // retired
        radio.keeper.onDelivered(carol.publicKeyHex, oneGuess);
        radio.copy(async, radio.contacts.first, stamp: 2000, text: 'next');
        expect(radio.contacts.first.path, oneGuess.pathBytes);
      });
    });

    test('a loss on a route Pathfinder had dropped blames nothing: the splice '
        'that replaced it is not retired', () {
      fakeAsync((async) {
        final radio = _Radio([_contact(stored: _pf1)])
          ..routes = [oneGuess, _pf2];
        final carol = radio.contacts.first;
        radio.copy(async, carol); // ACKed on PF1, which Pathfinder dropped
        expect(radio.writes, ['CAROL:other']);
        // Same message again: the PF1 ACK was lost, not the splice's.
        radio.copy(async, radio.contacts.first);
        expect(radio.writes, ['CAROL:other', 'CAROL:PF2']);
        radio.copy(async, radio.contacts.first, stamp: 2000, text: 'next');
        expect(radio.contacts.first.path, oneGuess.pathBytes,
            reason: 'the splice was never blamed');
      });
    });
  });
}
