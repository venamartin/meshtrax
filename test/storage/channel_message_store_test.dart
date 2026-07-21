import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Channel messages are stored by channel IDENTITY (the PSK), never by radio
// slot index. Filing by index let a message land in whatever channel later
// occupied the slot — the cross-channel contamination bug.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const idKeyA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const idKeyB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  ChannelMessage msg(String text, {int channelIndex = 2}) {
    return ChannelMessage(
      senderKey: null,
      senderName: 'Tester',
      text: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1752854400000),
      isOutgoing: false,
      status: ChannelMessageStatus.sent,
      channelIndex: channelIndex,
    );
  }

  late ChannelMessageStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    store = ChannelMessageStore();
    store.setPublicKeyHex = 'deadbeef00cafe';
  });

  test('messages saved under one identity are invisible to another', () async {
    await store.saveChannelMessages(idKeyA, [msg('hello A')]);

    final a = await store.loadChannelMessages(idKeyA);
    final b = await store.loadChannelMessages(idKeyB);

    expect(a.map((m) => m.text), ['hello A']);
    expect(b, isEmpty);
  });

  test('legacy index bucket migrates into the identity bucket once', () async {
    // Simulate a pre-identity store: messages persisted under slot index 2.
    final prefs = PrefsManager.instance;
    await store.saveChannelMessages(idKeyA, [msg('seed')]);
    final legacyJson = prefs.getString('${store.keyFor}id_$idKeyA')!;
    await prefs.remove('${store.keyFor}id_$idKeyA');
    await prefs.setString('${store.keyFor}2', legacyJson);

    await store.migrateLegacyIndexKey(2, idKeyA);

    final migrated = await store.loadChannelMessages(idKeyA);
    expect(migrated.map((m) => m.text), ['seed']);
    // Legacy key is gone — a future channel in slot 2 must not inherit it.
    expect(prefs.getString('${store.keyFor}2'), isNull);
  });

  test('migration never overwrites an existing identity bucket', () async {
    final prefs = PrefsManager.instance;
    await store.saveChannelMessages(idKeyA, [msg('identity wins')]);
    await store.saveChannelMessages(idKeyB, [msg('imposter')]);
    final imposterJson = prefs.getString('${store.keyFor}id_$idKeyB')!;
    await prefs.setString('${store.keyFor}2', imposterJson);

    await store.migrateLegacyIndexKey(2, idKeyA);

    final kept = await store.loadChannelMessages(idKeyA);
    expect(kept.map((m) => m.text), ['identity wins']);
    expect(prefs.getString('${store.keyFor}2'), isNull);
  });

  test('clearing one identity leaves others untouched', () async {
    await store.saveChannelMessages(idKeyA, [msg('keep me')]);
    await store.saveChannelMessages(idKeyB, [msg('delete me')]);

    await store.clearChannelMessages(idKeyB);

    expect(await store.loadChannelMessages(idKeyA), isNotEmpty);
    expect(await store.loadChannelMessages(idKeyB), isEmpty);
  });
}
