import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/arrival_clock.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A message the radio held past a failed queue read keeps the time its
// sender claimed, for "sent 14:00 by its clock". The line must survive the
// database: a reopened chat, a status change, a reaction.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const scope = 'deadbeef00cafe';
  const channel = 'c0ffee';
  const contact = 'aa11aa11aa11aa11aa11aa11aa11aa11';
  final shown = DateTime(2026, 11, 16, 16, 30);
  final claim = DateTime(2026, 11, 16, 14);

  late ChannelMessageStore channels;
  late MessageStore dms;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    channels = ChannelMessageStore()..setPublicKeyHex = scope;
    dms = MessageStore()..setPublicKeyHex = scope;
  });

  ChannelMessage post(String text, {DateTime? at, DateTime? claimedAt}) =>
      ChannelMessage(
        senderName: 'Bob',
        text: text,
        timestamp: at ?? shown,
        isOutgoing: false,
        status: ChannelMessageStatus.sent,
        channelIndex: 1,
        claimedAt: claimedAt,
      );

  Message dm(String text, {DateTime? claimedAt}) => Message(
    senderKey: Uint8List.fromList(List.filled(32, 7)),
    text: text,
    timestamp: claim,
    isOutgoing: false,
    status: MessageStatus.sent,
    claimedAt: claimedAt,
  );

  Future<String> payload(String messageId) async {
    final row = await (AppDatabase.instance.select(
      AppDatabase.instance.channelMessageRows,
    )..where((r) => r.messageId.equals(messageId))).getSingle();
    return row.payload;
  }

  group('channel rows', () {
    test('keep the claimed time through a reload, a status change and a '
        'reaction', () async {
      final m = post('Water at the spring', claimedAt: claim);
      await channels.insertIfNew(channel, m);
      expect(
        (await channels.loadChannelMessages(channel)).single.claimedAt,
        claim,
      );
      expect(
        (await channels.watchChannelMessages(channel).first).single.claimedAt,
        claim,
      );

      await channels.updateMessage(
        channel,
        m.messageId,
        (r) => r.copyWith(repeatCount: r.repeatCount + 1),
      );
      await channels.updatePayload(
        channel,
        m.messageId,
        (r) => r.copyWith(reactions: {'👍': 1}),
      );
      final row = (await channels.loadChannelMessages(channel)).single;
      expect(row.repeatCount, 1);
      expect(row.reactions, {'👍': 1});
      expect(row.claimedAt, claim);
      expect(row.timestamp, shown, reason: 'the shown time is unchanged');
    });

    test('without one, the row reads as before', () async {
      final m = post('Leaving camp');
      await channels.insertIfNew(channel, m);
      expect(
        (await channels.loadChannelMessages(channel)).single.claimedAt,
        isNull,
      );
      expect(
        (jsonDecode(await payload(m.messageId)) as Map).containsKey(
          'claimedAt',
        ),
        isFalse,
        reason: 'the payload is the one rows had before',
      );
    });

    test('a row written before the field existed reads without one', () async {
      final m = post('Old row');
      await channels.insertIfNew(channel, m);
      final json = jsonDecode(await payload(m.messageId)) as Map;
      json.remove('claimedAt');
      await (AppDatabase.instance.update(
        AppDatabase.instance.channelMessageRows,
      )..where((r) => r.messageId.equals(m.messageId))).write(
        ChannelMessageRowsCompanion(payload: Value(jsonEncode(json))),
      );
      expect(
        (await channels.loadChannelMessages(channel)).single.claimedAt,
        isNull,
      );
    });

    test(
      'newestShownTimeArrivedBefore: the newest message held at a moment',
      () async {
        await channels.insertIfNew(
          channel,
          post('a', at: DateTime(2026, 11, 15, 9)),
        );
        await channels.insertIfNew(
          channel,
          post('b', at: DateTime(2026, 11, 15, 8)),
        );
        await channels.insertIfNew(
          'other',
          post('c', at: DateTime(2026, 11, 15, 12)),
        );
        final stamp = ArrivalClock.next();
        await channels.insertIfNew(
          channel,
          post('d', at: DateTime(2026, 11, 16)),
        );

        expect(
          await channels.newestShownTimeArrivedBefore(channel, stamp),
          DateTime(2026, 11, 15, 9),
          reason: 'the latest shown time, of this channel, from before it',
        );
        expect(
          await channels.newestShownTimeArrivedBefore('empty', stamp),
          isNull,
        );
      },
    );
  });

  group('DM rows', () {
    test(
      'keep the claimed time through a reload and a status change',
      () async {
        final m = dm('Running low on water', claimedAt: claim);
        await dms.insertIfNew(contact, m);
        expect((await dms.loadMessages(contact)).single.claimedAt, claim);
        await dms.updateMessage(
          contact,
          m.messageId,
          (r) => r.copyWith(status: MessageStatus.delivered),
        );
        await dms.updatePayload(
          contact,
          m.messageId,
          (r) => r.copyWith(reactions: {'👍': 1}),
        );
        final row = (await dms.loadMessages(contact)).single;
        expect(row.status, MessageStatus.delivered);
        expect(row.reactions, {'👍': 1});
        expect(row.claimedAt, claim);
      },
    );

    test('without one, the row reads as before', () async {
      await dms.insertIfNew(contact, dm('Morning'));
      expect((await dms.loadMessages(contact)).single.claimedAt, isNull);
      final row = await AppDatabase.instance
          .select(AppDatabase.instance.contactMessageRows)
          .getSingle();
      expect(
        (jsonDecode(row.payload) as Map).containsKey('claimedAt'),
        isFalse,
      );
    });
  });
}
