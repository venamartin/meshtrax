import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:traxheard/traxheard.dart';

/// Answers from [heard] and keeps every request it got.
class _Server implements ObserverServer {
  final heard = <String, List<Sighting>>{};
  final requests = <List<String>>[];
  Object? failWith;

  @override
  Future<Map<String, List<Sighting>>> sightings(Iterable<String> hashes) async {
    requests.add(hashes.toList());
    if (failWith case final error?) throw error;
    return {
      for (final h in hashes)
        if (heard[h] case final s?) h: s,
    };
  }

  @override
  void close() {}
}

void main() {
  late _Server server;
  late List<(String, List<Sighting>)> heardCalls;
  late List<Object> errors;
  late bool on;

  HeardChecker checker() => HeardChecker(
        server: () => on ? server : null,
        onHeard: (id, sightings) => heardCalls.add((id, sightings)),
        onError: errors.add,
      );

  setUp(() {
    server = _Server();
    heardCalls = [];
    errors = [];
    on = true;
  });

  test('asks at 10, 25 and 60 s while nobody heard it', () {
    fakeAsync((time) {
      checker().track('m1', 'AAAA');
      time.elapse(const Duration(seconds: 9));
      expect(server.requests, isEmpty);
      time.elapse(const Duration(seconds: 2));
      expect(server.requests, [
        ['aaaa'],
      ]);
      time.elapse(const Duration(seconds: 15));
      time.elapse(const Duration(seconds: 35));
      expect(server.requests, hasLength(3));
      time.elapse(const Duration(minutes: 5));
      expect(server.requests, hasLength(3), reason: 'three asks, then done');
      expect(heardCalls, isEmpty);
    });
  });

  test('stops at the first sighting, one row per observer', () {
    fakeAsync((time) {
      server.heard['aaaa'] = const [
        Sighting(observer: 'Ridge', snr: -8, hops: 0),
        Sighting(observer: 'Ridge', snr: -9, hops: 1),
        Sighting(observer: 'Hollow', snr: 3, hops: 2),
      ];
      checker().track('m1', 'aaaa');
      time.elapse(const Duration(seconds: 11));
      expect(heardCalls.single.$1, 'm1');
      expect(heardCalls.single.$2.map((s) => s.observer), ['Ridge', 'Hollow']);
      time.elapse(const Duration(minutes: 2));
      expect(server.requests, hasLength(1));
    });
  });

  test('a resend is asked about with the first send, in one request', () {
    fakeAsync((time) {
      final c = checker()..track('m1', 'aaaa');
      time.elapse(const Duration(seconds: 15));
      c.track('m1', 'bbbb');
      server.heard['bbbb'] = const [Sighting(observer: 'Ridge')];
      time.elapse(const Duration(seconds: 11));
      expect(server.requests.last, ['aaaa', 'bbbb']);
      expect(heardCalls.single.$1, 'm1');
    });
  });

  test('messages due together share a request', () {
    fakeAsync((time) {
      checker()
        ..track('m1', 'aaaa')
        ..track('m2', 'bbbb');
      time.elapse(const Duration(seconds: 11));
      expect(server.requests, [
        ['aaaa', 'bbbb'],
      ]);
    });
  });

  test('switched off: nothing is asked', () {
    fakeAsync((time) {
      on = false;
      checker().track('m1', 'aaaa');
      time.elapse(const Duration(minutes: 2));
      expect(server.requests, isEmpty);
    });
  });

  test('a failed request is reported and the next turn asks again', () {
    fakeAsync((time) {
      server.failWith = Exception('offline');
      checker().track('m1', 'aaaa');
      time.elapse(const Duration(seconds: 11));
      expect(errors, hasLength(1));
      server.failWith = null;
      server.heard['aaaa'] = const [Sighting(observer: 'Ridge')];
      time.elapse(const Duration(seconds: 15));
      expect(heardCalls.single.$1, 'm1');
    });
  });

  test('a hash it was really heard under is asked about too', () {
    fakeAsync((time) {
      final c = checker()..track('m1', 'aaaa');
      c.addHash('m1', 'CCCC');
      expect(c.hashesOf('m1'), {'aaaa', 'cccc'});
      time.elapse(const Duration(seconds: 11));
      expect(server.requests.single, ['aaaa', 'cccc']);
    });
  });

  test('keeps the 32 newest messages', () {
    fakeAsync((time) {
      final c = checker();
      for (var i = 0; i < 40; i++) {
        c.track('m$i', 'h$i');
      }
      expect(c.hashesOf('m7'), isNull);
      expect(c.hashesOf('m8'), isNotNull);
      time.elapse(const Duration(seconds: 11));
      expect(server.requests.single, hasLength(32));
    });
  });
}
