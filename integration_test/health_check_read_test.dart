import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import 'harness/bench.dart';

/// Bench: the health check's read of the radio, over a real handshake.
///
/// It checks that a connection reaches "synced", that reading the settings
/// starts no contact download, and that a contact stream stopped by APP_START
/// is asked for again. Everything stays between the app and the radio; nothing
/// goes on the air.
///
/// Against the mesh simulator (in ../meshsimulator):
///
///   uv run meshsim run scenarios/dm-known.toml --port 5077
///   flutter test integration_test/health_check_read_test.dart -d windows \
///     --dart-define=MT_TCP_PORT=5077
///
/// Against a WiFi companion, add --dart-define=MT_HOST=<address>. It takes one
/// client, so this kicks any app connected to it off for the length of the run,
/// and the connector drains the radio's message queue into the test's database.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const host = String.fromEnvironment('MT_HOST', defaultValue: '127.0.0.1');
  const port = int.fromEnvironment('MT_TCP_PORT', defaultValue: 5000);

  testWidgets('reading the settings leaves the sync alone', (tester) async {
    await beginScenario(tester, 'Health check radio read');
    await PrefsManager.initialize();

    final radio = BenchRadio('TCP($host:$port)');
    radio.connector = await buildConnector();
    final c = radio.connector;
    final replies = <int>[];
    final subscription = c.receivedFrames.listen((frame) {
      if (frame.isNotEmpty) replies.add(frame[0]);
    });
    addTearDown(() async {
      await subscription.cancel();
      await c.disconnect();
    });

    final clock = Stopwatch()..start();
    await c.connectTcp(host: host, port: port);
    expect(
      await c.waitUntilSynced(timeout: const Duration(minutes: 2)),
      isTrue,
      reason: 'the first sync must finish, or every check waits and gives up',
    );
    blog(
      'synced after ${clock.elapsedMilliseconds} ms: "${c.selfName}", '
      '${c.firmwareVersion}, ${c.contacts.length} contacts, '
      '${c.channels.length} channels',
    );

    final contactsBefore = c.contacts.length;
    replies.clear();
    clock.reset();
    final answered = await c.readRadioSettings();
    blog(
      'read ${answered ? 'answered' : 'NOT answered'} in '
      '${clock.elapsedMilliseconds} ms, replies $replies',
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(answered, isTrue);
    expect(replies, isNot(contains(respCodeContactsStart)));
    expect(c.isLoadingContacts, isFalse);
    expect(c.contacts, hasLength(contactsBefore));
    expect(c.isSynced, isTrue);

    replies.clear();
    await c.refreshContacts();
    await waitUntil(
      () => replies.contains(respCodeContactsStart) || !c.isLoadingContacts,
      'the contact stream to start',
    );
    await c.refreshDeviceInfo();
    await waitUntil(
      () => !c.isLoadingContacts,
      'the contact download to finish after APP_START',
      timeout: const Duration(minutes: 2),
    );
    await waitUntil(
      () => c.isSynced,
      'the radio to be idle again',
      timeout: const Duration(minutes: 2),
    );
    blog(
      'after APP_START in a stream: ${c.contacts.length} contacts, '
      'replies $replies',
    );
    expect(c.contacts, hasLength(contactsBefore));
  }, timeout: const Timeout(Duration(minutes: 8)));
}
