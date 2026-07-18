import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel_message.dart';

// The channel notification body is built as
//   ChannelMessage.parseReply(text)?.actualMessage ?? text
// so these cases lock in that a reply's on-wire markup (mention, "re:"
// prefix, quoted snippet and its trailing marker dots) never leaks into
// the notification, while plain messages pass through untouched.
void main() {
  String notificationBodyFor(String wireText) {
    return ChannelMessage.parseReply(wireText)?.actualMessage ?? wireText;
  }

  group('reply markup stripping for notifications', () {
    test('strips mention, re: prefix and ellipsis marker', () {
      const wire = '@[GWQΔ\u{1F353}]\nre:I won\'t be able…\nHere is my answer';
      expect(notificationBodyFor(wire), 'Here is my answer');
    });

    test('handles a sender that uses three ASCII dots as the marker', () {
      const wire = '@[Alice] re:see you soon...actually running late';
      expect(notificationBodyFor(wire), 'actually running late');
    });

    test('drops the mention and re: markup that produced the reported dots', () {
      // The user saw "re:I won't be able......" leak into a notification.
      // Realistic wire form: a foreign sender whose "..." marker is followed
      // by the body on a new line. The mention, the "re:" prefix and the
      // quoted snippet must all be gone from the notification body.
      const wire = '@[GWQΔ\u{1F353}]\nre:I won\'t be able...\nno worries';
      final body = notificationBodyFor(wire);
      expect(body, 'no worries');
      expect(body.contains('re:'), isFalse);
      expect(body.contains('@['), isFalse);
    });

    test('leaves a plain channel message unchanged', () {
      const wire = 'just a normal message';
      expect(notificationBodyFor(wire), 'just a normal message');
    });

    test('leaves a plain @mention (no re:) unchanged', () {
      const wire = '@[Carol] hey are you around';
      expect(notificationBodyFor(wire), '@[Carol] hey are you around');
    });
  });
}
