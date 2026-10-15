import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/device_backup.dart';
import 'package:meshtrax/services/ble_debug_log_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The BLE debug log is always on, "Copy log" puts each entry's hexPreview
// on the clipboard and long-press copies the full payload, so the radio's
// private key (backup export, restore import) and channel secrets must
// never be stored in it.
final _key = Uint8List.fromList(List.generate(64, (i) => 0xA0 ^ i));

class _Connector extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    // Run the real sendFrame so its debug-log call happens; the transport
    // write afterwards has no link in a unit test and may throw.
    try {
      await super.sendFrame(data,
          channelSendQueueId: channelSendQueueId,
          expectsGenericAck: expectsGenericAck);
    } catch (_) {}
    final reply = data[0] == cmdExportPrivateKey
        ? Uint8List.fromList([respCodePrivateKey, ..._key])
        : Uint8List.fromList([respCodeOk]);
    scheduleMicrotask(() => handleFrameForTest(reply));
  }
}

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join(' ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('private key bytes never reach the BLE debug log', () async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();

    final log = BleDebugLogService();
    final c = _Connector();
    c.initialize(retryService: MessageRetryService(), bleDebugLogService: log);

    final exported = await c.exportPrivateKey();
    expect(exported, _key, reason: 'harness: export round-trip works');
    final imported = await c.importPrivateKey(_key);
    expect(imported, PrivateKeyImportResult.ok,
        reason: 'harness: import round-trip works');

    // What "Copy log" puts on the clipboard (ble_debug_log_screen.dart:46).
    final copyLog =
        log.entries.map((e) => '${e.description}\n${e.hexPreview}\n').join();
    // Any 8 consecutive key bytes is already a leak.
    final keyFragment = _hex(_key.sublist(0, 8));
    expect(copyLog.contains(keyFragment), isFalse,
        reason: '"Copy log" text contains private key bytes');

    // What long-press copies (ble_debug_log_screen.dart:123-125).
    final payloadHex = log.entries.map((e) => _hex(e.payload)).join('\n');
    expect(payloadHex.contains(keyFragment), isFalse,
        reason: 'a stored log payload holds private key bytes');

    // The entries are still there and say what happened.
    final described = log.entries.map((e) => e.description).toList();
    expect(described, contains('RX RESP_CODE_PRIVATE_KEY • secret redacted'));
    expect(described, contains('TX CMD_IMPORT_PRIVATE_KEY • secret redacted'));
  });

  test('channel secrets are cut from the log, the name is kept', () {
    final log = BleDebugLogService();
    final secret = Uint8List.fromList(List.generate(16, (i) => 0xC0 + i));
    final set = buildSetChannelFrame(3, 'Private', secret);
    // RESP_CODE_CHANNEL_INFO has the same layout as CMD_SET_CHANNEL.
    final info = Uint8List.fromList([respCodeChannelInfo, ...set.sublist(1)]);

    log.logFrame(set, outgoing: true);
    log.logFrame(info, outgoing: false);

    for (final e in log.entries) {
      expect(e.payload, hasLength(34), reason: 'code, index and name only');
      expect(_hex(e.payload).contains(_hex(secret.sublist(0, 8))), isFalse);
      expect(e.description, endsWith('secret redacted'));
    }
    expect(String.fromCharCodes(log.entries.first.payload.sublist(2, 9)),
        'Private');
  });

  test('frames without a secret are logged whole', () {
    final log = BleDebugLogService();
    final frame = buildGetChannelFrame(3);
    log.logFrame(frame, outgoing: true);
    expect(log.entries.single.payload, frame);
    expect(log.entries.single.description, 'TX CMD_GET_CHANNEL');
  });
}
