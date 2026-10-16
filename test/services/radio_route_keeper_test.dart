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
      radio.keeper.reassert(carol.publicKeyHex);
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

      // Pathfinder's best moved: within the cooldown it waits.
      radio.routes = [_pf2];
      radio.keeper.scheduleSync();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes, hasLength(2));

      // A reconnect checks again at once.
      radio.keeper.onConnected();
      async.elapse(RadioRouteKeeper.syncDelay);
      expect(radio.writes.skip(2), ['RECENT:PF2', 'FAV:PF2']);
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
}
