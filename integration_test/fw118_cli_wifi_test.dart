import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/services/companion_cli_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';
import 'harness/ble_nus_tcp_bridge.dart';

/// Firmware 1.18 bench: the companion command line and WiFi setup on GWQ 🚀
/// (Heltec V4, BLE+WiFi build). No mesh traffic: every step talks to the
/// radio only.
///
/// Over Bluetooth (full run: sets WiFi up, restarts, then opens a second
/// connection over WiFi). The password is read from a local file and never
/// printed, and the test never asks the radio for it back (`get wifi.pwd`
/// answers in plain text):
///
///   flutter test integration_test/fw118_cli_wifi_test.dart -d windows
///     --dart-define=WIFI_SSID=vena
///     --dart-define=WIFI_PWD_FILE=C:\Users\venam\.meshtrax\wifi_pwd.txt
///
/// Over WiFi, for a radio already on the network (command line and WiFi
/// state only; setup, restart and the second-app step need Bluetooth):
///
///   flutter test integration_test/fw118_cli_wifi_test.dart -d windows
///     --dart-define=MT_TCP_HOST=192.168.4.116
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const ssid = String.fromEnvironment('WIFI_SSID');
  const pwdFile = String.fromEnvironment('WIFI_PWD_FILE');
  const tcpHost = String.fromEnvironment('MT_TCP_HOST');
  const wifiPort = 5000;

  final ble = BenchRadio('BLE(${BenchConfig.bleName})');
  final bridge = BleNusTcpBridge();
  MeshCoreConnector? overWifi;

  tearDownAll(() async {
    try {
      await overWifi?.disconnect();
    } catch (_) {}
    if (tcpHost.isEmpty) {
      try {
        await ble.connector.disconnect();
      } catch (_) {}
      try {
        await bridge.stop();
      } catch (_) {}
    }
  });

  Future<String> cli(MeshCoreConnector c, String command) async {
    final reply = await c.companionCli.run(command);
    blog('  $command  →  $reply');
    return reply;
  }

  Future<void> connectBle() async {
    await ble.connector.connectTcp(
      host: '127.0.0.1',
      port: BenchConfig.bridgePort,
    );
    await waitConnectedVerified(ble);
  }

  Future<MeshCoreConnector> connectWifi(String host) async {
    final c = await buildConnector();
    await c.connectTcp(host: host, port: wifiPort);
    await waitUntil(() => c.isConnected && c.channelsVerified,
        'TCP connection to $host:$wifiPort verified',
        timeout: BenchConfig.handshakeTimeout);
    return c;
  }

  /// C1–C3: version gate, command line basics, WiFi probe.
  Future<void> basics(WidgetTester tester, MeshCoreConnector c) async {
    blog('companion: ${c.selfName}, firmware ${c.firmwareVersion}, '
        'protocol ${c.firmwareVerCode}');
    expect(c.firmwareVerCode, 14);
    expect(c.supportsCompanionCli, isTrue);

    await beginScenario(tester, 'C2 command line basics');
    expect(await cli(c, 'ver'), contains('v1.18'));
    expect(await cli(c, 'board'), isNotEmpty);
    expect(CliReply(await cli(c, 'get name')).value, c.selfName);
    expect(CliReply(await cli(c, 'get radio')).kind, CliReplyKind.value);
    expect(CliReply(await cli(c, 'get tx')).kind, CliReplyKind.value);
    expect(CliReply(await cli(c, 'get tz.offset')).kind, CliReplyKind.value);
    expect(CliReply(await cli(c, 'frobnicate now')).kind,
        CliReplyKind.unknown);

    await beginScenario(tester, 'C3 WiFi probe');
    if (!await pollFor(() => c.hasWifi != null, const Duration(seconds: 60))) {
      blog('sync-complete probe has not run yet; probing directly');
      await c.probeWifiForTest();
    }
    blog('hasWifi = ${c.hasWifi}');
    expect(c.hasWifi, isTrue, reason: 'a BLE+WiFi build knows wifi.enabled');
    for (final key in ['wifi.enabled', 'wifi.ssid', 'wifi.status', 'wifi.ip']) {
      await cli(c, 'get $key');
    }
  }

  testWidgets('1.18 command line and WiFi', (tester) async {
    await beginScenario(tester, 'firmware 1.18: CLI + WiFi');
    await PrefsManager.initialize();

    if (tcpHost.isNotEmpty) {
      overWifi = await connectWifi(tcpHost);
      await basics(tester, overWifi!);
      expect(CliReply(await cli(overWifi!, 'get wifi.status')).value,
          'connected');
      expect(CliReply(await cli(overWifi!, 'get wifi.ip')).value, tcpHost);
      blog('done over WiFi.');
      return;
    }

    expect(ssid, isNotEmpty, reason: 'pass --dart-define=WIFI_SSID=…');
    expect(pwdFile, isNotEmpty, reason: 'pass --dart-define=WIFI_PWD_FILE=…');
    // Strip only a byte-order mark and the line ending an editor adds;
    // spaces can be real.
    final password = File(pwdFile)
        .readAsStringSync()
        .replaceFirst(String.fromCharCode(0xFEFF), '')
        .replaceAll(RegExp(r'[\r\n]+$'), '');
    expect(password.isNotEmpty && password.length <= 63, isTrue,
        reason: 'the password file must hold 1–63 characters');

    // --- C1–C3 over Bluetooth ---------------------------------------------
    await bridge.start();
    ble.connector = await buildConnector();
    await connectBle();
    final c = ble.connector;
    await basics(tester, c);

    // --- C4: set WiFi up --------------------------------------------------
    await beginScenario(tester, 'C4 set network, password, on');
    expect(CliReply(await cli(c, 'set wifi.ssid $ssid')).kind,
        CliReplyKind.value);
    final pwdReply = await c.companionCli.run('set wifi.pwd $password');
    blog('  set wifi.pwd ••••••  →  $pwdReply');
    expect(CliReply(pwdReply).kind, CliReplyKind.value);
    expect(CliReply(await cli(c, 'set wifi.enabled 1')).kind,
        CliReplyKind.value);
    expect(CliReply(await cli(c, 'get wifi.ssid')).value, ssid);
    expect(CliReply(await cli(c, 'get wifi.enabled')).value, '1');

    // --- C5: restart, then the radio joins WiFi ---------------------------
    await beginScenario(tester, 'C5 restart and join WiFi');
    blog('restarting the radio (CMD_REBOOT)…');
    await c.rebootDevice();
    await Future<void>.delayed(const Duration(seconds: 3));
    try {
      await c.disconnect();
    } catch (_) {}
    // The bridge brings the BLE link back on its own; give the radio time
    // to boot before the app handshake.
    await Future<void>.delayed(const Duration(seconds: 12));
    await connectBle();
    blog('reconnected after restart');

    var status = '';
    for (var waited = 0; waited <= 90; waited += 5) {
      status = CliReply(await cli(c, 'get wifi.status')).value;
      if (status == 'connected') break;
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    expect(status, 'connected',
        reason: 'the radio did not join "$ssid" within 90 s — check the '
            'password file and that the network is 2.4 GHz');
    final ip = CliReply(await cli(c, 'get wifi.ip')).value;
    expect(RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(ip), isTrue,
        reason: 'wifi.ip should be an address, got "$ip"');
    blog('radio is on WiFi at $ip:$wifiPort');

    // --- C6: a second app over WiFi ---------------------------------------
    await beginScenario(tester, 'C6 second connection over WiFi (TCP)');
    await waitUntil(() => c.currentSyncStatus == null,
        'BLE side finished its own sync', timeout: const Duration(seconds: 90));
    expect(c.secondAppSuspected, isFalse);

    overWifi = await connectWifi(ip);
    blog('over WiFi: ${overWifi!.selfName}, protocol '
        '${overWifi!.firmwareVerCode}');
    expect(overWifi!.firmwareVerCode, 14);
    expect(CliReply(await cli(overWifi!, 'get wifi.status')).value,
        'connected');

    // The radio wrote the WiFi app's handshake replies to the BLE app too.
    final warned = await pollFor(
        () => c.secondAppSuspected, const Duration(seconds: 30));
    blog('BLE side sees another app: $warned');
    expect(warned, isTrue);

    await overWifi!.disconnect();
    overWifi = null;
    blog('done. WiFi stays on: "set wifi.enabled 0" + restart turns it off.');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
