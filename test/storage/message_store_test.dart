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

  test('messages load ordered by timestamp', () async {
    await store.upsertMessage(contactA, msg('late', id: 'x2', ts: 2000));
    await store.upsertMessage(contactA, msg('early', id: 'x1', ts: 1000));

    expect(
      (await store.loadMessages(contactA)).map((m) => m.text),
      ['early', 'late'],
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

  test('deleteMessage removes exactly one row', () async {
    await store.upsertMessage(contactA, msg('keep', id: 'k1'));
    await store.upsertMessage(contactA, msg('gone', id: 'g1'));

    await store.deleteMessage(contactA, 'g1');

    expect((await store.loadMessages(contactA)).map((m) => m.text), ['keep']);
  });
}
