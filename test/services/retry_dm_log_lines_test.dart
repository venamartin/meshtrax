import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';

// A field log is judged by which routes a DM tried, who chose each, and how
// it ended. The first 1.12.0 log (2026-11-26) took hours to read because
// every route try read "(graph)", whether Pathfinder had ranked the route
// or a path reply had named it, and nothing summed a DM up.

const _timeoutMs = 2000;

PathSelection _route(List<int> bytes, double est, {int? liveAgeMillis}) =>
    PathSelection(
      pathBytes: bytes,
      hopCount: bytes.length ~/ 2,
      hashSize: 2,
      useFlood: false,
      source: RouteSource.graph,
      estDelivery: est,
      liveAgeMillis: liveAgeMillis,
    );

final _best = _route(const [0xA2, 0x77, 0xAA, 0x77], 0.66);
final _next = _route(const [0xA2, 0x77, 0xF5, 0xEE, 0xAA, 0x77], 0.45);

void main() {
  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0x42 + i));
  Contact bob({int pathLength = -1, List<int> path = const []}) => Contact(
        publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
        name: 'Bob',
        type: 1,
        pathLength: pathLength,
        path: Uint8List.fromList(path),
        pathHashSize: 2,
        lastSeen: DateTime(2026, 11, 26),
      );

  late MessageRetryService svc;
  late AppDebugLogService log;
  late List<({String text, int attempt, int ts})> sends;
  List<PathSelection>? routes;

  int ackFor(int i) => MessageRetryService.computeExpectedAckHash(
      sends[i].ts, sends[i].attempt, sends[i].text, selfKey);

  /// The lines this change adds, in order.
  List<String> lines() => [
        for (final e in log.entries)
          if (e.message.startsWith('Try ') || e.message.startsWith('DM to '))
            e.message,
      ];

  /// The try that is out is taken by the radio, and nothing answers it.
  void missed(FakeAsync async) {
    svc.updateMessageFromSent(ackFor(sends.length - 1), _timeoutMs);
    async.elapse(const Duration(
        milliseconds: _timeoutMs + MessageRetryService.retryBackoffMs + 2));
  }

  setUp(() {
    svc = MessageRetryService();
    log = AppDebugLogService()..setEnabled(true);
    sends = [];
    routes = [_best, _next];
    svc.initialize(RetryServiceConfig(
      sendMessage: (_, text, attempt, ts) =>
          sends.add((text: text, attempt: attempt, ts: ts)),
      addMessage: (_, _) {},
      updateMessage: (_) {},
      clearContactPath: (_) {},
      setContactPath: (_, _, _, _) {},
      calculateTimeout: (_, _, {contact}) => _timeoutMs,
      getSelfPublicKey: () => selfKey,
      pathHashByteWidth: () => 2,
      graphRoutes: (_) => routes,
      debugLogService: log,
    ));
    svc.setMaxRetries(5);
  });

  test('each try names its route and who chose it, and the DM ends with one '
      'line', () {
    fakeAsync((async) {
      svc.sendMessageWithRetry(contact: bob(), text: 'hi');
      async.flushMicrotasks();
      missed(async);
      missed(async);
      svc.updateMessageFromSent(ackFor(2), _timeoutMs);
      svc.handleAckReceived(ackFor(2), 100);
      async.flushMicrotasks();

      expect(lines(), [
        "Try 1 of 5 to Bob: A277,AA77, Pathfinder's best (66%)",
        'Try 2 of 5 to Bob: A277,AA77, the same route again (66%)',
        "Try 3 of 5 to Bob: A277,F5EE,AA77, Pathfinder's next (45%)",
        matches(RegExp(r'^DM to Bob delivered on try 3 of 5 after \d+ s\. '
            r'Tries: A277,AA77; A277,AA77; A277,F5EE,AA77$')),
      ]);
      async.elapse(MessageRetryService.lateAckGrace);
    });
  });

  test("a route their path reply named says so, and how old it is", () {
    fakeAsync((async) {
      routes = [
        _route(const [0xA2, 0x77, 0x10, 0x00, 0x63, 0x0B, 0xC8, 0xE6], 0.12,
            liveAgeMillis: 4 * 60 * 1000),
      ];
      svc.sendMessageWithRetry(contact: bob(), text: 'hi');
      async.flushMicrotasks();
      expect(
          lines().single,
          'Try 1 of 5 to Bob: A277,1000,630B,C8E6, the route their last path '
          'reply named, 4 min ago (12%)');
      async.elapse(const Duration(minutes: 5));
    });
  });

  test('a DM given up lists every try, and marks one the radio never took',
      () {
    fakeAsync((async) {
      svc.setMaxRetries(2);
      routes = const [];
      svc.sendMessageWithRetry(contact: bob(), text: 'hi');
      async.flushMicrotasks();
      missed(async);
      // The second try is never taken by the radio.
      async.elapse(const Duration(minutes: 1));

      expect(lines(), [
        'Try 1 of 2 to Bob: flood',
        'Try 2 of 2 to Bob: flood',
        matches(RegExp(r'^DM to Bob failed after 2 tries in \d+ s\. '
            r'Tries: flood; flood \(not sent\)$')),
      ]);
      async.elapse(MessageRetryService.lateAckGrace);
    });
  });

  test("with Pathfinder off the try is on the radio's stored route", () {
    fakeAsync((async) {
      routes = null;
      svc.sendMessageWithRetry(
          contact: bob(pathLength: 2, path: const [0xA2, 0x77, 0xAA, 0x77]),
          text: 'hi');
      async.flushMicrotasks();
      expect(lines().single,
          "Try 1 of 5 to Bob: A277,AA77, the radio's stored route");
      async.elapse(const Duration(minutes: 5));
    });
  });
}
