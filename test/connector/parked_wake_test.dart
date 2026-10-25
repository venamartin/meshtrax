import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A parked message (no repeater echoed its flood) wakes when a repeater
// is heard: a relayed packet, a Discover answer, or a repeater's own
// zero-hop advert.
class _Retry extends MessageRetryService {
  int heard = 0;
  @override
  void noteRepeaterHeard() => heard++;
}

class _Connector extends MeshCoreConnector {
  @override
  bool get isConnected => true;
}

Uint8List _key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => seed + i));

Uint8List _advert(int type, {List<int> path = const []}) {
  final w = BytesBuilder();
  w.add([pushCodeLogRxData, 40, 0xA0]);
  w.add([(payloadTypeADVERT << 2) | (path.isEmpty ? 0x01 : 0x00), path.length]);
  w.add(path);
  w.add(_key(0x20));
  w.add((ByteData(4)..setUint32(0, 1752854400, Endian.little)).buffer.asUint8List());
  w.add(Uint8List(64));
  w.addByte(type | 0x80);
  w.add(utf8.encode('Hill'));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  test("a repeater's zero-hop advert counts as a repeater heard", () {
    final retry = _Retry();
    final c = _Connector()..initialize(retryService: retry);
    c.handleFrameForTest(_advert(advTypeRepeater));
    expect(retry.heard, 1);
    c.handleFrameForTest(_advert(advTypeChat));
    expect(retry.heard, 1, reason: "a companion's advert is no repeater");
    c.handleFrameForTest(_advert(advTypeChat, path: [0xA2]));
    expect(retry.heard, 2, reason: 'relayed: a repeater carried it');
  });
}
