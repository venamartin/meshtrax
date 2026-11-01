import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Replies come in order, so each OK pops the oldest entry. A share that got no
// reply left its entry behind, and the next channel send's OK was used up by
// it: that message sat on the clock for 30 s, then went on the air again.
class _Connector extends MeshCoreConnector {
  bool writeFails = false;
  final written = <int>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> writeToTransport(Uint8List data) async {
    if (writeFails) throw Exception('link down');
    written.add(data[0]);
  }
}

final _key = Uint8List.fromList(List.generate(32, (i) => 0x20 + i));
final _ok = [respCodeOk];

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

  test('a write that throws leaves no entry', () async {
    c.writeFails = true;
    expect(await c.shareContactZeroHop(_key), isFalse);
    expect(c.pendingGenericAckCountForTest, 0);
  });

  test('sendFrame still reports the failed write', () async {
    c.writeFails = true;
    await expectLater(
      c.sendFrame(Uint8List.fromList([cmdShareContact]), expectsGenericAck: true),
      throwsException,
    );
    expect(c.pendingGenericAckCountForTest, 0);
  });

  test('a share with no reply leaves no entry', () async {
    expect(await c.shareContactZeroHop(_key), isFalse);
    expect(c.written, [cmdShareContact]);
    expect(c.pendingGenericAckCountForTest, 0);
  });

  test('the next command keeps its own OK after a share with no reply',
      () async {
    await c.shareContactZeroHop(_key);

    await c.sendFrame(
      Uint8List.fromList([cmdSendChannelTxtMsg]),
      expectsGenericAck: true,
    );
    expect(c.pendingGenericAckCountForTest, 1);
    c.handleFrameForTest(_ok);
    expect(c.pendingGenericAckCountForTest, 0);
  });

  test('a late OK then the real one take one entry, and nothing breaks',
      () async {
    await c.shareContactZeroHop(_key);
    await c.sendFrame(
      Uint8List.fromList([cmdSendChannelTxtMsg]),
      expectsGenericAck: true,
    );

    c.handleFrameForTest(_ok); // the share's, arriving late
    expect(c.pendingGenericAckCountForTest, 0);
    c.handleFrameForTest(_ok); // the send's own
    expect(c.pendingGenericAckCountForTest, 0);
  });

  test('a reply in time pops the entry as before', () async {
    final share = c.shareContactZeroHop(_key);
    await pumpEventQueue();
    expect(c.pendingGenericAckCountForTest, 1);
    c.handleFrameForTest(_ok);
    expect(await share, isTrue);
    expect(c.pendingGenericAckCountForTest, 0);
  });

  test('a failed write takes its own entry, not an earlier one', () async {
    await c.sendFrame(
      Uint8List.fromList([cmdSendChannelTxtMsg]),
      channelSendQueueId: 'a',
      expectsGenericAck: true,
    );
    c.writeFails = true;
    await expectLater(
      c.sendFrame(
        Uint8List.fromList([cmdSendChannelTxtMsg]),
        channelSendQueueId: 'b',
        expectsGenericAck: true,
      ),
      throwsException,
    );
    expect(c.pendingGenericAckCountForTest, 1);
  });
}
