import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/services/background_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A failed TCP auto-reconnect attempt must not stop the foreground service
// (and its WiFi lock) while the retry loop keeps re-arming itself, or the
// service is gone for every later retry. A manual disconnect still stops it.
class _RecordingService extends BackgroundService {
  final List<String> events = [];
  int Function() attempt = () => 0;
  bool running = false;

  @override
  Future<void> start({bool wifiLock = false}) async {
    events.add('start(wifiLock: $wifiLock)@connectTcp#${attempt()}');
    running = true;
  }

  @override
  Future<void> stop() async {
    events.add('stop@connectTcp#${attempt()}');
    running = false;
  }
}

class _Connector extends MeshCoreConnector {
  int connectTcpCalls = 0;

  @override
  Future<void> connectTcp({required String host, required int port}) {
    connectTcpCalls++;
    return super.connectTcp(host: host, port: port);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'foreground service stays up while a TCP auto-reconnect is still pending',
      () async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();

    final service = _RecordingService();
    final c = _Connector();
    service.attempt = () => c.connectTcpCalls;
    c.initialize(retryService: MessageRetryService(), backgroundService: service);

    // A "radio" that accepts once, then drops off the network: the listening
    // socket goes away (later connects are refused) and the live socket is
    // closed, like the ESP32 falling off the AP.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    server.listen((client) async {
      await server.close();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      client.destroy();
    });

    try {
      await c.connectTcp(host: '127.0.0.1', port: port);
    } catch (_) {
      // The handshake never completes; the drop is what we care about.
    }

    expect(service.events.first, 'start(wifiLock: true)@connectTcp#1');

    // Let the 1 s retry fire, fail against the closed port, and the loop
    // re-arm itself for a further attempt.
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (c.connectTcpCalls < 3 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    // The retry loop is still alive (more than one retry was attempted)...
    expect(c.connectTcpCalls, greaterThanOrEqualTo(3),
        reason: 'retry loop should keep running after a failed retry');
    expect(c.willAutoReconnect, isTrue);
    expect(c.state, isNot(MeshCoreConnectionState.connected));

    // ...so the foreground service (and its WiFi lock) must still be up.
    expect(service.running, isTrue,
        reason: 'service events: ${service.events}; a reconnect is still '
            'pending but the foreground service was stopped');

    await c.disconnect();
    expect(service.running, isFalse,
        reason: 'a manual disconnect ends the loop and the service');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
