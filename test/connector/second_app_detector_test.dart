import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/connector/second_app_detector.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A BLE+WiFi companion (firmware 1.18) writes every reply to every connected
// app. A reply to a request this app never made means another app is
// driving the radio.
Uint8List _frame(List<int> bytes) => Uint8List.fromList(bytes);

class _Connector extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  // Bypasses the real write, so nothing is recorded as asked: every
  // tracked reply looks foreign here.
  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}

void main() {
  group('SecondAppDetector', () {
    late DateTime now;
    late SecondAppDetector detector;

    setUp(() {
      now = DateTime(2026, 10, 15, 12);
      detector = SecondAppDetector(clock: () => now);
    });

    test('our own reply is not foreign, and uses up its request', () {
      detector.onSent(_frame([cmdDeviceQuery, 3]));

      expect(detector.isForeign(_frame([respCodeDeviceInfo, 14])), isFalse);
      expect(detector.isForeign(_frame([respCodeDeviceInfo, 14])), isTrue,
          reason: 'one request, one reply');
    });

    test('a reply nobody here asked for is foreign', () {
      expect(detector.isForeign(_frame([respCodeSelfInfo])), isTrue);
      expect(detector.isForeign(_frame([respCodeContactsStart, 0, 0, 0, 0])),
          isTrue);
    });

    test('keepalive retries each get their own reply', () {
      detector.onSent(_frame([cmdAppStart]));
      detector.onSent(_frame([cmdAppStart]));

      expect(detector.isForeign(_frame([respCodeSelfInfo])), isFalse);
      expect(detector.isForeign(_frame([respCodeSelfInfo])), isFalse);
      expect(detector.isForeign(_frame([respCodeSelfInfo])), isTrue);
    });

    test('a request does not cover a reply of another kind', () {
      detector.onSent(_frame([cmdGetBattAndStorage]));

      expect(detector.isForeign(_frame([respCodeCurrTime, 0, 0, 0, 0])),
          isTrue);
      expect(detector.isForeign(_frame([respCodeBattAndStorage])), isFalse);
    });

    test('a reply later than the window is not ours', () {
      detector.onSent(_frame([cmdGetDeviceTime]));
      now = now.add(SecondAppDetector.replyWindow + const Duration(seconds: 1));

      expect(detector.isForeign(_frame([respCodeCurrTime, 0, 0, 0, 0])),
          isTrue);
    });

    test('pushes and shared acks prove nothing', () {
      for (final code in [
        respCodeOk,
        respCodeErr,
        respCodeSent,
        respCodeContact,
        respCodeContactMsgRecvV3,
        respCodeNoMoreMessages,
        pushCodeMsgWaiting,
        pushCodeLogRxData,
      ]) {
        expect(detector.isForeign(_frame([code])), isFalse, reason: '$code');
      }
    });

    test('reset forgets what was asked', () {
      detector.onSent(_frame([cmdDeviceQuery, 3]));
      detector.reset();

      expect(detector.isForeign(_frame([respCodeDeviceInfo, 14])), isTrue);
    });
  });

  group('connector warning', () {
    late _Connector c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      AppDatabase.useInMemoryForTesting();
      c = _Connector();
    });

    test('stays quiet during our own handshake', () {
      c.handleFrameForTest(_frame([respCodeBattAndStorage, 0x10, 0x0E]));

      expect(c.secondAppSuspected, isFalse);
    });

    test('warns after sync, once, until dismissed', () {
      c.markInitialSyncCompleteForTest();

      c.handleFrameForTest(_frame([respCodeBattAndStorage, 0x10, 0x0E]));
      expect(c.secondAppSuspected, isTrue);

      c.dismissSecondAppWarning();
      c.handleFrameForTest(_frame([respCodeBattAndStorage, 0x10, 0x0E]));
      expect(c.secondAppSuspected, isFalse);
    });

    test("another app's CLI reply gives it away; ours does not", () async {
      c.markInitialSyncCompleteForTest();
      // Send one of our own commands so its token is known.
      final ours = c.companionCli.run('ver');
      await Future<void>.delayed(Duration.zero);
      Uint8List reply(String text) =>
          Uint8List.fromList([respCodeCliReply, ...utf8.encode(text)]);

      // Our token is unknown to the test, so answer every possible one.
      for (var t = 0; t < 256; t++) {
        final token = '${t.toRadixString(16).padLeft(2, '0').toUpperCase()}|';
        if (c.companionCli.isOwnReply(reply('$token v1.18.0'))) {
          c.handleFrameForTest(reply('$token v1.18.0'));
        }
      }
      await ours;
      expect(c.secondAppSuspected, isFalse);

      c.handleFrameForTest(reply('> v1.18.0'));
      expect(c.secondAppSuspected, isTrue);
    });
  });
}
