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
        selfName: 'Me',
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

    test('strips our own leading mention from the quoted snippet', () {
      expect(
        build('@[Me] thanks for that', 'welcome'),
        '@[Alice]\n>thanks for..\nwelcome',
      );
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
}
