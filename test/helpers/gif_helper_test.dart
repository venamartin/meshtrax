import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/gif_helper.dart';
import 'package:meshtrax/services/notification_service.dart';

void main() {
  const id = 'EBaCc5MjS9xu';

  group('encodeGif', () {
    test('defaults to a g: code', () {
      expect(GifHelper.encodeGif(id), 'g:$id');
      expect(GifHelper.parseGif(GifHelper.encodeGif(id)), id);
    });

    test('asLink sends a giphy page link', () {
      final link = GifHelper.encodeGif(id, asLink: true);
      expect(link, 'https://giphy.com/gifs/$id');
      expect(GifHelper.parseGif(link), id);
      expect(GifHelper.isGifOnly(link), isTrue);
    });
  });

  group('parseGif and stripGif', () {
    final gifOnly = {
      'g:$id': id,
      'https://media.giphy.com/media/$id/giphy.gif': id,
      'media.giphy.com/media/$id/giphy.gif': id,
      'https://giphy.com/gifs/$id': id,
      'http://giphy.com/gifs/$id': id,
      'giphy.com/gifs/$id/': id,
      'https://www.giphy.com/gifs/$id': id,
      'https://giphy.com/gifs/lion-tiger-cubs-$id': id,
      '  https://giphy.com/gifs/$id  ': id,
    };
    gifOnly.forEach((text, expected) {
      test('"$text" is a GIF and strips to nothing', () {
        expect(GifHelper.parseGif(text), expected);
        expect(GifHelper.stripGif(text), '');
        expect(GifHelper.isGifOnly(text), isTrue);
      });
    });

    test('mention-first g: and links keep the mention', () {
      for (final gif in ['g:$id', 'https://giphy.com/gifs/$id']) {
        final text = '@[Bob] $gif';
        expect(GifHelper.parseGif(text), id);
        expect(GifHelper.stripGif(text), '@[Bob]');
        expect(GifHelper.isGifOnly(text), isFalse);
      }
    });

    test('reply wire body link renders and strips to the header', () {
      const text = '@[Bob]\n>hello..\nhttps://giphy.com/gifs/$id';
      expect(GifHelper.parseGif(text), id);
      expect(GifHelper.stripGif(text), '@[Bob]\n>hello..');
    });

    test('non-GIF text is left alone', () {
      for (final text in [
        'hello there',
        'https://giphy.com/gifs/',
        'xhttps://giphy.com/gifs/$id',
        'https://giphy.com/gifs/$id?x=1',
        'https://example.com/media/$id/giphy.gif',
        'g:short',
      ]) {
        expect(GifHelper.parseGif(text), isNull, reason: text);
        expect(GifHelper.stripGif(text), text.trim(), reason: text);
      }
    });
  });

  test('notification preview says Sent a GIF for both formats', () {
    expect(NotificationService.formatNotificationText('g:$id'), 'Sent a GIF');
    expect(
      NotificationService.formatNotificationText('https://giphy.com/gifs/$id'),
      'Sent a GIF',
    );
    expect(
      NotificationService.formatNotificationText('look @ this'),
      'look @ this',
    );
  });
}
