import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/helpers/repeater_identity.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/app_logger.dart';

import 'harness/bench.dart';
import 'harness/bench_config.dart';

/// Hardware proof for the Nearby Repeaters identity fix.
///
/// A repeater ten feet away was shown under the name of one 100 miles away
/// because the app matched a 1–2 byte hash instead of the 32-byte key the
/// discovery response actually carries.
///
/// This drives the USB companion on whatever frequency it is already tuned to
/// — the point is to hear the user's real mesh with the user's real contact
/// book, which is where the collisions live. It transmits exactly one thing: a
/// zero-hop NODE_DISCOVER_REQ, the same packet the Discover button sends. It
/// never writes to a repeater and never retunes the radio.
///
/// Run with:
///   flutter test integration_test/repeater_discovery_identity_test.dart \
///     -d windows
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final usb = BenchRadio('USB(${BenchConfig.usbPortName})');
  var ready = false;

  /// Raw NODE_DISCOVER_RESP payloads captured off the wire, keyed by pubkey.
  final rawResponses = <String, Uint8List>{};

  void requireReady() {
    if (!ready) fail('Bench not ready — see the first failure above.');
  }

  String hex(List<int> bytes) => PathHelper.hopHex(bytes);

  testWidgets('D0 USB companion up, contacts synced', (tester) async {
    await beginScenario(tester, 'D0 bring-up');
    await PrefsManager.initialize();
    final debugLog = AppDebugLogService();
    appLogger.initialize(debugLog, enabled: true);
    mirrorWarnings(debugLog);

    usb.connector = await buildConnector();
    usb.reconnect = () async {
      await usb.connector.connectUsb(portName: BenchConfig.usbPortName);
      await waitConnectedVerified(usb);
    };
    await usb.reconnect();

    final c = usb.connector;
    blog('radio: ${c.selfName} (${c.selfPublicKeyHex.substring(0, 12)}…)');
    await waitUntil(() => c.currentFreqHz != null, 'radio params known');
    blog('freq=${(c.currentFreqHz! / 1000).toStringAsFixed(3)} MHz '
        'sf=${c.currentSf} bw=${c.currentBwHz} cr=${c.currentCr} '
        'pathHashWidth=${c.pathHashByteWidth}');

    await waitUntil(() => !c.isLoadingContacts && c.contacts.isNotEmpty,
        'contact table synced', timeout: const Duration(seconds: 90));
    final repeaters =
        c.allContacts.where((x) => x.type == advTypeRepeater).length;
    blog('${c.allContacts.length} contacts, $repeaters repeaters');
    ready = true;
  });

  testWidgets('D1 the real contact book measured for hash collisions',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'D1 collision census');
    final c = usb.connector;
    final width = c.pathHashByteWidth;

    // The exposure the fix removes: every hash that more than one contact
    // answers to was a chance to name, locate and log into the wrong node.
    for (final w in {1, width}) {
      final byHash = <String, List<Contact>>{};
      for (final contact in c.allContacts) {
        if (contact.publicKey.length < w) continue;
        if (contact.type != advTypeRepeater && contact.type != advTypeRoom) {
          continue;
        }
        byHash
            .putIfAbsent(hex(PathHelper.pubKeyPrefix(contact.publicKey, stride: w)),
                () => [])
            .add(contact);
      }
      final collisions = byHash.entries.where((e) => e.value.length > 1);
      blog('$w-byte hashes: ${byHash.length} distinct, '
          '${collisions.length} shared by two or more contacts');
      for (final e in collisions) {
        blog('   ${e.key} -> ${e.value.map((x) => x.name).join(' | ')}');
      }
    }
  });

  testWidgets('D2 Discover: every response carries the full 32-byte key',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'D2 discovery on air');
    final c = usb.connector;

    // Capture the raw control frames the companion pushes up, so the wire
    // format is asserted rather than assumed.
    final sub = c.receivedFrames.listen((frame) {
      if (frame.length < 5 || frame[0] != pushCodeControlData) return;
      final payload = frame.sublist(4);
      if (payload.isEmpty) return;
      if ((payload[0] & 0xF0) != ctlTypeNodeDiscoverResp) return;
      if (payload.length < 6 + pubKeySize) {
        blog('SHORT response: ${payload.length} bytes — ${hex(payload)}');
        rawResponses['short:${hex(payload)}'] = payload;
        return;
      }
      final key = payload.sublist(6, 6 + pubKeySize);
      rawResponses[pubKeyToHex(key)] = payload;
      blog('resp ${payload.length} B  type=0x${payload[0].toRadixString(16)}  '
          'key=${hex(key.sublist(0, 4))}…  tail=${payload.length - 6 - pubKeySize} B');
    });

    try {
      blog('sending NODE_DISCOVER_REQ (zero hop)');
      await c.sendRepeaterDiscovery();
      // The firmware answers after getRetransmitDelay()x4 of anti-collision
      // delay, so the window has to be generous; sendRepeaterDiscovery uses 30s.
      await waitUntil(() => !c.isDiscovering, 'discovery window closed',
          timeout: const Duration(seconds: 40));
    } finally {
      await sub.cancel();
    }

    blog('${rawResponses.length} responses, '
        '${c.directRepeaters.length} tracked neighbours');
    if (rawResponses.isEmpty) {
      fail('No repeater answered Discover. Nothing to verify — is a repeater '
          'in range and on this frequency?');
    }

    for (final entry in rawResponses.entries) {
      expect(entry.key.startsWith('short:'), isFalse,
          reason: 'A response arrived without a full public key. The app asks '
              'with prefix_only = 0, so the firmware must send all 32 bytes.');
      final payload = entry.value;
      expect(payload[0] & 0x0F, advTypeRepeater);
      expect(payload.length, 6 + pubKeySize,
          reason: 'NODE_DISCOVER_RESP is [type][snr][tag x4][pub_key x32] and '
              'carries no name — if this ever grows, the name parser in '
              '_handleControlData starts mattering.');
    }
  });

  testWidgets('D3 every tracked neighbour keeps the key it was heard by',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'D3 tracked identity');
    final c = usb.connector;

    expect(c.directRepeaters, isNotEmpty,
        reason: 'D2 heard responses but nothing was tracked');

    for (final r in c.directRepeaters) {
      final identity = RepeaterIdentityHelper.resolve(
        contacts: c.allContacts,
        publicKey: r.publicKey,
        hashPrefix: r.pubkeyPrefix,
      );
      blog('${r.prefixHex}  snr=${r.snr.toStringAsFixed(1)}  '
          'source=${identity.source.name}  "${identity.displayName}"');

      if (r.publicKey == null) {
        // Heard only by hash, from an advert path rather than a response.
        expect(identity.source, isNot(RepeaterIdentitySource.exactKey));
        continue;
      }

      // Anything that answered Discover is addressable by exactly the key it
      // sent — never by a contact that merely shares its hash.
      expect(identity.addressableKey, isNotNull);
      expect(pubKeyToHex(identity.addressableKey!), pubKeyToHex(r.publicKey!),
          reason: 'the tile would have acted on a different node than the one '
              'that answered');
      if (identity.contact != null) {
        expect(identity.source, RepeaterIdentitySource.exactKey);
        expect(identity.contact!.publicKeyHex, pubKeyToHex(r.publicKey!));
      }
    }
  });

  testWidgets('D4 a planted collision cannot steal a real response',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'D4 the reported bug, reproduced');
    final c = usb.connector;

    final heard = c.directRepeaters
        .where((r) => r.publicKey != null)
        .toList();
    expect(heard, isNotEmpty, reason: 'no repeater with a full key to test');
    final real = heard.first;
    final realKey = real.publicKey!;

    // Exactly the field scenario: a contact that shares the leading hash bytes
    // of the repeater in the room, and is 100 miles away.
    final impostorKey = Uint8List.fromList(realKey);
    impostorKey[pubKeySize - 1] ^= 0xFF;
    expect(pubKeyToHex(impostorKey), isNot(pubKeyToHex(realKey)));

    final impostor = Contact(
      publicKey: impostorKey,
      name: 'MOUNTAIN-TOP-100MI',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      latitude: 34.0,
      longitude: -118.0,
      lastSeen: DateTime.now(), // most recently seen — the old tie-break winner
    );

    final contactsWithoutReal = c.allContacts
        .where((x) => x.publicKeyHex != pubKeyToHex(realKey))
        .toList();
    blog('planting ${impostor.name} sharing '
        '${hex(PathHelper.pubKeyPrefix(realKey, stride: c.pathHashByteWidth))} '
        'with the repeater that actually answered');

    final identity = RepeaterIdentityHelper.resolve(
      contacts: [...contactsWithoutReal, impostor],
      publicKey: realKey,
      hashPrefix: real.pubkeyPrefix,
    );
    blog('resolved: source=${identity.source.name} "${identity.displayName}"');

    expect(identity.contact, isNull,
        reason: 'a hash collision was allowed to claim a full-key response');
    expect(identity.displayName, isNot('MOUNTAIN-TOP-100MI'));
    expect(identity.source, RepeaterIdentitySource.unknown);
    expect(identity.isUnknownContact, isTrue);
    // Still usable: the login target is the radio that answered.
    expect(pubKeyToHex(identity.addressableKey!), pubKeyToHex(realKey));

    // And with the real contact present, the impostor changes nothing.
    final withReal = RepeaterIdentityHelper.resolve(
      contacts: [...c.allContacts, impostor],
      publicKey: realKey,
      hashPrefix: real.pubkeyPrefix,
    );
    if (withReal.contact != null) {
      blog('with the real contact present: "${withReal.displayName}"');
      expect(withReal.contact!.publicKeyHex, pubKeyToHex(realKey));
      expect(withReal.source, RepeaterIdentitySource.exactKey);
    }
  });

  testWidgets('D5 an advert hash shared by two contacts identifies neither',
      (tester) async {
    requireReady();
    await beginScenario(tester, 'D5 hash-only ambiguity');
    final c = usb.connector;

    final width = c.pathHashByteWidth;
    final anyRepeater = c.allContacts
        .cast<Contact?>()
        .firstWhere((x) => x!.type == advTypeRepeater, orElse: () => null);
    expect(anyRepeater, isNotNull, reason: 'no repeater contacts on this radio');

    final hash = PathHelper.pubKeyPrefix(anyRepeater!.publicKey, stride: width);
    final twinKey = Uint8List.fromList(anyRepeater.publicKey);
    twinKey[pubKeySize - 1] ^= 0xFF;
    final twin = Contact(
      publicKey: twinKey,
      name: 'TWIN-OF-${anyRepeater.name}',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.now(),
    );

    final identity = RepeaterIdentityHelper.resolve(
      contacts: [...c.allContacts, twin],
      hashPrefix: hash,
    );
    blog('hash ${hex(hash)} -> source=${identity.source.name} '
        '"${identity.displayName}"');

    expect(identity.source, RepeaterIdentitySource.ambiguousPrefix);
    expect(identity.contact, isNull);
    expect(identity.addressableKey, isNull,
        reason: 'an ambiguous hash must never yield a login target');
    expect(identity.candidates.length, greaterThanOrEqualTo(2));

    // Without the twin the same hash resolves cleanly, so the refusal above is
    // the ambiguity and not a broken matcher.
    final alone = RepeaterIdentityHelper.resolve(
      contacts: c.allContacts,
      hashPrefix: hash,
    );
    blog('without the twin: source=${alone.source.name} '
        '"${alone.displayName}"');
  });
}
