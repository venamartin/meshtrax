import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel_message.dart';

void main() {
  group('parseReply meshtrax dialect', () {
    test('parses "@[Name] re:<snippet>…<response>"', () {
      final info = ChannelMessage.parseReply(
        '@[Alice] re:hello worl…sounds good',
      );
      expect(info, isNotNull);
      expect(info!.mentionedNode, 'Alice');
      expect(info.snippet, 'hello worl');
      expect(info.actualMessage, 'sounds good');
    });

    test('parses the newline-separated wire form', () {
      final info = ChannelMessage.parseReply(
        '@[Alice]\nre:hello worl…\nsounds good',
      );
      expect(info, isNotNull);
      expect(info!.mentionedNode, 'Alice');
      expect(info.snippet, 'hello worl');
      expect(info.actualMessage, 'sounds good');
    });
  });

  group('parseReply MeshCore One dialect', () {
    test('parses the observed on-air example', () {
      final info = ChannelMessage.parseReply(
        '@[GWQ∆🍓]\n>what clien..\nMeshcore One w/ iPhone',
      );
      expect(info, isNotNull);
      expect(info!.mentionedNode, 'GWQ∆🍓');
      expect(info.snippet, 'what clien');
      expect(info.actualMessage, 'Meshcore One w/ iPhone');
    });

    test('short parent: no ".." truncation marker', () {
      final info = ChannelMessage.parseReply('@[Bob]\n>hi\nyes');
      expect(info, isNotNull);
      expect(info!.snippet, 'hi');
      expect(info.actualMessage, 'yes');
    });

    test('keeps a multiline body intact', () {
      final info = ChannelMessage.parseReply('@[Bob]\n>abc\nline1\nline2');
      expect(info, isNotNull);
      expect(info!.actualMessage, 'line1\nline2');
    });
  });

  group('parseReply non-replies', () {
    test('plain mention is not a reply', () {
      expect(ChannelMessage.parseReply('@[Bob] hello'), isNull);
      expect(ChannelMessage.parseReply('@[Bob]\nhello'), isNull);
    });

    test('MeshCore One reaction text is not a reply', () {
      expect(ChannelMessage.parseReply('👍@[Bob]\n66nf5k51'), isNull);
    });

    test('ordinary message is not a reply', () {
      expect(ChannelMessage.parseReply('just some text'), isNull);
    });
  });

  group('buildReplyWireText (MeshCore One dialect)', () {
    String? build(String quote, String body, {bool Function(String)? fits}) {
      return ChannelMessage.buildReplyWireText(
        targetName: 'Alice',
        quoteText: quote,
        body: body,
        fits: fits ?? (_) => true,
      );
    }

    test('emits >snippet.. with a 10-char truncated parent', () {
      expect(
        build('what client are you using?', 'Meshcore One w/ iPhone'),
        '@[Alice]\n>what clien..\nMeshcore One w/ iPhone',
      );
    });

    test('short parent gets no ".." marker', () {
      expect(build('hi', 'yes'), '@[Alice]\n>hi\nyes');
    });

    test('flattens whitespace in the snippet', () {
      // Unlike MC1's own builder, a multiline parent can't garble the framing.
      final wire = build('line one\nline two', 'ok')!;
      expect(wire, '@[Alice]\n>line one l..\nok');
    });

    test('round-trips through parseReply', () {
      final wire = build('what client are you using?', 'the reply body')!;
      final info = ChannelMessage.parseReply(wire);
      expect(info, isNotNull);
      expect(info!.mentionedNode, 'Alice');
      expect(info.snippet, 'what clien');
      expect(info.actualMessage, 'the reply body');
    });

    test('shrinks the snippet to fit, then falls back to a mention', () {
      final shrunk = build(
        'what client are you using?',
        'body',
        fits: (c) => c.length <= '@[Alice]\n>what c..\nbody'.length,
      );
      expect(shrunk, '@[Alice]\n>what c..\nbody');

      final mentionOnly = build(
        'what client are you using?',
        'body',
        fits: (c) => c.length <= '@[Alice]\nbody'.length,
      );
      expect(mentionOnly, '@[Alice]\nbody');

      expect(build('quote', 'body', fits: (_) => false), isNull);
    });

    test('quotes the words after a leading mention, whoever it names', () {
      expect(
        build('@[Me] thanks for that', 'welcome'),
        '@[Alice]\n>thanks for..\nwelcome',
      );
      // Ten characters of this one do not reach past its mention.
      expect(
        build('@[Ridge Top Repeater] the pass is open again', 'good'),
        '@[Alice]\n>the pass i..\ngood',
      );
      expect(build('@[Bob] @[Dan] hi all', 'hi'), '@[Alice]\n>hi all\nhi');
    });

    test('a parent that is only a mention is quoted as it is', () {
      expect(build('@[Bob]', 'yes?'), '@[Alice]\n>@[Bob]\nyes?');
    });

    test('the quote of a mention-led parent finds it again', () {
      const parent = '@[Ridge Top Repeater] the pass is open again';
      final snippet = ChannelMessage.parseReply(build(parent, 'good')!)!.snippet;
      expect(ChannelMessage.snippetMatches(parent, snippet), isTrue);
    });

    test('never cuts a character in two', () {
      // An emoji is two units: a cut by units leaves half of one, which
      // goes out as U+FFFD and matches nothing.
      final wire = build('Hi ${'\u{1F642}' * 9}', 'ok')!;
      expect(wire, '@[Alice]\n>Hi ${'\u{1F642}' * 7}..\nok');
      expect(utf8.decode(utf8.encode(wire)), wire);
    });

    test('a quote of combined emoji still leaves room to type', () {
      // A family is five code points and 18 bytes: ten whole ones would be
      // more than a channel message holds.
      final family = String.fromCharCodes([
        0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467, //
      ]);
      final snippet = ChannelMessage.buildReplySnippet(family * 9, 10);
      expect(snippet.runes.length, 10);
      expect(utf8.encode(snippet).length, lessThanOrEqualTo(40));
      expect(utf8.decode(utf8.encode(snippet)), snippet);
    });
  });

  group('parseReaction on ChannelMessage', () {
    test('reads both dialects at the model level', () {
      expect(ChannelMessage.parseReaction('r:a1b2:00'), isNotNull);
      expect(
        ChannelMessage.parseReaction('❤️@[Vacasity]\nd68tbhcs'),
        isNotNull,
      );
      expect(ChannelMessage.parseReaction('hello'), isNull);
    });
  });

  group('snippetMatches', () {
    test('plain prefix', () {
      expect(ChannelMessage.snippetMatches('hello world', 'hello worl'), isTrue);
      expect(ChannelMessage.snippetMatches('hello world', 'goodbye'), isFalse);
    });

    test('ignores case and collapses whitespace', () {
      expect(
        ChannelMessage.snippetMatches('Hello   World\nagain', 'hello world ag'),
        isTrue,
      );
    });

    test('strips leading mentions on both sides', () {
      expect(
        ChannelMessage.snippetMatches('@[Bob] hello world', 'hello worl'),
        isTrue,
      );
      expect(
        ChannelMessage.snippetMatches('hello world', '@[Bob] hello worl'),
        isTrue,
      );
    });

    test('empty snippet matches anything', () {
      expect(ChannelMessage.snippetMatches('whatever', ''), isTrue);
    });

    test('a quote of a reply, quote line and all, matches what it sent', () {
      const wire = '@[Bob]\n>Pine cones..\nI got mine';
      expect(ChannelMessage.snippetMatches('I got mine', '>Pine cone'), isFalse);
      expect(
        ChannelMessage.snippetMatches('I got mine', '>Pine cone', wireText: wire),
        isTrue,
      );
      expect(
        ChannelMessage.snippetMatches('I got mine', 'I got', wireText: wire),
        isTrue,
        reason: 'a quote of the body still matches',
      );
      expect(
        ChannelMessage.snippetMatches('I got mine', '>Fir cones', wireText: wire),
        isFalse,
      );
    });
  });
}
