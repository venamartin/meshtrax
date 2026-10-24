import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Contact (DM) messages follow the same storage contract as channel
// messages: one row per message, keyed by the contact's pubkey, unique per
// (nodeScope, contactKey, messageId). Legacy JSON blobs import once.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const contactA = 'aa11aa11aa11aa11aa11aa11aa11aa11';
  const contactB = 'bb22bb22bb22bb22bb22bb22bb22bb22';

  Message msg(String text, {String? id, int? ts, bool outgoing = false}) {
    return Message(
      senderKey: Uint8List.fromList(List.filled(32, 7)),
      text: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts ?? 1753000000000),
      isOutgoing: outgoing,
      status: MessageStatus.sent,
      messageId: id,
    );
  }

  String legacyBlob(List<Message> messages) {
    return jsonEncode([
      for (final m in messages)
        {
          'senderKey': base64Encode(m.senderKey),
          'text': m.text,
          'timestamp': m.timestamp.millisecondsSinceEpoch,
          'isOutgoing': m.isOutgoing,
          'status': m.status.index,
          'messageId': m.messageId,
        },
    ]);
  }

  late MessageStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    store = MessageStore();
    store.setPublicKeyHex = 'deadbeef00cafe';
  });

  test('keeps a message route width; null when it was never recorded', () async {
    await store.saveMessages(contactA, [
      msg('routed', id: 'r1').copyWith(
        pathBytes: Uint8List.fromList([0xA2, 0x77, 0xBE, 0xEF]),
        pathLength: 2,
        pathHashSize: 2,
      ),
      msg('old', id: 'o1'),
    ]);

    final byId = {
      for (final m in await store.loadMessages(contactA)) m.messageId: m,
    };
    expect(byId['r1']!.pathHashSize, 2);
    expect(byId['r1']!.pathLength, 2);
    expect(byId['o1']!.pathHashSize, isNull);
  });

  test('a legacy row holding the raw path_len byte decodes to hops', () async {
    await store.saveMessages(contactA, [msg('old', id: 'o1')]);
    await AppDatabase.instance.customStatement(
      "UPDATE contact_message_rows SET payload = json_set(payload, '\$.pathLength', 66)",
    );

    final loaded = (await store.loadMessages(contactA)).single;
    expect(loaded.pathLength, 2); // 0x42 = 2 hops at 2 bytes
    expect(loaded.pathHashSize, isNull);
  });

  test('conversations are isolated per contact', () async {
    await store.saveMessages(contactA, [msg('hello A')]);

    expect(
      (await store.loadMessages(contactA)).map((m) => m.text),
      ['hello A'],
    );
    expect(await store.loadMessages(contactB), isEmpty);
  });

  test('upserting the same messageId twice yields one row', () async {
    await store.upsertMessage(contactA, msg('first', id: 'fixed-id'));
    await store.upsertMessage(contactA, msg('edited', id: 'fixed-id'));

    final loaded = await store.loadMessages(contactA);
    expect(loaded, hasLength(1));
    expect(loaded.single.text, 'edited');
  });

  // Arrival order, not the sender's claimed send time (v6) — see the channel
  // store's equivalent. The message claiming to be OLDER arrives second, and
  // therefore displays second.
  test('messages load in arrival order, not sender-timestamp order', () async {
    await store.upsertMessage(contactA, msg('arrived first', id: 'x2', ts: 2000));
    await store.upsertMessage(contactA, msg('arrived second', id: 'x1', ts: 1000));

    expect(
      (await store.loadMessages(contactA)).map((m) => m.text),
      ['arrived first', 'arrived second'],
    );
  });

  test('legacy scoped blob imports once and the key is removed', () async {
    final prefs = PrefsManager.instance;
    await prefs.setString('${store.keyFor}$contactA', legacyBlob([msg('old')]));

    final migrated = await store.loadMessages(contactA);
    expect(migrated.map((m) => m.text), ['old']);
    expect(prefs.getString('${store.keyFor}$contactA'), isNull);
  });

  test('legacy unscoped blob imports too', () async {
    final prefs = PrefsManager.instance;
    await prefs.setString('messages_$contactA', legacyBlob([msg('ancient')]));

    expect(
      (await store.loadMessages(contactA)).map((m) => m.text),
      ['ancient'],
    );
    expect(prefs.getString('messages_$contactA'), isNull);
  });

  test('legacy import never overwrites existing rows', () async {
    await store.upsertMessage(contactA, msg('db wins', id: 'same-id'));
    final prefs = PrefsManager.instance;
    await prefs.setString(
      '${store.keyFor}$contactA',
      legacyBlob([msg('imposter', id: 'same-id')]),
    );

    final kept = await store.loadMessages(contactA);
    expect(kept.single.text, 'db wins');
  });

  test('clearing one conversation leaves others untouched', () async {
    await store.saveMessages(contactA, [msg('keep me')]);
    await store.saveMessages(contactB, [msg('delete me')]);

    await store.clearMessages(contactB);

    expect(await store.loadMessages(contactA), isNotEmpty);
    expect(await store.loadMessages(contactB), isEmpty);
  });

  test('node scopes are isolated', () async {
    await store.saveMessages(contactA, [msg('node one')]);

    final other = MessageStore();
    other.setPublicKeyHex = 'feedface99beef';
    expect(await other.loadMessages(contactA), isEmpty);
    expect(await store.loadMessages(contactA), isNotEmpty);
  });

  test('upsertMessages can NEVER shrink a conversation', () async {
    for (var i = 0; i < 5; i++) {
      await store.upsertMessage(contactA, msg('old $i', id: 'o$i', ts: 1000 + i));
    }
    await store.upsertMessages(contactA, [msg('new', id: 'n1', ts: 9000)]);

    expect(await store.loadMessages(contactA), hasLength(6));
  });

  // A DM whose app was killed mid-ladder is saved as pending or sent and
  // nothing would ever settle it: the clock icon forever (dm-stuck, 2026-10-23).
  group('failPendingSendsBefore', () {
    const cutoffMs = 1753000500000;
    final cutoff = DateTime.fromMillisecondsSinceEpoch(cutoffMs);

    Message inFlight(String id, MessageStatus status,
            {int ts = 1753000000000, bool cli = false}) =>
        Message(
          senderKey: Uint8List.fromList(List.filled(32, 7)),
          text: 'hi',
          timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
          isOutgoing: true,
          isCli: cli,
          status: status,
          messageId: id,
          waitingForRepeater: status == MessageStatus.sent,
        );

    Future<Message?> rowOf(String contact, String id) =>
        store.findByMessageId(contact, id);

    test('fails own pending and sent DMs from before the cutoff', () async {
      await store.upsertMessage(contactA, inFlight('p', MessageStatus.pending));
      await store.upsertMessage(contactB, inFlight('s', MessageStatus.sent));

      expect(await store.failPendingSendsBefore(cutoff), 2);
      expect((await rowOf(contactA, 'p'))!.status, MessageStatus.failed);
      final s = (await rowOf(contactB, 's'))!;
      expect(s.status, MessageStatus.failed);
      expect(s.waitingForRepeater, isFalse);
    });

    test('leaves this run, settled rows, incoming rows and CLI alone',
        () async {
      await store.upsertMessage(
          contactA, inFlight('live', MessageStatus.pending, ts: cutoffMs + 1));
      await store.upsertMessage(contactA,
          msg('done', id: 'done', outgoing: true)
              .copyWith(status: MessageStatus.delivered));
      await store.upsertMessage(contactA,
          msg('theirs', id: 'in').copyWith(status: MessageStatus.pending));
      await store.upsertMessage(
          contactA, inFlight('cli', MessageStatus.sent, cli: true));

      expect(await store.failPendingSendsBefore(cutoff), 0);
      expect((await rowOf(contactA, 'live'))!.status, MessageStatus.pending);
      expect((await rowOf(contactA, 'done'))!.status, MessageStatus.delivered);
      expect((await rowOf(contactA, 'in'))!.status, MessageStatus.pending);
      expect((await rowOf(contactA, 'cli'))!.status, MessageStatus.sent);
    });

    test('only touches the scoped node', () async {
      store.setPublicKeyHex = '0123456789ab';
      await store.upsertMessage(contactA, inFlight('other', MessageStatus.sent));
      store.setPublicKeyHex = 'deadbeef00cafe';

      expect(await store.failPendingSendsBefore(cutoff), 0);
      store.setPublicKeyHex = '0123456789ab';
      expect((await rowOf(contactA, 'other'))!.status, MessageStatus.sent);
    });
  });

  test('deleteMessage removes exactly one row', () async {
    await store.upsertMessage(contactA, msg('keep', id: 'k1'));
    await store.upsertMessage(contactA, msg('gone', id: 'g1'));

    await store.deleteMessage(contactA, 'g1');

    expect((await store.loadMessages(contactA)).map((m) => m.text), ['keep']);
  });
}
