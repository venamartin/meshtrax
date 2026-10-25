import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:path_graph/path_graph.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The automatic Discover: one, after a failed step, when Pathfinder has a
// doubt about my side of the air, and only through every gate.
class _Connector extends MeshCoreConnector {
  bool discovering = false, dmInFlight = true, channelQueued = false;
  DateTime? foreignAt;
  int discovers = 0;
  bool? lastAutomatic;

  @override
  String get selfPublicKeyHex => 'ab' * 32;
  @override
  int get pathHashByteWidth => 2;
  @override
  bool get isConnected => true;
  @override
  bool get hasGps => true;
  @override
  bool get gpsOn => true;
  @override
  int? get firmwareVerCode => 8;
  @override
  bool get selfPositionIsLive => true;
  @override
  bool get isDiscovering => discovering;
  @override
  bool get hasDmSendsInFlight => dmInFlight;
  @override
  bool get hasChannelSendsQueued => channelQueued;
  @override
  DateTime? get foreignDiscoverHeardAt => foreignAt;

  @override
  Future<void> requestSelfPosition() async {}

  @override
  Future<void> sendRepeaterDiscovery({bool automatic = false}) async {
    discovers++;
    lastAutomatic = automatic;
  }

  void fix(double lat, double lon) => selfGps.value =
      (latitude: lat, longitude: lon, altitude: 0, at: DateTime.now());
}

final _bob = Contact(
  publicKey: Uint8List.fromList([0xB0, 0xB0, ...List.filled(30, 0x11)]),
  name: 'Bob',
  type: advTypeChat,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 10, 25),
);

const _viaA277 = PathSelection(
  pathBytes: [0xA2, 0x77, 0xBE, 0xEF],
  hopCount: 2,
  hashSize: 2,
  useFlood: false,
  source: RouteSource.graph,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// A radio whose doorstep A277 was proven elsewhere, now in an area
  /// where nobody has been heard hearing it: Pathfinder's doubt.
  Future<(PathGraphService, _Connector)> doubtful() async {
    final c = _Connector();
    final service = PathGraphService()..autoDiscoverJitterMax = Duration.zero;
    await service.start(c, database: NativeDatabase.memory());
    service.graph!.reportSendResult(
        Uint8List.fromList(_viaA277.pathBytes), true,
        contactPubkey: _bob.publicKeyHex);
    c.fix(36.9712, -121.7334);
    return (service, c);
  }

  Future<void> failedStep(_Connector c) async {
    c.onSendAttemptResult!(_bob, _viaA277, false, null);
    await settle();
  }

  test('one Discover after a failed step, and not again for ten minutes',
      () async {
    final (service, c) = await doubtful();
    await failedStep(c);
    expect(c.discovers, 1);
    expect(c.lastAutomatic, isTrue);
    expect(service.lastAutoDiscoverAt, isNotNull);

    await failedStep(c);
    expect(c.discovers, 1, reason: 'the ten-minute cap');
    await service.stop();
  });

  test('a failed flood attempt asks too, while the ladder is still running',
      () async {
    final (service, c) = await doubtful();
    c.onSendAttemptResult!(
        _bob,
        const PathSelection(
            pathBytes: [], hopCount: 0, hashSize: 2, useFlood: true),
        false,
        null);
    await settle();
    expect(c.discovers, 1);
    await service.stop();
  });

  test('no doubt, no Discover', () async {
    final c = _Connector();
    final service = PathGraphService()..autoDiscoverJitterMax = Duration.zero;
    await service.start(c, database: NativeDatabase.memory());
    // No cell, nothing failing, no unanswered ladder: nothing to ask.
    await failedStep(c);
    expect(c.discovers, 0);
    await service.stop();
  });

  test('every gate holds it', () async {
    for (final gate in <void Function(_Connector, PathGraphService)>[
      (c, _) => c.discovering = true,
      (c, _) => c.dmInFlight = false,
      (c, _) => c.channelQueued = true,
      (c, _) => c.foreignAt = DateTime.now().subtract(const Duration(seconds: 30)),
      (_, s) => s.didChangeAppLifecycleState(AppLifecycleState.paused),
    ]) {
      final (service, c) = await doubtful();
      gate(c, service);
      await failedStep(c);
      expect(c.discovers, 0);
      await service.stop();
    }
  });

  test('a room whose way back ends where I was needs a flooded login first',
      () async {
    final c = _Connector();
    final service = PathGraphService();
    await service.start(c, database: NativeDatabase.memory());
    final graph = service.graph!;
    final room = Contact(
      publicKey: Uint8List.fromList([0x70, 0x70, ...List.filled(30, 0x22)]),
      name: 'Room',
      type: advTypeRoom,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 2,
      lastSeen: DateTime(2026, 10, 25),
    );
    // Home: A277 hears me, the room reaches me BEEF -> A277.
    c.fix(36.9712, -121.7334);
    graph.reportSendResult(Uint8List.fromList([0xA2, 0x77, 0xBE, 0xEF]), true,
        contactPubkey: room.publicKeyHex);
    for (var i = 0; i < 2; i++) {
      graph.observePath(Uint8List.fromList([0xBE, 0xEF, 0xA2, 0x77]), 2,
          ObservationOrigin.pubkeyConfirmed(room.publicKeyHex),
          messageId: 'room-$i');
    }
    expect(service.roomNeedsRelearnAfterMove(room), isFalse);
    // Two kilometres on: only F5EE hears me here.
    c.fix(36.9712 + 0.02, -121.7334);
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: 'F5EE', uplinkSnr: 8)],
        failureEpisode: false);
    expect(service.roomNeedsRelearnAfterMove(room), isTrue);
    expect(c.graphRoomNeedsRelearn!(room), isTrue);
    await service.stop();
  });

  test('a foreign Discover older than two minutes no longer holds it',
      () async {
    final (service, c) = await doubtful();
    c.foreignAt = DateTime.now().subtract(const Duration(seconds: 130));
    await failedStep(c);
    expect(c.discovers, 1);
    await service.stop();
  });
}
