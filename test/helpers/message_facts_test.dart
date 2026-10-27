import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/message_facts.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/services/short_link_resolver.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A row is built again every time it scrolls into view; what its text says
// is worked out once per text (owner, 2026-10-26: glitches scrolling).
// A short link the resolver already answered, from an earlier run.
const _resolvedLink = 'https://maps.app.goo.gl/Resolved1';

String _stamp(DateTime t) =>
    '${t.year}-${_two(t.month)}-${_two(t.day)} ${_two(t.hour)}:${_two(t.minute)}';
String _two(int n) => n.toString().padLeft(2, '0');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'short_link_cache': jsonEncode({_resolvedLink: '47.0707,15.4395'}),
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test('one answer per text, shared by every row that shows it', () {
    final facts = MessageFacts.of('see you at the hut');
    expect(MessageFacts.of('see you at the hut'), same(facts));
    expect(MessageFacts.of('see you at the hut', announcement: true),
        isNot(same(facts)));
  });

  test('the answers are the parsers\' own', () {
    final reply = MessageFacts.of('@[GWQ]\n>what clien..\nMeshcore One');
    expect(reply.reply?.mentionedNode, 'GWQ');
    expect(reply.reply?.actualMessage, 'Meshcore One');

    final location = MessageFacts.of('Location: 47.070123, 15.440123');
    expect(location.structured, isA<LocationMessage>());
    expect(location.emojiOnly, isFalse);

    expect(MessageFacts.of('👍🎉').emojiOnly, isTrue);
    expect(MessageFacts.of('ok 👍').emojiOnly, isFalse);

    // A room server's plain post is still its announcement card.
    expect(MessageFacts.of('Coffee at noon').structured, isNull);
    final post = MessageFacts.of('Coffee at noon', announcement: true);
    expect(post.structured, isA<NoticeMessage>());
    expect((post.structured! as NoticeMessage).announcement, isTrue);
  });

  test('only a short message lists its short links', () {
    const link = 'https://maps.app.goo.gl/AbCdEf';
    expect(ShortLinkResolver.shortLinksIn('Here $link'), [link]);
    expect(ShortLinkResolver.shortLinksIn('a\nb\nc\nd $link'), isEmpty);
    expect(
        ShortLinkResolver.shortLinksIn('https://example.com/x'), isEmpty);
  });

  test('a short link lookup that finishes starts the cache over', () async {
    const link = 'https://maps.app.goo.gl/MfTest01';
    final before = MessageFacts.of('Meet here $link');
    // Unanswerable in a test: it fails, and listeners hear it either way.
    await ShortLinkResolver.instance.resolve(link);
    expect(MessageFacts.of('Meet here $link'), isNot(same(before)));
  });

  test('a failed lookup says when a row should ask again', () async {
    const link = 'https://maps.app.goo.gl/MfTest02';
    expect(MessageFacts.of('Here $link').prefetchShortLinks(), isNull,
        reason: 'nothing has failed yet');
    await ShortLinkResolver.instance.resolve(link);
    final retry = MessageFacts.of('Here $link').prefetchShortLinks();
    final now = DateTime.now();
    expect(retry, isNotNull);
    expect(retry!.isAfter(now.add(const Duration(minutes: 4))), isTrue);
    expect(retry.isBefore(now.add(const Duration(minutes: 6))), isTrue);
    expect(MessageFacts.of('Location: 47.07, 15.44').prefetchShortLinks(),
        isNull);
  });

  test('a quote reads a short link as the link, the row as its card', () {
    final facts = MessageFacts.of(_resolvedLink);
    expect(facts.structured, isA<LocationMessage>());
    expect(facts.quoteCard, isNull);
    expect(MessageFacts.of('Location: 47.070123, 15.440123').quoteCard,
        isA<LocationMessage>());
  });

  test('a card says when the clock changes it', () {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final later = now.add(const Duration(days: 3));
    final laterMinute = DateTime(
        later.year, later.month, later.day, later.hour, later.minute);

    // Its day label turns at midnight, every night until it is over.
    expect(MessageFacts.of('Event: Net\n${_stamp(later)}').changesAt,
        midnight);
    expect(
        MessageFacts.of('Event: Net\n${_stamp(now.subtract(const Duration(days: 3)))}')
            .changesAt,
        isNull);
    expect(MessageFacts.of('Notice: Road closed\nexpires=${_stamp(later)}')
            .changesAt,
        laterMinute);
    expect(
        MessageFacts.of('Notice: Road closed\nexpires=${_stamp(now.subtract(const Duration(days: 1)))}')
            .changesAt,
        isNull);
    expect(MessageFacts.of('just words').changesAt, isNull);
  });
}
