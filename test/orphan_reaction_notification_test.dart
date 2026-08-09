import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/reaction_helper.dart';
import 'package:meshtrax/models/channel_message.dart';

// A MeshCore One reaction names the person whose message it reacted to, so
// its raw text contains "@[their name]". mentionsUser() cannot tell that
// apart from real addressing — and a mention deliberately cuts through a
// muted channel. _maybeNotifyChannelMessage must therefore recognise an
// unplaced reaction and stay quiet, matching the silence of a reaction that
// DID resolve (which never reaches the notifier at all).
void main() {
  const self = '3rabbit🐇';

  group('an unplaced reaction must not read as a mention', () {
    final wire = ReactionHelper.encodeMeshCoreOne(
      '🥂',
      ReactionHelper.computeMeshCoreOneHash('some message', 1786299588),
      targetSender: self,
    );

    test('premise: the raw text DOES look like a mention of the target', () {
      // This is exactly why the notifier needs its own reaction guard: the
      // generic mention test cannot be made smart enough on its own.
      expect(ChannelMessage.mentionsUser(wire, self), isTrue);
    });

    test('but it parses as a reaction, which is the guard the notifier uses',
        () {
      final info = ReactionHelper.parseMeshCoreOneReaction(wire);
      expect(info, isNotNull);
      expect(info!.emoji, '🥂');
      expect(info.targetSender, self);
    });

    test('a genuine mention of the same person is NOT seen as a reaction', () {
      const real = '@[3rabbit🐇] are you around?';
      expect(ChannelMessage.mentionsUser(real, self), isTrue);
      expect(ReactionHelper.parseMeshCoreOneReaction(real), isNull,
          reason: 'the guard must never swallow a real mention');
    });

    test('a two-line message that merely starts with an emoji still notifies',
        () {
      // The reaction shape needs a trailing 8-char Crockford line; ordinary
      // prose cannot reach it, so the guard cannot silence real messages.
      const prose = '🥂@[3rabbit🐇]\ncongratulations on the new node';
      expect(ReactionHelper.parseMeshCoreOneReaction(prose), isNull);
      expect(ChannelMessage.mentionsUser(prose, self), isTrue);
    });
  });
}
