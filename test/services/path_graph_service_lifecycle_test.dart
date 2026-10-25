import 'package:drift/drift.dart' show LazyDatabase, QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pathfinder's start and stop follow the settings switch, which can flip
// while the graph database is still opening, and the app awaits the first
// start before it launches.
class _Connector extends MeshCoreConnector {
  @override
  String get selfPublicKeyHex => 'ab' * 32;

  @override
  int get pathHashByteWidth => 2;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  test('switched off while the graph is opening: it ends up off', () async {
    final c = _Connector();
    final service = PathGraphService();

    final starting = service.start(c, database: NativeDatabase.memory());
    await service.stop();
    await starting;

    expect(service.isRunning, isFalse);
    expect(c.graphRouteCandidates, isNull,
        reason: 'the ladder must not keep asking a graph that was turned off');
  });

  // Pathfinder off = the radio routes as it always did: no graph ladder, no
  // ACK route keeper, no attempt reports, nothing listening to packets.
  test('switched off: every hook into the connector is gone', () async {
    final c = _Connector();
    final service = PathGraphService();
    await service.start(c, database: NativeDatabase.memory());
    expect(c.graphRouteCandidates, isNotNull);
    expect(c.onContactMessageCopy, isNotNull, reason: 'the keeper listens');

    await service.stop();

    expect(service.isRunning, isFalse);
    expect(c.graphRouteCandidates, isNull);
    expect(c.graphDistanceTo, isNull);
    expect(c.onContactMessageCopy, isNull, reason: 'the keeper is gone');
    expect(c.onSendAttemptResult, isNull);
    expect(c.onSendAttemptStarted, isNull);
    expect(c.onFirmwarePathLearned, isNull);
    expect(c.onContactMessageHeard, isNull);
    expect(c.onChannelPacketHeard, isNull);
    expect(c.onOwnEchoHeard, isNull);
    expect(c.onSendOutcome, isNull);
    expect(c.graphRoomNeedsRelearn, isNull);
  });

  test('two starts at once open one graph', () async {
    final c = _Connector();
    final service = PathGraphService();
    var opens = 0;
    QueryExecutor counted() => LazyDatabase(() async {
          opens++;
          return NativeDatabase.memory();
        });

    await Future.wait([
      service.start(c, database: counted()),
      service.start(c, database: counted()),
    ]);

    expect(service.isRunning, isTrue);
    expect(opens, 1);
    await service.stop();
    expect(service.isRunning, isFalse);
    expect(c.graphRouteCandidates, isNull);
  });

  test('a database that will not open leaves Pathfinder off, not the app',
      () async {
    final c = _Connector();
    final service = PathGraphService();

    await service.start(c,
        database: LazyDatabase(() async => throw StateError('disk full')));

    expect(service.isRunning, isFalse);
    expect(service.lastError.toString(), contains('disk full'));
    expect(c.graphRouteCandidates, isNull);

    // The next try works and clears the error.
    await service.start(c, database: NativeDatabase.memory());
    expect(service.isRunning, isTrue);
    expect(service.lastError, isNull);
    await service.stop();
  });
}
