import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Channel messages are stored one row per message, keyed by channel IDENTITY
// (the PSK) with a UNIQUE(nodeScope, idKey, messageId) constraint. Slot
// indexes never key storage; legacy JSON blobs import once and are removed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const idKeyA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const idKeyB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  ChannelMessage msg(String text, {String? id, int? ts}) {
    return ChannelMessage(
      senderKey: null,
      senderName: 'Tester',
      text: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts ?? 1753000000000),
      isOutgoing: false,
      status: ChannelMessageStatus.sent,
      channelIndex: 2,
      messageId: id,
    );
  }

  String legacyBlob(List<ChannelMessage> messages) {
    return jsonEncode([
      for (final m in messages)
        {
          'senderName': m.senderName,
          'text': m.text,
          'timestamp': m.timestamp.millisecondsSinceEpoch,
          'isOutgoing': m.isOutgoing,
          'status': m.status.index,
          'messageId': m.messageId,
        },
    ]);
  }

  late ChannelMessageStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
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

  test('upserting the same messageId twice yields one row', () async {
    final original = msg('first', id: 'fixed-id');
    await store.upsertMessage(idKeyA, original);
    await store.upsertMessage(idKeyA, msg('edited', id: 'fixed-id'));

    final loaded = await store.loadChannelMessages(idKeyA);
    expect(loaded, hasLength(1));
    expect(loaded.single.text, 'edited');
  });

  test('messages load ordered by timestamp', () async {
    await store.upsertMessage(idKeyA, msg('late', id: 'x2', ts: 2000));
    await store.upsertMessage(idKeyA, msg('early', id: 'x1', ts: 1000));

    final loaded = await store.loadChannelMessages(idKeyA);
    expect(loaded.map((m) => m.text), ['early', 'late']);
  });

  test('legacy index blob imports into identity rows once', () async {
    final prefs = PrefsManager.instance;
    await prefs.setString('${store.keyFor}2', legacyBlob([msg('seed')]));

    await store.migrateLegacyIndexKey(2, idKeyA);

    final migrated = await store.loadChannelMessages(idKeyA);
    expect(migrated.map((m) => m.text), ['seed']);
    expect(prefs.getString('${store.keyFor}2'), isNull);
  });

  test('legacy import never overwrites existing rows', () async {
    final keeper = msg('identity wins', id: 'same-id');
    await store.upsertMessage(idKeyA, keeper);
    final prefs = PrefsManager.instance;
    await prefs.setString(
      '${store.keyFor}2',
      legacyBlob([msg('imposter', id: 'same-id')]),
    );

    await store.migrateLegacyIndexKey(2, idKeyA);

    final kept = await store.loadChannelMessages(idKeyA);
    expect(kept.single.text, 'identity wins');
  });

  test('identity JSON blob from previous store imports on load', () async {
    final prefs = PrefsManager.instance;
    await prefs.setString(
      '${store.keyFor}id_$idKeyA',
      legacyBlob([msg('from blob')]),
    );

    final loaded = await store.loadChannelMessages(idKeyA);
    expect(loaded.map((m) => m.text), ['from blob']);
    expect(prefs.getString('${store.keyFor}id_$idKeyA'), isNull);
  });

  test('clearing one identity leaves others untouched', () async {
    await store.saveChannelMessages(idKeyA, [msg('keep me')]);
    await store.saveChannelMessages(idKeyB, [msg('delete me')]);

    await store.clearChannelMessages(idKeyB);

    expect(await store.loadChannelMessages(idKeyA), isNotEmpty);
    expect(await store.loadChannelMessages(idKeyB), isEmpty);
  });

  test('node scopes are isolated', () async {
    await store.saveChannelMessages(idKeyA, [msg('node one')]);

    final other = ChannelMessageStore();
    other.setPublicKeyHex = 'feedface99beef';
    expect(await other.loadChannelMessages(idKeyA), isEmpty);
    expect(await store.loadChannelMessages(idKeyA), isNotEmpty);
  });

  test('upsertMessages can NEVER shrink history (stale window persist)',
      () async {
    for (var i = 0; i < 5; i++) {
      await store.upsertMessage(idKeyA, msg('old $i', id: 'o$i', ts: 1000 + i));
    }
    // A stale/windowed in-memory list persisting must only refresh its own
    // rows — the truncation class behind Public reverting to old snapshots.
    await store.upsertMessages(idKeyA, [msg('new', id: 'n1', ts: 9000)]);

    final loaded = await store.loadChannelMessages(idKeyA);
    expect(loaded, hasLength(6));
  });

  test('deleteMessage removes exactly one row', () async {
    await store.upsertMessage(idKeyA, msg('keep', id: 'k1'));
    await store.upsertMessage(idKeyA, msg('gone', id: 'g1'));

    await store.deleteMessage(idKeyA, 'g1');

    final loaded = await store.loadChannelMessages(idKeyA);
    expect(loaded.map((m) => m.text), ['keep']);
  });
}
