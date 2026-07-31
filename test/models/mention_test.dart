import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/models/channel_message.dart';

// Mention notifications cut through channel mutes; detection is a pure text
// check on the wire form, where mentions and replies both carry `@[Name]`.
void main() {
  group('ChannelMessage.mentionsUser', () {
    test('plain mention anywhere in the text', () {
      expect(ChannelMessage.mentionsUser('hey @[Martin] look', 'Martin'),
          isTrue);
    });

    test('reply header counts — replies to me always carry my mention', () {
      expect(
        ChannelMessage.mentionsUser(
          '@[Martin]\n>on my way..\nsounds good',
          'Martin',
        ),
        isTrue,
      );
    });

    test('case-insensitive: other apps let senders type names by hand', () {
      expect(ChannelMessage.mentionsUser('@[martin] hi', 'Martin'), isTrue);
    });

    test('a longer name is not a match for its prefix', () {
      expect(ChannelMessage.mentionsUser('@[Martina] hi', 'Martin'), isFalse);
    });

    test('bare name without mention syntax does not fire', () {
      expect(
        ChannelMessage.mentionsUser('martin said it works', 'Martin'),
        isFalse,
      );
    });

    test('no self name known yet means no mention', () {
      expect(ChannelMessage.mentionsUser('@[Martin] hi', null), isFalse);
      expect(ChannelMessage.mentionsUser('@[Martin] hi', ''), isFalse);
    });
  });

  group('notifyOnMention setting', () {
    test('defaults to ENABLED', () {
      expect(AppSettings().notifyOnMention, isTrue);
    });

    test('absent from stored json defaults to ENABLED', () {
      expect(AppSettings.fromJson(const {}).notifyOnMention, isTrue);
    });

    test('round-trips through json and copyWith', () {
      final off = AppSettings().copyWith(notifyOnMention: false);
      expect(off.notifyOnMention, isFalse);
      expect(AppSettings.fromJson(off.toJson()).notifyOnMention, isFalse);
    });
  });
}
