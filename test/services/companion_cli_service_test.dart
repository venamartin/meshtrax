import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/companion_cli_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firmware 1.18 CLI: [66][command] -> [29][reply]. A command shaped
// "XX|cmd" gets "XX|" echoed at the start of its reply.
class _Radio extends MeshCoreConnector {
  final commands = <String>[];
  // Reply per command (token stripped); null = stay silent.
  String? Function(String command) answer = (_) => null;
  // Replies to another app's commands, delivered before ours.
  final otherAppReplies = <String>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (data[0] != cmdRunCliCommand) return;
    final text = utf8.decode(data.sublist(1));
    commands.add(text);
    for (final r in otherAppReplies) {
      scheduleMicrotask(() => handleFrameForTest(_reply(r)));
    }
    final reply = answer(text.substring(3));
    if (reply == null) return;
    scheduleMicrotask(
        () => handleFrameForTest(_reply('${text.substring(0, 3)}$reply')));
  }

  static Uint8List _reply(String text) =>
      Uint8List.fromList([respCodeCliReply, ...utf8.encode(text)]);
}

Uint8List _deviceInfo(int verCode) => Uint8List(82)
  ..[0] = respCodeDeviceInfo
  ..[1] = verCode
  ..[2] = 50
  ..[3] = 8;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Radio radio;
  late CompanionCliService cli;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    radio = _Radio();
    cli = CompanionCliService(radio);
  });

  test('sends a tokened command and returns the reply without the token',
      () async {
    radio.answer = (c) => c == 'get name' ? '> Base' : null;

    expect(await cli.run('get name'), '> Base');
    expect(radio.commands.single, matches(RegExp(r'^[0-9A-F]{2}\|get name$')));
  });

  test("another app's replies are not taken for ours", () async {
    radio.otherAppReplies.addAll(['ZZ|> theirs', 'Unknown command']);
    radio.answer = (_) => '> ours';

    expect(await cli.run('get tx'), '> ours');
  });

  test('a get is asked twice before giving up', () {
    fakeAsync((async) {
      // Built inside the fake zone: its command queue starts from a
      // Future, and one made in setUp never resolves under fakeAsync.
      final cli = CompanionCliService(radio);
      var calls = 0;
      radio.answer = (_) => ++calls == 1 ? null : '> 1';
      String? result;
      cli.run('get wifi.enabled').then((r) => result = r);
      async.flushMicrotasks();

      async.elapse(CompanionCliService.attemptTimeout);
      async.flushMicrotasks();

      expect(radio.commands, hasLength(2));
      expect(result, '> 1');
    });
  });

  test('a set is asked once', () {
    fakeAsync((async) {
      final cli = CompanionCliService(radio);
      Object? error;
      cli.run('set wifi.enabled 1').catchError((Object e) {
        error = e;
        return '';
      });
      async.flushMicrotasks();

      async.elapse(CompanionCliService.attemptTimeout * 2);

      expect(radio.commands, hasLength(1));
      expect(error, isA<TimeoutException>());
    });
  });

  test('commands go out one at a time', () async {
    radio.answer = (c) => '> $c';

    final results = await Future.wait([cli.run('get a1'), cli.run('get b2')]);

    expect(results, ['> get a1', '> get b2']);
    expect(radio.commands.map((c) => c.substring(3)), ['get a1', 'get b2']);
  });

  test('a trailing space survives: it is how a value is set empty', () async {
    radio.answer = (_) => '> wifi.pwd updated (reboot to apply)';

    await cli.run('set wifi.pwd ');

    expect(radio.commands.single.substring(3), 'set wifi.pwd ');
  });

  test('reboot, poweroff and shutdown go out without a token', () async {
    await cli.sendWithoutReply('reboot');

    expect(radio.commands.single, 'reboot');
  });

  group('CliReply', () {
    test('classifies the firmware wordings', () {
      expect(CliReply('> 920.0,250.0,11,5').kind, CliReplyKind.value);
      expect(CliReply('v1.18.0 (Build: 15 Oct 2026)').kind, CliReplyKind.value);
      expect(CliReply('OK - reboot to apply').kind, CliReplyKind.ok);
      expect(CliReply('Error, invalid radio params').kind, CliReplyKind.error);
      expect(CliReply('ERROR: af must be 0-9').kind, CliReplyKind.error);
      expect(CliReply('Error: unsupported').kind, CliReplyKind.error);
      expect(CliReply('Unknown command').kind, CliReplyKind.unknown);
    });

    test('strips the value marker', () {
      expect(CliReply('> 192.168.1.42').value, '192.168.1.42');
      expect(CliReply('> (not set)').value, '(not set)');
      expect(CliReply('Heltec V4').value, 'Heltec V4');
    });
  });

  group('WiFi probe', () {
    test('an older radio is never asked', () async {
      radio.handleFrameForTest(_deviceInfo(13));

      await radio.probeWifiForTest();

      expect(radio.supportsCompanionCli, isFalse);
      expect(radio.commands, isEmpty);
      expect(radio.hasWifi, isNull);
    });

    test('a WiFi build answers with a value, even when WiFi is off',
        () async {
      radio.handleFrameForTest(_deviceInfo(14));
      radio.answer = (c) => c == 'get wifi.enabled' ? '> 0' : null;

      await radio.probeWifiForTest();

      expect(radio.hasWifi, isTrue);
    });

    test('a BLE-only build does not know the key', () async {
      radio.handleFrameForTest(_deviceInfo(14));
      radio.answer = (_) => 'Unknown command';

      await radio.probeWifiForTest();

      expect(radio.hasWifi, isFalse);
    });
  });
}
