import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A watched chat re-runs its query on every write to the table, any chat's.
// A row whose payload did not change comes back as the same decoded object,
// and a window that did not change is not passed on (channels here, DMs in
// the connector, after a room's re-order), so the screen has nothing to
// rebuild (owner, 2026-10-26: glitches scrolling).

/// A stream's emissions as they arrive.
class _Watch<T> {
  _Watch(Stream<T> stream) {
    _sub = stream.listen((event) {
      seen.add(event);
      _arrived?.complete();
      _arrived = null;
    });
  }

  final seen = <T>[];
  late final StreamSubscription<T> _sub;
  Completer<void>? _arrived;

  Future<T> nth(int n) async {
    while (seen.length <= n) {
      _arrived = Completer<void>();
      await _arrived!.future.timeout(const Duration(seconds: 5));
    }
    return seen[n];
  }

  Future<void> cancel() => _sub.cancel();
}

// Long enough for the re-run query of an unrelated write to have landed.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 200));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  group('contact messages', () {
    const chatA = 'aa11aa11aa11aa11aa11aa11aa11aa11';
    const chatB = 'bb22bb22bb22bb22bb22bb22bb22bb22';
    late MessageStore store;

    Message dm(String text, String id) => Message(
          senderKey: Uint8List.fromList(List.filled(32, 7)),
          text: text,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1753000000000),
          isOutgoing: false,
          status: MessageStatus.sent,
          messageId: id,
        );

    setUp(() async {
      store = MessageStore()..setPublicKeyHex = 'deadbeef00cafe';
      await store.upsertMessage(chatA, dm('one', 'a1'));
      await store.upsertMessage(chatA, dm('two', 'a2'));
    });

    test('another chat\'s write brings the same rows; a changed row is new',
        () async {
      final watch = _Watch(store.watchConversation(chatA));
      final first = await watch.nth(0);
      expect(first.map((m) => m.text), ['one', 'two']);

      // Passed on here: a room's order can change with no row (the
      // connector drops what did not change, after re-ordering).
      await store.upsertMessage(chatB, dm('elsewhere', 'b1'));
      final again = await watch.nth(1);
      expect(MessageStore.sameMessages(again, first), isTrue);

      await store.updatePayload(
          chatA, 'a2', (m) => m.copyWith(status: MessageStatus.delivered));
      final second = await watch.nth(2);
      expect(second[0], same(first[0]));
      expect(second[1], isNot(same(first[1])));
      expect(second[1].status, MessageStatus.delivered);
      await watch.cancel();
    });

    test('a bigger window reuses the rows it already decoded', () async {
      final small = await store.watchConversation(chatA, limit: 1).first;
      final big = await store.watchConversation(chatA, limit: 2).first;
      expect(big.map((m) => m.text), ['one', 'two']);
      expect(big.last, same(small.single));
    });
  });

  group('channel messages', () {
    const idKeyA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const idKeyB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    late ChannelMessageStore store;

    ChannelMessage post(String text, String id) => ChannelMessage(
          senderKey: null,
          senderName: 'Tester',
          text: text,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1753000000000),
          isOutgoing: false,
          status: ChannelMessageStatus.sent,
          channelIndex: 2,
          messageId: id,
        );

    setUp(() async {
      store = ChannelMessageStore()..setPublicKeyHex = 'deadbeef00cafe';
      await store.upsertMessage(idKeyA, post('one', 'c1'));
      await store.upsertMessage(idKeyA, post('two', 'c2'));
    });

    test('another channel\'s write is not passed on; a changed row is new',
        () async {
      final watch = _Watch(store.watchChannelMessages(idKeyA));
      final first = await watch.nth(0);
      expect(first.map((m) => m.text), ['one', 'two']);

      await store.upsertMessage(idKeyB, post('elsewhere', 'd1'));
      await _settle();
      expect(watch.seen, hasLength(1));

      await store.updatePayload(idKeyA, 'c2',
          (m) => m.copyWith(status: ChannelMessageStatus.delivered));
      final second = await watch.nth(1);
      expect(second[0], same(first[0]));
      expect(second[1], isNot(same(first[1])));
      expect(second[1].status, ChannelMessageStatus.delivered);
      await watch.cancel();
    });

    test('a bigger window reuses the rows it already decoded', () async {
      final small = await store.watchChannelMessages(idKeyA, limit: 1).first;
      final big = await store.watchChannelMessages(idKeyA, limit: 2).first;
      expect(big.map((m) => m.text), ['one', 'two']);
      expect(big.last, same(small.single));
    });
  });

  test('the same messages in the same order are the same list', () {
    final a = Object(), b = Object();
    expect(MessageStore.sameMessages([a, b], [a, b]), isTrue);
    expect(MessageStore.sameMessages([a, b], [b, a]), isFalse);
    expect(MessageStore.sameMessages([a], [a, b]), isFalse);
    expect(MessageStore.sameMessages([Object()], [Object()]), isFalse,
        reason: 'a newly decoded row is a change');
  });
}
