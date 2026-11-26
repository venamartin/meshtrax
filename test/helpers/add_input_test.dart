import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/add_input.dart';
import 'package:meshtrax/models/channel.dart';

// One box on the Add page takes any contact or channel format (owner,
// 2026-11-26: "Paste a link and manually add should be combined and just
// take any format you can think of"). Channels have no <...> form.
const _key = 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';
const _secret = '0123456789abcdef0123456789abcdef';

String _hashtagKey(String name) =>
    Channel.formatPskHex(Channel.derivePskFromHashtag(name));

void main() {
  ContactFound contact(String text) => AddInput.read(text)! as ContactFound;
  ChannelFound channel(String text) => AddInput.read(text)! as ChannelFound;

  group('contacts', () {
    test('a meshcore:// contact link', () {
      final c = contact('meshcore://contact/add?name=Anna&public_key=$_key&type=1');
      expect(c.data.name, 'Anna');
      expect(c.data.pubKeyHex, _key);
      expect(c.data.type, 1);
    });

    test('any link with public_key=, like letsmesh.net', () {
      final c = contact('https://letsmesh.net/node?public_key=$_key&name=Ridge');
      expect(c.data.pubKeyHex, _key);
      expect(c.data.name, 'Ridge');
    });

    test('<key:type:name> text, also inside a message', () {
      final c = contact('Here you go: <$_key:2:Hill Top> thanks');
      expect(c.data.name, 'Hill Top');
      expect(c.data.type, 2);
    });

    test('a bare 64-character key, any case', () {
      final c = contact(_key.toUpperCase());
      expect(c.data.pubKeyHex, _key);
      expect(c.data.name, '');
    });
  });

  group('channels', () {
    test('a meshcore:// channel link, also inside a message', () {
      for (final text in [
        'meshcore://channel/add?name=Hiking&secret=$_secret',
        'Join us: meshcore://channel/add?name=Hiking&secret=$_secret see you',
      ]) {
        final c = channel(text);
        expect(c.name, 'Hiking', reason: text);
        expect(c.pskHex, _secret, reason: text);
        expect(c.keyOnly, isFalse, reason: text);
        expect(c.isHashtag, isFalse, reason: text);
      }
    });

    test('#hashtag: the lowercase channel, and what was typed', () {
      final c = channel('#BayArea');
      expect(c.name, '#bayarea');
      expect(c.pskHex, _hashtagKey('#bayarea'));
      expect(c.typedHashtag, '#BayArea');
      final kept = c.withCapitals;
      expect(kept.name, '#BayArea');
      expect(kept.pskHex, _hashtagKey('#BayArea'));
    });

    test('a single word is its hashtag channel', () {
      final c = channel('bayarea');
      expect(c.name, '#bayarea');
      expect(c.typedHashtag, '#bayarea');
    });

    test('a secret key alone: the name is to be typed', () {
      final c = channel(_secret.toUpperCase());
      expect(c.pskHex, _secret);
      expect(c.keyOnly, isTrue);
      expect(c.name, isNull);
    });

    test('a secret key and its name, either side, labelled or not', () {
      for (final text in [
        'Hiking $_secret',
        '$_secret Hiking',
        'name: Hiking\nsecret: $_secret',
        'Hiking, key=$_secret',
      ]) {
        final c = channel(text);
        expect(c.name, 'Hiking', reason: text);
        expect(c.pskHex, _secret, reason: text);
        expect(c.keyOnly, isTrue, reason: text);
      }
    });

    test('the Public key is Public', () {
      final c = channel(Channel.publicChannelPsk);
      expect(c.isPublic, isTrue);
      expect(c.name, 'Public');
    });
  });

  group('nothing it can add', () {
    test('ordinary text, a sentence with a hashtag, a short key', () {
      for (final text in [
        '',
        '   ',
        'hello there',
        'join #team tonight',
        'meshcore://channel/add?name=Hiking',
        _secret.substring(1),
      ]) {
        expect(AddInput.read(text), isNull, reason: text);
      }
    });
  });
}
