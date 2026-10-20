import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A contact whose radio floods with 1-byte repeater codes can never be
// learned by Pathfinder (it drops such paths). The chat says so once.

class _Connector extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  List<Contact> get contacts => const [];

  @override
  List<Contact> get allContacts => const [];

  @override
  String get selfPublicKeyHex => 'ab' * 32;

  @override
  int get pathHashByteWidth => 2;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bob = 'b0' * 32;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<(PathGraphService, _Connector)> started() async {
    final c = _Connector();
    final service = PathGraphService();
    await service.start(c, database: NativeDatabase.memory());
    return (service, c);
  }

  test('a 1-byte flood from a contact raises the notice; 2-byte and direct '
      'do not', () async {
    final (service, c) = await started();
    c.onContactMessageHeard!(bob, 0x41, null); // 1 hop, 2-byte
    c.onContactMessageHeard!(bob, 0xFF, null); // arrived direct
    expect(service.showNarrowNotice(bob), isFalse);

    c.onContactMessageHeard!(bob, 0x02, null); // 2 hops, 1-byte
    expect(service.showNarrowNotice(bob), isTrue);
    expect(service.showNarrowNotice(bob.toUpperCase()), isTrue);
    await service.stop();
    expect(service.showNarrowNotice(bob), isFalse,
        reason: 'only while Pathfinder runs');
  });

  test('dismissed once, never shown again for that contact', () async {
    final (service, c) = await started();
    c.onContactMessageHeard!(bob, 0x01, null);
    await service.dismissNarrowNotice(bob);
    expect(service.showNarrowNotice(bob), isFalse);
    await service.stop();

    final (again, c2) = await started();
    c2.onContactMessageHeard!(bob, 0x01, null);
    expect(again.showNarrowNotice(bob), isFalse,
        reason: 'the dismissal is kept across restarts');
    await again.stop();
  });
}
