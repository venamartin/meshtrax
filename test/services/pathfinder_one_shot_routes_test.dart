import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/repeater_command_service.dart';
import 'package:meshtrax/services/server_login_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Logins and repeater commands use Pathfinder like DMs do (owner, 2026-10-14):
// Pathfinder's routes best first, then floods, by the same planAttempts rule;
// the radio's own route when Pathfinder cannot route. Each attempt's route
// is written and its packet sent with no other route write in between.

const _g1 = PathSelection(
  pathBytes: [0xA2, 0x77, 0x10, 0xAA],
  hopCount: 2,
  hashSize: 2,
  useFlood: false,
  source: RouteSource.graph,
  estDelivery: 0.8,
);
const _g2 = PathSelection(
  pathBytes: [0xAD, 0x77, 0x10, 0xAA],
  hopCount: 2,
  hashSize: 2,
  useFlood: false,
  source: RouteSource.graph,
  estDelivery: 0.6,
);
const _f = [0xBE, 0x41];

class _Connector extends MeshCoreConnector {
  final frames = <Uint8List>[];
  Duration writeDelay = Duration.zero;

  @override
  bool get isConnected => true;

  @override
  int get pathHashByteWidth => 2;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    frames.add(data);
    if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
  }

  /// What went to the radio, in order: route writes by their bytes.
  List<String> get log => [
        for (final f in frames)
          switch (f[0]) {
            cmdAddUpdateContact => 'route ${_hex(f.sublist(36, 40))}',
            cmdResetPath => 'reset',
            cmdSendLogin => 'login',
            cmdSendTxtMsg => 'text',
            _ => 'cmd ${f[0]}',
          }
      ];
}

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

Contact _repeater({int? override, int type = advTypeRepeater}) => Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => 0xC0 + i)),
      name: 'HILL',
      type: type,
      pathLength: 1,
      path: Uint8List.fromList(_f),
      pathHashSize: 2,
      pathOverride: override,
      lastSeen: DateTime(2026, 10, 14),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
  });

  group('the route of each try', () {
    List<String> kinds(List<PathSelection> plan) => [
          for (final s in plan)
            s.useFlood ? 'flood' : '${s.source!.name} ${_hex(s.pathBytes)}'
        ];

    test('Pathfinder on: its routes best first, then floods', () {
      c.graphRouteCandidates = (_) => [_g1, _g2];
      expect(kinds(c.planRequestAttempts(_repeater(), 4)),
          ['graph a27710aa', 'graph ad7710aa', 'flood', 'flood']);
      expect(kinds(c.planRequestAttempts(_repeater(), 3)),
          ['graph a27710aa', 'flood', 'flood']);
    });

    test('Pathfinder knows nothing: every try floods', () {
      c.graphRouteCandidates = (_) => [];
      expect(kinds(c.planRequestAttempts(_repeater(), 3)),
          ['flood', 'flood', 'flood']);
    });

    test('Pathfinder off or unable to route: the radio\'s route every try', () {
      expect(kinds(c.planRequestAttempts(_repeater(), 3)),
          ['firmware be41', 'firmware be41', 'firmware be41']);
      c.graphRouteCandidates = (_) => null;
      expect(kinds(c.planRequestAttempts(_repeater(), 2)),
          ['firmware be41', 'firmware be41']);
    });

    test('a user override wins over Pathfinder', () {
      c.graphRouteCandidates = (_) => [_g1];
      expect(kinds(c.planRequestAttempts(_repeater(override: -1), 2)),
          ['flood', 'flood']);
    });
  });

  test('two sends on different routes never interleave their route writes',
      () async {
    c.writeDelay = const Duration(milliseconds: 5);
    final a = _repeater();
    await Future.wait([
      c.sendOnRoute(a, _g1, () => c.sendFrame(buildSendLoginFrame(a.publicKey, 'x'))),
      c.sendOnRoute(a, _g2, () => c.sendFrame(buildSendLoginFrame(a.publicKey, 'y'))),
    ]);
    expect(c.log, ['route a27710aa', 'login', 'route ad7710aa', 'login']);
  });

  test('a login tries Pathfinder\'s route first, then floods', () {
    fakeAsync((async) {
      c.graphRouteCandidates = (_) => [_g1, _g2];
      final room = _repeater(type: advTypeRoom);
      ServerLoginService(c).login(room, 'pw', maxAttempts: 2);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 120));
      async.flushMicrotasks();
      expect(c.log, ['route a27710aa', 'login', 'reset', 'login']);
    });
  });

  test('a repeater command steps from Pathfinder\'s route to a flood', () {
    fakeAsync((async) {
      c.graphRouteCandidates = (_) => [_g1];
      final service = RepeaterCommandService(c);
      service
          .sendCommand(_repeater(), 'get tx', retries: 2)
          .catchError((_) => '');
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 120));
      async.flushMicrotasks();
      expect(c.log, ['route a27710aa', 'text', 'reset', 'text']);
    });
  });
}
