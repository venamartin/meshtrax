import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Only a flooded attempt can come back as an echo of my own DM. A direct
// attempt must not open an echo window, or a stranger's flood that happens
// to carry the same two address bytes is taken for mine.
class _Connector extends MeshCoreConnector {
  @override
  String get selfPublicKeyHex => 'ab' * 32;

  @override
  int get pathHashByteWidth => 2;
}

final _bob = Contact(
  publicKey: Uint8List.fromList(List.filled(32, 0x5B)),
  name: 'BOB',
  type: 1,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 2,
  lastSeen: DateTime(2026, 10, 14),
);

// A flooded DM, dest Bob (5B), src me (AB), first hop A277.
final _floodEcho = Uint8List.fromList([
  0x88, 32, 0, (0x02 << 2) | 0x01, 0x41, 0xA2, 0x77, 0x5B, 0xAB, 7, 7, //
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<bool> provenAfter(PathSelection selection) async {
    final c = _Connector();
    final service = PathGraphService();
    await service.start(c, database: NativeDatabase.memory());
    c.onSendAttemptStarted!(_bob, selection, 0);
    service.adapter!.handleFrame(_floodEcho);
    final proven = service.graph!
        .egressCandidates()
        .any((cand) => cand.repeaterHash == 'A277' && cand.proven);
    await service.stop();
    return proven;
  }

  test('a flooded attempt opens the echo window', () async {
    expect(await provenAfter(PathSelection.flood(2)), isTrue);
  });

  test('a direct attempt opens none', () async {
    const direct = PathSelection(
      pathBytes: [0xBE, 0xEF],
      hopCount: 1,
      hashSize: 2,
      useFlood: false,
      source: RouteSource.graph,
    );
    expect(await provenAfter(direct), isFalse);
  });
}
