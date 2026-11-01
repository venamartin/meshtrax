import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// CMD_APP_START stops the radio's contact stream, and only that stream sends
// END_OF_CONTACTS (companion_radio MyMesh.cpp). These tests answer the way the
// firmware does, so they see what a radio that never replies cannot show.
class _Radio extends MeshCoreConnector {
  final sent = <Uint8List>[];
  Map<int, List<int>> answers = {};

  List<int> get commands => [for (final f in sent) f[0]];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data);
    final answer = answers[data[0]];
    if (answer != null) scheduleMicrotask(() => handleFrameForTest(answer));
  }
}

final _selfKey = Uint8List(32)..fillRange(0, 32, 0x11);
final _friendKey = Uint8List(32)..fillRange(0, 32, 0x22);

Uint8List _deviceInfo({String version = 'v1.18.0', int code = 14}) {
  final frame = Uint8List(82);
  frame[0] = respCodeDeviceInfo;
  frame[1] = code;
  frame.setRange(60, 60 + version.length, version.codeUnits);
  return frame;
}

Uint8List _selfInfo({int multiAcks = 0, int manualAdd = 1}) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(_selfKey);
  w.add(Uint8List(8)); // lat, lon
  w.add([multiAcks, 0, 0, manualAdd]);
  w.add(
    (ByteData(8)
          ..setUint32(0, 910525, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Uint8List _contactsStart(int total) =>
    (BytesBuilder()
          ..addByte(respCodeContactsStart)
          ..add(
            (ByteData(
              4,
            )..setUint32(0, total, Endian.little)).buffer.asUint8List(),
          ))
        .toBytes();

Uint8List _endOfContacts() =>
    Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]);

Uint8List _contact(Uint8List key, String name) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(key);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _clockNow() {
  final secs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return (BytesBuilder()
        ..addByte(respCodeCurrTime)
        ..add(
          (ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List(),
        ))
      .toBytes();
}

Future<void> _settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  _Radio radioStillDownloading() {
    final radio = _Radio()..initialize(retryService: MessageRetryService());
    radio.handleFrameForTest(_deviceInfo());
    radio.handleFrameForTest(_selfInfo());
    return radio;
  }

  /// A radio past its first sync, with one contact and every reply ready.
  Future<_Radio> syncedRadio() async {
    final radio = radioStillDownloading();
    await _settle();
    radio.handleFrameForTest(_contactsStart(1));
    radio.handleFrameForTest(_contact(_friendKey, 'Friend'));
    radio.handleFrameForTest(_endOfContacts());
    await _settle();
    radio.markInitialSyncCompleteForTest();
    radio.sent.clear();
    radio.answers = {
      cmdDeviceQuery: _deviceInfo(),
      cmdAppStart: _selfInfo(multiAcks: 1),
      cmdGetBattAndStorage: [respCodeBattAndStorage, 0, 0],
      cmdGetAutoAddConfig: [respCodeAutoAddConfig, autoAddChatFlag, 0],
      cmdGetDeviceTime: _clockNow(),
    };
    return radio;
  }

  group('reading the settings', () {
    test('reads fresh values and leaves the contact list alone', () async {
      final radio = await syncedRadio();
      expect(radio.contacts, hasLength(1));

      expect(await radio.readRadioSettings(), isTrue);
      await _settle();

      expect(radio.commands, [
        cmdDeviceQuery,
        cmdAppStart,
        cmdGetBattAndStorage,
        cmdGetAutoAddConfig,
        cmdGetDeviceTime,
      ]);
      expect(radio.multiAcks, 1);
      expect(radio.autoAddUsers, isTrue);
      expect(radio.contacts, hasLength(1));
      expect(radio.isLoadingContacts, isFalse);
    });

    test('asks for one thing at a time', () async {
      final radio = await syncedRadio();
      radio.answers = {};

      final read = radio.readRadioSettings(
        replyTimeout: const Duration(milliseconds: 10),
      );
      await _settle();
      expect(radio.commands, [cmdDeviceQuery]);
      expect(await read, isFalse, reason: 'the radio did not answer');
    });

    test('never asks while the contact list is still streaming', () async {
      final radio = radioStillDownloading();
      await _settle();
      expect(radio.isLoadingContacts, isTrue);
      radio.sent.clear();

      expect(
        await radio.readRadioSettings(syncTimeout: Duration.zero),
        isFalse,
      );
      expect(radio.sent, isEmpty);
    });

    test('a clock far ahead is reported, and Check again sees it go', () async {
      final radio = await syncedRadio();
      final ahead = DateTime.now().add(const Duration(hours: 1));
      radio.answers[cmdGetDeviceTime] =
          (BytesBuilder()
                ..addByte(respCodeCurrTime)
                ..add(
                  (ByteData(4)..setUint32(
                        0,
                        ahead.millisecondsSinceEpoch ~/ 1000,
                        Endian.little,
                      ))
                      .buffer
                      .asUint8List(),
                ))
              .toBytes();
      await radio.readRadioSettings();
      expect(radio.deviceClockStuckAhead, isTrue);

      radio.answers[cmdGetDeviceTime] = _clockNow();
      await radio.readRadioSettings();
      expect(radio.deviceClockStuckAhead, isFalse);
    });
  });

  group('a contact stream the radio stopped', () {
    test('a SELF_INFO after CONTACTS_START asks for the list again', () async {
      final radio = radioStillDownloading();
      await _settle();
      radio.handleFrameForTest(_contactsStart(300));
      radio.sent.clear();

      radio.handleFrameForTest(_selfInfo());
      await _settle();

      expect(radio.commands, contains(cmdGetContacts));
      expect(radio.isLoadingContacts, isTrue, reason: 'the new request');
    });

    test('a SELF_INFO before CONTACTS_START does not ask twice', () async {
      final radio = radioStillDownloading();
      await _settle();
      expect(radio.isLoadingContacts, isTrue);
      radio.sent.clear();

      // Its APP_START reached the radio before GET_CONTACTS, so the stream is
      // still coming, and a second request would be refused.
      radio.handleFrameForTest(_selfInfo());
      await _settle();

      expect(radio.commands, isNot(contains(cmdGetContacts)));
    });
  });

  test('a contact the radio overwrote leaves the list', () async {
    final radio = await syncedRadio();
    expect(radio.contacts, hasLength(1));

    radio.handleFrameForTest([pushCodeContactDeleted, ..._friendKey]);
    expect(radio.contacts, isEmpty);
  });

  group('the Multi-ACK write', () {
    test('keeps the on/off switch of firmware that has nothing else', () async {
      final radio = _Radio()..initialize(retryService: MessageRetryService());
      radio.handleFrameForTest(_deviceInfo(version: 'v1.9.0', code: 8));
      radio.handleFrameForTest(_selfInfo(manualAdd: 0));
      radio.sent.clear();

      await radio.setTelemetryModeBase(0, 0, 0, 0, 1);

      final frame = radio.sent.single;
      expect(frame[0], cmdSetOtherParams);
      expect(frame[1], 0, reason: 'auto-add stays on');
      expect(frame[4], 1);
    });

    test('per-type firmware stays on its filter flags', () async {
      final radio = _Radio()..initialize(retryService: MessageRetryService());
      radio.handleFrameForTest(_deviceInfo());
      radio.handleFrameForTest(_selfInfo());
      radio.sent.clear();

      await radio.setTelemetryModeBase(0, 0, 0, 0, 1);

      expect(radio.sent.single[1], 1);
    });
  });
}
