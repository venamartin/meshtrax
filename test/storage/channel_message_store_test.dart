import 'dart:convert';
import 'dart:typed_data';

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

  ChannelMessage msg(
    String text, {
    String? id,
    int? ts,
    String? hash,
    Uint8List? sender,
    bool outgoing = false,
  }) {
    return ChannelMessage(
      senderKey: sender,
      senderName: 'Tester',
      text: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts ?? 1753000000000),
      isOutgoing: outgoing,
      status: ChannelMessageStatus.sent,
      channelIndex: 2,
      messageId: id,
      packetHash: hash,
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

  // Ordering follows ARRIVAL, not the sender's claimed send time (v6). A mesh
  // node's clock can be hours out and cannot always be corrected, and ingest
  // rewrites implausible timestamps outright — so the sender's value is not
  // something a conversation can be ordered by. Here the message claiming to
  // be OLDER arrives second, and therefore displays second.
  test('messages load in arrival order, not sender-timestamp order', () async {
    await store.upsertMessage(idKeyA, msg('arrived first', id: 'x2', ts: 2000));
    await store.upsertMessage(idKeyA, msg('arrived second', id: 'x1', ts: 1000));

    final loaded = await store.loadChannelMessages(idKeyA);
    expect(loaded.map((m) => m.text), ['arrived first', 'arrived second']);
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

  // --- Phase 3d: watched queries and DB-authoritative ingest -------------

  test('watchChannelMessages: newest N, oldest-first, live-updating',
      () async {
    expect(await store.watchChannelMessages(idKeyA).first, isEmpty);
    await store.upsertMessage(idKeyA, msg('one', id: 'w1', ts: 1000));
    await store.upsertMessage(idKeyA, msg('two', id: 'w2', ts: 2000));
    await store.upsertMessage(idKeyA, msg('three', id: 'w3', ts: 3000));

    final view = await store.watchChannelMessages(idKeyA, limit: 2).first;
    expect(view.map((m) => m.text), ['two', 'three']);
  });

  test('insertIfNew is the dedup authority', () async {
    expect(await store.insertIfNew(idKeyA, msg('x', id: 'dup')), isTrue);
    expect(
        await store.insertIfNew(idKeyA, msg('x again', id: 'dup')), isFalse);
    expect((await store.loadChannelMessages(idKeyA)).single.text, 'x');
  });

  test('findByPacketHash resolves repeats via SQL', () async {
    await store.upsertMessage(idKeyA, msg('orig', id: 'p1', hash: 'cafe01'));
    expect((await store.findByPacketHash(idKeyA, 'cafe01'))?.text, 'orig');
    expect(await store.findByPacketHash(idKeyA, 'beef99'), isNull);
  });

  test('unread is a watched COUNT against the read mark', () async {
    await store.insertIfNew(idKeyA, msg('new stuff', id: 'u1', ts: 5000));
    expect(await store.watchUnreadCount(idKeyA).first, 1);

    await store.markRead(idKeyA);
    expect(await store.watchUnreadCount(idKeyA).first, 0);
  });

  test('own and outgoing messages never count as unread', () async {
    final selfSender =
        Uint8List.fromList([0xde, 0xad, 0xbe, 0xef, 0x00, 1, 2, 3]);
    await store.insertIfNew(
        idKeyA, msg('mine echoed', id: 'u2', sender: selfSender));
    await store.insertIfNew(idKeyA, msg('sent by me', id: 'u3', outgoing: true));
    expect(await store.watchUnreadCount(idKeyA).first, 0);
  });

  test('initializeReadMarkIfAbsent shields pre-existing history', () async {
    await store.upsertMessage(idKeyA, msg('old history', id: 'h1', ts: 7000));
    await store.initializeReadMarkIfAbsent(idKeyA);
    expect(await store.watchUnreadCount(idKeyA).first, 0);

    await store.insertIfNew(idKeyA, msg('fresh', id: 'h2', ts: 9000));
    expect(await store.watchUnreadCount(idKeyA).first, 1);
  });

  // --- v6: arrival time ---------------------------------------------------
  //
  // Conversations will be ordered by when this app first SAW a message, not by
  // the sender's claimed clock. The stamp is therefore written once and must
  // survive every later rewrite — upsertMessage uses InsertMode.insertOrReplace,
  // which SQLite implements as delete-then-insert, so anything derived from the
  // row id would move a message to the bottom of the chat on every status
  // change.

  Future<int?> arrivalOf(String idKey, String messageId) async {
    final db = AppDatabase.instance;
    final rows = await (db.select(db.channelMessageRows)).get();
    for (final row in rows) {
      if (row.channelIdKey == idKey && row.messageId == messageId) {
        return row.receivedAtUs;
      }
    }
    return null;
  }

  test('a first insert stamps arrival time', () async {
    await store.insertIfNew(idKeyA, msg('hello', id: 'a1'));
    expect(await arrivalOf(idKeyA, 'a1'), greaterThan(0));
  });

  test('arrival time survives a status update', () async {
    await store.insertIfNew(idKeyA, msg('pending', id: 'a2'));
    final first = await arrivalOf(idKeyA, 'a2');

    await store.updateMessage(
      idKeyA,
      'a2',
      (m) => m.copyWith(status: ChannelMessageStatus.delivered),
    );

    expect(await arrivalOf(idKeyA, 'a2'), first,
        reason: 'a delivery receipt must not move the message in the chat');
  });

  test('arrival time survives a batch upsert', () async {
    await store.insertIfNew(idKeyA, msg('one', id: 'b1'));
    await store.insertIfNew(idKeyA, msg('two', id: 'b2'));
    final before = [
      await arrivalOf(idKeyA, 'b1'),
      await arrivalOf(idKeyA, 'b2'),
    ];

    // The shape the reaction and repeat-merge paths use.
    await store.upsertMessages(idKeyA, [
      msg('one', id: 'b1'),
      msg('two', id: 'b2'),
    ]);

    expect(
      [await arrivalOf(idKeyA, 'b1'), await arrivalOf(idKeyA, 'b2')],
      before,
    );
  });

  test('messages arriving later get later stamps', () async {
    // Same sender timestamp on both: ordering must come from arrival, not the
    // sender's clock, which is the entire point of the column.
    await store.insertIfNew(idKeyA, msg('first', id: 'c1', ts: 5000));
    await store.insertIfNew(idKeyA, msg('second', id: 'c2', ts: 5000));

    expect(
      await arrivalOf(idKeyA, 'c2'),
      greaterThan((await arrivalOf(idKeyA, 'c1'))!),
    );
  });
}
