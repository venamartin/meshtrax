import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/structured_message.dart';

void main() {
  group('leadingMentions', () {
    test('the mentions a message starts with, as typed', () {
      expect(
        StructuredMessage.leadingMentions('@[Bob] location: 1,2'),
        '@[Bob]',
      );
      expect(
        StructuredMessage.leadingMentions('@[Bob] @[Ann 🐧]\nsos: help'),
        '@[Bob] @[Ann 🐧]',
      );
    });

    test('none when the message starts with text', () {
      expect(StructuredMessage.leadingMentions('location: 1,2'), '');
      expect(StructuredMessage.leadingMentions('hi @[Bob]'), '');
    });

    test('the card still parses after the mentions', () {
      expect(
        StructuredMessage.parse('@[Bob] location: 47.070123, 15.440123'),
        isA<LocationMessage>(),
      );
    });
  });
}
