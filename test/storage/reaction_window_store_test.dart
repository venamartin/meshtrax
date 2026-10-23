import 'dart:typed_data';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Reactions and replies search only recent arrivals and write back only
// their target: the window must be exactly the tail of the full history,
// and the write must leave every other column and row as ingest set them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const scope = 'deadbeef00cafe';
  const channelA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const channelB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  const contactA = 'aa11aa11aa11aa11aa11aa11aa11aa11';
  const contactB = 'bb22bb22bb22bb22bb22bb22bb22bb22';
  const day = Duration.microsecondsPerDay;
  final base = DateTime.utc(2026, 10, 1).microsecondsSinceEpoch;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  Future<void> setArrival(String table, String messageId, int us) =>
      AppDatabase.instance.customStatement(
        'UPDATE $table SET received_at_us = ? WHERE message_id = ?',
        [us, messageId],
      );

  Future<List<Map<String, Object?>>> rawRows(String table) async {
    final rows = await AppDatabase.instance
        .customSelect(
          'SELECT id, message_id, received_at_us, unread_eligible, payload '
          'FROM $table ORDER BY id',
        )
        .get();
    return [for (final r in rows) r.data];
  }

  group('channels', () {
    late ChannelMessageStore store;
    setUp(() => store = ChannelMessageStore()..setPublicKeyHex = scope);

    ChannelMessage msg(String id, {String text = 'hi'}) => ChannelMessage(
      senderName: 'Tester',
      text: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1753000000000),
      isOutgoing: false,
      status: ChannelMessageStatus.sent,
      channelIndex: 1,
      messageId: id,
    );

    test('arrived-since is the tail of the full history', () async {
      // Arrival order differs from insert order, and two rows tie.
      const arrivals = {'m1': 0, 'm2': 3, 'm3': 1, 'm4': 2, 'm5': 2, 'm6': 4};
      for (final id in arrivals.keys) {
        await store.insertIfNew(channelA, msg(id));
        await setArrival(
          'channel_message_rows',
          id,
          base + arrivals[id]! * day,
        );
      }
      await store.insertIfNew(channelB, msg('other'));
      await setArrival('channel_message_rows', 'other', base + 4 * day);

      final full = [
        for (final m in await store.loadChannelMessages(channelA)) m.messageId,
      ];
      expect(full, ['m1', 'm3', 'm4', 'm5', 'm2', 'm6']);
      for (var d = 0; d <= 5; d++) {
        final since = DateTime.fromMicrosecondsSinceEpoch(base + d * day);
        final window = [
          for (final m in await store.loadChannelMessagesArrivedSince(
            channelA,
            since,
          ))
            m.messageId,
        ];
        expect(
          window,
          full.sublist(full.length - window.length),
          reason: 'cutoff day $d',
        );
        expect(
          window.length,
          arrivals.values.where((a) => a >= d).length,
          reason: 'cutoff day $d',
        );
      }
    });

    test('updatePayload writes one payload and nothing else', () async {
      await store.insertIfNew(channelA, msg('t1'));
      await store.insertIfNew(channelA, msg('t2'), unreadEligible: false);
      await store.insertIfNew(channelA, msg('t3'));
      final before = await rawRows('channel_message_rows');

      final wrote = await store.updatePayload(
        channelA,
        't2',
        (m) => m.copyWith(
          reactions: {'👍': 1},
          reactionSenders: {
            '👍': ['Bob'],
          },
        ),
      );
      expect(wrote, isTrue);
      final after = await rawRows('channel_message_rows');
      expect(after.length, before.length);
      for (var i = 0; i < before.length; i++) {
        final changed = before[i]['message_id'] == 't2';
        for (final column in ['id', 'message_id', 'received_at_us', 'unread_eligible']) {
          expect(after[i][column], before[i][column], reason: '$column of row $i');
        }
        expect(
          after[i]['payload'] == before[i]['payload'],
          !changed,
          reason: 'payload of row $i',
        );
      }
      final target = await store.findByMessageId(channelA, 't2');
      expect(target!.reactions, {'👍': 1});
      expect(target.reactionSenders, {
        '👍': ['Bob'],
      });

      expect(await store.updatePayload(channelA, 't2', (_) => null), isFalse);
      expect(await store.updatePayload(channelA, 'nope', (m) => m), isFalse);
      expect(await rawRows('channel_message_rows'), after);
    });

    test('updatePayload merges into the row as stored', () async {
      await store.insertIfNew(channelA, msg('t1'));
      await store.updatePayload(
        channelA,
        't1',
        (m) => m.copyWith(reactions: {'👍': 1}),
      );
      // A second writer that never saw the first reaction still keeps it.
      await store.updatePayload(
        channelA,
        't1',
        (m) => m.copyWith(reactions: {...m.reactions, '❤️': 1}),
      );
      expect((await store.findByMessageId(channelA, 't1'))!.reactions, {
        '👍': 1,
        '❤️': 1,
      });
    });

    test('a watched chat sees the reaction', () async {
      await store.insertIfNew(channelA, msg('t1'));
      final seen = store
          .watchChannelMessages(channelA, limit: 50)
          .map((rows) => rows.single.reactions)
          .firstWhere((r) => r.isNotEmpty);
      await store.updatePayload(
        channelA,
        't1',
        (m) => m.copyWith(reactions: {'👍': 1}),
      );
      expect(await seen, {'👍': 1});
    });
  });

  group('DMs and rooms', () {
    late MessageStore store;
    setUp(() => store = MessageStore()..setPublicKeyHex = scope);

    Message msg(String id) => Message(
      senderKey: Uint8List.fromList(List.filled(32, 7)),
      text: 'hi',
      timestamp: DateTime.fromMillisecondsSinceEpoch(1753000000000),
      isOutgoing: false,
      status: MessageStatus.delivered,
      messageId: id,
    );

    test('arrived-since is the tail of the full history', () async {
      const arrivals = {'d1': 0, 'd2': 2, 'd3': 1, 'd4': 2};
      for (final id in arrivals.keys) {
        await store.insertIfNew(contactA, msg(id));
        await setArrival(
          'contact_message_rows',
          id,
          base + arrivals[id]! * day,
        );
      }
      await store.insertIfNew(contactB, msg('other'));

      final full = [
        for (final m in await store.loadMessages(contactA)) m.messageId,
      ];
      for (var d = 0; d <= 3; d++) {
        final window = [
          for (final m in await store.loadMessagesArrivedSince(
            contactA,
            DateTime.fromMicrosecondsSinceEpoch(base + d * day),
          ))
            m.messageId,
        ];
        expect(window, full.sublist(full.length - window.length));
        expect(window.length, arrivals.values.where((a) => a >= d).length);
      }
    });

    test('updatePayload writes one payload and nothing else', () async {
      await store.insertIfNew(contactA, msg('t1'));
      await store.insertIfNew(contactA, msg('t2'), unreadEligible: false);
      await store.insertIfNew(contactA, msg('t3'));
      final before = await rawRows('contact_message_rows');

      expect(
        await store.updatePayload(
          contactA,
          't2',
          (m) => m.copyWith(
            reactionStatuses: {'👍': MessageStatus.pending},
          ),
        ),
        isTrue,
      );
      final after = await rawRows('contact_message_rows');
      for (var i = 0; i < before.length; i++) {
        final changed = before[i]['message_id'] == 't2';
        for (final column in ['id', 'message_id', 'received_at_us', 'unread_eligible']) {
          expect(after[i][column], before[i][column], reason: '$column of row $i');
        }
        expect(after[i]['payload'] == before[i]['payload'], !changed);
      }
      expect(
        (await store.findByMessageId(contactA, 't2'))!.reactionStatuses,
        {'👍': MessageStatus.pending},
      );
      expect(await store.updatePayload(contactA, 't2', (_) => null), isFalse);
    });
  });

  test('a fresh database has both arrival indexes', () async {
    final names = await AppDatabase.instance
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name = ? "
          'OR name = ?',
          variables: [
            Variable.withString('idx_channel_arrival'),
            Variable.withString('idx_contact_arrival'),
          ],
        )
        .map((r) => r.read<String>('name'))
        .get();
    expect(names.toSet(), {'idx_channel_arrival', 'idx_contact_arrival'});
  });
}
