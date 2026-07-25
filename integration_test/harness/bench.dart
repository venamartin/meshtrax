import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_history_service.dart';
import 'package:meshtrax/services/storage_service.dart';

import 'bench_config.dart';

final List<String> _benchLog = <String>[];
final ValueNotifier<int> _benchLogVersion = ValueNotifier<int>(0);
final ValueNotifier<String> _benchScenario = ValueNotifier<String>('starting…');

void blog(String msg) {
  final t = DateTime.now().toIso8601String().substring(11, 19);
  // ignore: avoid_print
  print('[bench $t] $msg');
  _benchLog.add('$t  $msg');
  if (_benchLog.length > 400) {
    _benchLog.removeRange(0, _benchLog.length - 400);
  }
  _benchLogVersion.value++;
}

/// Mirrors connector warnings/errors into the on-screen console.
void mirrorWarnings(AppDebugLogService service) {
  var seen = service.entries.length;
  service.addListener(() {
    final entries = service.entries;
    for (var i = seen; i < entries.length; i++) {
      final e = entries[i];
      if (e.level != AppDebugLogLevel.info) {
        blog('⚠ [${e.tag}] ${e.message}');
      }
    }
    seen = entries.length;
  });
}

/// Live console rendered into the integration-test window so the bench can
/// be watched without tailing the terminal.
class BenchConsole extends StatelessWidget {
  const BenchConsole({super.key});

