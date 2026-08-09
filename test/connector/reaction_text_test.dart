import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/reaction_helper.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/message.dart';

// The reaction SEND builders. They commit to one wire timestamp and one text
// form; the receive matcher tries whole candidate sets — so the property that
// matters is that what these emit always lands inside what receivers try.
void main() {
  group('channelReactionText', () {
    test('incoming row: hashes the wire clock, not the display clock', () {
      // messageId leads with the ORIGINAL wire ms; the stored timestamp was
      // clamped by ingest and must not participate.
      final target = ChannelMessage(
        senderName: 'GWQ∆🍓',
        text: 'Hello',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1111111111000),
        isOutgoing: false,
        messageId: '1234567890000_x_y',
      );
      final wire = MeshCoreConnector.channelReactionText(target, '😂');
      final expectedHash =
          ReactionHelper.computeMeshCoreOneHash('Hello', 1234567890);
      expect(wire, '😂@[GWQ∆🍓]\n$expectedHash');
    });

    test('hashes the mention-stripped display text — what MC1 clients hold',
        () {
      final target = ChannelMessage(
        senderName: 'GWQ∆🍓',
        text: '@[Vacasity] Hello',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1234567890000),
        isOutgoing: false,
        messageId: '1234567890000_x_y',
      );
      final wire = MeshCoreConnector.channelReactionText(target, '😂');
      final expectedHash =
          ReactionHelper.computeMeshCoreOneHash('Hello', 1234567890);
      expect(wire.endsWith('\n$expectedHash'), isTrue,
          reason: 'got "$wire"');
    });

    test('own row with recorded stamps commits to the LAST transmission', () {
      // The retry that actually got through is the copy everyone holds.
      final target = ChannelMessage(
        senderName: 'Me',
        text: 'Hello',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1234567890000),
        isOutgoing: true,
        messageId: '1234567890000_x_y',
        sentWireSecs: const [1234567892, 1234567921],
      );
      final wire = MeshCoreConnector.channelReactionText(target, '👍');
      final expectedHash =
          ReactionHelper.computeMeshCoreOneHash('Hello', 1234567921);
      expect(wire, '👍@[Me]\n$expectedHash');
    });

    test('round-trips through the receive matcher on another meshtrax', () {
      // The receiver stores the raw mention-led text and its own wire clock;
      // its matcher tries variants and candidate seconds. Our send must land.
      final theirRow = _FakeRow(
        secs: 1234567890,
        sender: 'GWQ∆🍓',
        text: '@[Vacasity] Hello',
      );
      final ourCopy = ChannelMessage(
        senderName: 'GWQ∆🍓',
        text: '@[Vacasity] Hello',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1234567890000),
        isOutgoing: false,
        messageId: '1234567890000_x_y',
      );
      final wire = MeshCoreConnector.channelReactionText(ourCopy, '😂');
      final applied = ReactionHelper.applyReaction<_FakeRow>(
        messages: [theirRow],
        reactionInfo: ReactionHelper.parseIncomingReaction(wire)!,
        reactorName: 'Vacasity',
        shouldSkip: (_) => false,
        getTimestampSecs: (m) => m.secs,
        getWireTimestampSecs: (m) => [m.secs],
        getMessageTextVariants: (m) => {
          m.text,
          ChannelMessage.stripLeadingMentions(m.text),
        }.toList(),
        getSenderName: (m) => m.sender,
        getMessageText: (m) => m.text,
        getReactions: (m) => m.reactions,
        getReactionSenders: (m) => m.reactionSenders,
        updateMessage: (i, reactions, senders) {
          theirRow.reactions = reactions;
          theirRow.reactionSenders = senders;
        },
      );
      expect(applied, isTrue);
      expect(theirRow.reactions['😂'], 1);
      expect(theirRow.reactionSenders['😂'], ['Vacasity']);
    });
  });

  group('contactReactionText', () {
    test('DM shape: no sender tag, wire-clock hash', () {
      final target = Message(
        senderKey: Uint8List(32),
        text: 'Hi there',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1111111111000),
        isOutgoing: false,
        messageId: '1234567890123_ab_1',
      );
      final wire = MeshCoreConnector.contactReactionText(target, '❤️');
      final expectedHash =
          ReactionHelper.computeMeshCoreOneHash('Hi there', 1234567890);
      expect(wire, '❤️\n$expectedHash');
      expect(
        ReactionHelper.parseIncomingReaction(wire)!.targetSender,
        isNull,
      );
    });
  });
}

class _FakeRow {
  _FakeRow({required this.secs, required this.sender, required this.text});

  final int secs;
  final String sender;
  final String text;
  Map<String, int> reactions = {};
  Map<String, List<String>> reactionSenders = {};
}
