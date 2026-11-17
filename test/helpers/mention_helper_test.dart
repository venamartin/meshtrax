import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/mention_helper.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/contact_note.dart';

Contact _contact(int seed, String name, {int type = advTypeChat}) => Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
      name: name,
      type: type,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime(2026, 11, 17),
    );

ChannelMessage _post(int minute, String sender, {bool outgoing = false}) =>
    ChannelMessage(
      senderName: sender,
      text: 'hello',
      timestamp: DateTime(2026, 11, 17, 9, minute),
      isOutgoing: outgoing,
      status: ChannelMessageStatus.sent,
      channelIndex: 1,
      messageId: 'p$minute',
    );

TextEditingValue _typed(String text, [int? cursor]) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor ?? text.length),
    );

void main() {
  group('query', () {
    test('an @ at the start or after a space or line break', () {
      expect(MentionHelper.query(_typed('@')), (at: 0, query: ''));
      expect(MentionHelper.query(_typed('hi @Ri')), (at: 3, query: 'Ri'));
      expect(MentionHelper.query(_typed('hi\n@Ri')), (at: 3, query: 'Ri'));
    });

    test('a name with a space can be typed out', () {
      expect(MentionHelper.query(_typed('@Ridge W')), (at: 0, query: 'Ridge W'));
    });

    test('not a mention', () {
      for (final text in [
        '',
        'mail me@home',
        '@ noon',
        '@[Ridge Walker] ',
        '@Ri\nnext line',
        '@${'x' * 33}',
      ]) {
        expect(MentionHelper.query(_typed(text)), isNull, reason: text);
      }
    });

    test('only the text up to the cursor counts', () {
      expect(MentionHelper.query(_typed('@Rid and more', 4)),
          (at: 0, query: 'Rid'));
    });

    test('a selection is not a mention', () {
      const value = TextEditingValue(
        text: '@Ri',
        selection: TextSelection(baseOffset: 1, extentOffset: 3),
      );
      expect(MentionHelper.query(value), isNull);
    });
  });

  test('insert puts "@[name] " in place of the typed word', () {
    final value =
        MentionHelper.insert(_typed('hi @Ri, see you', 6), 3, 'Ridge Walker');
    expect(value.text, 'hi @[Ridge Walker] , see you');
    expect(value.selection, const TextSelection.collapsed(offset: 19));
  });

  test('filter puts the names that start with the text first, in their order',
      () {
    final pine = _contact(0x10, 'Pine Hollow');
    final ann = _contact(0x30, 'Ann');
    final hollis = _contact(0x50, 'Hollis');
    final notes = {ann.publicKeyHex: const ContactNote(realName: 'Ann Holloway')};
    expect(
      MentionHelper.filter([pine, ann, hollis], 'Holl', (k) => notes[k]),
      [hollis, pine, ann],
      reason: 'Hollis starts with it; Pine Hollow holds it; Ann by full name',
    );
    expect(MentionHelper.filter([pine, ann], 'Pine H', (_) => null), [pine]);
    expect(MentionHelper.filter([pine, ann], '', (_) => null), [pine, ann]);
  });

  test('filter does not match on the public key', () {
    final pine = _contact(0xab, 'Pine Hollow');
    expect(pine.publicKeyHex, startsWith('ab'));
    expect(MentionHelper.filter([pine], 'ab', (_) => null), isEmpty);
  });

  group('channelCandidates', () {
    test('posters first, the latest one first, then the others A to Z', () {
      final walker = _contact(0x10, 'Ridge Walker');
      final zed = _contact(0x30, 'Zed');
      final amy = _contact(0x50, 'amy');
      final bird = _contact(0x70, '🦅 Bird');
      final candidates = MentionHelper.channelCandidates(
        [_post(0, 'Zed'), _post(1, 'Ridge Walker'), _post(2, 'Zed')],
        [walker, zed, amy, bird],
      );
      expect(candidates, [zed, walker, bird, amy],
          reason: 'emoji-led names before the rest, which can be typed');
    });

    test('a poster with no contact or a shared name gets a stand-in', () {
      final pineA = _contact(0x10, 'Pine Hollow');
      final pineB = _contact(0x30, 'Pine Hollow');
      final candidates = MentionHelper.channelCandidates(
        [_post(0, 'Stranger'), _post(1, 'Pine Hollow')],
        [pineA, pineB],
      );
      expect(candidates.map((c) => c.name), ['Pine Hollow', 'Stranger']);
      expect(candidates.any((c) => identical(c, pineA) || identical(c, pineB)),
          isFalse,
          reason: 'a post can not tell which Pine Hollow wrote it');
    });

    test('my own posts, repeaters, rooms and sensors are left out', () {
      final walker = _contact(0x10, 'Ridge Walker');
      final candidates = MentionHelper.channelCandidates(
        [_post(0, 'Me', outgoing: true)],
        [
          walker,
          _contact(0x30, 'Hilltop RPT', type: advTypeRepeater),
          _contact(0x50, 'Club Room', type: advTypeRoom),
          _contact(0x70, 'Weather', type: advTypeSensor),
        ],
      );
      expect(candidates, [walker]);
    });

    test('one row per name, whatever its case', () {
      final walker = _contact(0x10, 'Ridge Walker');
      final candidates = MentionHelper.channelCandidates(
        [_post(0, 'ridge walker'), _post(1, 'Ridge Walker')],
        [walker],
      );
      expect(candidates, [walker]);
    });
  });
}
