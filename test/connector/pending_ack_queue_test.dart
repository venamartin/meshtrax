import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Replies come in order, so each OK or ERR pops the oldest entry. A share that
// got no reply left its entry behind, and the next channel send's OK was used
// up by it: that message sat on the clock for 30 s, then went on the air again.
class _Connector extends MeshCoreConnector {
  bool writeFails = false;
  Completer<void>? gate;
  final written = <int>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> writeToTransport(Uint8List data) async {
    final hold = gate;
    if (hold != null) await hold.future;
    if (writeFails) throw Exception('link down');
    written.add(data[0]);
  }
}

final _key = Uint8List.fromList(List.generate(32, (i) => 0x20 + i));
final _ok = [respCodeOk];
final _err = [respCodeErr, 1];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  final window = MeshCoreConnector.givenUpAckWindow;

  Future<void> channelSend(String id) => c.sendFrame(
        Uint8List.fromList([cmdSendChannelTxtMsg]),
        channelSendQueueId: id,
        expectsGenericAck: true,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    MeshCoreConnector.givenUpAckWindow = window;
    c = _Connector();
  });

  tearDown(() => MeshCoreConnector.givenUpAckWindow = window);

  test('a write that throws leaves no entry', () async {
    c.writeFails = true;
    expect(await c.shareContactZeroHop(_key), isFalse);
    expect(c.pendingGenericAckIdsForTest, isEmpty);
  });

  test('sendFrame still reports the failed write', () async {
    c.writeFails = true;
    await expectLater(channelSend('a'), throwsException);
    expect(c.pendingGenericAckIdsForTest, isEmpty);
  });

  test('a failed write takes its own entry, not a later one', () async {
    c.gate = Completer<void>();
    final first = channelSend('a');
    final second = channelSend('b');
    c.writeFails = true;
    c.gate!.complete();
    await expectLater(first, throwsException);
    await expectLater(second, throwsException);
    expect(c.pendingGenericAckIdsForTest, isEmpty);

    c.writeFails = false;
    c.gate = Completer<void>();
    final kept = channelSend('kept');
    final failing = channelSend('failing');
    c.gate!.complete();
    await kept;
    await failing;
    expect(c.pendingGenericAckIdsForTest, ['kept', 'failing']);
  });

  group('a share with no reply yet', () {
    setUp(() async {
      expect(await c.shareContactZeroHop(_key), isFalse);
      expect(c.written, [cmdShareContact]);
      await channelSend('msg');
    });

    test('a late OK is its own, and the send keeps its OK', () {
      c.handleFrameForTest(_ok);
      expect(c.pendingGenericAckIdsForTest, ['msg']);
      c.handleFrameForTest(_ok);
      expect(c.pendingGenericAckIdsForTest, isEmpty);
    });

    test('a late ERR is its own and fails nothing else', () {
      c.handleFrameForTest(_err);
      expect(c.pendingGenericAckIdsForTest, ['msg']);
    });

    test('once given up for good, the send keeps its own OK', () {
      MeshCoreConnector.givenUpAckWindow = Duration.zero;
      c.handleFrameForTest(_ok);
      expect(c.pendingGenericAckIdsForTest, isEmpty);
    });
  });

  test('a reply in time pops the entry as before', () async {
    final share = c.shareContactZeroHop(_key);
    await pumpEventQueue();
    expect(c.pendingGenericAckIdsForTest, hasLength(1));
    c.handleFrameForTest(_ok);
    expect(await share, isTrue);
    expect(c.pendingGenericAckIdsForTest, isEmpty);
  });

  test('an entry nobody gave up on is never dropped as lost', () async {
    MeshCoreConnector.givenUpAckWindow = Duration.zero;
    await channelSend('a');
    await channelSend('b');
    c.handleFrameForTest(_ok);
    expect(c.pendingGenericAckIdsForTest, ['b']);
  });
}
