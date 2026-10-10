import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel_message.dart';

// Room replies reuse the channel wire format but ride the contact send path,
// capped by the room server's post store (MAX_POST_TEXT_LEN = 151 bytes).
void main() {
  bool fitsRoom(String candidate) =>
      utf8.encode(candidate).length <= maxRoomMessageBytes();

  test('room budget is the firmware post cap, under the contact frame cap',
      () {
    expect(maxRoomMessageBytes(), equals(151));
    expect(maxRoomMessageBytes(), lessThan(maxContactMessageBytes()));
  });

  test('reply round-trips through parseReply within the room budget', () {
    final built = ChannelMessage.buildReplyWireText(
      targetName: 'Trunks 🩳',
      quoteText: 'Let me see if I can see it',
      body: 'Looks good from here',
      selfName: 'MRY',
      fits: fitsRoom,
    );

    expect(built, isNotNull);
    expect(fitsRoom(built!), isTrue);

    final parsed = ChannelMessage.parseReply(built);
    expect(parsed, isNotNull);
    expect(parsed!.mentionedNode, equals('Trunks 🩳'));
    expect(parsed.actualMessage, equals('Looks good from here'));
    expect('Let me see if I can see it', startsWith(parsed.snippet));
  });

  test('quoting a reply quotes its body, not its reply header', () {
    final original = ChannelMessage.buildReplyWireText(
      targetName: 'Alice',
      quoteText: 'first message text',
      body: 'second message body',
      selfName: 'Bob',
      fits: fitsRoom,
    )!;

    // What the app passes as quoteText when replying to a stored reply.
    final quoteSource =
        ChannelMessage.parseReply(original)?.actualMessage ?? original;
    expect(quoteSource, equals('second message body'));

    final nested = ChannelMessage.buildReplyWireText(
      targetName: 'Bob',
      quoteText: quoteSource,
      body: 'third message',
      selfName: 'Alice',
      fits: fitsRoom,
    );
    final parsed = ChannelMessage.parseReply(nested!);
    expect(parsed!.snippet, isNot(contains('@[')));
    expect(parsed.actualMessage, equals('third message'));
  });

  test('tight budget falls back to a plain mention, then to null', () {
    final longBody = 'x' * 120;
    final built = ChannelMessage.buildReplyWireText(
      targetName: 'VeryLongRoomMemberName',
      quoteText: 'a quoted message that will not fit alongside the body',
      body: longBody,
      selfName: '',
      fits: fitsRoom,
    );
    // 120 + name + markup still fits as a mention-only reply.
    expect(built, equals('@[VeryLongRoomMemberName]\n$longBody'));
    expect(ChannelMessage.parseReply(built!), isNull,
        reason: 'a mention-only fallback is a mention, not a reply');

    final hopeless = ChannelMessage.buildReplyWireText(
      targetName: 'VeryLongRoomMemberName',
      quoteText: 'quote',
      body: 'y' * 160,
      selfName: '',
      fits: fitsRoom,
    );
    expect(hopeless, isNull);
  });

  test('a plain room post parses as no reply', () {
    expect(ChannelMessage.parseReply('DM from room: You have logged in!'),
        isNull);
    expect(ChannelMessage.parseReply('@[MRY] hello there'), isNull,
        reason: 'a leading mention with a space is addressing, not a reply');
  });
}