  Color _colorFor(String line) {
    if (line.contains('CONTAMINATION')) return Colors.redAccent;
    if (line.contains('WARNING') || line.contains('⚠')) {
      return Colors.orangeAccent;
    }
    if (line.contains('REPEATER CONFIRMED')) return Colors.lightGreenAccent;
    if (line.contains('[bridge]')) return Colors.cyanAccent;
    if (line.contains('===')) return Colors.white;
    return const Color(0xFF9CCC65);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: const Color(0xFF102027),
          title: ValueListenableBuilder<String>(
            valueListenable: _benchScenario,
            builder: (_, value, _) => Text(
              value,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 15),
            ),
          ),
        ),
        body: ValueListenableBuilder<int>(
          valueListenable: _benchLogVersion,
          builder: (_, _, _) => ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(8),
            itemCount: _benchLog.length,
            itemBuilder: (_, i) {
              final line = _benchLog[_benchLog.length - 1 - i];
              return Text(
                line,
                style: TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 13,
                  color: _colorFor(line),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Call first in every scenario: names it on screen and mounts the console.
Future<void> beginScenario(WidgetTester tester, String title) async {
  _benchScenario.value = title;
  blog('=== $title ===');
  await tester.pumpWidget(const BenchConsole());
  await tester.pump();
}

/// One physical radio on the bench, wrapped in a stock app connector.
class BenchRadio {
  BenchRadio(this.label);

  final String label;
  late MeshCoreConnector connector;

  /// Re-runs this radio's transport connect (set by the suite).
  late Future<void> Function() reconnect;

  /// slot -> idKey of every NON-harness channel found at bench start.
  /// These slots are untouchable for the rest of the run.
  Map<int, String> protectedSlots = {};
}

/// The live list is rebuilt from empty during every slot resync — decisions
/// made mid-rebuild see a partial table. Always settle first.
Future<void> awaitSyncIdle(BenchRadio radio) async {
  await waitUntil(
    () =>
        radio.connector.channelsVerified &&
        !radio.connector.isLoadingChannels,
    '${radio.label}: channel sync settles',
    timeout: const Duration(seconds: 60),
  );
}

void snapshotProtectedSlots(BenchRadio radio, Set<String> harnessIdKeys) {
  radio.protectedSlots = {
    for (final c in radio.connector.channels)
      if (!harnessIdKeys.contains(c.idKey)) c.index: c.idKey,
  };
  final slots = radio.protectedSlots.keys.toList()..sort();
  blog('${radio.label}: protecting ${slots.length} pre-existing channel '
      'slot(s): $slots');
}

/// Dedicated bench radios start every run from a clean slate: all
/// non-Public slots cleared, so leftovers from aborted runs vanish.
Future<void> wipeNonPublicChannels(BenchRadio radio) async {
  for (var pass = 0; pass < 3; pass++) {
    await awaitSyncIdle(radio);
    final targets =
        radio.connector.channels.where((c) => !c.isPublicChannel).toList();
    if (targets.isEmpty) {
      blog('${radio.label}: slot table clean (Public only)');
      return;
    }
    blog('${radio.label}: wiping ${targets.length} channel slot(s) '
        '(dedicated bench radio)');
    for (final c in targets) {
      await radio.connector.deleteChannel(c.index);
    }
  }
  await awaitSyncIdle(radio);
  expect(
    radio.connector.channels.where((c) => !c.isPublicChannel),
    isEmpty,
    reason: '${radio.label}: wipe left channels behind after 3 passes',
  );
}

/// First byte of sha256(psk) — the firmware's 1-byte on-air channel hash.
int channelHashByte(Uint8List psk) =>
    crypto.sha256.convert(psk).bytes.first;

/// Finds a hashtag whose derived PSK shares the on-air hash byte with
/// [targetHashtag]'s — the bench uses it to build a DELIBERATE collision
/// pair instead of waiting for a 1-in-256 accident.
String mineCollidingHashtag(String targetHashtag) {
  final target = channelHashByte(Channel.derivePskFromHashtag(targetHashtag));
  for (var i = 1; i < 10000; i++) {
    final name = '#hxc$i';
    if (name == targetHashtag) continue;
    if (channelHashByte(Channel.derivePskFromHashtag(name)) == target) {
      return name;
    }
  }
  fail('No colliding hashtag in 10000 candidates — statistically impossible');
}

Future<void> verifyUserChannelsIntact(BenchRadio radio) async {
  await awaitSyncIdle(radio);
  final disturbed = <String>[];
  radio.protectedSlots.forEach((slot, idKey) {
    final live = liveByIdKey(radio.connector, idKey);
    if (live == null) {
      disturbed.add('slot $slot (${idKey.substring(0, 8)}…) MISSING');
    } else if (live.index != slot) {
      disturbed.add('slot $slot (${idKey.substring(0, 8)}…) moved to '
          '${live.index}');
    }
  });
  expect(disturbed, isEmpty,
      reason: '${radio.label}: pre-existing channels were disturbed: '
          '${disturbed.join('; ')}');
  blog('${radio.label}: all ${radio.protectedSlots.length} pre-existing '
      'channels intact');
}

/// Builds a connector wired exactly like main.dart does, minus UI services.
Future<MeshCoreConnector> buildConnector() async {
  final storage = StorageService();
  final connector = MeshCoreConnector();
  final appSettings = AppSettingsService();
  await appSettings.loadSettings();
  connector.initialize(
    retryService: MessageRetryService(),
    pathHistoryService: PathHistoryService(storage),
    appSettingsService: appSettings,
  );
  await connector.loadContactCache();
  await connector.loadCachedChannels();
  await connector.loadChannelSettings();
  return connector;
}

/// Non-failing poll: true when the condition holds within [timeout].
Future<bool> pollFor(
  bool Function() condition,
  Duration timeout, {
  Duration poll = const Duration(milliseconds: 500),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) return false;
    await Future<void>.delayed(poll);
  }
  return true;
}

Future<void> waitUntil(
  bool Function() condition,
  String what, {
  Duration timeout = const Duration(seconds: 30),
  Duration poll = const Duration(milliseconds: 250),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out after ${timeout.inSeconds}s waiting for: $what');
    }
    await Future<void>.delayed(poll);
  }
}

Future<void> waitConnectedVerified(BenchRadio radio) async {
  await waitUntil(
    () => radio.connector.isConnected && radio.connector.channelsVerified,
    '${radio.label}: connected + channel map verified',
    timeout: BenchConfig.handshakeTimeout,
  );
  blog('${radio.label}: connected, ${radio.connector.channels.length} '
      'channels verified');
}

Channel? liveByIdKey(MeshCoreConnector c, String idKey) {
  for (final ch in c.channels) {
    if (ch.idKey == idKey) return ch;
  }
  return null;
}

/// A free slot on a SETTLED channel table, never slot 0 (Public) and never
/// a slot that held a pre-existing channel at bench start.
int freeSlot(BenchRadio radio, {Set<int> avoid = const {}}) {
  final c = radio.connector;
  final occupied = c.channels.map((ch) => ch.index).toSet();
  for (var i = 1; i < c.maxChannels; i++) {
    if (occupied.contains(i)) continue;
    if (avoid.contains(i)) continue;
    if (radio.protectedSlots.containsKey(i)) continue;
    return i;
  }
  fail('No free channel slot on the radio — refusing to touch existing '
      'channels. Free a slot and re-run.');
}

Future<Channel> ensureChannel(
  BenchRadio radio,
  String name,
  Uint8List psk, {
  int? atSlot,
}) async {
  await awaitSyncIdle(radio);
  final idKey = Channel.formatPskHex(psk);
  final existing = liveByIdKey(radio.connector, idKey);
  if (existing != null) return existing;

  final slot = atSlot ?? freeSlot(radio);
  final protectedIdKey = radio.protectedSlots[slot];
  if (protectedIdKey != null && protectedIdKey != idKey) {
    fail('${radio.label}: refusing to write $name into slot $slot — a '
        'pre-existing channel (${protectedIdKey.substring(0, 8)}…) '
        'lives there');
  }
  Channel? occupant;
  for (final c in radio.connector.channels) {
    if (c.index == slot) {
      occupant = c;
      break;
    }
  }
  if (occupant != null && occupant.idKey != idKey) {
    fail('${radio.label}: refusing to write $name into slot $slot — '
        'occupied by ${occupant.displayName}');
  }

  blog('${radio.label}: creating $name in slot $slot');
  await radio.connector.setChannel(slot, name, psk);
  await waitUntil(
    () => liveByIdKey(radio.connector, idKey) != null,
    '${radio.label}: $name appears in live channel list',
    timeout: const Duration(seconds: 60),
  );
  return liveByIdKey(radio.connector, idKey)!;
}

Future<void> removeChannelIfPresent(BenchRadio radio, String idKey) async {
  await awaitSyncIdle(radio);
  final live = liveByIdKey(radio.connector, idKey);
  if (live == null) return;
  blog('${radio.label}: deleting ${live.displayName} (slot ${live.index})');
  await radio.connector.deleteChannel(live.index);
  await waitUntil(
    () => liveByIdKey(radio.connector, idKey) == null,
    '${radio.label}: channel $idKey removed',
    timeout: const Duration(seconds: 60),
  );
  await awaitSyncIdle(radio);
}

/// Moves the radio to [khz] (default: bench frequency), keeping its own
/// BW/SF/CR. Firmware applies CMD_SET_RADIO_PARAMS live — no reboot needed.
Future<void> alignFrequency(BenchRadio radio, {int? khz}) async {
  final target = khz ?? BenchConfig.targetFreqKhz;
  final targetMhz = (target / 1000).toStringAsFixed(3);
  final c = radio.connector;
  await waitUntil(
    () => c.currentFreqHz != null && c.currentSf != null,
    '${radio.label}: radio params known from self info',
  );
  final mhz = (c.currentFreqHz! / 1000).toStringAsFixed(3);
  blog('${radio.label}: freq=$mhz MHz bw=${c.currentBwHz} '
      'sf=${c.currentSf} cr=${c.currentCr}');
  if (c.currentFreqHz == target) return;

  final cr = c.currentCr! >= 5 ? c.currentCr! : c.currentCr! + 4;
  blog('${radio.label}: retuning to $targetMhz MHz');
  await c.sendFrame(
    buildSetRadioParamsFrame(target, c.currentBwHz!, c.currentSf!, cr),
  );
  await Future<void>.delayed(const Duration(seconds: 1));
  await c.refreshDeviceInfo();
  await waitUntil(
    () => c.currentFreqHz == target,
    '${radio.label}: frequency confirms $targetMhz MHz',
    timeout: const Duration(seconds: 20),
  );
  blog('${radio.label}: now on $targetMhz MHz');
}

/// Twin-slot warnings are bench failures. Hash-collision and nameless-slot
/// notes are informational — they can legitimately involve the radios'
/// pre-existing channels (and on this bench #hx2 really does collide with a
/// user channel, which is bonus coverage for the multi-candidate decode path).
List<String> fatalHealthWarnings(MeshCoreConnector c) {
  for (final w in c.channelHealthWarnings) {
    if (!w.startsWith('Duplicate channel:')) {
      blog('health (informational): $w');
    }
  }
  return c.channelHealthWarnings
      .where((w) => w.startsWith('Duplicate channel:'))
      .toList();
}

/// Which harness text belongs in which channel identity. The sweep asserts
/// every harness text found anywhere sits ONLY under its expected idKey —
/// the direct detector for the field-reported cross-contamination.
class MessageLedger {
  final Map<String, Set<String>> expectedByIdKey = {};
  final Set<String> allTexts = {};

  void expectText(String idKey, String text) {
    expectedByIdKey.putIfAbsent(idKey, () => {}).add(text);
    allTexts.add(text);
  }
}

Future<void> contaminationSweep(
  List<BenchRadio> radios,
  MessageLedger ledger,
) async {
  for (final radio in radios) {
    for (final ch in radio.connector.channels) {
      final messages = await radio.connector.loadChannelMessagesFor(ch);
      final counts = <String, int>{};
      for (final m in messages) {
        if (!ledger.allTexts.contains(m.text)) continue;
        counts[m.text] = (counts[m.text] ?? 0) + 1;
        final allowed =
            ledger.expectedByIdKey[ch.idKey]?.contains(m.text) ?? false;
        expect(
          allowed,
          isTrue,
          reason:
              'CONTAMINATION on ${radio.label}: "${m.text}" surfaced in '
              '${ch.displayName} (slot ${ch.index}, '
              'idKey ${ch.idKey.substring(0, 8)}…) where it does not belong',
        );
      }
      counts.forEach((text, n) {
        expect(
          n,
          1,
          reason: 'DUPLICATE on ${radio.label}: "$text" appears $n times '
              'in ${ch.displayName} — dedup failed',
        );
      });
    }
  }
}

/// Asserts a text is not visible in ANY channel of a radio (e.g. traffic on
/// a channel the radio is not subscribed to must vanish entirely).
Future<void> assertTextAbsentEverywhere(BenchRadio radio, String text) async {
  for (final ch in radio.connector.channels) {
    final hit =
        (await radio.connector.loadChannelMessagesFor(ch))
            .any((m) => m.text == text);
    expect(hit, isFalse,
        reason: 'LEAK on ${radio.label}: "$text" visible in '
            '${ch.displayName} — this radio must never see it');
  }
}

/// Tolerant arrival check: true if the text shows up in the right channel
/// within the window. Never fails the test — for loss-accounting scenarios.
Future<bool> textArrived(
  BenchRadio radio,
  String idKey,
  String text, {
  Duration? timeout,
}) async {
  final deadline =
      DateTime.now().add(timeout ?? BenchConfig.messageTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final ch = liveByIdKey(radio.connector, idKey);
    if (ch != null &&
        (await radio.connector.loadChannelMessagesFor(ch))
            .any((m) => m.text == text)) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  return false;
}

Future<void> awaitText(
  BenchRadio radio,
  String idKey,
  String text, {
  Duration? timeout,
}) async {
  final ok = await textArrived(radio, idKey, text, timeout: timeout);
  if (!ok) {
    fail('Timed out waiting for: ${radio.label}: "$text" arrives in '
        'channel $idKey');
  }
}

// --- Direct Drift-database audit layer -----------------------------------
// The connectors persist through ChannelMessageStore into AppDatabase; these
// helpers assert at the ROW level so the new database is a test subject in
// its own right, not just an implicit dependency.

/// Matches ChannelMessageStore's truncation of the node pubkey.
String nodeScopeOf(BenchRadio radio) {
  final hex = radio.connector.selfPublicKeyHex;
  return hex.length > 10 ? hex.substring(0, 10) : '';
}

Future<List<ChannelMessageRow>> dbRows(String scope, String idKey) {
  final db = AppDatabase.instance;
  return (db.select(db.channelMessageRows)
        ..where((r) => r.nodeScope.equals(scope) & r.channelIdKey.equals(idKey))
        ..orderBy([
          (r) => drift.OrderingTerm(expression: r.timestampMs),
          (r) => drift.OrderingTerm(expression: r.id),
        ]))
      .get();
}

String? _rowText(ChannelMessageRow row) {
  try {
    return (jsonDecode(row.payload) as Map<String, dynamic>)['text']
        as String?;
  } catch (_) {
    return null;
  }
}

/// Row-level integrity: unique messageIds per (scope, idKey), and every
/// harness text stored ONLY under its home identity.
Future<void> assertDbIntegrity(
  List<BenchRadio> radios,
  MessageLedger ledger,
  Iterable<String> idKeys,
) async {
  for (final radio in radios) {
    final scope = nodeScopeOf(radio);
    expect(scope, isNotEmpty,
        reason: '${radio.label}: node scope unknown — self info missing?');
    for (final idKey in idKeys) {
      final rows = await dbRows(scope, idKey);
      final ids = rows.map((r) => r.messageId).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'DB DUPLICATES on ${radio.label}: repeated messageId '
              'rows under idKey ${idKey.substring(0, 8)}…');
      for (final row in rows) {
        final text = _rowText(row);
        if (text == null || !ledger.allTexts.contains(text)) continue;
        expect(
          ledger.expectedByIdKey[idKey]?.contains(text) ?? false,
          isTrue,
          reason: 'DB CONTAMINATION on ${radio.label}: "$text" stored '
              'under idKey ${idKey.substring(0, 8)}… where it does not '
              'belong',
        );
      }
    }
    blog('${radio.label}: DB rows clean for scope $scope');
  }
}

/// Asserts no rows exist at all for an identity under a radio's scope —
/// node-scope isolation and deletion-purge proofs.
Future<void> assertDbEmptyFor(
  BenchRadio radio,
  String idKey,
  String why,
) async {
  final rows = await dbRows(nodeScopeOf(radio), idKey);
  expect(rows, isEmpty,
      reason: 'DB LEAK on ${radio.label}: ${rows.length} row(s) under '
          'idKey ${idKey.substring(0, 8)}… — $why');
}

/// Asserts specific texts do not survive in the DB for an identity/scope
/// (deleted-history resurrection guard).
Future<void> assertDbTextsGone(
  BenchRadio radio,
  String idKey,
  Iterable<String> texts,
) async {
  final rows = await dbRows(nodeScopeOf(radio), idKey);
  final stored = rows.map(_rowText).whereType<String>().toSet();
  for (final t in texts) {
    expect(stored.contains(t), isFalse,
        reason: 'ZOMBIE on ${radio.label}: deleted text "$t" still in the '
            'DB under idKey ${idKey.substring(0, 8)}…');
  }
}

Future<ChannelMessage?> findOutgoing(
  BenchRadio radio,
  String idKey,
  String text,
) async {
  final ch = liveByIdKey(radio.connector, idKey);
  if (ch == null) return null;
  for (final m in await radio.connector.loadChannelMessagesFor(ch)) {
    if (m.isOutgoing && m.text == text) return m;
  }
  return null;
}

/// Reports whether the repeater echoed a message we sent — the sender's own
/// copy collects a Repeat entry (or reaches `delivered`) when the echo is
/// heard. Report-only: the bench must not fail on repeater availability.
Future<void> reportRepeaterEcho(
  BenchRadio radio,
  String idKey,
  String text, {
  Duration window = const Duration(seconds: 45),
}) async {
  final deadline = DateTime.now().add(window);
  while (DateTime.now().isBefore(deadline)) {
    final m = await findOutgoing(radio, idKey, text);
    if (m != null &&
        (m.repeats.isNotEmpty ||
            m.status == ChannelMessageStatus.delivered)) {
      final names = m.repeats
          .map((r) => '${r.repeaterName} (${r.tripTimeMs} ms)')
          .join(', ');
      blog('REPEATER CONFIRMED: ${m.repeats.length} repeat(s)'
          '${names.isEmpty ? ' (delivered status)' : ' — $names'}');
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  blog('WARNING: REPEATER NOT HEARD in ${window.inSeconds}s — is F857 '
      'powered, on 920.000 MHz, with the same SF/BW as the companions?');
}

/// Waits for the sender's own copy to leave `pending`; failure is a hard
/// error, missing repeat-echo confirmation is only logged (environmental).
Future<void> awaitSendSettled(
  BenchRadio radio,
  String idKey,
  String text,
) async {
  final appearBy = DateTime.now().add(const Duration(seconds: 30));
  ChannelMessage? m;
  while (DateTime.now().isBefore(appearBy)) {
    m = await findOutgoing(radio, idKey, text);
    if (m != null) break;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  if (m == null) {
    fail('${radio.label}: outgoing "$text" never appeared locally');
  }
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (DateTime.now().isBefore(deadline)) {
    m = await findOutgoing(radio, idKey, text);
    if (m != null && m.status != ChannelMessageStatus.pending) {
      if (m.status == ChannelMessageStatus.failed) {
        // Delivery is proven by the receive-side assert; "failed" here only
        // means the repeat-echo heuristic never heard the repeater.
        blog('${radio.label}: WARNING "$text" marked failed — no repeater '
            'echo heard (is F857 on 920.000 MHz with matching SF/BW?)');
      } else {
        blog('${radio.label}: "$text" -> ${m.status.name}');
      }
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  blog('${radio.label}: "$text" still pending after 60s '
      '(no repeat echo heard — repeater off-air?); continuing');
}

// --- Contact / DM / repeater helpers --------------------------------------

Contact? findContactByHex(
  MeshCoreConnector c,
  String pubKeyHex, {
  bool savedOnly = false,
}) {
  final hx = pubKeyHex.toLowerCase();
  for (final ct in c.contacts) {
    if (ct.publicKeyHex.toLowerCase() == hx) return ct;
  }
  if (!savedOnly) {
    for (final ct in c.discoveredContacts) {
      if (ct.publicKeyHex.toLowerCase() == hx) return ct;
    }
  }
  return null;
}

Contact? findContactByPrefix(
  MeshCoreConnector c,
  String hexPrefix, {
  bool savedOnly = false,
}) {
  final px = hexPrefix.toLowerCase();
  for (final ct in c.contacts) {
    if (ct.publicKeyHex.toLowerCase().startsWith(px)) return ct;
  }
  if (!savedOnly) {
    for (final ct in c.discoveredContacts) {
      if (ct.publicKeyHex.toLowerCase().startsWith(px)) return ct;
    }
  }
  return null;
}

/// Waits for [pubKeyHex] to be known on [on] (advert must have flowed) and
/// promotes a discovered-only entry to a saved contact.
Future<Contact> ensureSavedContact(
  BenchRadio on,
  String pubKeyHex,
  String what,
) async {
  await waitUntil(
    () => findContactByHex(on.connector, pubKeyHex) != null,
    '${on.label}: $what appears in contacts',
    timeout: const Duration(seconds: 90),
    poll: const Duration(seconds: 1),
  );
  if (findContactByHex(on.connector, pubKeyHex, savedOnly: true) == null) {
    final discovered = findContactByHex(on.connector, pubKeyHex)!;
    blog('${on.label}: importing discovered contact ${discovered.name}');
    await on.connector.importDiscoveredContact(discovered);
    await waitUntil(
      () =>
          findContactByHex(on.connector, pubKeyHex, savedOnly: true) != null,
      '${on.label}: $what saved to contacts',
    );
  }
  return findContactByHex(on.connector, pubKeyHex, savedOnly: true)!;
}

Future<bool> dmArrived(
  BenchRadio radio,
  Contact from,
  String text, {
  Duration? timeout,
}) async {
  final deadline =
      DateTime.now().add(timeout ?? BenchConfig.messageTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final hit = (await radio.connector.loadMessagesFor(from))
        .any((m) => !m.isOutgoing && m.text == text);
    if (hit) return true;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  return false;
}

/// Polls the sender's copy of a DM until it reaches a terminal status
/// (delivered/failed) or the window closes; returns the last status seen.
Future<MessageStatus?> awaitDmStatus(
  BenchRadio radio,
  Contact to,
  String text, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  MessageStatus? last;
  while (DateTime.now().isBefore(deadline)) {
    for (final m in await radio.connector.loadMessagesFor(to)) {
      if (m.isOutgoing && m.text == text) {
        last = m.status;
        break;
      }
    }
    if (last == MessageStatus.delivered || last == MessageStatus.failed) {
      return last;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  return last;
}

/// CMD_SEND_LOGIN to a repeater contact; waits for the push response.
/// Returns (success, isAdmin); success is null on timeout.
Future<(bool?, bool)> repeaterLogin(
  BenchRadio radio,
  Contact repeater,
  String password, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final completer = Completer<(bool?, bool)>();
  final targetPrefix = repeater.publicKey.sublist(0, 6);
  final sub = radio.connector.receivedFrames.listen((frame) {
    if (frame.isEmpty) return;
    final code = frame[0];
    if (code != pushCodeLoginSuccess && code != pushCodeLoginFail) return;
    if (frame.length < 8) return;
    if (!listEquals(frame.sublist(2, 8), targetPrefix)) return;
    if (!completer.isCompleted) {
      completer.complete((code == pushCodeLoginSuccess, frame[1] == 1));
    }
  });
  try {
    await radio.connector
        .sendFrame(buildSendLoginFrame(repeater.publicKey, password));
    return await completer.future
        .timeout(timeout, onTimeout: () => (null, false));
  } finally {
    await sub.cancel();
  }
}

/// Sends a CLI command to a repeater contact; returns the reply text, or
/// null on timeout. CLI replies are deliberately NOT stored in the chat
/// conversation (that was the "CLI leak" bug) — management screens consume
/// them straight off the frame stream, so the bench does the same.
/// Read-only commands only — the bench repeater must stay configured.
Future<String?> repeaterCli(
  BenchRadio radio,
  Contact repeater,
  String command, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final completer = Completer<String?>();
  final target = repeater.publicKey.sublist(0, 6);
  final sub = radio.connector.receivedFrames.listen((frame) {
    if (frame.isEmpty) return;
    if (frame[0] != respCodeContactMsgRecv &&
        frame[0] != respCodeContactMsgRecvV3) {
      return;
    }
    final parsed = parseContactMessageText(frame);
    if (parsed == null) return;
    if (parsed.senderPrefix.length < 6 ||
        !listEquals(parsed.senderPrefix.sublist(0, 6), target)) {
      return;
    }
    if (!completer.isCompleted) completer.complete(parsed.text);
  });
  try {
    blog('${radio.label}: repeater CLI "$command"');
    await radio.connector
        .sendFrame(buildSendCliCommandFrame(repeater.publicKey, command));
    return await completer.future
        .timeout(timeout, onTimeout: () => null);
  } finally {
    await sub.cancel();
  }
}

/// idKey -> harness texts currently visible; used for the restart test.
Future<Map<String, Set<String>>> snapshotHarnessTexts(
  BenchRadio radio,
  MessageLedger ledger,
) async {
  final snapshot = <String, Set<String>>{};
  for (final ch in radio.connector.channels) {
    final texts = (await radio.connector.loadChannelMessagesFor(ch))
        .map((m) => m.text)
        .where(ledger.allTexts.contains)
        .toSet();
    if (texts.isNotEmpty) snapshot[ch.idKey] = texts;
  }
  return snapshot;
}
