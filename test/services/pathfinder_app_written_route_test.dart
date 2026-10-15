import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Audit repro r1-6-0: _appWrittenPath lives only in memory and restore writes
// never enter it, so a route the APP wrote into the radio is later read back
// by PathGraphService's contact-list pass as a firmware route and its first
// hop is proven to "hear me" (self-proving loop, owner rule 4 / no false
// 'hears me').
class _Connector extends MeshCoreConnector {
  _Connector(this.list);

  List<Contact> list;
  final frames = <Uint8List>[];
  bool connected = true;

  @override
  bool get isConnected => connected;

  @override
  List<Contact> get contacts => list;

  @override
  List<Contact> get allContacts => list;

  @override
  String get selfPublicKeyHex => 'ab' * 32;

  @override
  int get pathHashByteWidth => 2;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    frames.add(data);
  }
}

final _key = Uint8List.fromList(List.generate(32, (i) => 0xC0 + i));
final _graphRoute = Uint8List.fromList([0xBE, 0xEF, 0xAD, 0x77]);

Contact _contact({int pathLength = -1, Uint8List? path}) => Contact(
      publicKey: _key,
      name: 'CAROL',
      type: 1,
      pathLength: pathLength,
      path: path ?? Uint8List(0),
      pathHashSize: 2,
      lastSeen: DateTime.now(),
    );

Future<List<String>> _provenEgressAfterListPass(_Connector c) async {
  final service = PathGraphService();
  await service.start(c, database: NativeDatabase.memory());
  c.notifyListeners();
  final proven = service.graph!
      .egressCandidates()
      .where((cand) => cand.proven)
      .map((cand) => cand.repeaterHash.toUpperCase())
      .toList();
  await service.stop();
  return proven;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  test('a route the app wrote is not proven as firmware evidence after an app restart',
      () async {
    // Session 1: the ladder writes graph route BEEF,AD77 into the radio.
    final before = _Connector([_contact()]);
    await before.setContactPath(before.list.single, _graphRoute, 2, hashSize: 2);
    final afterWrite = _contact(pathLength: 2, path: _graphRoute);
    before.list = [afterWrite];
    expect(before.wroteContactPath(afterWrite), isTrue,
        reason: 'sanity: this session knows it wrote the route');
    expect(await _provenEgressAfterListPass(before), isEmpty,
        reason: 'sanity: same session, the gate holds');

    // App restarts: a fresh connector; the radio still holds out_path
    // BEEF,AD77 (delivered on it, so the ladder never cleared it).
    final restarted = _Connector([_contact(pathLength: 2, path: _graphRoute)]);
    expect(await _provenEgressAfterListPass(restarted), isEmpty,
        reason: 'BEEF only ever carried a route this app wrote; nothing '
            'proved it hears this radio');
  });

  test('a route written by restoreContacts is not proven as firmware evidence',
      () async {
    final restored = _contact(pathLength: 2, path: _graphRoute);
    final c = _Connector([]);
    await c.restoreContacts([restored]);
    expect(c.frames, isNotEmpty, reason: 'sanity: restore wrote the route');
    // The contact fetch after the restore returns the route the app wrote.
    c.list = [restored];
    expect(await _provenEgressAfterListPass(c), isEmpty,
        reason: 'a restored route came from a backup (maybe another radio), '
            'not from this radio\'s firmware hearing a PATH reply');
  });
}
