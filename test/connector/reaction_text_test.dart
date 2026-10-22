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
      expect(wire, '@[GWQ∆🍓]😂\n$expectedHash');
    });

    test('keeps a leading mention in the hash — MC1 never strips it', () {
      final target = ChannelMessage(
        senderName: 'GWQ∆🍓',
        text: '@[Vacasity] Hello',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1234567890000),
        isOutgoing: false,
        messageId: '1234567890000_x_y',
      );
      final wire = MeshCoreConnector.channelReactionText(target, '😂');
      final expectedHash = ReactionHelper.computeMeshCoreOneHash(
          '@[Vacasity] Hello', 1234567890);
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
      expect(wire, '@[Me]👍\n$expectedHash');
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

  group('reply rows — pinned to the 2026-08-12 #mtdebug on-air capture', () {
    // Ground truth measured against MeshCore One (iOS) on real radios:
    //   hash 8p4kahn8 = MC1's 😂 to a MeshTrax reply, computed over the RAW
    //   wire markup '@[GWQ∆🚀]\n>This is a ..\nSure is.' at ts 1786548879.
    //   hash 2s693yek = MC1's 😮 to the SAME reply, hashed over the RETRY
    //   copy's stamp (ts+31) — proof reactors hash whichever copy they heard.
    //   hash 2ehjvpha = what MeshTrax USED to send for a reply (body-only
    //   'Nice!' at 1786549146) — the form MC1 can never match.
    const rawReply = '@[GWQ∆🚀]\n>This is a ..\nSure is.';
    const replySecs = 1786548879;

    test('pinned vectors reproduce', () {
      expect(ReactionHelper.computeMeshCoreOneHash(rawReply, replySecs),
          '8p4kahn8');
      expect(ReactionHelper.computeMeshCoreOneHash(rawReply, replySecs + 31),
          '2s693yek');
      expect(ReactionHelper.computeMeshCoreOneHash('Nice!', 1786549146),
          '2ehjvpha');
    });

    test('reacting to a reply row hashes the RAW wire markup', () {
      // The row displays only the body; wireText carries what flew.
      final replyRow = ChannelMessage(
        senderName: 'GWQ∆🍓',
        text: 'Sure is.',
        wireText: rawReply,
        timestamp: DateTime.fromMillisecondsSinceEpoch(replySecs * 1000),
        isOutgoing: false,
        messageId: '${replySecs}000_x_y',
      );
      final wire = MeshCoreConnector.channelReactionText(replyRow, '😂');
      expect(wire, '@[GWQ∆🍓]😂\n8p4kahn8',
          reason: 'must produce the hash MeshCore One resolves — the '
              'body-only hash (2ehjvpha) chips on nobody');
    });

    test('an incoming MC1 reaction to our reply resolves via wireText', () {
      final replyRow = ChannelMessage(
        senderName: 'GWQ∆🍓',
        text: 'Sure is.',
        wireText: rawReply,
        timestamp: DateTime.fromMillisecondsSinceEpoch(replySecs * 1000),
        isOutgoing: false,
        messageId: '${replySecs}000_x_y',
      );
      final rows = [replyRow];
      final applied = ReactionHelper.applyReaction<ChannelMessage>(
        messages: rows,
        reactionInfo:
            ReactionHelper.parseIncomingReaction('😂@[GWQ∆🍓]\n8p4kahn8')!,
        reactorName: 'GWQ∆🚀',
        shouldSkip: (_) => false,
        getTimestampSecs: (m) => m.timestamp.millisecondsSinceEpoch ~/ 1000,
        getWireTimestampSecs: (m) => [replySecs],
        getMessageTextVariants: (m) => {
          m.text,
          if (m.wireText != null) m.wireText!,
        }.toList(),
        getSenderName: (m) => m.senderName,
        getMessageText: (m) => m.text,
        getReactions: (m) => m.reactions,
        getReactionSenders: (m) => m.reactionSenders,
        updateMessage: (i, reactions, senders) {
          rows[i] = rows[i]
              .copyWith(reactions: reactions, reactionSenders: senders);
        },
      );
      expect(applied, isTrue);
      expect(rows.first.reactions['😂'], 1);
    });

    test('a reaction hashed over a RETRY stamp resolves via harvested secs',
        () {
      // The 😮 case: the reactor heard the re-stamped retry (+31 s). The
      // row must carry every stamp heard, and the matcher must try them.
      final replyRow = ChannelMessage(
        senderName: 'GWQ∆🍓',
        text: 'Sure is.',
        wireText: rawReply,
        timestamp: DateTime.fromMillisecondsSinceEpoch(replySecs * 1000),
        isOutgoing: false,
        messageId: '${replySecs}000_x_y',
        sentWireSecs: const [replySecs + 31],
      );
      final index = ReactionHelper.findTargetIndex<ChannelMessage>(
        messages: [replyRow],
        reactionInfo:
            ReactionHelper.parseIncomingReaction('😮@[GWQ∆🍓]\n2s693yek')!,
        shouldSkip: (_) => false,
        getTimestampSecs: (m) => m.timestamp.millisecondsSinceEpoch ~/ 1000,
        getWireTimestampSecs: (m) => {replySecs, ...m.sentWireSecs}.toList(),
        getMessageTextVariants: (m) => {
          m.text,
          if (m.wireText != null) m.wireText!,
        }.toList(),
        getSenderName: (m) => m.senderName,
        getMessageText: (m) => m.text,
      );
      expect(index, 0,
          reason: 'without the harvested retry stamp this reaction orphans');
    });

    test('mc1DisplayText (receive tolerance) strips addressing, keeps reply '
        'markup', () {
      expect(ChannelMessage.mc1DisplayText('@[Bob] hello'), 'hello');
      expect(ChannelMessage.mc1DisplayText('@[Bob]\n>quote..\nhello'),
          '@[Bob]\n>quote..\nhello');
      expect(ChannelMessage.mc1DisplayText('plain'), 'plain');
    });
  });

  group('edge whitespace — pinned to the 2026-10-21 #Public field log', () {
    // Vacasity X1 and Lil_Meshy both reacted 😂 with hash nksybmwk to SG
    // Meshpocket's message heard at stamp 1792645827. It reproduces from the
    // FULL text, mention kept, at offset 0 — yet our stored row missed:
    // MC1 trims the channel body's edges (ChannelMessageFormat.parse) and
    // the sender's text carried trailing whitespace we keep.
    const mc1Text =
        '@[PIBER 📟] important news about their car’s extended warranty.';
    const stored = '$mc1Text ';
    const secs = 1792645827;
    final row = ChannelMessage(
      senderName: 'SG Meshpocket',
      text: stored,
      timestamp: DateTime.fromMillisecondsSinceEpoch(secs * 1000),
      isOutgoing: false,
      messageId: '${secs}000_x_y',
    );

    test('pinned vector reproduces', () {
      expect(ReactionHelper.computeMeshCoreOneHash(mc1Text, secs), 'nksybmwk');
    });

    test('mc1HashText trims tab and Zs at the edges only', () {
      expect(ChannelMessage.mc1HashText(stored), mc1Text);
      expect(ChannelMessage.mc1HashText('\t a  b 　'), 'a  b');
      expect(ChannelMessage.mc1HashText('hi\n'), 'hi\n',
          reason: 'Swift .whitespaces excludes newlines');
    });

    test('an MC1 reaction to a trailing-space row resolves', () {
      final index = ReactionHelper.findTargetIndex<ChannelMessage>(
        messages: [row],
        reactionInfo: ReactionHelper.parseIncomingReaction(
            '@[SG Meshpocket]😂\nnksybmwk')!,
        shouldSkip: (_) => false,
        getTimestampSecs: (m) => secs,
        getSenderName: (m) => m.senderName,
        getMessageText: (m) => m.text,
        getMessageTextVariants: (m) =>
            MeshCoreConnector.mc1TextVariants(m.text, m.wireText),
      );
      expect(index, 0);
    });

    test('our reaction to that row carries the hash MC1 holds', () {
      expect(MeshCoreConnector.channelReactionText(row, '😂'),
          '@[SG Meshpocket]😂\nnksybmwk');
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

    test('room shape: names the author, same hash as the bare form', () {
      final target = Message(
        senderKey: Uint8List(32),
        text: 'Hi there',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1111111111000),
        isOutgoing: false,
        messageId: '1234567890123_ab_1',
      );
      final wire = MeshCoreConnector.contactReactionText(
        target,
        '👍',
        targetSender: 'GWQ∆🍓',
      );
      final expectedHash =
          ReactionHelper.computeMeshCoreOneHash('Hi there', 1234567890);
      expect(wire, '@[GWQ∆🍓]👍\n$expectedHash');
      final parsed = ReactionHelper.parseIncomingReaction(wire)!;
      expect(parsed.targetSender, 'GWQ∆🍓');
      expect(parsed.emoji, '👍');
      expect(parsed.targetHash, expectedHash);
    });
  });

  group('contactWireSecsCandidates', () {
    // A room server stamps our post with ITS clock when it arrives and never
    // sends it back, so the stamp everyone else hashes lies between the row
    // clock and the ACK, shifted by the room's clock skew. Field case
    // 2026-10-12: row 09:59:52, attempt 0 unacked, attempt 1 confirmed
    // 10:00:22 — the old t..t+3 window could never hold +6 or +28.
    const row = 1791823192;
    Message outgoing({DateTime? deliveredAt, DateTime? sentAt}) => Message(
          senderKey: Uint8List(32),
          text: 'post',
          timestamp: DateTime.fromMillisecondsSinceEpoch(row * 1000),
          isOutgoing: true,
          deliveredAt: deliveredAt,
          sentAt: sentAt,
        );
    final delivered30 =
        outgoing(deliveredAt: DateTime.fromMillisecondsSinceEpoch((row + 30) * 1000));

    test('plain DM: the t..t+3 window is unchanged', () {
      expect(
        MeshCoreConnector.contactWireSecsCandidates(delivered30),
        [row, row + 1, row + 2, row + 3],
      );
    });

    test('room, incoming row: only its own server stamp', () {
      final incoming = Message(
        senderKey: Uint8List(32),
        text: 'post',
        timestamp: DateTime.fromMillisecondsSinceEpoch(row * 1000),
        isOutgoing: false,
      );
      expect(
        MeshCoreConnector.contactWireSecsCandidates(incoming, roomSkewSecs: -600),
        [row],
      );
    });

    test('room, own post: row-5 .. deliveredAt+5 at skew 0', () {
      final secs = MeshCoreConnector.contactWireSecsCandidates(
        delivered30,
        roomSkewSecs: 0,
      );
      expect(secs.first, row - 5);
      expect(secs.last, row + 35);
      expect(secs, contains(row + 6));
      expect(secs, contains(row + 28));
      expect(secs, isNot(contains(row + 36)));
    });

    test('room, own post: the skew shifts the whole window', () {
      final secs = MeshCoreConnector.contactWireSecsCandidates(
        delivered30,
        roomSkewSecs: -600,
      );
      expect(secs, contains(row + 28 - 600));
      expect(secs, isNot(contains(row + 28)));
    });

    test('room, own post: the window is capped', () {
      final late = outgoing(
        deliveredAt: DateTime.fromMillisecondsSinceEpoch((row + 1000) * 1000),
      );
      expect(
        MeshCoreConnector.contactWireSecsCandidates(late, roomSkewSecs: 0).length,
        121,
      );
    });

    test('room, undelivered post: sentAt + grace, else row + 60', () {
      final sentOnly = outgoing(
        sentAt: DateTime.fromMillisecondsSinceEpoch((row + 20) * 1000),
      );
      expect(
        MeshCoreConnector.contactWireSecsCandidates(sentOnly, roomSkewSecs: 0).last,
        row + 20 + 30 + 5,
      );
      expect(
        MeshCoreConnector.contactWireSecsCandidates(outgoing(), roomSkewSecs: 0)
            .last,
        row + 60 + 5,
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
