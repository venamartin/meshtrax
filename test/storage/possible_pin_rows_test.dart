import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/helpers/smaz.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The map reads only the rows SQL says could be pins (possiblePinRowSql).
// A pin the filter dropped would vanish from the map, so every shape the
// parser turns into a Location or SOS message must come back, plain and
// SMAZ-compressed, in the order a full load gives.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const graz = '47.070123, 15.440123';
  const pins = [
    'Location: $graz',
    'LOCATION: Picnic\n$graz',
    'POI: Pub | $graz\nnote',
    'SOS: help | $graz',
    'sos:$graz',
    'Location: https://www.google.com/maps/place/Hauptplatz/@47.0707,15.4395,17z',
    'Location: https://maps.google.com/?q=47.07,15.44',
    'SOS: stuck | geo:47,15',
    '@[Bob] Location: $graz',
    '@[Bob]\n>hi there..\nLocation: $graz',
    '@[Bob] re:hi there…Location: $graz',
    'm:47.070123,15.440123|Parking|poi',
    'm:47,15|x|poi',
    graz,
    'Hauptplatz\n$graz',
    'https://www.google.com/maps/place/Hauptplatz/@47.0707,15.4395,17z',
    'https://maps.google.com/?q=47.07,15.44',
    'geo:47,15',
    'GEO:47,15',
    'https://maps.app.goo.gl/AbCdEf',
    // Without a scheme ("https:" alone would pass as s:).
    'maps.google.com/?q=47.07,15.44',
    'Location: Pub | maps.apple.com/?ll=47.07,15.44',
    'goo.gl/maps/AbCdEf',
    'Treffpunkt 🍺\n$graz',
  ];
  const chatter = ['hello there', 'see you at 5', 'ok 👍', 'Event: 2026-10-18'];

  // Short links count as pins once resolved; the filter must not depend on
  // whether the resolver has answered yet.
  bool isPin(String text) => switch (StructuredMessage.parse(
    text,
    resolveShortLink: (_) => const LatLng(1, 1),
  )) {
    LocationMessage() || SosMessage() => true,
    _ => false,
  };

  String compressed(String text) =>
      's:${base64Encode(Smaz.compressBytes(Uint8List.fromList(utf8.encode(text))))}';

  // Each pin plain and compressed, between chatter, oldest first.
  final texts = [
    for (final (i, pin) in pins.indexed) ...[
      chatter[i % chatter.length],
      pin,
      compressed(pin),
    ],
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  test('the corpus is all pins, and compressed copies decode back', () {
    for (final pin in pins) {
      expect(isPin(pin), isTrue, reason: pin);
      expect(Smaz.tryDecodePrefixed(compressed(pin)), pin);
    }
    for (final text in chatter) {
      expect(isPin(text), isFalse, reason: text);
    }
  });

  test('DMs: every pin comes back, in loadMessages order', () async {
    final store = MessageStore()..setPublicKeyHex = 'deadbeef00cafe';
    const a = 'aa11aa11aa11aa11aa11aa11aa11aa11';
    const b = 'bb22bb22bb22bb22bb22bb22bb22bb22';
    Message msg(int i) => Message(
      senderKey: Uint8List.fromList(List.filled(32, 7)),
      text: texts[i],
      timestamp: DateTime.fromMillisecondsSinceEpoch(1753000000000 + i * 1000),
      isOutgoing: i.isEven,
      status: MessageStatus.sent,
      messageId: 'm$i',
    );
    // Interleaved across two contacts, so grouping is tested too.
    await store.saveMessages(a, [
      for (var i = 0; i < texts.length; i += 2) msg(i),
    ]);
    await store.saveMessages(b, [
      for (var i = 1; i < texts.length; i += 2) msg(i),
    ]);

    final candidates = await store.loadPossiblePinMessages([a, b]);
    for (final key in [a, b]) {
      final full = await store.loadMessages(key);
      final got = candidates[key] ?? const <Message>[];
      expect(
        got.where((m) => isPin(m.text)).map((m) => m.messageId).toList(),
        full.where((m) => isPin(m.text)).map((m) => m.messageId).toList(),
        reason: key,
      );
      expect(got.length, lessThan(full.length), reason: 'chatter is skipped');
    }
    expect(
      (await store.loadPossiblePinMessages([a])).keys,
      [a],
      reason: 'only the asked-for contacts',
    );
    expect(await store.loadPossiblePinMessages(const []), isEmpty);
  });

  test('channels: every pin comes back, in loadChannelMessages order', () async {
    final store = ChannelMessageStore()..setPublicKeyHex = 'deadbeef00cafe';
    const a = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const b = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    ChannelMessage msg(int i) => ChannelMessage(
      senderKey: null,
      senderName: 'Tester',
      text: texts[i],
      timestamp: DateTime.fromMillisecondsSinceEpoch(1753000000000 + i * 1000),
      isOutgoing: false,
      status: ChannelMessageStatus.sent,
      channelIndex: 2,
      messageId: 'c$i',
    );
    await store.saveChannelMessages(a, [
      for (var i = 0; i < texts.length; i += 2) msg(i),
    ]);
    await store.saveChannelMessages(b, [
      for (var i = 1; i < texts.length; i += 2) msg(i),
    ]);

    final candidates = await store.loadPossiblePinMessages([a, b]);
    for (final key in [a, b]) {
      final full = await store.loadChannelMessages(key);
      final got = candidates[key] ?? const <ChannelMessage>[];
      expect(
        got.where((m) => isPin(m.text)).map((m) => m.messageId).toList(),
        full.where((m) => isPin(m.text)).map((m) => m.messageId).toList(),
        reason: key,
      );
      expect(got.length, lessThan(full.length), reason: 'chatter is skipped');
    }
    expect(
      await store.loadPossiblePinMessages(const []),
      isEmpty,
      reason: 'no channels yet (just connected)',
    );
  });

  test('a legacy DM blob still imports on the pin path', () async {
    final store = MessageStore()..setPublicKeyHex = 'deadbeef00cafe';
    const key = 'cc33cc33cc33cc33cc33cc33cc33cc33';
    final legacyKey = '${store.keyFor}$key';
    await PrefsManager.instance.setString(
      legacyKey,
      jsonEncode([
        {
          'senderKey': base64Encode(List.filled(32, 7)),
          'text': 'Location: $graz',
          'timestamp': 1753000000000,
          'isOutgoing': false,
          'status': MessageStatus.sent.index,
          'messageId': 'legacy1',
        },
      ]),
    );

    final candidates = await store.loadPossiblePinMessages([key]);
    expect(candidates[key]!.single.messageId, 'legacy1');
    expect(PrefsManager.instance.containsKey(legacyKey), isFalse);
  });
}
